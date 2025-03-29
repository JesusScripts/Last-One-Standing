local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Fix the require statements to properly find the modules
local GameModeSelector
if ServerScriptService:FindFirstChild("GameModeSelector_Server") then
	if ServerScriptService.GameModeSelector_Server:IsA("ModuleScript") then
		GameModeSelector = require(ServerScriptService.GameModeSelector_Server)
	else
		error("GameModeSelector_Server must be a ModuleScript")
	end
else
	error("GameModeSelector_Server module not found in ServerScriptService")
end

local HexAGone
if ServerScriptService:FindFirstChild("HexAGone") then
	if ServerScriptService.HexAGone:IsA("ModuleScript") then
		HexAGone = require(ServerScriptService.HexAGone)
	else
		error("HexAGone must be a ModuleScript")
	end
else
	error("HexAGone module not found in ServerScriptService")
end

-- Create game starter module
local GameStarter = {}

-- Function to start the appropriate game based on selection
function GameStarter:StartGame(selectedGame)
	print("Starting game: " .. selectedGame.name)

	-- Start the appropriate game based on the selection
	if selectedGame.name == "Hex-A-Gone" then
		-- Starting Hex-A-Gone game
		print("Initializing Hex-A-Gone...")

		-- Set up configuration from the selected game
		HexAGone.Config.EliminationCount = selectedGame.eliminationCount or 8
		HexAGone.Config.FloorCount = selectedGame.floorCount or 3

		-- Start the game at a specific position (you can modify this)
		local centerPosition = Vector3.new(0, 100, 0)
		HexAGone:Start(centerPosition)

		return true
	elseif selectedGame.name == "Fall Ball" then
		-- Placeholder for Fall Ball logic
		print("Fall Ball game would start here")
		-- Add Fall Ball implementation
		return true
	else
		print("Game not implemented yet: " .. selectedGame.name)
		return false
	end
end

-- Use this function to handle game selection from the menu
function GameStarter:StartFromSelection()
	GameModeSelector.StartSelectionForAll(function(selectedGame)
		self:StartGame(selectedGame)
	end)
end

-- Use this to directly start a specific game
function GameStarter:StartSpecificGame(gameName)
	local gameData = GameModeSelector.SelectSpecificGameMode(gameName, function(selectedGame)
		self:StartGame(selectedGame)
	end)

	return gameData ~= nil
end

return GameStarter