GameMetatable = getrawmetatable and getrawmetatable(game) or {
    __index = function(self, Index)
            return self[Index]
    end,

    __newindex = function(self, Index, Value)
        self[Index] = Value
    end

}
local function __index(table, key)
    if table == nil then
        return nil
    end
    return GameMetatable.__index(table, key) or rawget(table, key)
end
local function __newindex(table, key, value)
    if table == nil then
        return
    end
    rawset(table, key, value)
    GameMetatable.__newindex(table, key, value)
end
local GetService = __index(game, "GetService")
local FindFirstChild = __index(game, "FindFirstChild")
local FindFirstChildWhichIsA = __index(game, "FindFirstChildWhichIsA")
local WaitForChild = __index(game, "WaitForChild")
local IsA = __index(game, "IsA")

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
    StatsService = GetService(game, "Stats")
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
    end
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




local Remotes = WaitForChild(Services.ReplicatedStorage, "Remotes")
local ForcePower = __index(Remotes, "ForcePower")
local ForcePowerStorage = WaitForChild(Services.ReplicatedStorage, "ForcePowerStorage")


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

-- Actions --

-- local Jump = function()
--     if OnGround(lplrVars.lplrname) then
--         -- lplrwsHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
--         __index(lplrVars.lplrwsHumanoid, "Jump") = true
--     end
-- end

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

-- local function Flip()
-- 	if __index(__index(lplrVars.lplr, "Force"), "Value") >= 25 and FlipCooldown == false and DashCooldown == false and GlobalCooldown == false then
-- 		FlipCooldown = true
-- 		ForcePower:FireServer("Dash", {}, 25)
-- 		if MovementDirection() == "Forward" or MovementDirection() == "Sideways" or MovementDirection() == "Standing Still" then
-- 			__index(ForcePowerStorage, "FlipForward"):Play(nil, nil, 1.35)
--         elseif MovementDirection() == "Backward" then
-- 			__index(ForcePowerStorage, "FlipBackward"):Play(nil, nil, 1.35)
-- 		end
-- 		__index(lplrVars.lplrHumanoid, "WalkSpeed") = 42
-- 		__index(lplrVars.lplrHumanoid, "JumpPower") = 75
-- 		RunService.RenderStepped:wait()
-- 		__index(lplrVars.lplrHumanoid, "Jump") = true
-- 		for i = 1, 13 do
-- 			__index(lplrVars.lplrHumanoid, "WalkSpeed") = 16 + (i * 2)
-- 			task.wait()
-- 		end
-- 		for i = 1, 13 do
-- 			__index(lplrVars.lplrHumanoid, "WalkSpeed") = 42 - (i * 2)
-- 			task.wait()
-- 		end
-- 		__index(lplrVars.lplrHumanoid, "JumpPower") = 50
-- 		FlipCooldown = false
-- 	end
-- end

-- local function Dash()
-- 	if  __index(__index(lplrVars.lplr, "Force"), "Value") >= 30 and FlipCooldown == false and DashCooldown == false and GlobalCooldown == false then
-- 		DashCooldown = true
-- 		__index(ForcePowerStorage, "Dash"):Play(nil, nil, 1.25)
-- 		__index(lplrVars.lplrHumanoid, "WalkSpeed") = 55
-- 		local DashParticles = WaitForChild(ForcePowerStorage, "DashParticles"):Clone()
-- 		DashParticles.Parent = lplrVars.lplrhrp
-- 		DashParticles:Emit(75)
-- 		ForcePower:FireServer("Dash", {}, 30)
-- 		local Sound = Instance.new("Sound")
-- 		Sound.Parent = lplrhrp
-- 		Sound.SoundId = "rbxassetid://203697228"
-- 		Sound.Looped = false
-- 		Sound.Volume = 1
-- 		Sound:Play()
-- 		Sound.Stopped:connect(function()
-- 			Sound:Destroy()
-- 		end)
-- 		task.wait(0.25)
-- 		for i = 1, 24 do
-- 			__index(lplrVars.lplrHumanoid, "WalkSpeed") = 40 - i
-- 			task.wait()
-- 		end
-- 		DashParticles:Destroy()
-- 		DashCooldown = false
-- 	end
-- end

-- local 
-- Lightsaber


-- will be implemented later
local Block = function()
    local Saber = FindFirstChildWhichIsA(lplrVars.lplrws, "Tool")
    local detectedToolType = DetectToolType(Saber)
    if #detectedToolType > 1 and detectedToolType [1] == "Saber" then
        local SaberConfiguration = __index(Saber, "Configuration")
        local SaberType = __index(SaberConfiguration, "LightsaberType")
        local Animations = require(__index(Saber, "Lightsaber_Animations"))
        local saberScript = getsenv(__index(Saber, "Local"))

        local Block1 = LoadAnimation(Animations[detectedToolType[2]].Block1)
        local Block2 = LoadAnimation(Animations[detectedToolType[2]].Block2)
        local Block3 = LoadAnimation(Animations[detectedToolType[2]].Block3)

        if saberScript.BlockHealth > 0 and saberScript.Equip == true and saberScript.CanBlock == true and LocalPlayer.Stunned.Value == false then
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

function CancelBlock()
    local Saber = FindFirstChildWhichIsA(lplrVars.lplrws, "Tool")
    local detectedToolType = DetectToolType(Saber)
    if #detectedToolType > 1 and detectedToolType [1] == "Saber" then
        local SaberConfiguration = __index(Saber, "Configuration")
        local SaberType = __index(SaberConfiguration, "LightsaberType")
        local Animations = require(__index(Saber, "Lightsaber_Animations"))
        local saberScript = getsenv(__index(Saber, "Local"))

        local Block1 = LoadAnimation(Animations[detectedToolType[2]].Block1)
        local Block2 = LoadAnimation(Animations[detectedToolType[2]].Block2)
        local Block3 = LoadAnimation(Animations[detectedToolType[2]].Block3)

        Block1:Stop(); Block2:Stop(); Block3:Stop()
        saberScript.IsBlocking = false
        Saber.RemoteEvent:FireServer("Block", false)
    end
end

local Swing = function()
    local Saber = FindFirstChildWhichIsA(lplrVars.lplrws, "Tool")
    if DetectToolType(Saber)[1] == "Saber" then
        Saber:Activate()
    end
end

local AC_dec = function()
    local Saber = FindFirstChildWhichIsA(lplrVars.lplrws, "Tool")
    if DetectToolType(Saber)[1] == "Saber" then
        local saberScript = getsenv(__index(Saber, "Local"))
        if saberScript.IsBlocking == true then
            CancelBlock()
        end
        Swing()
        task.wait(math.random(5, 15)*0.001)
        Block()
    end
end

---

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

-- Decision Making --


-- Toggle --

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