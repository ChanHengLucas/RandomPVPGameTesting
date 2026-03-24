--[[
	DamagePipeline.lua
	Canonical damage pipeline used by CombatService and GunsService.

	Normal damage: baseDamage -> armor DR -> pierce -> Angelic/Demonic 1.5x -> PvE 2.5x -> round/clamp.
	True damage: bypasses armor, pierce, affinity, PvE; returns rounded/clamped baseDamage only.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDefs
local ArmorService

local function init()
	PlayerDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerDefs"))
end

init()

local function getArmorService()
	if not ArmorService then
		local Services = game:GetService("ServerScriptService"):FindFirstChild("Services")
		if Services then
			local mod = Services:FindFirstChild("ArmorService")
			if mod then
				ArmorService = require(mod)
			end
		end
	end
	return ArmorService
end

-- Normalize affinity to canonical form for opposite check (angelic vs demonic)
local function normalizeAffinity(affinity)
	if not affinity or type(affinity) ~= "string" then return nil end
	local a = affinity:lower()
	if a == "angelic" or a == "godly" then return "angelic" end
	if a == "demonic" or a == "unholy" then return "demonic" end
	return nil
end

local function isOppositeAffinity(weaponAffinity, targetAffinity)
	local w = normalizeAffinity(weaponAffinity)
	local t = normalizeAffinity(targetAffinity)
	if not w or not t then return false end
	return (w == "angelic" and t == "demonic") or (w == "demonic" and t == "angelic")
end

local function getMobAffinity(targetHumanoid)
	local attr = targetHumanoid:GetAttribute("Affinity")
	if attr and type(attr) == "string" then return attr end
	local parent = targetHumanoid.Parent
	if parent then
		attr = parent:GetAttribute("Affinity")
		if attr and type(attr) == "string" then return attr end
	end
	local MobDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MobDefs"))
	if parent and parent.Name then
		local mobDef = MobDefs[parent.Name]
		if mobDef and mobDef.affinity then return mobDef.affinity end
	end
	return nil
end

local DamagePipeline = {}

--[[
	ApplyTrueDamage(humanoid, amount)
	Bypasses armor, pierce, affinity, PvE. Directly applies damage to humanoid.
	Use for hazards (lava, void, storm).
]]
function DamagePipeline.ApplyTrueDamage(humanoid, amount)
	if not humanoid or humanoid.Health <= 0 then return end
	local dmg = math.max(1, math.floor((amount or 0) + 0.5))
	humanoid:TakeDamage(dmg)
end

function DamagePipeline.ApplyDamage(
	baseDamage,
	attackerPlayer,
	targetHumanoid,
	weaponStats,
	attackerIsPlayer,
	damageType
)
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	damageType = damageType or "normal"

	-- True damage: skip armor, pierce, affinity, PvE; return rounded/clamped baseDamage only
	if damageType == "true" then
		return math.max(1, math.floor(baseDamage + 0.5))
	end

	-- Normal damage pipeline
	local targetPlayer = Players:GetPlayerFromCharacter(targetHumanoid.Parent)
	local pierce = (weaponStats and weaponStats.pierce) or 0

	-- 1) baseDamage
	local dmg = baseDamage

	-- 2) totalArmorDR (only for player targets)
	local totalDR = 0
	if targetPlayer then
		local arm = getArmorService()
		if arm then
			totalDR = arm.GetDamageReduction(targetPlayer)
		end
	end

	-- 3) effectiveDR = DR*(1-pierce)
	local effectiveDR = totalDR * (1 - pierce)

	-- 4) dmg = baseDamage*(1-effectiveDR)
	dmg = dmg * (1 - effectiveDR)

	-- 5) Angelic/Demonic 1.5x if (weapon Angelic + armor Demonic) OR vice versa
	local weaponAffinity = weaponStats and weaponStats.affinity
	local targetAffinity = nil
	if targetPlayer then
		local arm = getArmorService()
		if arm then
			targetAffinity = arm.GetTargetAffinity(targetPlayer)
		end
	else
		targetAffinity = getMobAffinity(targetHumanoid)
	end
	if isOppositeAffinity(weaponAffinity, targetAffinity) then
		dmg = dmg * 1.5
	end

	-- 6) PvE multiplier 2.5x if target tagged "Mob" (player damaging mob only) — before final round/clamp
	if attackerIsPlayer and CollectionService:HasTag(targetHumanoid, "Mob") then
		dmg = dmg * PlayerDefs.PvEMultiplier
	end

	-- 7) Final round and clamp minimum damage (once at end)
	dmg = math.max(1, math.floor(dmg + 0.5))

	return dmg
end

return DamagePipeline
