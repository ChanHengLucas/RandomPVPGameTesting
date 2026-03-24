--[[
	InventoryService
	Server-authoritative inventory per player.
	Data: { [itemName] = count }
	On any change, fires InventoryUpdate:FireClient(player, snapshot)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local inventories = {}
local remotes

local function getRemotes()
	if not remotes then
		remotes = ReplicatedStorage:FindFirstChild("Remotes")
	end
	return remotes
end

local function fireInventoryUpdate(player, snapshot)
	local r = getRemotes()
	if r then
		local evt = r:FindFirstChild("InventoryUpdate")
		if evt and evt:IsA("RemoteEvent") then
			evt:FireClient(player, snapshot)
		end
	end
end

local function ensureInventory(player)
	if not inventories[player] then
		inventories[player] = {}
	end
	return inventories[player]
end

local itemAddedCallbacks = {}
local itemRemovedCallbacks = {}

local AMMO_CAPS = {
	PistolAmmo = 40,
	RifleAmmo = 90,
	SniperAmmo = 15,
}

local InventoryService = {}

function InventoryService.OnItemAdded(callback)
	table.insert(itemAddedCallbacks, callback)
end

function InventoryService.OnItemRemoved(callback)
	table.insert(itemRemovedCallbacks, callback)
end

function InventoryService.AddItem(player, itemName, amount)
	if not player or not player:IsA("Player") or type(itemName) ~= "string" or type(amount) ~= "number" or amount < 1 then
		return
	end
	local inv = ensureInventory(player)
	local cap = AMMO_CAPS[itemName]
	local current = inv[itemName] or 0
	local added = amount
	if cap then
		local space = math.max(0, cap - current)
		added = math.min(amount, space)
		if added <= 0 then return end
	end
	inv[itemName] = current + added
	fireInventoryUpdate(player, InventoryService.GetInventory(player))
	for _, cb in ipairs(itemAddedCallbacks) do
		task.spawn(cb, player, itemName, added)
	end
end

function InventoryService.RemoveItem(player, itemName, amount)
	if not player or not player:IsA("Player") or type(itemName) ~= "string" or type(amount) ~= "number" or amount < 1 then
		return false
	end
	local inv = ensureInventory(player)
	local current = inv[itemName] or 0
	if current < amount then
		return false
	end
	inv[itemName] = current - amount
	if inv[itemName] == 0 then
		inv[itemName] = nil
	end
	fireInventoryUpdate(player, InventoryService.GetInventory(player))
	for _, cb in ipairs(itemRemovedCallbacks) do
		task.spawn(cb, player, itemName, amount)
	end
	return true
end

function InventoryService.GetInventory(player)
	if not player or not player:IsA("Player") then
		return {}
	end
	return ensureInventory(player)
end

function InventoryService.HasItem(player, itemName, amount)
	amount = amount or 1
	local inv = InventoryService.GetInventory(player)
	return (inv[itemName] or 0) >= amount
end

-- Init: PlayerAdded / PlayerRemoving
Players.PlayerAdded:Connect(function(player)
	ensureInventory(player)
	fireInventoryUpdate(player, InventoryService.GetInventory(player))
end)

Players.PlayerRemoving:Connect(function(player)
	inventories[player] = nil
end)

-- Existing players on script load
for _, player in ipairs(Players:GetPlayers()) do
	task.defer(function()
		ensureInventory(player)
		fireInventoryUpdate(player, InventoryService.GetInventory(player))
	end)
end

return InventoryService
