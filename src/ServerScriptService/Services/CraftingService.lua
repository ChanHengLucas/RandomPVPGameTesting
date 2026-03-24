--[[
	CraftingService
	Handles RequestCraft: player requests crafting an item.
	Validates: recipe exists, player has all materials, best-tool-replaces-worse rule.
	Removes materials then adds crafted item.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CraftingRecipes
local InventoryService
local CraftingTiers
local RoundService

local function init()
	CraftingRecipes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CraftingRecipes"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	CraftingTiers = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CraftingTiers"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
end

init()

local function canCraftByTier(player, itemName)
	local category = CraftingTiers.GetCategory(itemName)
	if not category then
		return true
	end
	if CraftingTiers.IsAngelicOrDemonic(itemName) then
		return true
	end
	local tier = CraftingTiers.GetTier(itemName)
	local best = RoundService.GetBestTier(player, category)
	return tier >= best
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestCraft = remotes:FindFirstChild("RequestCraft")
	if RequestCraft and RequestCraft:IsA("RemoteEvent") then
		RequestCraft.OnServerEvent:Connect(function(player, itemName)
			if type(itemName) ~= "string" or itemName == "" then
				return
			end

			local recipe = CraftingRecipes[itemName]
			if not recipe or type(recipe.requires) ~= "table" then
				return
			end

			if not canCraftByTier(player, itemName) then
				return
			end

			for material, requiredAmount in pairs(recipe.requires) do
				if type(requiredAmount) ~= "number" or requiredAmount < 1 then
					return
				end
				if not InventoryService.HasItem(player, material, requiredAmount) then
					return
				end
			end

			for material, requiredAmount in pairs(recipe.requires) do
				if not InventoryService.RemoveItem(player, material, requiredAmount) then
					return
				end
			end

			local category = CraftingTiers.GetCategory(itemName)
			if category then
				local tier = CraftingTiers.GetTier(itemName)
				RoundService.SetBestTier(player, category, tier)
			end

			local yields = type(recipe.yields) == "number" and recipe.yields > 0 and recipe.yields or 1
			InventoryService.AddItem(player, itemName, yields)
		end)
	end
end

return {}
