--[[
	CombatService
	Handles RequestAttack: player requests an attack.
	Validates: cooldown, tool equipped, tool in WeaponStats.
	Uses canonical damage pipeline: baseDamage -> armor -> pierce -> Angelic/Demonic 1.5x -> PvE multiplier.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local WeaponStats
local DamageTracker
local DamagePipeline
local PlayerSetupService
local RoundService
local StatusEffectsService
local lastAttack = {}

local function init()
	WeaponStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponStats"))
	DamageTracker = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamageTracker"))
	DamagePipeline = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamagePipeline"))
	PlayerSetupService = require(script.Parent:FindFirstChild("PlayerSetupService"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
	StatusEffectsService = require(script.Parent:FindFirstChild("StatusEffectsService"))
end

init()

local function getEquippedTool(player)
	local character = player.Character
	if not character then
		return nil
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end
	return nil
end

local function distance3D(a, b)
	return (a - b).Magnitude
end

local function findNearestHumanoidInRange(excludeHumanoid, origin, range)
	local nearest = nil
	local nearestDist = range
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("Humanoid") and desc ~= excludeHumanoid and desc.Health > 0 then
			local root = desc.Parent and desc.Parent:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				local d = distance3D(origin, root.Position)
				if d <= range and d < nearestDist then
					nearestDist = d
					nearest = desc
				end
			end
		end
	end
	return nearest
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestAttack = remotes:FindFirstChild("RequestAttack")
	if RequestAttack and RequestAttack:IsA("RemoteEvent") then
		RequestAttack.OnServerEvent:Connect(function(player)
			if RoundService.HasAnyProtection(player) then
				return
			end
			local tool = getEquippedTool(player)
			if not tool then
				return
			end

			local stats = WeaponStats[tool.Name]
			if not stats or type(stats.damage) ~= "number" or type(stats.range) ~= "number" or type(stats.cooldown) ~= "number" then
				return
			end

			-- Cooldown check
			local now = tick()
			if lastAttack[player] and (now - lastAttack[player]) < stats.cooldown then
				return
			end
			lastAttack[player] = now

			local character = player.Character
			local humanoid = character and character:FindFirstChild("Humanoid")
			if not humanoid then
				return
			end

			local handle = tool:FindFirstChild("Handle")
			local origin = handle and handle:IsA("BasePart") and handle.Position or (character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position or character:GetPivot().Position)

			local target = findNearestHumanoidInRange(humanoid, origin, stats.range)
			if target then
				local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
				if targetPlayer and RoundService.HasAnyProtection(targetPlayer) then
					return
				end
				local baseDmg = stats.damage * StatusEffectsService.GetDamageMultiplier(player)
				local damage = DamagePipeline.ApplyDamage(baseDmg, player, target, stats, true)
				if damage and damage > 0 then
					if targetPlayer then
						damage = math.max(1, math.floor(damage * StatusEffectsService.GetDefenseMultiplier(targetPlayer) + 0.5))
					end
					PlayerSetupService.RecordCombat(player)
					if targetPlayer then
						PlayerSetupService.RecordCombat(targetPlayer)
					end
					DamageTracker.RecordDamage(target, player)
					target:TakeDamage(damage)
				end
			end
		end)
	end
end

return {}
