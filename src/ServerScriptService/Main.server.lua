-- FastCraft PvP - Main server entry point
-- Services are required in dependency order
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ensure Remotes folder exists (user creates in Studio)
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	warn("[FastCraft] Remotes folder not found. Create ReplicatedStorage.Remotes with RemoteEvents in Studio.")
end

-- Init services (order matters: Inventory first, PlayerSetup before Combat, StatusEffects/Stamina before Combat)
local Services = ServerScriptService:FindFirstChild("Services")
if Services then
	require(Services:FindFirstChild("InventoryService"))
	require(Services:FindFirstChild("PlayerSetupService"))
	require(Services:FindFirstChild("PickupService"))
	require(Services:FindFirstChild("CraftingService"))
	require(Services:FindFirstChild("EquipService"))
	require(Services:FindFirstChild("StaminaService"))
	require(Services:FindFirstChild("StatusEffectsService"))
	require(Services:FindFirstChild("CombatService"))
	require(Services:FindFirstChild("MiningService"))
	require(Services:FindFirstChild("AutoSmeltService"))
	require(Services:FindFirstChild("ChoppingService"))
	require(Services:FindFirstChild("ConsumableService"))
	require(Services:FindFirstChild("DropsService"))
	require(Services:FindFirstChild("MobsService"))
	require(Services:FindFirstChild("AIController"))
	require(Services:FindFirstChild("GunsService"))
	require(Services:FindFirstChild("ThrowingService"))
	require(Services:FindFirstChild("OffhandService"))
	require(Services:FindFirstChild("ArmorService"))
	require(Services:FindFirstChild("HazardsService"))
	require(Services:FindFirstChild("VotingService"))
	require(Services:FindFirstChild("MapLoadService"))
	require(Services:FindFirstChild("StormService"))
	require(Services:FindFirstChild("TeamService"))
	require(Services:FindFirstChild("RoundService"))
	require(Services:FindFirstChild("PotionSpawnerService"))
	require(Services:FindFirstChild("AutoConvertService"))
	require(Services:FindFirstChild("DeathDropService"))
	require(Services:FindFirstChild("RespawnService"))
end

print("FastCraft PvP server started")
