import numpy as np
import skfuzzy as fuzz
from skfuzzy import control as ctrl
import os
import pickle
import json
import asyncio
import websockets
from datetime import datetime

# Constants
MODEL_FILE = 'combat_model.anfis'

def trimf(x, params):
    return fuzz.trimf(x, params)

def trapmf(x, params):
    return fuzz.trapmf(x, params)

class GameState:
    def __init__(self, **kwargs):
        self.player_health = kwargs.get('player_health', 100.0)
        self.target_health = kwargs.get('target_health', 100.0)
        self.player_force = kwargs.get('player_force', 50.0)
        self.target_force = kwargs.get('target_force', 50.0)
        self.distance = kwargs.get('distance', 10.0)
        self.player_blocks = kwargs.get('player_blocks', 0)
        self.target_blocks = kwargs.get('target_blocks', 0)
        self.ac_timing = kwargs.get('ac_timing', 0.2)

class ANFISCombatModel:
    def __init__(self):
        self._setup_variables()
        self._create_rules()
        self.control_system = ctrl.ControlSystem(self.rules)
        self.simulator = ctrl.ControlSystemSimulation(self.control_system)
    
    def _setup_variables(self):
        """Initialize all fuzzy vars"""
        self.health_diff = ctrl.Antecedent(np.arange(-100, 101, 1), 'health_diff')
        self.force_diff = ctrl.Antecedent(np.arange(-100, 101, 1), 'force_diff')
        self.distance = ctrl.Antecedent(np.arange(0, 25, 0.1), 'distance')
        self.block_diff = ctrl.Antecedent(np.arange(-10, 11, 1), 'block_diff')
        
        self.action = ctrl.Consequent(np.arange(0, 100, 1), 'action')
        
        # Membership funcs
        self._configure_membership()

    def _configure_membership(self):
        """Setup fuzzy membership funcs"""
        # Health difference
        self.health_diff['losing'] = trimf(self.health_diff.universe, [-100, -100, 0])
        self.health_diff['even'] = trimf(self.health_diff.universe, [-20, 0, 20])
        self.health_diff['winning'] = trimf(self.health_diff.universe, [0, 100, 100])

        # Force difference
        self.force_diff['weaker'] = trimf(self.force_diff.universe, [-100, -100, 0])
        self.force_diff['balanced'] = trimf(self.force_diff.universe, [-30, 0, 30])
        self.force_diff['stronger'] = trimf(self.force_diff.universe, [0, 100, 100])

        # Block difference
        self.block_diff['losing'] = trimf(self.block_diff.universe, [-10, -10, 0])
        self.block_diff['even'] = trimf(self.block_diff.universe, [-2, 0, 2])
        self.block_diff['winning'] = trimf(self.block_diff.universe, [0, 10, 10])

        # Distance
        self.distance['close'] = trapmf(self.distance.universe, [0, 0, 5, 8])
        self.distance['medium'] = trapmf(self.distance.universe, [6, 10, 14, 18])
        self.distance['far'] = trapmf(self.distance.universe, [16, 20, 25, 25])

        # Output actions
        self.action['run'] = trimf(self.action.universe, [0, 0, 50])
        self.action['chase'] = trimf(self.action.universe, [30, 50, 70])
        self.action['clash'] = trimf(self.action.universe, [50, 100, 100])
    
    def _create_rules(self):
        """Initial rule base, adapts overtime to have better rules (better player = better rules)"""
        self.rules = [
            # Run rules
            ctrl.Rule(
                self.health_diff['losing'] & 
                (self.force_diff['weaker'] | self.distance['close']),
                self.action['run']
            ),
            
            # Aggressive rules
            ctrl.Rule(
                self.health_diff['winning'] & 
                self.force_diff['stronger'] & 
                self.distance['close'],
                self.action['clash']
            ),
            
            ctrl.Rule(
                self.distance['medium'] & 
                self.force_diff['balanced'],
                self.action['chase']
            )
        ]
    
    def decide(self, state: GameState) -> tuple:
        """Make combat decision"""
        self.simulator.input['health_diff'] = state.player_health - state.target_health
        self.simulator.input['force_diff'] = state.player_force - state.target_force
        self.simulator.input['distance'] = state.distance
        self.simulator.input['block_diff'] = state.player_blocks - state.target_blocks
        
        self.simulator.compute()
        
        # Get best action with confidence
        output = self.simulator.output['action']
        action = max(self.action.terms.items(), 
                    key=lambda x: fuzz.interp_membership(self.action.universe, 
                                                         x[1].mf, 
                                                         output))
        return action[0], output
    
    def update_from_expert(self, state: GameState, expert_action: str):
        """Update data based on expert (duelist) actions"""
        current_action, _ = self.decide(state)
        
        for rule in self.rules:
            if expert_action in rule.consequent.label:
                rule.weight = min(1.0, rule.weight + 0.02)
            elif current_action in rule.consequent.label:
                rule.weight = max(0.1, rule.weight - 0.01)
    
    def update_from_outcome(self, state: GameState, action_taken: str, won: bool):
        """Reinforcement learning update"""
        reward = 1 if won else -1
        
        for rule in self.rules:
            if action_taken in rule.consequent.label:
                rule.weight = np.clip(rule.weight + 0.01 * reward, 0.1, 1.0)

    def save_model(self):
        """Save the trained model"""
        model_dir = os.path.dirname(MODEL_FILE)
        if model_dir and not os.path.exists(model_dir):
            os.makedirs(model_dir, exist_ok=True)

        with open(MODEL_FILE, 'wb') as f:
            pickle.dump({
                'rules': self.rules,
                'membership': {
                    var: {term: mf.params for term, mf in self.__dict__[var].terms.items()}
                    for var in ['health_diff', 'force_diff', 'distance', 'block_diff']
                }
            }, f)

    def load_model(self):
        """Load model if exists"""
        if os.path.exists(MODEL_FILE):
            with open(MODEL_FILE, 'rb') as f:
                data = pickle.load(f)
                self.rules = data['rules']
                self.control_system = ctrl.ControlSystem(self.rules)
                self.simulator = ctrl.ControlSystemSimulation(self.control_system)
                return True
        return False

async def training_server():
    model = ANFISCombatModel()
    if not model.load_model():
        print("No saved model found, starting fresh")
    
    async with websockets.serve(
        lambda ws, path: handle_connection(ws, path, model),
        "localhost", 8765
    ):
        print("ANFIS Training Server Running...")
        await asyncio.Future()

async def handle_connection(websocket, path, model: ANFISCombatModel):
    async for message in websocket:
        try:
            data = json.loads(message)
            response = None

            if data['type'] == 'save_model':
                model.save_model()
                response = {
                    'type': 'save_result',
                    'success': True,
                    'timestamp': datetime.now().isoformat(),
                    'rule_count': len(model.rules)
                }
            
            elif data['type'] == 'expert_action':
                state = GameState(**{k: data[k] for k in [
                    'player_health', 'target_health', 
                    'player_force', 'target_force',
                    'distance', 'player_blocks', 
                    'target_blocks', 'ac_timing'
                ]})
                model.update_from_expert(state, data['expert_action'])
                response = {
                    'type': 'expert_ack',
                    'updated_rules': len([r for r in model.rules 
                                        if data['expert_action'] in r.consequent.label]),
                    'average_weight': np.mean([r.weight for r in model.rules 
                                            if data['expert_action'] in r.consequent.label])
                }

            elif data['type'] == 'reinforcement':
                state = GameState(**data['state'])
                model.update_from_outcome(state, data['action_taken'], data['outcome'] == 'win')
                response = {
                    'type': 'reinforcement_ack',
                    'action': data['action_taken'],
                    'reward': 1 if data['outcome'] == 'win' else -1,
                    'updated_rules': len([r for r in model.rules 
                                        if data['action_taken'] in r.consequent.label])
                }

            elif data['type'] == 'decision_request':
                state = GameState(**data)
                action, confidence = model.decide(state)
                response = {
                    'type': 'decision_response',
                    'action': action,
                    'confidence': float(confidence),
                    'state': data
                }

            if response:
                await websocket.send(json.dumps(response))

        except Exception as e:
            error_msg = f"Error processing {data.get('type', 'unknown')}: {str(e)}"
            print(error_msg)
            await websocket.send(json.dumps({
                'type': 'error',
                'message': error_msg,
                'details': str(e)
            }))

if __name__ == "__main__":
    asyncio.run(training_server())