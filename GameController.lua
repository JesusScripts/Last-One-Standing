local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local GameModeSelector = require(script.Parent:WaitForChild("GameModeSelector_Server"))
local HexAGone = require(script.Parent:WaitForChild("HexAGone"))

-- Game state
local isInLobby = true
local currentGame = nil
local gameInProgress = false
local pendingSelectedGame = nil -- Track the game that was selected by the UI

-- Function declarations (to avoid undefined function errors)
local StartNewRound
local DetermineWinner
local AnnounceWinner
local StartGame
local ResetForNewRound
local StartSpecificGame

-- Function to reset the game for a new round
ResetForNewRound = function()
	isInLobby = true
	currentGame = nil
	gameInProgress = false
	pendingSelectedGame = nil

	-- Teleport all players to lobby
	-- Your teleport code here

	-- Wait a bit before starting the next round
	wait(5)

	-- Start a new round
	StartNewRound()
	StartSpecificGame("Hex-A-Gone")
end

-- Function to determine winner (placeholder)
DetermineWinner = function()
	-- In a real implementation, you would check which player is the last one standing
	-- For now, just return a random player as the winner
	local players = Players:GetPlayers()
	if #players > 0 then
		return players[math.random(#players)]
	end
	return nil
end

-- Function to announce winner (placeholder)
AnnounceWinner = function(winner)
	print(winner.Name .. " is the winner!")
	-- In a real implementation, you would display this to all players
	-- Create UI to show winner, etc.
end

-- Function to start a game
StartGame = function(gameMode)
	if not gameMode then
		print("Error: No game mode provided to StartGame")
		return
	end

	gameInProgress = true
	currentGame = gameMode
	print("Starting game: " .. gameMode.name)

	-- Here you would implement the actual game logic for the selected game mode
	if gameMode.name == "Hex-A-Gone" then
		-- Start Hex-A-Gone game
		print("Starting Hex-A-Gone!")

		-- Configure Hex-A-Gone
		HexAGone.Config.EliminationCount = gameMode.eliminationCount or 8
		HexAGone.Config.FloorCount = gameMode.floorCount or 3

		-- Start Hex-A-Gone at a specific position
		HexAGone:Start()

		-- Let the HexAGone game handle the completion
		return
	elseif gameMode.name == "Slime Climb" then
		-- Start Slime Climb game
		print("Slime Climb would start here (not implemented)")

		-- For this example, we'll just wait a bit and then end the round
		wait(30) -- Simulate game duration
	elseif gameMode.name == "Door Dash" then
		-- Start Door Dash game
		print("Door Dash would start here (not implemented)")

		-- For this example, we'll just wait a bit and then end the round
		wait(30) -- Simulate game duration
	elseif gameMode.name == "Fall Ball" then
		-- Start Fall Ball game
		print("Fall Ball would start here (not implemented)")

		-- For this example, we'll just wait a bit and then end the round
		wait(30) -- Simulate game duration
	end

	-- Check for winner (last one standing)
	local winner = DetermineWinner()
	if winner then
		AnnounceWinner(winner)
	end

	-- Reset for next round
	ResetForNewRound()
end

-- Function to start a new round
StartNewRound = function()
	if not isInLobby then return end

	isInLobby = false

	-- Track which game was selected (important to handle client responses)
	local function handleSelection(selectedGame)
		if selectedGame and not gameInProgress then
			pendingSelectedGame = selectedGame
			StartGame(selectedGame)
		end
	end

	-- Run the game mode selection animation for all players
	GameModeSelector.StartSelectionForAll(handleSelection)
end

-- Add a function to start a specific game
StartSpecificGame = function(gameName)
	if not isInLobby then return end

	isInLobby = false

	local function handleSelection(selectedGame)
		if selectedGame and not gameInProgress then
			pendingSelectedGame = selectedGame
			StartGame(selectedGame)
		end
	end

	GameModeSelector.SelectSpecificGameMode(gameName, handleSelection)
end

-- Handle player selection responses
local Events = ReplicatedStorage:WaitForChild("GameSelectorEvents")
local GameSelectedEvent = Events:WaitForChild("GameSelected")

GameSelectedEvent.OnServerEvent:Connect(function(player, selectedGameName)
	print(player.Name .. " is ready for game: " .. selectedGameName)

	-- Important: We need to use the pendingSelectedGame, not lookup by name again
	-- This ensures we start the game that was actually selected during GameModeSelector.StartSelectionForAll
	if pendingSelectedGame and pendingSelectedGame.name == selectedGameName then
		-- The player is ready for the correct game
		-- If you need to track multiple players' readiness, add that logic here
	end
end)

-- Handle new player joining
Players.PlayerAdded:Connect(function(player)
	-- If a game is in progress, add them to spectators or waiting area
	-- If in lobby, they can join the next round

	player.CharacterAdded:Connect(function(character)
		-- Your character setup code here
	end)
end)

-- Make functions available 
local GameController = {}
GameController.StartNewRound = StartNewRound
GameController.StartSpecificGame = StartSpecificGame

-- Start the game loop
wait(5) -- Wait for players to join

-- Explicitly start Hex-A-Gone for testing
StartSpecificGame("Hex-A-Gone")
-- Or start a random round:
-- StartNewRound()

return GameController