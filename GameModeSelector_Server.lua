local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load the game modes configuration
local GameModesConfig

-- Try to find GameModesConfig in different locations
if script:FindFirstChild("GameModesConfig") then
	GameModesConfig = require(script.GameModesConfig)
elseif script.Parent:FindFirstChild("GameModesConfig") then
	GameModesConfig = require(script.Parent.GameModesConfig)
else
	-- Create a minimal default config if none found
	GameModesConfig = {
		{
			name = "Hex-A-Gone",
			description = "Tiles disappear when stepped on - be the last player standing!",
			image = "rbxassetid://5998954819",
			maxPlayers = 24,
			minPlayers = 10,
			teamBased = false,
			duration = 180,
			difficulty = 4,
			category = "survival",
			eliminationCount = 8,
			floorCount = 3
		}
	}
	print("Warning: GameModesConfig not found, using default config")
end

local Events = ReplicatedStorage:FindFirstChild("GameSelectorEvents")
if not Events then
	Events = Instance.new("Folder")
	Events.Name = "GameSelectorEvents"
	Events.Parent = ReplicatedStorage

	local StartSelectionEvent = Instance.new("RemoteEvent")
	StartSelectionEvent.Name = "StartSelection"
	StartSelectionEvent.Parent = Events

	local GameSelectedEvent = Instance.new("RemoteEvent")
	GameSelectedEvent.Name = "GameSelected"
	GameSelectedEvent.Parent = Events
else
	if not Events:FindFirstChild("StartSelection") then
		local StartSelectionEvent = Instance.new("RemoteEvent")
		StartSelectionEvent.Name = "StartSelection"
		StartSelectionEvent.Parent = Events
	end

	if not Events:FindFirstChild("GameSelected") then
		local GameSelectedEvent = Instance.new("RemoteEvent")
		GameSelectedEvent.Name = "GameSelected"
		GameSelectedEvent.Parent = Events
	end
end

-- Create folder for game modes if it doesn't exist
local GameModes = ReplicatedStorage:FindFirstChild("GameModes")
if not GameModes then
	GameModes = Instance.new("Folder")
	GameModes.Name = "GameModes"
	GameModes.Parent = ReplicatedStorage

	-- Create the game modes from config
	for _, modeInfo in ipairs(GameModesConfig) do
		local gameMode = Instance.new("StringValue")
		gameMode.Name = modeInfo.name
		gameMode:SetAttribute("Description", modeInfo.description)
		gameMode:SetAttribute("Image", modeInfo.image)

		-- Store additional attributes if needed
		gameMode:SetAttribute("MaxPlayers", modeInfo.maxPlayers)
		gameMode:SetAttribute("MinPlayers", modeInfo.minPlayers)
		gameMode:SetAttribute("TeamBased", modeInfo.teamBased)
		gameMode:SetAttribute("Duration", modeInfo.duration)
		gameMode:SetAttribute("Difficulty", modeInfo.difficulty)
		gameMode:SetAttribute("Category", modeInfo.category)

		-- Additional attributes for specific games
		if modeInfo.name == "Hex-A-Gone" then
			gameMode:SetAttribute("EliminationCount", modeInfo.eliminationCount)
			gameMode:SetAttribute("FloorCount", modeInfo.floorCount)
		end

		gameMode.Parent = GameModes
	end
end

local SelectorModule = {}

function SelectorModule.StartSelectionForAll(callback, waitTime, filter)
	waitTime = waitTime or 30

	local allModes = {}
	for _, gameMode in ipairs(GameModes:GetChildren()) do
		-- Filter game modes if filter criteria provided
		local include = true

		if filter then
			if filter.category and gameMode:GetAttribute("Category") ~= filter.category then
				include = false
			end

			if filter.minDifficulty and gameMode:GetAttribute("Difficulty") < filter.minDifficulty then
				include = false
			end

			if filter.maxDifficulty and gameMode:GetAttribute("Difficulty") > filter.maxDifficulty then
				include = false
			end

			if filter.teamBased ~= nil and gameMode:GetAttribute("TeamBased") ~= filter.teamBased then
				include = false
			end

			if filter.minPlayers and Players:GetPlayers() < filter.minPlayers then
				include = false
			end
		end

		if include then
			local modeData = {
				name = gameMode.Name,
				description = gameMode:GetAttribute("Description"),
				image = gameMode:GetAttribute("Image"),
				maxPlayers = gameMode:GetAttribute("MaxPlayers"),
				minPlayers = gameMode:GetAttribute("MinPlayers"),
				teamBased = gameMode:GetAttribute("TeamBased"),
				duration = gameMode:GetAttribute("Duration"),
				difficulty = gameMode:GetAttribute("Difficulty"),
				category = gameMode:GetAttribute("Category")
			}

			-- Add special attributes for specific games
			if gameMode.Name == "Hex-A-Gone" then
				modeData.eliminationCount = gameMode:GetAttribute("EliminationCount")
				modeData.floorCount = gameMode:GetAttribute("FloorCount")
			end

			table.insert(allModes, modeData)
		end
	end

	if #allModes == 0 then 
		print("Warning: No game modes found matching the filter criteria")
		return 
	end

	local selectedGame = allModes[math.random(#allModes)]

	for _, player in ipairs(Players:GetPlayers()) do
		pcall(function()
			Events.StartSelection:FireClient(player, selectedGame.name)
		end)
	end

	task.delay(waitTime, function()
		if callback then
			callback(selectedGame)
		end
	end)

	return selectedGame
end

function SelectorModule.SelectSpecificGameMode(gameModeName, callback, waitTime)
	waitTime = waitTime or 30

	local gameMode = GameModes:FindFirstChild(gameModeName)
	if not gameMode then
		warn("Game mode " .. gameModeName .. " not found!")
		return false
	end

	local selectedGame = {
		name = gameMode.Name,
		description = gameMode:GetAttribute("Description"),
		image = gameMode:GetAttribute("Image"),
		maxPlayers = gameMode:GetAttribute("MaxPlayers"),
		minPlayers = gameMode:GetAttribute("MinPlayers"),
		teamBased = gameMode:GetAttribute("TeamBased"),
		duration = gameMode:GetAttribute("Duration"),
		difficulty = gameMode:GetAttribute("Difficulty"),
		category = gameMode:GetAttribute("Category")
	}

	-- Add special attributes for specific games
	if gameMode.Name == "Hex-A-Gone" then
		selectedGame.eliminationCount = gameMode:GetAttribute("EliminationCount")
		selectedGame.floorCount = gameMode:GetAttribute("FloorCount")
	end

	for _, player in ipairs(Players:GetPlayers()) do
		pcall(function()
			Events.StartSelection:FireClient(player, selectedGame.name)
		end)
	end

	task.delay(waitTime, function()
		if callback then
			callback(selectedGame)
		end
	end)

	return selectedGame
end

Events.GameSelected.OnServerEvent:Connect(function(player, selectedGameName)
	print(player.Name .. " is ready for game: " .. selectedGameName)
end)

return SelectorModule