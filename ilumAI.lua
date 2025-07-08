GameMetatable = getrawmetatable and getrawmetatable(game) or {
    __index = function(self, Index)
            return self[Index]
    end,

    __newindex = function(self, Index, Value)
        self[Index] = Value
    end

}

local __index = GameMetatable.__index
local GetService = __index(game, "GetService")
local FindFirstChild = __index(game, "FindFirstChild")
local FindFirstChildWhichIsA = __index(game, "FindFirstChildWhichIsA")
local WaitForChild = __index(game, "WaitForChild")
local IsA = __index(game, "IsA")

tonumber(LocalPlayer.PlayerGui:WaitForChild("StatsGui").Block.Count.Text)

local Services = {
    Workspace = GetService(game, "Workspace"),
    Players = GetService(game, "Players"),
    RunService = GetService(game, "RunService"),
    UserInputService = GetService(game, "UserInputService"),
    VirtualInputManager = GetService(game, "VirtualInputManager"),
    ReplicatedStorage = GetService(game, "ReplicatedStorage"),
    ScriptContext = GetService(game, "ScriptContext"),
    LogService = GetService(game, "LogService"),
    HttpService = GetService(game, "HttpService"),
    PathfindingService = GetService(game, "PathfindingService"),
    StatsService = GetService(game, "Stats"),
}

getgenv().lplrVars = {
    lplr = __index(Services.Players, "LocalPlayer"),
    lplrChar = __index(__index(Services.Players, "LocalPlayer"), "Character"),
    lplrHumanoid = __index(__index(__index(Services.Players, "LocalPlayer"), "Character"), "Humanoid"),
    lplrHRP = __index(__index(__index(Services.Players, "LocalPlayer"), "Character"), "HumanoidRootPart"),
    lplrPos = __index(__index(__index(__index(Services.Players, "LocalPlayer"), "Character"), "HumanoidRootPart"), "Position"),
    lplrName = __index(__index(Services.Players, "LocalPlayer"), "Name"),
    lplrws = __index(Services.Workspace, __index(__index(Services.Players, "LocalPlayer"), "Name")),
    lplrismoving = function()
        return lplrVars.lplrHumanoid.MoveDirection.Magnitude > 0
    end,
    BlockCount = lplr.PlayerGui:WaitForChild("StatsGui").Block.Count.Text
}

getgenv()._stopMoveToDestination = false

simulate = {
    keypress = function(key)
        keypress(key)
    end,

    keyrelease = function(key)
        keyrelease(key)
    end,

    mouseclick = function(button)
        if button == true then mouse1click() elseif button == false then mouse2click() end
    end,

    mousepress = function(button)
        if button == true then mouse1press() elseif button == false then mouse2press() end
    end,

    mouserelease = function(button)
        if button == true then mouse1release() elseif button == false then mouse2release() end
    end,

    mousemoveabs = function(x, y)
        mousemoveabs(x, y)
    end,

    mousemoverel = function(x, y)
        mousemoverel(x, y)
    end,

    mousescroll = function(px)
        mousescroll(px)
    end,

    jump = function()
        task.spawn(function() 
            keypress(0x20)
            task.wait(0.01)
            keyrelease(0x20)
        end)
    end,

    cameraCFrame = function(pos)
        local camera = Services.Workspace.CurrentCamera
        if not camera then return end
        local targetCFrame = CFrame.new(lplrVars.lplrPos, pos) 
        camera.CFrame = targetCFrame
    end,

    shiftlock = function()
        task.spawn(function() 
            keypress(0x10)
            task.wait(0.01)
            keyrelease(0x10)
        end)
    end,

    move = function(direction, camera)
        local humanoid = lplrVars.lplrHumanoid
        if not humanoid then return end
        humanoid:Move(direction, camera)
    end,

    stopmovingtodestination = function()
        getgenv()._stopMoveToDestination = true
    end,

    stopmoving = function()
        task.spawn(function() 
            keypress(0x57)
            task.wait(0.001)
            keyrelease(0x57)
        end)
    end,

    moveto = function(position, part)
        local humanoid = lplrVars.lplrHumanoid
        if not humanoid then return end
        humanoid:MoveTo(position, part)
    end,

    movetodestination = function(destination)
        local humanoid = lplrVars.lplrHumanoid
        if not humanoid then return end

        getgenv()._stopMoveToDestination = false

        local path = Services.PathfindingService:CreatePath({
            AgentRadius = (lplrVars.lplrHRP and lplrVars.lplrHRP.Size.X / 2) or 2,
            AgentHeight = humanoid.HipHeight or 5,
            AgentCanJump = humanoid.Jump or true,
            AgentJumpHeight = humanoid.JumpHeight or 10,
            AgentMaxSlope = 45
        })
        path:ComputeAsync(lplrVars.lplrPos, destination)

        if path.Status == Enum.PathStatus.Success or path.Status == Enum.PathStatus.ClosestOutOfRange then
            local waypoints = path:GetWaypoints()
            task.spawn(function()
                for i, waypoint in ipairs(waypoints) do
                    if getgenv()._stopMoveToDestination then
                        break
                    end
                    humanoid:MoveTo(waypoint.Position)
                    if waypoint.Action == Enum.PathWaypointAction.Jump then
                        if Services.UserInputService then
                            simulate.jump()
                        end
                    end
                    local finished = false
                    local conn
                    conn = humanoid.MoveToFinished:Connect(function()
                        finished = true
                    end)
                    while not finished do
                        if getgenv()._stopMoveToDestination then
                            if conn then conn:Disconnect() end
                            return
                        end
                        task.wait(0.01)
                    end
                    if conn then conn:Disconnect() end
                end
            end)
        else
            -- warn("Path could not be computed!")
        end
    end,

    lookat = function(targetPosition)
        local hrp = lplrVars.lplrHRP
        if not hrp then return end
        local currentPos = hrp.Position
        local lookAt = CFrame.new(currentPos, targetPosition)
        hrp.CFrame = CFrame.new(currentPos, targetPosition)
    end,

    VIM = {
        -- Input Simulation
        SendKeyEvent = function(isPressed, keyCode, isRepeatedKey, layerCollector)
            return Services.VirtualInputManager:SendKeyEvent(isPressed, keyCode, isRepeatedKey, layerCollector)
        end,
        SendMouseButtonEvent = function(x, y, mouseButton, isDown, layerCollector, repeatCount)
            return Services.VirtualInputManager:SendMouseButtonEvent(x, y, mouseButton, isDown, layerCollector, repeatCount)
        end,
        SendMouseMoveEvent = function(x, y, layerCollector)
            return Services.VirtualInputManager:SendMouseMoveEvent(x, y, layerCollector)
        end,
        SendMouseMoveDeltaEvent = function(deltaX, deltaY, layerCollector)
            return Services.VirtualInputManager:SendMouseMoveDeltaEvent(deltaX, deltaY, layerCollector)
        end,
        SendMouseWheelEvent = function(x, y, isForwardScroll, layerCollector)
            return Services.VirtualInputManager:SendMouseWheelEvent(x, y, isForwardScroll, layerCollector)
        end,
        SendTouchEvent = function(touchId, state, x, y)
            return Services.VirtualInputManager:SendTouchEvent(touchId, state, x, y)
        end,
        SendTextInputCharacterEvent = function(str, layerCollector)
            return Services.VirtualInputManager:SendTextInputCharacterEvent(str, layerCollector)
        end,
        SendAccelerometerEvent = function(x, y, z)
            return Services.VirtualInputManager:SendAccelerometerEvent(x, y, z)
        end,
        SendGyroscopeEvent = function(quatX, quatY, quatZ, quatW)
            return Services.VirtualInputManager:SendGyroscopeEvent(quatX, quatY, quatZ, quatW)
        end,
        SendGravityEvent = function(x, y, z)
            return Services.VirtualInputManager:SendGravityEvent(x, y, z)
        end,
        SendScroll = function(x, y, deltaX, deltaY, options, layerCollector)
            return Services.VirtualInputManager:SendScroll(x, y, deltaX, deltaY, options, layerCollector)
        end,
        HandleGamepadAxisInput = function(objectId, keyCode, x, y, z)
            return Services.VirtualInputManager:HandleGamepadAxisInput(objectId, keyCode, x, y, z)
        end,
        HandleGamepadButtonInput = function(deviceId, keyCode, buttonState)
            return Services.VirtualInputManager:HandleGamepadButtonInput(deviceId, keyCode, buttonState)
        end,
        HandleGamepadConnect = function(deviceId)
            return Services.VirtualInputManager:HandleGamepadConnect(deviceId)
        end,
        HandleGamepadDisconnect = function(deviceId)
            return Services.VirtualInputManager:HandleGamepadDisconnect(deviceId)
        end,

        -- Playback & Recording
        StartRecording = function()
            return Services.VirtualInputManager:StartRecording()
        end,
        StopRecording = function()
            return Services.VirtualInputManager:StopRecording()
        end,
        StartPlaying = function(fileName)
            return Services.VirtualInputManager:StartPlaying(fileName)
        end,
        StartPlayingJSON = function(json)
            return Services.VirtualInputManager:StartPlayingJSON(json)
        end,
        StopPlaying = function()
            return Services.VirtualInputManager:StopPlaying()
        end,
        WaitForInputEventsProcessed = function()
            return Services.VirtualInputManager:WaitForInputEventsProcessed()
        end,

        -- Miscellaneous
        SetInputTypesToIgnore = function(inputTypesToIgnore)
            return Services.VirtualInputManager:SetInputTypesToIgnore(inputTypesToIgnore)
        end,
        sendRobloxEvent = function(namespace, detail, detailType)
            return Services.VirtualInputManager:sendRobloxEvent(namespace, detail, detailType)
        end,
        sendThemeChangeEvent = function(themeName)
            return Services.VirtualInputManager:sendThemeChangeEvent(themeName)
        end,
        Dump = function()
            return Services.VirtualInputManager:Dump()
        end,
    }
}

getgenv().targetData = {
    ExampleData = {targetWs = FindFirstChild(Services.Workspace, "ExampleName"),
                        targetACTimes = {},
                        Stunned = false,
                        Force = 100,
                        Health = 100,
                        isSafeAC = false,
                        currentACTiming = 0,
                        prevBlockCount = 6,
                        saberEquipped = false,
                        -- HRP = __index(FindFirstChild(Services.Workspace, "ExampleName"), "HumanoidRootPart"),
                        distanceFromLplr = 0,
                        acData = {
                                samples = {},
                                lastState = "saber.Blocking",
                                lastFalseTime = 0
                            },
                                                },
}


local Remotes = WaitForChild(Services.ReplicatedStorage, "Remotes")
local ForcePower = __index(Remotes, "ForcePower")
local ForcePowerStorage = WaitForChild(Services.ReplicatedStorage, "ForcePowerStorage")

-- Constants
local AC_VARIATION_THRESHOLD = 0.03 
local REQUIRED_AC_SAMPLES = 2

--

local initTargetData = function(playerName)
    if not targetData[playerName] then
        local targetWs = FindFirstChild(Services.Workspace, playerName)
        targetData[playerName] =                {
                                                targetWs = targetWs,
                                                targetACTimes = {},
                                                Stunned = false,
                                                Health = __index(targetWs, "Humanoid").Health.Value,
                                                Force = __index(__index((FindFirstChild(Services.Players, playerName)), "Force"), "Value"),
                                                isSafeAC = false,
                                                currentACTiming = 0,
                                                prevBlockCount = 6,
                                                saberEquipped = false,
                                                HRP = __index(targetWs, "HumanoidRootPart"),
                                                distanceFromLplr = 0,
                                                -- acData = {
                                                --         samples = {},
                                                --         lastState = saber.Blocking,
                                                --         lastFalseTime = 0
                                                --     }
                                                }
    end
end


local updateTargetData = function(playerName, data)
    local targetPlayers = FindFirstChild(Services.Players, playerName)
    local targetWs = FindFirstChild(Services.Workspace, playerName)

    data.Health = __index(__index(targetWs, "Health"), "Value")
    data.Force = __index(__index(targetPlayers, "Force"), "Value")
    data.Stunned = __index(__index(targetPlayers, "Stunned"), "Value")
    data.saberEquipped = checkIfSaberEquipped(playerName)
    if data.saberEquipped then
        data.prevBlockCount = __index(__index(__index(targetWs, "Lightsaber"), "Configuration"), "BlockHealth")
    end
    data.HRP = __index(targetWs, "HumanoidRootPart")
    data.distanceFromLplr = (data.HRP.Position - lplrVars.lplrPos.Position).Magnitude
end


local OnGround = function(player)
    local player = __index(Services.Players, player)
    local playerchar = __index(player, "Character")
    local playerhumanoid = __index(playerchar, "Humanoid")
    local playerrootpart = __index(playerhumanoid, "RootPart")
    local playervelocity = __index(playerrootpart, "Velocity")
    return playervelocity.Y == 0 or playervelocity.Y > 0
end

local DetectToolType = function(tool)
    if tool and typeof(tool) == "Instance" and tool:IsA("Tool") then
        if FindFirstChild(tool, "Lightsaber_Animations") then
            return {"Saber", tool.Configuration.LightsaberType.Value}
        elseif FindFirstChild(tool, "GunSettings") or tool.Name == "Flamethrower" then
            return {"Gun"}
        end
    end
end

local LoadAnimation = function(Id)
	local Animation = Instance.new("Animation")
	Animation.Parent = lplrchar
	Animation.AnimationId = "rbxassetid://"..tostring(Id)
	return lplrchar.Humanoid:LoadAnimation(Animation)
end

local function MovementDirection()
    local velocity = __index(lplrVars.lplrhrp, "AssemblyLinearVelocity")
    local lookvector = __index(__index(lplrVars.lplrhrp, "CFrame"), "LookVector")
    local rightvector = __index(__index(lplrVars.lplrhrp, "CFrame"), "RightVector")

    local forwarddot = velocity:Dot(lookvector)
    local sidewaysdot = velocity:Dot(rightvector)

    local movementdirection = ""

    if velocity.Magnitude < 0.1 then
        movementdirection = "Standing Still"
    elseif forwarddot > 0 then
        movementdirection = "Forward"
    elseif forwarddot < 0 then
        movementdirection = "Backward"
    elseif math.abs(sidewaysdot) > 0.1 then
        movementdirection = "Sideways"
    end

    return movementdirection
end

-- Decision Making --

local analyzeACTiming = function(playerName, saber)
    if not targetData[playerName] then
        targetData[playerName] = {
            acData = {
                samples = {},
                lastState = saber.Blocking,
                lastFalseTime = 0
            }
        }
    end

    local tracker = targetData[playerName].acData

    if tracker.connection then
        tracker.connection:Disconnect()
    end

    local saberBlocking = __index(saber, "Blocking")

    tracker.connection = saberBlocking:GetPropertyChangedSignal("Value"):Connect(function()
        local current = saberBlocking.Value

        if tracker.lastState == false and current == true then
            local now = os.clock()
            if tracker.lastFalseTime > 0 then
                local acTime = now - tracker.lastFalseTime

                table.insert(tracker.samples, acTime)
                if #tracker.samples > REQUIRED_SAMPLES then
                    table.remove(tracker.samples, 1)
                end
                    -- aa
                if #tracker.samples == REQUIRED_SAMPLES then
                    local diff = math.abs(tracker.samples[1] - tracker.samples[2])
                    targetData[playerName].isSafeAC = (diff <= AC_VARIATION_THRESHOLDD)
                    targetData[playerName].lastACTiming = (tracker.samples[1] + tracker.samples[2]) / 2
                end
            end
        end
        if current == false then
            tracker.lastFalseTime = os.clock()
        end

        tracker.lastState = current
    end)
end

local resetACTiming = function(playerName)
    if targetData[playerName] and targetData[playerName].acData then
        targetData[playerName].acData.samples = {}
        targetData[playerName].isSafeAC = false
    end
end


local predictLanding = function(fallingPlayerWs, targetPlayerWs)
    
    local fallingHRP = FindFirstChild(fallingPlayerWs, "HumanoidRootPart")
    local targetHRP = FindFirstChild(targetPlayerWs, "HumanoidRootPart")

    local fallTime = calculateFreefallTime(fallingHRP, targetHRP.Position.Y)
    local landingPosition = predictHorizontalPosition(targetHRP, fallTime)
    
    return {
        position = landingPosition,
        time = fallTime,
        horizontalLandingDisplacement = (landingPosition - targetHRP.Position) * Vector3.new(1, 0, 1)
    }
end

local calculateFreefallTime = function(fallingHRP, targetY)
    local GRAVITY = workspace.Gravity
    local TERMINAL_VELOCITY = 120 
    local currentFallSpeed = -fallingHRP.Velocity.Y
    
    if currentFallSpeed >= TERMINAL_VELOCITY then
        return (fallingHRP.Position.Y - targetY) / TERMINAL_VELOCITY
    end
    
    local timeToTerminalVelocity = (TERMINAL_VELOCITY - currentFallSpeed) / GRAVITY
    local accelerationDistance = currentFallSpeed * timeToTerminalVelcoity + 0.5 * GRAVITY * timeToTerminalVelcoity^2
    local totalFallDistance = fallingHRP.Position.Y - targetY
    

    -- quadratic solution, errors if solution is complex
    if totalFallDistance <= accelerationDistance then
        return (-currentFallSpeed + math.sqrt(currentFallSpeed^2 + 2 * GRAVITY * totalFallDistance)) / GRAVITY
    end
    
    local remainingDistance = totalFallDistance - accelerationDistance
    return timeToTerminalVelcoity + (remainingDistance / TERMINAL_VELOCITY)
end

local predictHorizontalLandingPosition = function(targetHRP, fallingDuration)
    local horizontalVelocity = Vector3.new(
        targetHRP.Velocity.X,
        0,
        targetHRP.Velocity.Z
    )
    return targetHRP.Position + (horizontalVelocity * duration)
end


local checkIfSaberEquipped = function(targetName)
    if not FindFirstChild(FindFirstChild(Services.Workspace, targetName), "Lightsaber") then
        return false
    end

    return true
end

local detectIfClashing = function(targetName)
    if not targetData[playerName] then
        initTargetData(playerName)
    end
    local data = targetData[playerName]

    if not data.saberEquipped then return end

    local targetSaber = __index(data.targetWs, "Lightsaber")

    if data.distanceFromLplr <= 6 then
        if data.Stunned and data.prevBlockCount < 6 then
            return true
        end
    end
    return false
end

local runChaseOrClash = function(playerName)
    local opponentData = targetData[playerName]

    local opponentHealth = targetData[playerName].Health
    local opponentForce = targetData[playerName].Force
    local opponentStunned = targetData[playerName].Stunned
    local opponentBlocks = targetData[playerName].prevBlockCount
    local opponentForce = targetData[playerName].Force

    local lplrHealth = lplrVars.lplrHumanoid.Health

    local lplrHealth = lplrVars.lplrHumanoid.Health
    if lplrHealth <= 23 and opponentHealth > 50 then
        return "Run"
    
    -- check if losing clash
    elseif (lplrVars.BlockCount < opponentBlocks) or (lplrVars.BlockCount <= 1) then
        return "Run"
    end
end


-- Actions 

local Jump = function()
    if OnGround(lplrVars.lplrname) then
        -- lplrwsHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        lplrVars.lplrwsHumanoid.Jump = true
    end
end

-- Force


local Abilities = {
	"Lightning",
	"Choke",
	"Rage",
	"Push",
	"Telekinesis",
	"Grab",
	"Barrier",
	"Heal",
	"Mindtrick",
	"ForceRepulse"
}

local FlipCooldown = false

local GlobalCooldown
-- task.spawn(function()
--     while task.wait() do
--         GlobalCooldown = StatsGuiLocalScript.GlobalCooldown
--     end
-- end)

local DashCooldown = false

local function SimulateFlip()
	if __index(__index(lplrVars.lplr, "Force"), "Value") >= 25 and FlipCooldown == false and DashCooldown == false and GlobalCooldown == false then
		FlipCooldown = true
		ForcePower:FireServer("Dash", {}, 25)
		if MovementDirection() == "Forward" or MovementDirection() == "Sideways" or MovementDirection() == "Standing Still" then
			FlipForward.FlipForward:Play(nil, nil, 1.35)
        elseif MovementDirection() == "Backward" then
			FlipBackward.FlipBackward:Play(nil, nil, 1.35)
		end
		lplrVars.lplrHumanoid.Walkspeed = 42
		lplrVars.lplrHumanoid.JumpPower = 75
		RunService.RenderStepped:wait()
		lplrVars.lplrHumanoid.Jump = true
		for i = 1, 13 do
			lplrVars.lplrHumanoid.Walkspeed = 16 + (i * 2)
			task.wait()
		end
		for i = 1, 13 do
			lplrVars.lplrHumanoid.Walkspeed = 42 - (i * 2)
			task.wait()
		end
		lplrVars.lplrHumanoid.JumpPower = 50
		FlipCooldown = false
	end
end

local function SimulateDash()
	if  __index(__index(lplrVars.lplr, "Force"), "Value") >= 30 and FlipCooldown == false and DashCooldown == false and GlobalCooldown == false then
		DashCooldown = true
		FlipForward.Dash:Play(nil, nil, 1.25)
		lplrVars.lplrHumanoid.Walkspeed = 55
		local DashParticles = WaitForChild(ForcePowerStorage, "DashParticles"):Clone()
		DashParticles.Parent = lplrVars.lplrhrp
		DashParticles:Emit(75)
		ForcePower:FireServer("Dash", {}, 30)
		local Sound = Instance.new("Sound")
		Sound.Parent = lplrhrp
		Sound.SoundId = "rbxassetid://203697228"
		Sound.Looped = false
		Sound.Volume = 1
		Sound:Play()
		Sound.Stopped:connect(function()
			Sound:Destroy()
		end)
		task.wait(0.25)
		for i = 1, 24 do
			lplrVars.lplrHumanoid.Walkspeed = 40 - i
			task.wait()
		end
		DashParticles:Destroy()
		DashCooldown = false
	end
end


-- will be implemented later
local function SimulateBlock()
    local Saber = FindFirstChildWhichIsA(lplrVars.lplrws, "Tool")
    local detectedToolType = DetectToolType(Saber)
    if #detectedToolType > 1 and detectedToolType [1] == "Saber" then
        local SaberConfiguration = __index(Saber, "Configuration")
        local SaberType = __index(SaberConfiguration, "LightsaberType")
        local Animations = require(__index(Saber, "Lightsaber_Animations"))
        local saberScript = getsenv(Saber.Local)

        local Block1 = LoadAnimation(Animations[detectedToolType[2]].Block1)
        local Block2 = LoadAnimation(Animations[detectedToolType[2]].Block2)
        local Block3 = LoadAnimation(Animations[detectedToolType[2]].Block3)

        if saberScript.BlockHealth > 0 and saberScript.Equip == true and saberScript.CanBlock == true and lplrVars.lplr.Stunned.Value == false then
            local RandomNumber = math.random(1, 3)
            if RandomNumber == 1 then
                Block1:Play()
            elseif RandomNumber == 2 then
                Block2:Play()
            else
                Block3:Play()
            end
            Saber.RemoteEvent:FireServer("Block", true)
            saberScript.IsBlocking = true
        end
    end
end

local function SimulateCancelBlock()
    local Saber = FindFirstChildWhichIsA(lplrVars.lplrws, "Tool")
    local detectedToolType = DetectToolType(Saber)
    if #detectedToolType > 1 and detectedToolType [1] == "Saber" then
        local SaberConfiguration = __index(Saber, "Configuration")
        local SaberType = __index(SaberConfiguration, "LightsaberType")
        local Animations = require(__index(Saber, "Lightsaber_Animations"))
        local saberScript = getsenv(Saber.Local)

        local Block1 = LoadAnimation(Animations[detectedToolType[2]].Block1)
        local Block2 = LoadAnimation(Animations[detectedToolType[2]].Block2)
        local Block3 = LoadAnimation(Animations[detectedToolType[2]].Block3)

        Block1:Stop(); Block2:Stop(); Block3:Stop()
        saberScript.IsBlocking = false
        Saber.RemoteEvent:FireServer("Block", false)
    end
end

local function SimulateSwing()
    local Saber = FindFirstChildWhichIsA(lplrVars.lplrws, "Tool")
    if DetectToolType(Saber)[1] == "Saber" then
        Saber:Activate()
    end
end

local function SimulateAC()
    local Saber = FindFirstChildWhichIsA(lplrVars.lplrws, "Tool")
    if DetectToolType(Saber)[1] == "Saber" then
        local saberScript = getsenv(Saber.Local)
        if saberScript.IsBlocking == true then
            SimulateCancelBlock()
        end
        SimulateSwing()
        task.wait(math.random(5, 15)*0.001)
        SimulateBlock()
    end
end

local mouse2HeldDown = false

local AC = function()
    local Saber = FindFirstChildWhichIsA(lplrVars.lplrws, "Tool")
    if DetectToolType(Saber)[1] == "Saber" then
        if mouse2HeldDown then
            simulate.mouserelease(false)
            mouse2HeldDown = false
        end
        simulate.mouseclick(true)
        wait(0.05)
        simulate.mouserelease(true)
        task.wait(math.random(5, 15)*0.001)
        simulate.mousepress(false)
        task.wait(0.1 // 128)
        simulate.mouserelease(false)
    end
end

local smartAC = function(targetName)
    --
end



-- Toggle --

local Bot = function()
    -- TBI
end

local IsMobile = false
if not __index(Services.UserInputService, "MouseEnabled") then
	IsMobile = true
elseif not __index(Services.UserInputService, "KeyboardEnabled") and __index(Services.UserInputService, "TouchEnabled") then
	IsMobile = true
elseif not __index(Services.UserInputService, "KeyboardEnabled") or __index(Services.UserInputService, "TouchEnabled") then
	if __index(__index(StatsGui, "AbsoluteSize"), "X") <= 500 or __index(__index(StatsGui, "AbsoluteSize"), "Y") <= 500 then
		IsMobile = true
	end
elseif __index(Services.UserInputService, "AccelerometerEnabled") then
	IsMobile = true
elseif __index(Services.UserInputService, "GyroscopeEnabled") then
	IsMobile = true
end

local toggle = false

local function ToggleAI(input, gameProcessedEvent)
    if gameProcessedEvent or IsMobile then return end
    if input.KeyCode == Enum.KeyCode.R then
        toggle = not toggle
    end
end

AC()