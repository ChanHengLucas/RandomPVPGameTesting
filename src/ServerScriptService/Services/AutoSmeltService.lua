--[[
	AutoSmeltService
	Queue-based auto-smelt. No fuel.
	Copper/Iron/Gold: 10s. Sapphire/Emerald/Ruby/Diamond: 15s.
	Angelic/Demonic: mob drop only (no smelting).
	Cancel on round reset.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ORE_TO_INGOT = {
	CopperOre = true,
	IronOre = true,
	GoldOre = true,
	SapphireOre = true,
	EmeraldOre = true,
	RubyOre = true,
	DiamondOre = true,
}

local ORE_TO_INGOT_NAME = {
	CopperOre = "CopperIngot",
	IronOre = "IronIngot",
	GoldOre = "GoldIngot",
	SapphireOre = "SapphireIngot",
	EmeraldOre = "EmeraldIngot",
	RubyOre = "RubyIngot",
	DiamondOre = "DiamondIngot",
}

local SMELT_DURATION = {
	CopperOre = 10,
	IronOre = 10,
	GoldOre = 10,
	SapphireOre = 15,
	EmeraldOre = 15,
	RubyOre = 15,
	DiamondOre = 15,
}

local MAX_QUEUE_SIZE = 20

local queue = {}
local activeTimer = {}
local InventoryService
local RoundService

local function init()
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
end

init()

local function ensureQueue(player)
	if not queue[player] then
		queue[player] = {}
	end
	return queue[player]
end

local function processNext(player)
	local q = ensureQueue(player)
	if #q == 0 then
		activeTimer[player] = nil
		return
	end

	local entry = table.remove(q, 1)
	local oreName = entry.oreName
	local duration = SMELT_DURATION[oreName]

	activeTimer[player] = true
	task.delay(duration, function()
		activeTimer[player] = nil
		if not player.Parent then
			return
		end
		if not RoundService.IsRoundActive() then
			queue[player] = {}
			return
		end
		if InventoryService.HasItem(player, oreName, 1) then
			InventoryService.RemoveItem(player, oreName, 1)
			local ingotName = ORE_TO_INGOT_NAME[oreName]
			if ingotName then
				InventoryService.AddItem(player, ingotName, 1)
			end
		end
		processNext(player)
	end)
end

local function onOreAdded(player, itemName, amount)
	if not ORE_TO_INGOT[itemName] then
		return
	end
	local q = ensureQueue(player)
	if #q >= MAX_QUEUE_SIZE then
		return
	end
	for _ = 1, amount do
		table.insert(q, { oreName = itemName })
	end
	if not activeTimer[player] then
		processNext(player)
	end
end

InventoryService.OnItemAdded(onOreAdded)

local AutoSmeltService = {}
function AutoSmeltService.CancelAll()
	for player, _ in pairs(queue) do
		queue[player] = {}
		activeTimer[player] = nil
	end
end

RoundService.OnStateChanged(function(_, newState)
	if newState == "EndRound" then
		AutoSmeltService.CancelAll()
	end
end)

return AutoSmeltService
