--[[
	AutoConvertService
	Auto-convert recipes: RawMeat→CookedMeat, Apple 2→AppleJuice, Orange 2→OrangeJuice.
	One timer per player per recipe. Start when inputs present.
	AUTO-LOOPS: after a conversion, if inputs still available, restart immediately.
	All recipes run in parallel (each has its own independent timer).
	Fires AutoConvertUpdate remote so client can show per-recipe progress.
	Cancel on EndRound, PlayerRemoving.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoConvertDefs
local InventoryService
local RoundService

-- timers[player][recipeIndex] = { thread = threadRef, endTime = tick + duration }
local timers = {}

local function hasInputs(player, recipe)
	for itemName, amount in pairs(recipe.inputs) do
		if not InventoryService.HasItem(player, itemName, amount) then
			return false
		end
	end
	return true
end

local function removeInputs(player, recipe)
	for itemName, amount in pairs(recipe.inputs) do
		InventoryService.RemoveItem(player, itemName, amount)
	end
end

local function addOutputs(player, recipe)
	for itemName, amount in pairs(recipe.output) do
		InventoryService.AddItem(player, itemName, amount)
	end
end

local function fireAutoConvertUpdate(player)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild("AutoConvertUpdate")
	if not evt or not evt:IsA("RemoteEvent") then return end

	local pTimers = timers[player] or {}
	local snapshot = {}
	local now = tick()
	for idx, t in pairs(pTimers) do
		local recipe = AutoConvertDefs[idx]
		if recipe and t.endTime then
			local remaining = math.max(0, t.endTime - now)
			-- Derive a label name for the recipe: use the first output name
			local outputName = next(recipe.output)
			snapshot[outputName or ("Recipe" .. idx)] = {
				timeRemaining = remaining,
				duration = recipe.duration,
				inputs = recipe.inputs,
			}
		end
	end
	evt:FireClient(player, snapshot)
end

local function cancelTimer(player, recipeIndex)
	local pTimers = timers[player]
	if pTimers and pTimers[recipeIndex] then
		local t = pTimers[recipeIndex]
		if t and t.thread then
			pcall(function() task.cancel(t.thread) end)
		end
		pTimers[recipeIndex] = nil
		if player and player.Parent then
			fireAutoConvertUpdate(player)
		end
	end
end

-- Forward declaration so start/restart can call itself
local startRecipeTimer

startRecipeTimer = function(player, recipeIndex)
	local recipe = AutoConvertDefs[recipeIndex]
	if not recipe then return end
	if not player.Parent then return end
	if not hasInputs(player, recipe) then
		cancelTimer(player, recipeIndex)
		return
	end

	-- If already running, don't double-start
	if timers[player] and timers[player][recipeIndex] then return end

	local endTime = tick() + recipe.duration
	local thread = task.delay(recipe.duration, function()
		if not player.Parent then return end
		-- Clear timer slot
		if timers[player] then
			timers[player][recipeIndex] = nil
		end

		if not hasInputs(player, recipe) then
			if player.Parent then fireAutoConvertUpdate(player) end
			return
		end

		removeInputs(player, recipe)
		addOutputs(player, recipe)

		-- Auto-loop: if inputs still available, restart immediately
		if hasInputs(player, recipe) then
			startRecipeTimer(player, recipeIndex)
		else
			if player.Parent then fireAutoConvertUpdate(player) end
		end
	end)

	if not timers[player] then
		timers[player] = {}
	end
	timers[player][recipeIndex] = {
		thread = thread,
		endTime = endTime,
	}
	fireAutoConvertUpdate(player)
end

local function checkAllRecipes(player)
	for i, recipe in ipairs(AutoConvertDefs) do
		if hasInputs(player, recipe) then
			-- startRecipeTimer is a no-op if already running
			startRecipeTimer(player, i)
		else
			cancelTimer(player, i)
		end
	end
end

local function cancelAllForPlayer(player)
	if not timers[player] then return end
	for i in pairs(timers[player]) do
		cancelTimer(player, i)
	end
	timers[player] = nil
	if player and player.Parent then
		fireAutoConvertUpdate(player)
	end
end

local function init()
	AutoConvertDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AutoConvertDefs"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
end

init()

InventoryService.OnItemAdded(function(player, itemName, amount)
	checkAllRecipes(player)
end)

InventoryService.OnItemRemoved(function(player, itemName, amount)
	checkAllRecipes(player)
end)

RoundService.OnStateChanged(function(oldState, newState)
	if newState == "EndRound" or newState == "Lobby" then
		for _, player in ipairs(Players:GetPlayers()) do
			cancelAllForPlayer(player)
		end
	end
end)

Players.PlayerRemoving:Connect(cancelAllForPlayer)

return {}
