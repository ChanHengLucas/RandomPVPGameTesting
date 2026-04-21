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

-- Pick a random spawn position from a folder of BasePart spawn markers.
local function randomSpawnFrom(folder)
	if not folder or not folder:IsA("Folder") then return nil end
	local parts = {}
	for _, c in ipairs(folder:GetChildren()) do
		if c:IsA("BasePart") then table.insert(parts, c) end
	end
	if #parts == 0 then return nil end
	return parts[math.random(1, #parts)].Position
end

-- Teleport a freshly spawned character to an appropriate map spawn for the current mode.
local function teleportToMapSpawn(player)
	local Services = script.Parent
	local MapLoadSvc = Services:FindFirstChild("MapLoadService")
	if not MapLoadSvc then return end
	local mls = require(MapLoadSvc)

	local mode = RoundService.GetGameMode()
	local pos = nil
	if mode == "R_FFA" or mode == "SL_FFA" then
		pos = randomSpawnFrom(mls.GetSpawnPointsFFA and mls.GetSpawnPointsFFA())
	elseif mode == "R_TDM" or mode == "SL_TDM" then
		local TeamSvc = Services:FindFirstChild("TeamService")
		local teamId = nil
		if TeamSvc then
			local ts = require(TeamSvc)
			teamId = ts.GetTeam and ts.GetTeam(player)
		end
		if teamId == 1 then
			pos = randomSpawnFrom(mls.GetSpawnPointsTeam1 and mls.GetSpawnPointsTeam1())
		else
			pos = randomSpawnFrom(mls.GetSpawnPointsTeam2 and mls.GetSpawnPointsTeam2())
		end
	end

	if not pos then return end
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	char:PivotTo(CFrame.new(pos))
end

local function onSpawn(player)
	task.defer(function()
		local st = RoundService.GetState()
		if st == "ActiveRound" or st == "SuddenDeath" then
			-- Only grant for genuine mid-round respawns (roundTime > 2).
			-- Round-start tools are granted explicitly by RoundService.
			if RoundService.GetCurrentRoundTime() > 2 then
				-- Teleport fresh character to map spawn (only R_* modes respawn mid-round;
				-- SL_* players stay dead). Keep guard for safety.
				if RoundService.IsRespawnMode() then
					teleportToMapSpawn(player)
					RoundService.SetSpawnProtection(player, 1)
				end
				grantStarterTools(player)
				grantStarterMaterials(player)
			end
		end
		-- All other states: do nothing. RoundService handles grants and strips.
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
