--[[
	ArmorService
	Tracks equipped armor per player.
	RequestEquipArmor(player, slot, itemName) - slot: Head, Body, Legs, Feet.
	GetTargetAffinity(player) - for godly/unholy combat.
	GetDamageReduction(player) - total reduction 0..1.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArmorStats
local InventoryService

local equippedArmor = {}

local function init()
	ArmorStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ArmorStats"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
end

init()

local ArmorService = {}

function ArmorService.Unequip(player, slot)
	if not player or not player:IsA("Player") then
		return
	end
	equippedArmor[player] = equippedArmor[player] or {}
	equippedArmor[player][slot] = nil
end

function ArmorService.GetAllEquipped(player)
	if not player or not player:IsA("Player") then
		return {}
	end
	local armor = equippedArmor[player]
	if not armor then return {} end
	local list = {}
	for slot, itemName in pairs(armor) do
		if itemName then
			table.insert(list, { slot = slot, itemName = itemName })
		end
	end
	return list
end

function ArmorService.UnequipAll(player)
	if not player or not player:IsA("Player") then return {} end
	local list = ArmorService.GetAllEquipped(player)
	for _, entry in ipairs(list) do
		ArmorService.Unequip(player, entry.slot)
	end
	return list
end

function ArmorService.Equip(player, slot, itemName)
	if not player or not player:IsA("Player") or type(slot) ~= "string" or type(itemName) ~= "string" then
		return false
	end
	local validSlots = { Head = true, Body = true, Legs = true, Feet = true }
	if not validSlots[slot] then
		return false
	end
	if not ArmorStats[itemName] then
		return false
	end
	if not InventoryService.HasItem(player, itemName, 1) then
		return false
	end
	equippedArmor[player] = equippedArmor[player] or {}
	equippedArmor[player][slot] = itemName
	return true
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestEquipArmor = remotes:FindFirstChild("RequestEquipArmor")
	if RequestEquipArmor and RequestEquipArmor:IsA("RemoteEvent") then
		RequestEquipArmor.OnServerEvent:Connect(function(player, slot, itemName)
			if type(slot) ~= "string" or type(itemName) ~= "string" then
				return
			end
			ArmorService.Equip(player, slot, itemName)
		end)
	end
end

function ArmorService.GetTargetAffinity(player)
	if not player or not player:IsA("Player") then
		return nil
	end
	local armor = equippedArmor[player]
	if not armor then
		return nil
	end
	for _, itemName in pairs(armor) do
		local def = ArmorStats[itemName]
		if def and def.affinity then
			return def.affinity
		end
	end
	return nil
end

function ArmorService.GetDamageReduction(player)
	if not player or not player:IsA("Player") then
		return 0
	end
	local armor = equippedArmor[player]
	if not armor then
		return 0
	end
	local total = 0
	for _, itemName in pairs(armor) do
		local def = ArmorStats[itemName]
		if def and def.reduction then
			total = total + def.reduction
		end
	end
	return math.min(total, 0.9)
end

return ArmorService
