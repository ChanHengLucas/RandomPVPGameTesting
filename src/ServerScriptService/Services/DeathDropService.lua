--[[
	DeathDropService
	Handles death drops based on game mode.
	SL_FFA/SL_TDM: single-life, drop everything except starter tools, no respawn until round reset.
	R_FFA/R_TDM: respawn, drop 30% materials, 1s spawn protection.
	Starter wooden tools NEVER drop.
	No killer: create ground drops (pickup proxies) with 60s despawn.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DropDefs
local RoundService
local InventoryService
local ArmorService

local GROUND_DROP_DESPAWN = 60

local function init()
	DropDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DropDefs"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	ArmorService = require(script.Parent:FindFirstChild("ArmorService"))
end

init()

local function isStarterTool(toolName)
	return DropDefs.STARTER_TOOLS_NEVER_DROP[toolName] == true
end

local function isMaterial(itemName)
	return DropDefs.MATERIALS[itemName] == true
end

local function isRespawnMode()
	return RoundService.IsRespawnMode()
end

local function createGroundDrop(position, itemName, amount)
	local pickupsFolder = Workspace:FindFirstChild("Pickups")
	if not pickupsFolder then
		pickupsFolder = Instance.new("Folder")
		pickupsFolder.Name = "Pickups"
		pickupsFolder.Parent = Workspace
	end
	local part = Instance.new("Part")
	part.Name = "GroundDrop"
	part.Size = Vector3.new(2, 2, 2)
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part:SetAttribute("ItemName", itemName)
	part:SetAttribute("Amount", amount)
	part.Parent = pickupsFolder
	task.delay(GROUND_DROP_DESPAWN, function()
		if part and part.Parent then
			part:Destroy()
		end
	end)
end

local function giveOrGroundDrop(killer, position, itemName, amount)
	if killer and killer:IsA("Player") then
		InventoryService.AddItem(killer, itemName, amount)
	else
		createGroundDrop(position, itemName, amount)
	end
end

local function dropRespawnMode(player, killer)
	local inv = InventoryService.GetInventory(player)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local dropPos = hrp and hrp.Position or Vector3.zero

	for itemName, count in pairs(inv) do
		if isMaterial(itemName) and count > 0 then
			local toDrop = math.floor(count * 0.3)
			if toDrop > 0 then
				InventoryService.RemoveItem(player, itemName, toDrop)
				giveOrGroundDrop(killer, dropPos, itemName, toDrop)
			end
		end
	end
end

-- Map tool name to inventory item name (for crafted tools)
local TOOL_TO_ITEM = {
	WoodSwordTool = "WoodSword",
	StoneSwordTool = "StoneSword",
	CopperSwordTool = "CopperSword",
	IronSwordTool = "IronSword",
	GoldSwordTool = "GoldSword",
	SapphireSwordTool = "SapphireSword",
	EmeraldSwordTool = "EmeraldSword",
	RubySwordTool = "RubySword",
	DiamondSwordTool = "DiamondSword",
	AngelicSwordTool = "AngelicSword",
	DemonicSwordTool = "DemonicSword",
	WoodPickaxeTool = "WoodPickaxe",
	StonePickaxeTool = "StonePickaxe",
	CopperPickaxeTool = "CopperPickaxe",
	IronPickaxeTool = "IronPickaxe",
	GoldPickaxeTool = "GoldPickaxe",
	SapphirePickaxeTool = "SapphirePickaxe",
	EmeraldPickaxeTool = "EmeraldPickaxe",
	RubyPickaxeTool = "RubyPickaxe",
	DiamondPickaxeTool = "DiamondPickaxe",
	AngelicPickaxeTool = "AngelicPickaxe",
	DemonicPickaxeTool = "DemonicPickaxe",
	WoodAxeTool = "WoodAxe",
	StoneAxeTool = "StoneAxe",
	CopperAxeTool = "CopperAxe",
	IronAxeTool = "IronAxe",
	GoldAxeTool = "GoldAxe",
	SapphireAxeTool = "SapphireAxe",
	EmeraldAxeTool = "EmeraldAxe",
	RubyAxeTool = "RubyAxe",
	DiamondAxeTool = "DiamondAxe",
	AngelicAxeTool = "AngelicAxe",
	DemonicAxeTool = "DemonicAxe",
	WoodSpearTool = "WoodSpear",
	CopperSpearTool = "CopperSpear",
	IronSpearTool = "IronSpear",
	GoldSpearTool = "GoldSpear",
	SapphireSpearTool = "SapphireSpear",
	EmeraldSpearTool = "EmeraldSpear",
	RubySpearTool = "RubySpear",
	DiamondSpearTool = "DiamondSpear",
	AngelicSpearTool = "AngelicSpear",
	DemonicSpearTool = "DemonicSpear",
	PistolTool = "Pistol",
	RifleTool = "Rifle",
	SniperTool = "Sniper",
}

local function getItemFromTool(toolName)
	return TOOL_TO_ITEM[toolName]
end

local function dropSingleLife(player, killer)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local dropPos = hrp and hrp.Position or Vector3.zero

	-- Unequip armor so slots are cleared; armor items are in inventory and dropped below
	ArmorService.UnequipAll(player)

	-- Drop all inventory (includes armor; starter tools are Tool instances, not inventory)
	local inv = InventoryService.GetInventory(player)
	for itemName, count in pairs(inv) do
		if count > 0 then
			InventoryService.RemoveItem(player, itemName, count)
			giveOrGroundDrop(killer, dropPos, itemName, count)
		end
	end

	-- Drop equipped tools (except starter) - destroy once, one drop representation
	local toolsToDrop = {}
	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and not isStarterTool(child.Name) then
				table.insert(toolsToDrop, child)
			end
		end
	end
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") and not isStarterTool(child.Name) then
				table.insert(toolsToDrop, child)
			end
		end
	end
	for _, tool in ipairs(toolsToDrop) do
		local itemName = getItemFromTool(tool.Name)
		if itemName then
			giveOrGroundDrop(killer, dropPos, itemName, 1)
		end
		tool:Destroy()
	end

	-- Single-life: character stays dead for Players.RespawnTime seconds (default 3s),
	-- then Roblox auto-respawns at LobbySpawn (the only SpawnLocation). RoundService
	-- teleports the winner(s) at EndRound; losers naturally end up in the lobby
	-- via default auto-respawn. `Player.RespawnTime` is NOT a valid property in this
	-- Roblox API and assigning to it errors, so we don't use it.
end

local function onPlayerDied(player, killer)
	if killer and killer:IsA("Player") then
		local rs = RoundService
		if rs.RecordKill then
			rs.RecordKill(killer, player)
		end
	end
	if isRespawnMode() then
		dropRespawnMode(player, killer)
	else
		dropSingleLife(player, killer)
	end
end

-- Connect to player deaths
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			humanoid.Died:Connect(function()
				local killer = nil
				local DamageTracker = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamageTracker"))
				killer = DamageTracker.GetKiller(humanoid)
				onPlayerDied(player, killer)
			end)
		end
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(function()
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid", 5)
			if humanoid then
				humanoid.Died:Connect(function()
					local killer = nil
					local DamageTracker = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamageTracker"))
					killer = DamageTracker.GetKiller(humanoid)
					onPlayerDied(player, killer)
				end)
			end
		end)
	end)
end

return {}
