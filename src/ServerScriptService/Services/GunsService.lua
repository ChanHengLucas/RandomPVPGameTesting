--[[
	GunsService
	Handles RequestShoot and RequestReload.
	Projectile-based: spawns projectile Part, validates hit on server.
	Uses fireInterval, DamagePipeline for damage.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local WeaponStats
local DamageTracker
local DamagePipeline
local PlayerSetupService
local InventoryService
local StatusEffectsService

local magazine = {}
local lastShot = {}
local reloading = {}
local projectiles = {}
local PROJECTILE_SPEED = 200
local MAX_PROJECTILES_PER_PLAYER = 5

local function init()
	WeaponStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WeaponStats"))
	DamageTracker = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamageTracker"))
	DamagePipeline = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamagePipeline"))
	PlayerSetupService = require(script.Parent:FindFirstChild("PlayerSetupService"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
	StatusEffectsService = require(script.Parent:FindFirstChild("StatusEffectsService"))
end

init()

local function getEquippedTool(player)
	local character = player.Character
	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				return child
			end
		end
	end
	return nil
end

local function getMuzzlePosition(tool)
	local muzzle = tool:FindFirstChild("Muzzle") or tool:FindFirstChild("Handle")
	if muzzle and muzzle:IsA("BasePart") then
		return muzzle.Position, muzzle.CFrame.LookVector
	end
	return tool:GetPivot().Position, Vector3.new(0, 0, -1)
end

local function ensureMagazine(player, gunName)
	if not magazine[player] then
		magazine[player] = {}
	end
	if magazine[player][gunName] == nil then
		magazine[player][gunName] = 0
	end
	return magazine[player][gunName]
end

local function countPlayerProjectiles(player)
	local n = 0
	for _, proj in pairs(projectiles) do
		if proj.owner == player then
			n = n + 1
		end
	end
	return n
end

local function createProjectile(origin, direction, range, stats, owner)
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.2, 0.2, 0.5)
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.CFrame = CFrame.new(origin, origin + direction)
	part.Parent = Workspace

	local proj = {
		part = part,
		position = origin,
		direction = direction.Unit,
		range = range,
		stats = stats,
		owner = owner,
		traveled = 0,
	}
	projectiles[part] = proj
	return proj
end

local function updateProjectiles(dt)
	for part, proj in pairs(projectiles) do
		if not part.Parent then
			projectiles[part] = nil
			continue
		end
		local move = PROJECTILE_SPEED * dt
		local newPos = proj.position + proj.direction * move
		proj.traveled = proj.traveled + move

		-- Raycast for hit
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local exclude = {}
		if proj.owner and proj.owner.Character then
			table.insert(exclude, proj.owner.Character)
		end
		params.FilterDescendantsInstances = exclude

		local result = Workspace:Raycast(proj.position, proj.direction * move, params)
		if result and result.Instance then
			local hit = result.Instance
			local humanoid = hit:FindFirstChildOfClass("Humanoid") or (hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid"))
			if humanoid and humanoid.Health > 0 then
				local Players = game:GetService("Players")
				local targetPlayer = Players:GetPlayerFromCharacter(humanoid.Parent)
				if targetPlayer and RoundService.HasAnyProtection(targetPlayer) then
					-- Skip damage; do not destroy projectile (let it continue)
				else
					local baseDmg = (proj.stats.damage or 16) * (proj.owner and StatusEffectsService.GetDamageMultiplier(proj.owner) or 1)
					local damage = DamagePipeline.ApplyDamage(baseDmg, proj.owner, humanoid, proj.stats, true)
					if damage and damage > 0 then
						if targetPlayer then
							damage = math.max(1, math.floor(damage * StatusEffectsService.GetDefenseMultiplier(targetPlayer) + 0.5))
						end
						PlayerSetupService.RecordCombat(proj.owner)
						if targetPlayer then
							PlayerSetupService.RecordCombat(targetPlayer)
						end
						DamageTracker.RecordDamage(humanoid, proj.owner)
						humanoid:TakeDamage(damage)
					end
				end
			end
		end

		proj.position = newPos
		part.CFrame = CFrame.new(newPos, newPos + proj.direction)

		if proj.traveled >= proj.range then
			part:Destroy()
			projectiles[part] = nil
		end
	end
end

RunService.Heartbeat:Connect(function(dt)
	updateProjectiles(dt)
end)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestShoot = remotes:FindFirstChild("RequestShoot")
	if RequestShoot and RequestShoot:IsA("RemoteEvent") then
		RequestShoot.OnServerEvent:Connect(function(player)
			if RoundService.HasAnyProtection(player) then
				return
			end
			local tool = getEquippedTool(player)
			if not tool then
				return
			end
			local stats = WeaponStats[tool.Name]
			if not stats or not stats.ammoType then
				return
			end
			if reloading[player] then
				return
			end
			local mag = ensureMagazine(player, tool.Name)
			if mag <= 0 then
				return
			end
			if countPlayerProjectiles(player) >= MAX_PROJECTILES_PER_PLAYER then
				return
			end
			local now = tick()
			local fireInterval = stats.fireInterval or 0.5
			if lastShot[player] and (now - lastShot[player]) < fireInterval then
				return
			end
			lastShot[player] = now

			magazine[player][tool.Name] = mag - 1

			local character = player.Character
			local origin, look = getMuzzlePosition(tool)
			createProjectile(origin, look, stats.range or 80, stats, player)
		end)
	end

	local RequestReload = remotes:FindFirstChild("RequestReload")
	if RequestReload and RequestReload:IsA("RemoteEvent") then
		RequestReload.OnServerEvent:Connect(function(player)
			local tool = getEquippedTool(player)
			if not tool then
				return
			end
			local stats = WeaponStats[tool.Name]
			if not stats or not stats.ammoType then
				return
			end
			if reloading[player] then
				return
			end
			local currentMag = ensureMagazine(player, tool.Name)
			if currentMag >= stats.magSize then
				return
			end
			if not InventoryService.HasItem(player, stats.ammoType, 1) then
				return
			end
			reloading[player] = true
			task.delay(stats.reloadTime or 2, function()
				if not player.Parent then
					reloading[player] = nil
					return
				end
				local toAdd = stats.magSize - ensureMagazine(player, tool.Name)
				for _ = 1, toAdd do
					if InventoryService.HasItem(player, stats.ammoType, 1) then
						InventoryService.RemoveItem(player, stats.ammoType, 1)
						magazine[player][tool.Name] = ensureMagazine(player, tool.Name) + 1
					else
						break
					end
				end
				reloading[player] = nil
			end)
		end)
	end
end

return {}
