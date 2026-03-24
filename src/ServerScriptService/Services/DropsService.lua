--[[
	DropsService
	Awards RNG drops to killer when mob dies.
	GrantDrops(killer, dropsKey) rolls from DropTables and adds to inventory.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DropTables
local InventoryService

local function init()
	DropTables = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DropTables"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
end

init()

local function rollDrop(killer, dropsKey)
	local table = DropTables[dropsKey]
	if not table or type(table) ~= "table" then
		return
	end
	local totalWeight = 0
	for _, entry in ipairs(table) do
		totalWeight = totalWeight + (entry.weight or 0)
	end
	if totalWeight <= 0 then
		return
	end
	local roll = math.random() * totalWeight
	for _, entry in ipairs(table) do
		local w = entry.weight or 0
		if roll < w then
			if entry.itemName and killer and killer:IsA("Player") then
				InventoryService.AddItem(killer, entry.itemName, 1)
			end
			return
		end
		roll = roll - w
	end
end

local DropsService = {}

function DropsService.GrantDrops(killer, dropsKey)
	if not killer or not killer:IsA("Player") then
		return
	end
	rollDrop(killer, dropsKey)
end

return DropsService
