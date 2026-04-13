--[[
	EquipService
	Handles RequestEquip: player requests equipping an item.
	Validates: player has item in inventory.
	Clones tool template from ServerStorage to Backpack; avoids duplicates.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local InventoryService

-- Map itemName -> tool template name in ServerStorage
local ITEM_TO_TOOL = {
	-- Swords
	WoodSword = "WoodSwordTool",
	StoneSword = "StoneSwordTool",
	CopperSword = "CopperSwordTool",
	IronSword = "IronSwordTool",
	GoldSword = "GoldSwordTool",
	SapphireSword = "SapphireSwordTool",
	EmeraldSword = "EmeraldSwordTool",
	RubySword = "RubySwordTool",
	DiamondSword = "DiamondSwordTool",
	AngelicSword = "AngelicSwordTool",
	DemonicSword = "DemonicSwordTool",
	-- Spears
	WoodSpear = "WoodSpearTool",
	CopperSpear = "CopperSpearTool",
	IronSpear = "IronSpearTool",
	GoldSpear = "GoldSpearTool",
	SapphireSpear = "SapphireSpearTool",
	EmeraldSpear = "EmeraldSpearTool",
	RubySpear = "RubySpearTool",
	DiamondSpear = "DiamondSpearTool",
	AngelicSpear = "AngelicSpearTool",
	DemonicSpear = "DemonicSpearTool",
	-- Pickaxes
	WoodPickaxe = "WoodPickaxeTool",
	StonePickaxe = "StonePickaxeTool",
	CopperPickaxe = "CopperPickaxeTool",
	IronPickaxe = "IronPickaxeTool",
	GoldPickaxe = "GoldPickaxeTool",
	SapphirePickaxe = "SapphirePickaxeTool",
	EmeraldPickaxe = "EmeraldPickaxeTool",
	RubyPickaxe = "RubyPickaxeTool",
	DiamondPickaxe = "DiamondPickaxeTool",
	AngelicPickaxe = "AngelicPickaxeTool",
	DemonicPickaxe = "DemonicPickaxeTool",
	-- Axes
	WoodAxe = "WoodAxeTool",
	StoneAxe = "StoneAxeTool",
	CopperAxe = "CopperAxeTool",
	IronAxe = "IronAxeTool",
	GoldAxe = "GoldAxeTool",
	SapphireAxe = "SapphireAxeTool",
	EmeraldAxe = "EmeraldAxeTool",
	RubyAxe = "RubyAxeTool",
	DiamondAxe = "DiamondAxeTool",
	AngelicAxe = "AngelicAxeTool",
	DemonicAxe = "DemonicAxeTool",
	-- Guns
	Pistol = "PistolTool",
	Rifle = "RifleTool",
	Sniper = "SniperTool",
	-- Misc
	Torch = "TorchTool",
	Shield = "ShieldTool",
	Bucket = "BucketTool",
}

local function init()
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
end

init()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestEquip = remotes:FindFirstChild("RequestEquip")
	if RequestEquip and RequestEquip:IsA("RemoteEvent") then
		RequestEquip.OnServerEvent:Connect(function(player, itemName)
			-- Validation: itemName is string
			if type(itemName) ~= "string" or itemName == "" then
				return
			end

			-- Must have at least 1 in inventory
			if not InventoryService.HasItem(player, itemName, 1) then
				return
			end

			local toolTemplateName = ITEM_TO_TOOL[itemName]
			if not toolTemplateName then
				return
			end

			local template = ServerStorage:FindFirstChild(toolTemplateName)
			if not template or not template:IsA("Tool") then
				return
			end

			-- Remove existing equipped copy to avoid duplicates
			local backpack = player:FindFirstChild("Backpack")
			local character = player.Character
			if backpack then
				local existing = backpack:FindFirstChild(toolTemplateName)
				if existing then
					existing:Destroy()
				end
			end
			if character then
				local existing = character:FindFirstChild(toolTemplateName)
				if existing then
					existing:Destroy()
				end
			end

			local clone = template:Clone()
			clone.Parent = backpack or player:WaitForChild("Backpack")
		end)
	end
end

return {}
