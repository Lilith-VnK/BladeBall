local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local connection
local previousVelocity = nil
local previousPlayerPosition = nil

local function GetBallFromFolder(folder)
    for _, ball in ipairs(folder:GetChildren()) do
        if ball:GetAttribute("realBall") then
            if ball:GetAttribute("parried") == nil then
                ball:SetAttribute("parried", false)
            end
            return ball
        end
    end
    return nil
end

local function ResetConnection()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

workspace.Balls.ChildAdded:Connect(function(child)
    if Player.Character and Player.Character.Parent and Player.Character.Parent.Name == "Alive" then
        local ball = GetBallFromFolder(workspace.Balls)
        if not ball then return end
        ResetConnection()
        connection = ball:GetAttributeChangedSignal("target"):Connect(function()
            ball:SetAttribute("parried", false)
        end)
    end
end)

workspace.TrainingBalls.ChildAdded:Connect(function(child)
    if Player.Character and Player.Character.Parent and Player.Character.Parent.Name ~= "Alive" then
        local ball = GetBallFromFolder(workspace.TrainingBalls)
        if not ball then return end
        ResetConnection()
        connection = ball:GetAttributeChangedSignal("target"):Connect(function()
            ball:SetAttribute("parried", false)
        end)
    end
end)

RunService.PreSimulation:Connect(function()
    local character = Player.Character
    if not character then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local ballFolder = (character.Parent and character.Parent.Name == "Alive") and workspace.Balls or workspace.TrainingBalls

    local ball = GetBallFromFolder(ballFolder)
    if not ball then return end

    local currentVelocity = ball.zoomies.VectorVelocity
    local speed = currentVelocity.Magnitude
    local distance = (hrp.Position - ball.Position).Magnitude

    local curvature = 0
    if previousVelocity and speed > 0 and previousVelocity.Magnitude > 0 then
        local dot = math.clamp(previousVelocity.Unit:Dot(currentVelocity.Unit), -1, 1)
        curvature = math.acos(dot)
    end
    previousVelocity = currentVelocity

    local reactionTimeThreshold = (ballFolder == workspace.TrainingBalls) and 0.7 or 0.55
    if curvature > math.rad(10) then
        reactionTimeThreshold = reactionTimeThreshold + 0.1
    end

    local effectiveThreshold = reactionTimeThreshold
    if speed >= 20 and speed < 70 then
        effectiveThreshold = reactionTimeThreshold * (speed / 70)
    end

    if speed > 100 then
        effectiveThreshold = effectiveThreshold + ((speed - 100) / 150)
    end

    local predictedTime = distance / speed

    local TELEPORT_THRESHOLD = 50
    local TELEPORT_DISTANCE_THRESHOLD = 15
    if previousPlayerPosition then
        local displacement = (hrp.Position - previousPlayerPosition).Magnitude
        if displacement > TELEPORT_THRESHOLD and distance < TELEPORT_DISTANCE_THRESHOLD then
            if ball:GetAttribute("target") == Player.Name and not ball:GetAttribute("parried") then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                ball:SetAttribute("parried", true)
            end
        end
    end

    if ball:GetAttribute("target") == Player.Name and not ball:GetAttribute("parried") and speed > 0 then
        if predictedTime <= effectiveThreshold then
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            ball:SetAttribute("parried", true)
        end
    end

    hrp.CFrame = CFrame.new(hrp.Position, ball.Position)
    previousPlayerPosition = hrp.Position
end)