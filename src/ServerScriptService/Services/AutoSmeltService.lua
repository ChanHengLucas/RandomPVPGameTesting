--[[
	AutoSmeltService
	Parallel per-ore-type auto-smelt. No fuel.
	Copper/Iron/Gold: 10s. Sapphire/Emerald/Ruby/Diamond: 15s.
	Angelic/Demonic: mob drop only (no smelting).

	Each ore type has its OWN timer. If a player has 10 Copper + 10 Iron,
	both ore types tick down simultaneously (not sequentially). After 10s,
	both produce 1 ingot each, and their timers restart if ore remains.

	Fires AutoSmeltUpdate remote so client can show per-ore progress.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- activeTimers[player][oreName] = endTime (tick() when smelt completes)
local activeTimers = {}

local InventoryService
local RoundService

local function init()
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
end

init()

local function fireAutoSmeltUpdate(player)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild("AutoSmeltUpdate")
	if not evt or not evt:IsA("RemoteEvent") then return end

	local timers = activeTimers[player] or {}
	local snapshot = {}
	local now = tick()
	for oreName, endTime in pairs(timers) do
		local remaining = math.max(0, endTime - now)
		local duration = SMELT_DURATION[oreName] or 10
		snapshot[oreName] = {
			timeRemaining = remaining,
			duration = duration,
		}
	end
	evt:FireClient(player, snapshot)
end

local function startSmeltTimer(player, oreName)
	if not player.Parent then return end
	if not ORE_TO_INGOT_NAME[oreName] then return end

	activeTimers[player] = activeTimers[player] or {}
	if activeTimers[player][oreName] then
		return -- already running for this ore type
	end

	local duration = SMELT_DURATION[oreName]
	local endTime = tick() + duration
	activeTimers[player][oreName] = endTime

	fireAutoSmeltUpdate(player)

	task.delay(duration, function()
		-- Player disconnected?
		if not player.Parent then
			if activeTimers[player] then
				activeTimers[player][oreName] = nil
			end
			return
		end
		-- Round ended?
		if not RoundService.IsRoundActive() then
			if activeTimers[player] then
				activeTimers[player][oreName] = nil
				fireAutoSmeltUpdate(player)
			end
			return
		end

		-- Clear this timer slot first
		if activeTimers[player] then
			activeTimers[player][oreName] = nil
		end

		-- Do the conversion if ore still present
		if InventoryService.HasItem(player, oreName, 1) then
			InventoryService.RemoveItem(player, oreName, 1)
			local ingotName = ORE_TO_INGOT_NAME[oreName]
			if ingotName then
				InventoryService.AddItem(player, ingotName, 1)
			end
			-- If more of this ore remains, restart immediately
			if InventoryService.HasItem(player, oreName, 1) then
				startSmeltTimer(player, oreName)
			else
				fireAutoSmeltUpdate(player)
			end
		else
			fireAutoSmeltUpdate(player)
		end
	end)
end

local function onItemAdded(player, itemName, _amount)
	if not ORE_TO_INGOT_NAME[itemName] then return end
	-- Start a timer for this ore type if not already running
	startSmeltTimer(player, itemName)
end

InventoryService.OnItemAdded(onItemAdded)

local AutoSmeltService = {}

function AutoSmeltService.CancelAll()
	for player, _ in pairs(activeTimers) do
		activeTimers[player] = nil
		if player and player.Parent then
			fireAutoSmeltUpdate(player)
		end
	end
end

RoundService.OnStateChanged(function(_, newState)
	if newState == "EndRound" or newState == "Lobby" then
		AutoSmeltService.CancelAll()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	activeTimers[player] = nil
end)

return AutoSmeltService
