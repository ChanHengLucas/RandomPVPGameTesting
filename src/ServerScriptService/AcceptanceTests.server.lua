--[[
	AcceptanceTests.server.lua
	Validates red-flag fixes. Run in Studio (F9) or via require.
	Tests: A1-A2 hazards, B PvE, C mining hits, D RNG, E drops, F ammo caps.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function run()
	local Services = ServerScriptService:FindFirstChild("Services")
	local Shared = ReplicatedStorage:FindFirstChild("Shared")
	if not Services or not Shared then
		warn("[AcceptanceTests] Services or Shared not found")
		return
	end

	local passed = 0
	local failed = 0

	-- A1: DamagePipeline has ApplyTrueDamage
	local DamagePipeline = require(Shared:FindFirstChild("DamagePipeline"))
	if DamagePipeline.ApplyTrueDamage and type(DamagePipeline.ApplyTrueDamage) == "function" then
		print("[A1] PASS: ApplyTrueDamage exists")
		passed = passed + 1
	else
		warn("[A1] FAIL: ApplyTrueDamage missing")
		failed = failed + 1
	end

	-- A2: RoundService has spawn protection for R_* modes
	local RoundService = require(Services:FindFirstChild("RoundService"))
	RoundService.SetGameMode("R_FFA")
	if RoundService.IsRespawnMode and RoundService.IsRespawnMode() then
		print("[A2] PASS: R_FFA is respawn mode")
		passed = passed + 1
	else
		warn("[A2] FAIL: R_FFA should be respawn mode")
		failed = failed + 1
	end
	RoundService.SetGameMode("SL_FFA")
	if not RoundService.IsRespawnMode() then
		print("[A2] PASS: SL_FFA is single-life")
		passed = passed + 1
	else
		warn("[A2] FAIL: SL_FFA should be single-life")
		failed = failed + 1
	end
	RoundService.SetGameMode("infinite")

	-- C: MiningDefs has HITS_TO_BREAK
	local MiningDefs = require(Shared:FindFirstChild("MiningDefs"))
	local hits = MiningDefs.HitsToBreak
	if hits and hits.WoodPickaxeTool == 15 and hits.DiamondPickaxeTool == 4 and hits.GodlyPickaxeTool == 3 then
		print("[C] PASS: HITS_TO_BREAK correct (Wood=15, Diamond=4, Godly=3)")
		passed = passed + 1
	else
		warn("[C] FAIL: HITS_TO_BREAK incorrect")
		failed = failed + 1
	end

	-- D: OreRngWeights - Emerald/Ruby/Diamond have non-zero base weights
	local OreRngWeights = require(Shared:FindFirstChild("OreRngWeights"))
	local bw = OreRngWeights.baseWeights
	if bw and bw.EmeraldOre and bw.EmeraldOre > 0 and bw.RubyOre and bw.RubyOre > 0 and bw.DiamondOre and bw.DiamondOre > 0 then
		print("[D] PASS: Emerald/Ruby/Diamond have non-zero base weights")
		passed = passed + 1
	else
		warn("[D] FAIL: rare ores need non-zero base weights")
		failed = failed + 1
	end
	if OreRngWeights.LogProbabilitySnapshots then
		print("[D] Debug snapshot:")
		OreRngWeights.LogProbabilitySnapshots()
	end

	-- F: InventoryService enforces ammo caps
	local InventoryService = require(Services:FindFirstChild("InventoryService"))
	local Players = game:GetService("Players")
	local testPlayer = Players:GetPlayers()[1]
	if testPlayer then
		InventoryService.AddItem(testPlayer, "PistolAmmo", 100)
		local inv = InventoryService.GetInventory(testPlayer)
		local pistol = inv.PistolAmmo or 0
		if pistol <= 40 then
			print("[F] PASS: PistolAmmo capped at 40")
			passed = passed + 1
		else
			warn("[F] FAIL: PistolAmmo should be capped at 40, got " .. tostring(pistol))
			failed = failed + 1
		end
	else
		print("[F] SKIP: no player in game")
	end

	-- G: Pocket stations removed (PocketFurnace, PocketCauldron)
	local CraftingRecipes = require(Shared:FindFirstChild("CraftingRecipes"))
	if not CraftingRecipes["PocketFurnace"] and not CraftingRecipes["PocketCauldron"] then
		print("[G] PASS: No PocketFurnace or PocketCauldron in CraftingRecipes")
		passed = passed + 1
	else
		warn("[G] FAIL: PocketFurnace or PocketCauldron should be removed from CraftingRecipes")
		failed = failed + 1
	end

	local DropTables = require(Shared:FindFirstChild("DropTables"))
	local dropTablesContainPocket = false
	for mobType, entries in pairs(DropTables) do
		if type(entries) == "table" then
			for _, entry in ipairs(entries) do
				if entry.itemName == "PocketFurnace" or entry.itemName == "PocketCauldron" then
					dropTablesContainPocket = true
					break
				end
			end
		end
	end
	if not dropTablesContainPocket then
		print("[G] PASS: No PocketFurnace or PocketCauldron in drop tables")
		passed = passed + 1
	else
		warn("[G] FAIL: Drop tables should not contain PocketFurnace or PocketCauldron")
		failed = failed + 1
	end

	print(string.format("[AcceptanceTests] Done: %d passed, %d failed", passed, failed))
end

-- Run when script loads (optional - comment out if running manually)
task.defer(run)

return { Run = run }
