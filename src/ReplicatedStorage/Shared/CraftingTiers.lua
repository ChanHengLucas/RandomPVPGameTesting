--[[
	CraftingTiers.lua
	For best-tool-replaces-worse rule.
	Map itemName -> { category, tier }
	Category: sword, spear, axe, pickaxe, armor
	Tier: 1=Wood/Stone, 2=Copper, 3=Iron, 4=Gold, 5=Sapphire, 6=Emerald, 7=Ruby, 8=Diamond, 9=Godly/Unholy
	Godly/Unholy (Angelic/Demonic) are always craftable - tier 9.
]]

-- Check in order of specificity (longer names first to avoid "Iron" matching "Iron" in "IronIngot" wrongly)
local TIER_CHECK_ORDER = { "Diamond", "Sapphire", "Emerald", "Ruby", "Godly", "Unholy", "Gold", "Iron", "Copper", "Stone", "Wood" }
local TIER_LEVEL = { Wood = 1, Stone = 2, Copper = 3, Iron = 4, Gold = 5, Sapphire = 6, Emerald = 7, Ruby = 8, Diamond = 9, Godly = 10, Unholy = 10 }

local function getTierFromItem(itemName)
	for _, material in ipairs(TIER_CHECK_ORDER) do
		if itemName:find(material) then
			return TIER_LEVEL[material] or 0
		end
	end
	return 0
end

local function getCategory(itemName)
	if itemName:find("Sword") then return "sword" end
	if itemName:find("Spear") then return "spear" end
	if itemName:find("Axe") and not itemName:find("Pickaxe") then return "axe" end
	if itemName:find("Pickaxe") then return "pickaxe" end
	if itemName:find("Helmet") or itemName:find("Chestplate") or itemName:find("Leggings") or itemName:find("Boots") then
		return "armor"
	end
	return nil
end

local function isAngelicOrDemonic(itemName)
	return itemName:find("Godly") or itemName:find("Unholy")
end

return {
	GetCategory = getCategory,
	GetTier = getTierFromItem,
	IsAngelicOrDemonic = isAngelicOrDemonic,
}
