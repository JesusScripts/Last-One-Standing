local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local HexAGone = {}

HexAGone.Config = {
	Position = Vector3.new(483, 120, 0),
	FloorCount = 3,
	HexSize = 8,
	GridWidth = 15,
	GridLength = 15,
	HexagonGap = 0.1,
	DisappearTime = 1.5,       -- Slower disappear time
	DisappearDropDistance = 2,
	FloorSpacing = 25,
	EliminationCount = 8,
	FloatHeight = 15,
	FloatDuration = 3,
	CollisionRadius = 4.5,
	VerticalCheckRange = 8,
	EdgeBoostForce = 5,
	EdgeBoostHeight = 2,
	HexHeight = 0.8,
	MaxHorizontalSpeed = 30,
	MaxVerticalSpeed = 60,
	JumpPower = 65,             -- Improved jump power
	Colors = {
		Color3.fromRGB(255, 100, 100),
		Color3.fromRGB(100, 100, 255),
		Color3.fromRGB(100, 255, 100),
	}
}

-- Set up collision groups
local function setupCollisions()
	local groups = {"Players", "Hexagons", "AntiClimb"}
	for _, name in ipairs(groups) do
		if not PhysicsService:IsCollisionGroupRegistered(name) then
			PhysicsService:RegisterCollisionGroup(name)
		end
	end

	PhysicsService:CollisionGroupSetCollidable("Players", "Hexagons", true)
	PhysicsService:CollisionGroupSetCollidable("Players", "AntiClimb", true)
	PhysicsService:CollisionGroupSetCollidable("Hexagons", "AntiClimb", false)
end

function HexAGone:CreateHexagon(position, color, floor)
	local hex = Instance.new("Model")
	hex.Name = "Hex_" .. floor

	-- Base part
	local base = Instance.new("Part")
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(self.Config.HexHeight, self.Config.HexSize - self.Config.HexagonGap/2, self.Config.HexSize - self.Config.HexagonGap/2)
	base.Orientation = Vector3.new(0, 0, 90)
	base.Position = position
	base.Color = color
	base.Anchored = true
	base.CollisionGroup = "Hexagons"
	base.Parent = hex
	hex.PrimaryPart = base

	-- Top visual
	local top = base:Clone()
	top.Size = Vector3.new(0.1, base.Size.Y * 0.95, base.Size.Z * 0.95)
	top.Position = position + Vector3.new(0, (self.Config.HexHeight / 2) - 0.05, 0)
	top.CanCollide = false
	top.Parent = hex

	-- Anti-climb barrier
	local antiClimb = Instance.new("Part")
	antiClimb.Shape = Enum.PartType.Cylinder
	antiClimb.Size = Vector3.new(2.5, base.Size.Y * 0.9, base.Size.Z * 0.9)
	antiClimb.Orientation = Vector3.new(0, 0, 90)
	antiClimb.Position = position + Vector3.new(0, self.Config.HexHeight + 1.25, 0)
	antiClimb.Transparency = 1
	antiClimb.Anchored = true
	antiClimb.CollisionGroup = "AntiClimb"
	antiClimb.Parent = hex

	-- Edge collision 
	local rim = Instance.new("Part")
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(0.8, base.Size.Y * 0.6, base.Size.Z * 0.6)
	rim.Orientation = Vector3.new(0, 0, 90)
	rim.Position = position + Vector3.new(0, (self.Config.HexHeight / 2) - 0.3, 0)
	rim.Transparency = 0.98
	rim.Anchored = true
	rim.CollisionGroup = "Hexagons"
	rim.Parent = hex

	-- Store data
	hex:SetAttribute("Floor", floor)
	hex:SetAttribute("Active", true)
	hex:SetAttribute("Position2D", Vector2.new(position.X, position.Z))
	hex:SetAttribute("ModelPosition", position)
	hex:SetAttribute("LastTouched", 0)
	hex:SetAttribute("BaseColor", color)

	return hex
end

function HexAGone:CreateArena(centerPos)
	setupCollisions()
	centerPos = Vector3.new(centerPos.X, self.Config.Position.Y, centerPos.Z)

	local arena = Instance.new("Model")
	arena.Name = "HexAGoneArena"

	local hexContainer = Instance.new("Model")
	hexContainer.Name = "HexContainer"
	hexContainer.Parent = arena

	-- Create floors
	for floor = 1, self.Config.FloorCount do
		local floorModel = Instance.new("Model")
		floorModel.Name = "Floor_" .. floor
		floorModel.Parent = hexContainer

		local floorY = centerPos.Y - (floor * self.Config.FloorSpacing)
		local color = self.Config.Colors[floor] or Color3.fromRGB(255, 255, 255)

		for x = -self.Config.GridWidth/2, self.Config.GridWidth/2 do
			for z = -self.Config.GridLength/2, self.Config.GridLength/2 do
				local offset = z % 2 == 0 and self.Config.HexSize/2 or 0
				local pos = Vector3.new(
					centerPos.X + (x * self.Config.HexSize) + offset,
					floorY,
					centerPos.Z + (z * self.Config.HexSize * 0.866)
				)
				local hex = self:CreateHexagon(pos, color, floor)
				hex.Parent = floorModel
			end
		end
	end

	-- Create barriers
	local barriers = Instance.new("Model")
	barriers.Name = "Barriers"
	barriers.Parent = arena

	local barrierY = centerPos.Y - (self.Config.FloorCount * self.Config.FloorSpacing / 2)
	local barrierHeight = self.Config.FloorCount * self.Config.FloorSpacing + 50
	local width = (self.Config.GridWidth + 2) * self.Config.HexSize
	local length = (self.Config.GridLength + 2) * self.Config.HexSize

	local function createBarrier(name, size, pos)
		local b = Instance.new("Part")
		b.Name = name
		b.Size = size
		b.Position = pos
		b.Anchored = true
		b.CanCollide = true
		b.Transparency = 1
		b.CollisionGroup = "AntiClimb"
		b.Parent = barriers
	end

	-- Create walls
	createBarrier("NorthWall", Vector3.new(width, barrierHeight, 1), Vector3.new(centerPos.X, barrierY, centerPos.Z + length/2))
	createBarrier("SouthWall", Vector3.new(width, barrierHeight, 1), Vector3.new(centerPos.X, barrierY, centerPos.Z - length/2))
	createBarrier("EastWall", Vector3.new(1, barrierHeight, length), Vector3.new(centerPos.X + width/2, barrierY, centerPos.Z))
	createBarrier("WestWall", Vector3.new(1, barrierHeight, length), Vector3.new(centerPos.X - width/2, barrierY, centerPos.Z))
	createBarrier("Bottom", Vector3.new(width, 1, length), Vector3.new(centerPos.X, centerPos.Y - (self.Config.FloorCount * self.Config.FloorSpacing) - 30, centerPos.Z))

	arena.Parent = workspace
	return arena
end

function HexAGone:SetupGame()
	local playerData = {}
	local hexesByFloor = {}
	local gameActive = true
	local gameStarted = false
	local eliminatedCount = 0

	-- Initialize hexagon collections
	local hexArena = workspace:FindFirstChild("HexAGoneArena")
	if not hexArena then return end

	local hexContainer = hexArena:FindFirstChild("HexContainer")
	if not hexContainer then return end

	-- Group hexes by floor
	for i = 1, self.Config.FloorCount do
		hexesByFloor[i] = {}
		local floor = hexContainer:FindFirstChild("Floor_" .. i)
		if floor then
			for _, hex in pairs(floor:GetChildren()) do
				if hex:GetAttribute("Active") then
					table.insert(hexesByFloor[i], hex)
				end
			end
		end
	end

	-- Create UI
	local function createCountdownUI()
		local ui = Instance.new("ScreenGui")
		ui.Name = "HexAGoneUI"

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0.3, 0, 0.2, 0)
		frame.Position = UDim2.new(0.35, 0, 0.4, 0)
		frame.BackgroundTransparency = 1
		frame.Parent = ui

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.Text = "3"
		text.TextStrokeTransparency = 0
		text.Parent = frame

		return ui
	end

	-- Simple disappear effect for hex
	local function removeHex(hex, floorIndex, player)
		if not hex or not hex:GetAttribute("Active") then return end
		hex:SetAttribute("Active", false)

		-- Get position
		local position = hex:GetAttribute("ModelPosition") or hex.PrimaryPart.Position

		-- Simple color change to show warning
		for _, part in pairs(hex:GetChildren()) do
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(0.2), {
					Color = Color3.fromRGB(255, 255, 0)
				}):Play()
			end
		end

		-- Apply boost if player is on this hex
		if player then
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local hrp = char.HumanoidRootPart
				-- Simple boost upward and slightly random direction
				hrp.Velocity = Vector3.new(
					math.random(-10, 10) / 10 * self.Config.EdgeBoostForce,
					self.Config.EdgeBoostHeight,
					math.random(-10, 10) / 10 * self.Config.EdgeBoostForce
				)
			end
		end

		-- Simple sound effect
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://142497291" -- Swoosh sound
		sound.Volume = 0.5
		sound.PlaybackSpeed = 1
		sound.Parent = hex.PrimaryPart
		sound:Play()
		game.Debris:AddItem(sound, 1)

		-- Wait a moment before dropping
		delay(0.5, function()
			-- Simple animation - drop and fade out
			for _, part in pairs(hex:GetChildren()) do
				if part:IsA("BasePart") then
					TweenService:Create(part, TweenInfo.new(self.Config.DisappearTime), {
						Position = part.Position - Vector3.new(0, self.Config.DisappearDropDistance, 0),
						Transparency = 1,
						Color = Color3.fromRGB(80, 80, 80)
					}):Play()

					-- Disable collision immediately
					part.CanCollide = false
				end
			end

			-- Remove from collection
			for i, h in pairs(hexesByFloor[floorIndex]) do
				if h == hex then
					table.remove(hexesByFloor[floorIndex], i)
					break
				end
			end

			-- Delete after delay
			delay(self.Config.DisappearTime, function()
				if hex and hex.Parent then
					hex:Destroy()
				end
			end)
		end)
	end

	-- Check for hexes at position
	local function checkHexesAt(position, player)
		local position2D = Vector2.new(position.X, position.Z)
		local pd = playerData[player.UserId]
		if not pd then return end

		local floorIndex
		for i = 1, self.Config.FloorCount do
			local floorY = self.Config.Position.Y - (i * self.Config.FloorSpacing)
			if math.abs(position.Y - floorY) < self.Config.VerticalCheckRange then
				floorIndex = i
				break
			end
		end

		if not floorIndex then return end

		for _, hex in pairs(hexesByFloor[floorIndex]) do
			if hex:GetAttribute("Active") then
				local hexPos2D = hex:GetAttribute("Position2D")
				if hexPos2D and (position2D - hexPos2D).Magnitude < self.Config.CollisionRadius then
					local lastHex = pd.lastHexes[floorIndex]
					if not lastHex or lastHex ~= hex then
						pd.lastHexes[floorIndex] = hex

						local now = tick()
						local lastTouch = hex:GetAttribute("LastTouched") or 0
						if now - lastTouch > 0.1 then
							hex:SetAttribute("LastTouched", now)
							removeHex(hex, floorIndex, player)
						end
					end
				end
			end
		end
	end

	-- Check position between frames
	local function checkMovement(player, lastPos, currentPos)
		if not lastPos or not currentPos then return end

		local dir = (currentPos - lastPos).Unit
		local dist = (currentPos - lastPos).Magnitude
		local steps = math.min(5, math.ceil(dist / (self.Config.CollisionRadius / 2)))

		if steps > 1 then
			for i = 1, steps - 1 do
				local pos = lastPos + dir * (dist * (i / steps))
				checkHexesAt(pos, player)
			end
		end
	end

	-- Anti-exploit function for characters
	local function setupAntiExploit(character)
		if not character then return end

		-- Set collision groups
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Players"
			end
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			-- Disable climbing
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)

			-- Stop climbing animations
			local function checkAnimations()
				local tracks = humanoid:GetPlayingAnimationTracks()
				for _, track in pairs(tracks) do
					local name = string.lower(track.Animation.Name)
					if name:find("climb") or name:find("wall") or name:find("ladder") then
						track:Stop()
					end
				end
			end

			humanoid.AnimationPlayed:Connect(function() 
				checkAnimations()
			end)

			checkAnimations()
		end
	end

	-- Process player
	local function checkPlayer(player)
		local pd = playerData[player.UserId]
		if not pd or pd.frozen or not pd.active then return end

		local char = player.Character
		if not char then return end

		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		-- Limit horizontal velocity only
		local vel = hrp.Velocity
		local horizVel = Vector3.new(vel.X, 0, vel.Z)
		local horizSpeed = horizVel.Magnitude

		if horizSpeed > self.Config.MaxHorizontalSpeed then
			local factor = self.Config.MaxHorizontalSpeed / horizSpeed
			hrp.Velocity = Vector3.new(vel.X * factor, vel.Y, vel.Z * factor)
		end

		-- Only limit extreme vertical velocity
		if math.abs(vel.Y) > self.Config.MaxVerticalSpeed then
			local vertSign = vel.Y > 0 and 1 or -1
			hrp.Velocity = Vector3.new(
				hrp.Velocity.X,
				self.Config.MaxVerticalSpeed * vertSign,
				hrp.Velocity.Z
			)
		end

		local position = hrp.Position

		-- Check hexes at current position
		checkHexesAt(position, player)

		-- Check positions between frames
		if pd.lastPosition then
			checkMovement(player, pd.lastPosition, position)
		end

		pd.lastPosition = position

		-- Check if fallen out of arena
		local lowestY = self.Config.Position.Y - (self.Config.FloorCount * self.Config.FloorSpacing) - 20
		if position.Y < lowestY then
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end
	end

	-- Initialize players
	local floatHeight = self.Config.Position.Y + self.Config.FloatHeight
	local spawnRadius = (self.Config.GridWidth * self.Config.HexSize) / 4
	local playerCount = #Players:GetPlayers()

	if playerCount > 0 then
		local angleStep = (2 * math.pi) / playerCount

		for i, player in ipairs(Players:GetPlayers()) do
			playerData[player.UserId] = {
				active = true,
				frozen = true,
				lastPosition = nil,
				lastHexes = {}
			}

			local char = player.Character
			if not char then
				char = player.CharacterAdded:Wait()
			end

			-- UI
			local ui = createCountdownUI()
			ui.Parent = player.PlayerGui

			-- Position player
			local angle = angleStep * (i - 1)
			local spawnPos = Vector3.new(
				self.Config.Position.X + math.cos(angle) * spawnRadius,
				floatHeight,
				self.Config.Position.Z + math.sin(angle) * spawnRadius
			)

			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(spawnPos)
			end

			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
				humanoid:ChangeState(Enum.HumanoidStateType.Swimming)

				humanoid.Died:Connect(function()
					local pd = playerData[player.UserId]
					if pd and pd.active then
						pd.active = false
						eliminatedCount = eliminatedCount + 1

						if eliminatedCount >= self.Config.EliminationCount then
							self:EndGame()
							gameActive = false
						end
					end
				end)
			end

			-- Anti-exploit setup
			setupAntiExploit(char)
			player.CharacterAdded:Connect(setupAntiExploit)
		end

		-- Countdown
		local countdown = self.Config.FloatDuration
		spawn(function()
			while countdown > 0 and gameActive do
				for _, player in pairs(Players:GetPlayers()) do
					local ui = player.PlayerGui:FindFirstChild("HexAGoneUI")
					if ui and ui:FindFirstChild("Frame") and ui.Frame:FindFirstChild("TextLabel") then
						ui.Frame.TextLabel.Text = tostring(math.max(1, math.ceil(countdown)))
					end
				end
				countdown = countdown - 0.1
				wait(0.1)
			end

			gameStarted = true

			-- Unfreeze all players
			for _, player in pairs(Players:GetPlayers()) do
				local pd = playerData[player.UserId]
				if pd and pd.active and pd.frozen then
					-- Remove UI
					local ui = player.PlayerGui:FindFirstChild("HexAGoneUI")
					if ui then ui:Destroy() end

					local char = player.Character
					if char then
						local humanoid = char:FindFirstChild("Humanoid")
						if humanoid then
							humanoid.WalkSpeed = 16
							humanoid.JumpPower = self.Config.JumpPower -- Higher jump power
							humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
							humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
							humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
							humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
							humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
						end

						local hrp = char:FindFirstChild("HumanoidRootPart")
						if hrp then
							pd.lastPosition = hrp.Position
						end
					end

					pd.frozen = nil
				end
			end
		end)
	end

	-- Main game loop
	local heartbeat = RunService.Heartbeat:Connect(function()
		if not gameStarted or not gameActive then return end

		for _, player in pairs(Players:GetPlayers()) do
			checkPlayer(player)
		end
	end)
end

function HexAGone:EndGame()
	local qualified = {}

	-- Find qualified players
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
			table.insert(qualified, player)
		end
	end

	-- Show results
	for _, player in pairs(Players:GetPlayers()) do
		-- Clean up UI
		local ui = player.PlayerGui:FindFirstChild("HexAGoneUI")
		if ui then ui:Destroy() end

		-- Create result UI
		local isQualified = table.find(qualified, player) ~= nil
		local resultUI = Instance.new("ScreenGui")
		resultUI.Name = "HexAGoneResult"

		local frame = Instance.new("Frame")
		frame.Size = UDim2.new(0.4, 0, 0.2, 0)
		frame.Position = UDim2.new(0.3, 0, 0.3, 0)
		frame.BackgroundColor3 = isQualified and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
		frame.BackgroundTransparency = 0.3
		frame.BorderSizePixel = 4
		frame.Parent = resultUI

		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(0.9, 0, 0.8, 0)
		text.Position = UDim2.new(0.05, 0, 0.1, 0)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.Text = isQualified and "QUALIFIED!" or "ELIMINATED!"
		text.TextStrokeTransparency = 0
		text.Parent = frame

		resultUI.Parent = player.PlayerGui

		-- Auto-remove
		delay(5, function()
			if resultUI and resultUI.Parent then
				resultUI:Destroy()
			end
		end)
	end

	-- Clean up
	delay(5, function()
		if workspace:FindFirstChild("HexAGoneArena") then
			workspace.HexAGoneArena:Destroy()
		end
	end)

	return {Qualified = qualified, QualifiedCount = #qualified}
end

function HexAGone:Start(centerPosition)
	-- Clean up
	if workspace:FindFirstChild("HexAGoneArena") then
		workspace.HexAGoneArena:Destroy()
	end

	-- Set position
	if not centerPosition then
		centerPosition = self.Config.Position
	else
		centerPosition = Vector3.new(centerPosition.X, self.Config.Position.Y, centerPosition.Z)
	end

	-- Create arena
	local arena = self:CreateArena(centerPosition)

	-- Start game
	delay(3, function() 
		self:SetupGame() 
	end)

	return true
end

return HexAGone