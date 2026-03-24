--[[
	AutoConvertService
	Auto-convert recipes: RawMeat→CookedMeat, Apple 2→AppleJuice, Orange 2→OrangeJuice.
	One timer per player per recipe. Start when inputs present. Cancel if inputs drop.
	Cancel on EndRound, PlayerRemoving. No client remotes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoConvertDefs
local InventoryService
local RoundService

local timers = {} -- [player][recipeIndex] = { cancel = function }

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

local function cancelTimer(player, recipeIndex)
	local pTimers = timers[player]
	if pTimers and pTimers[recipeIndex] then
		local t = pTimers[recipeIndex]
		if t and t.cancel then
			pcall(t.cancel)
		end
		pTimers[recipeIndex] = nil
	end
end

local function startOrRestartTimer(player, recipeIndex)
	local recipe = AutoConvertDefs[recipeIndex]
	if not recipe then return end
	cancelTimer(player, recipeIndex)
	if not hasInputs(player, recipe) then return end

	local thread = task.delay(recipe.duration, function()
		if not player.Parent then return end
		if not hasInputs(player, recipe) then return end
		removeInputs(player, recipe)
		addOutputs(player, recipe)
		if timers[player] then
			timers[player][recipeIndex] = nil
		end
	end)

	if not timers[player] then
		timers[player] = {}
	end
	timers[player][recipeIndex] = {
		cancel = function()
			task.cancel(thread)
		end,
	}
end

local function checkAllRecipes(player)
	for i, recipe in ipairs(AutoConvertDefs) do
		if hasInputs(player, recipe) then
			startOrRestartTimer(player, i)
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
	if newState == "EndRound" then
		for _, player in ipairs(Players:GetPlayers()) do
			cancelAllForPlayer(player)
		end
	end
end)

Players.PlayerRemoving:Connect(cancelAllForPlayer)

return {}
