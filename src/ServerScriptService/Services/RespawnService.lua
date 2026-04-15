--[[
	RespawnService
	On player spawn: grants starter tools to Backpack.
	Starter tools: WoodPickaxeTool, WoodAxeTool, WoodSwordTool (actual Tool instances).
	Optional starter materials: Wood, Rock in Inventory.
	Starter tools NEVER drop on death (handled by DeathDropService).
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local InventoryService
local RoundService

local STARTER_TOOLS = { "WoodPickaxeTool", "WoodAxeTool", "WoodSwordTool" }
local STARTER_MATERIALS = { Wood = 5, Rock = 3 }

local function init()
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
end

init()

local function grantStarterTools(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		backpack = player:WaitForChild("Backpack", 5)
	end
	if not backpack then
		return
	end

	for _, toolName in ipairs(STARTER_TOOLS) do
		-- Remove existing copy to avoid duplicates
		local existing = backpack:FindFirstChild(toolName)
		if existing then
			existing:Destroy()
		end
		local char = player.Character
		if char then
			local existingChar = char:FindFirstChild(toolName)
			if existingChar then
				existingChar:Destroy()
			end
		end

		local template = ServerStorage:FindFirstChild(toolName)
		if template and template:IsA("Tool") then
			local clone = template:Clone()
			clone.Parent = backpack
		end
	end
	-- Starter tools = tier 1 achieved for best-tool rule
	RoundService.SetBestTier(player, "pickaxe", 1)
	RoundService.SetBestTier(player, "axe", 1)
	RoundService.SetBestTier(player, "sword", 1)
end

local function grantStarterMaterials(player)
	for itemName, amount in pairs(STARTER_MATERIALS) do
		InventoryService.AddItem(player, itemName, amount)
	end
end

local function stripAllTools(player)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") then child:Destroy() end
		end
	end
	local char = player.Character
	if char then
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Tool") then child:Destroy() end
		end
	end
end

local function onSpawn(player)
	task.defer(function()
		local st = RoundService.GetState()
		if st == "ActiveRound" or st == "SuddenDeath" then
			grantStarterTools(player)
			grantStarterMaterials(player)
			if RoundService.IsRespawnMode() then
				RoundService.SetSpawnProtection(player, 1)
			end
		else
			-- Not in an active round: ensure no tools
			stripAllTools(player)
			-- Double-check after a short wait (catch late tool grants)
			task.wait(0.2)
			stripAllTools(player)
		end
	end)
end

local function connectRespawn(player)
	player.CharacterAdded:Connect(function()
		onSpawn(player)
	end)
	if player.Character then
		onSpawn(player)
	end
end

Players.PlayerAdded:Connect(connectRespawn)

for _, player in ipairs(Players:GetPlayers()) do
	task.defer(function()
		connectRespawn(player)
	end)
end

return {
	STARTER_TOOLS = STARTER_TOOLS,
}
