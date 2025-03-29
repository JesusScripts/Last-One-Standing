local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "GameModeSelector"
gui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = gui

local carousel = Instance.new("Frame")
carousel.Size = UDim2.new(1, 0, 0.8, 0)
carousel.BackgroundTransparency = 1
carousel.Parent = mainFrame

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.2, 0, 0.4, 0)
grid.CellPadding = UDim2.new(0.05, 0, 0.05, 0)
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.VerticalAlignment = Enum.VerticalAlignment.Center
grid.Parent = carousel

local particleEmitter = Instance.new("ParticleEmitter")
particleEmitter.Size = NumberSequence.new(5)
particleEmitter.Texture = "rbxassetid://2452008786"
particleEmitter.Lifetime = NumberRange.new(1, 2)
particleEmitter.Rate = 50
particleEmitter.Speed = NumberRange.new(50)
particleEmitter.Parent = carousel

local spinSound = Instance.new("Sound")
spinSound.SoundId = "rbxassetid://911347055"
spinSound.Parent = gui

local selectSound = Instance.new("Sound")
selectSound.SoundId = "rbxassetid://714662672"
selectSound.Parent = gui

local gameModes = require(game.ReplicatedStorage.GameModesConfig)
local selectedMode = nil
local isSpinning = false

local function CreateModeCard(modeData)
    local card = Instance.new("ImageButton")
    card.Image = modeData.icon or "rbxassetid://123456789"  -- Default fallback icon

    card.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    card.Size = UDim2.new(1, 0, 1, 0)
    
    local glow = Instance.new("ImageLabel")
    glow.Image = "rbxassetid://48965808"
    glow.Size = UDim2.new(1.2, 0, 1.2, 0)
    glow.Position = UDim2.new(-0.1, 0, -0.1, 0)
    glow.BackgroundTransparency = 1
    glow.Visible = false
    glow.Parent = card
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 0.8, 0)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 0.2, 0))
    }
    gradient.Parent = glow
    
    local title = Instance.new("TextLabel")
    title.Text = modeData.name
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Size = UDim2.new(1, 0, 0.2, 0)
    title.Position = UDim2.new(0, 0, 0.8, 0)
    title.BackgroundTransparency = 1
    title.Parent = card
    
    return card
end

local function AnimateCardRotation(targetCard)
    local startTime = tick()
    local spinDuration = 3
    local maxAngle = 360 * 3
    local startRotation = carousel.Rotation
    
    spinSound:Play()
    particleEmitter.Enabled = true
    
    while tick() - startTime < spinDuration do
        local elapsed = tick() - startTime
        local progress = elapsed / spinDuration
        local angle = maxAngle * (1 - math.cos(math.pi * progress / 2))
        
        carousel.Rotation = startRotation + angle
        carousel.Position = UDim2.new(
            0.5, math.sin(angle * math.pi/180) * 50,
            0.5, math.cos(angle * math.pi/180) * 50
        )
        
        RunService.RenderStepped:Wait()
    end
    
    local selectionTween = TweenService:Create(
        targetCard,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad),
        {Size = UDim2.new(1.2, 0, 1.2, 0)}
    )
    selectionTween:Play()
    
    particleEmitter.Enabled = false
    selectSound:Play()
    
    for _, card in ipairs(carousel:GetChildren()) do
        if card:IsA("ImageButton") then
            card.glow.Visible = (card == targetCard)
        end
    end
end

for _, mode in pairs(gameModes) do
    if not mode.icon then
        warn("Game mode ".. mode.name .." is missing icon!")
        continue
    end
    local card = CreateModeCard(mode)

    card.Parent = carousel
    
    card.MouseButton1Click:Connect(function()
        if not isSpinning then
            isSpinning = true
            AnimateCardRotation(card)
            selectedMode = mode.name
            game.ReplicatedStorage.GameModeSelected:FireServer(selectedMode)
            isSpinning = false
        end
    end)
end

-- Camera animation
game.Workspace.CurrentCamera:GetPropertyChangedSignal("CFrame"):Connect(function()
    if isSpinning then
        local cam = game.Workspace.CurrentCamera
        local offset = CFrame.new(
            math.sin(tick()) * 2,
            math.cos(tick()) * 1,
            math.cos(tick()) * 2
        )
        cam.CFrame = cam.CFrame:Lerp(cam.CFrame * offset, 0.1)
    end
end)
