--[[
	StatusEffectsService
	Tracks active buffs/debuffs per player.
	Regen: heals 1 HP per second for duration.
	Superiority: max HP 150, max stamina 150 for duration.
	CombatService queries GetTargetAffinity for angelic/demonic affinity.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local effects = {}
local regenConnections = {}
local speedConnections = {}
local remotes

local BASE_WALKSPEED = 16

local function getRemotes()
	if not remotes then
		remotes = ReplicatedStorage:FindFirstChild("Remotes")
	end
	return remotes
end

local function fireStatusEffectUpdate(player, activeEffects)
	local r = getRemotes()
	if r then
		local evt = r:FindFirstChild("StatusEffectUpdate")
		if evt and evt:IsA("RemoteEvent") then
			evt:FireClient(player, activeEffects)
		end
	end
end

local function ensureEffects(player)
	if not effects[player] then
		effects[player] = {}
	end
	return effects[player]
end

local function notifyClient(player)
	local list = {}
	for effectId, data in pairs(ensureEffects(player)) do
		table.insert(list, { effectId = effectId, duration = data.untilTime - tick() })
	end
	fireStatusEffectUpdate(player, list)
end

local StatusEffectsService = {}

local function clearSpeedEffects(player)
	for id in pairs(ensureEffects(player)) do
		if id:match("^Speed:") then
			ensureEffects(player)[id] = nil
		end
	end
	local conn = speedConnections[player]
	if conn then
		conn:Disconnect()
		speedConnections[player] = nil
	end
	local char = player.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = BASE_WALKSPEED
	end
end

function StatusEffectsService.AddEffect(player, effectId, duration)
	if not player or not player:IsA("Player") or type(effectId) ~= "string" or type(duration) ~= "number" or duration <= 0 then
		return
	end
	local playerEffects = ensureEffects(player)
	if effectId:match("^Speed:") then
		clearSpeedEffects(player)
	end
	playerEffects[effectId] = { untilTime = tick() + duration }
	notifyClient(player)

	if effectId == "Regen" then
		local conn = regenConnections[player]
		if conn then
			conn:Disconnect()
			regenConnections[player] = nil
		end
		local startTime = tick()
		conn = RunService.Heartbeat:Connect(function()
			if not player.Parent then
				if conn then conn:Disconnect() end
				return
			end
			local char = player.Character
			local humanoid = char and char:FindFirstChild("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end
			local elapsed = tick() - startTime
			if elapsed >= duration then
				playerEffects["Regen"] = nil
				regenConnections[player] = nil
				conn:Disconnect()
				notifyClient(player)
				return
			end
			humanoid.Health = math.min(humanoid.Health + 3 * 1/60, humanoid.MaxHealth)
		end)
		regenConnections[player] = conn
	elseif effectId:match("^Speed:") then
		local percent = tonumber(effectId:match("^Speed:(%d+)$"))
		if not percent then return end
		local conn = speedConnections[player]
		if conn then
			conn:Disconnect()
			speedConnections[player] = nil
		end
		local startTime = tick()
		local function applySpeed()
			local char = player.Character
			local humanoid = char and char:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = BASE_WALKSPEED * (1 + percent / 100)
			end
		end
		local function clearSpeed()
			local char = player.Character
			local humanoid = char and char:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = BASE_WALKSPEED
			end
		end
		applySpeed()
		conn = player.CharacterAdded:Connect(function()
			applySpeed()
		end)
		speedConnections[player] = conn
		task.delay(duration, function()
			if not player.Parent then return end
			playerEffects[effectId] = nil
			if speedConnections[player] == conn then
				conn:Disconnect()
				speedConnections[player] = nil
			end
			clearSpeed()
			notifyClient(player)
		end)
	elseif effectId == "Superiority" then
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
		clearSpeedEffects(player)
		StatusEffectsService.AddEffect(player, "Speed:10", duration)
	end
end

function StatusEffectsService.HasEffect(player, effectId)
	if not player or not player:IsA("Player") then return false end
	local data = ensureEffects(player)[effectId]
	return data and data.untilTime > tick()
end

function StatusEffectsService.GetDamageMultiplier(player)
	if StatusEffectsService.HasEffect(player, "Superiority") then
		return 1.1
	end
	return 1.0
end

function StatusEffectsService.GetDefenseMultiplier(player)
	if StatusEffectsService.HasEffect(player, "Superiority") then
		return 0.9
	end
	return 1.0
end

function StatusEffectsService.GetTargetAffinity(player)
	-- Check ArmorService for equipped armor affinity
	local ArmorService = script.Parent:FindFirstChild("ArmorService")
	if ArmorService then
		local arm = require(ArmorService)
		local affinity = arm.GetTargetAffinity(player)
		if affinity then
			return affinity
		end
	end
	return nil
end

Players.PlayerRemoving:Connect(function(player)
	effects[player] = nil
	local conn = regenConnections[player]
	if conn then
		conn:Disconnect()
		regenConnections[player] = nil
	end
	conn = speedConnections[player]
	if conn then
		conn:Disconnect()
		speedConnections[player] = nil
	end
end)

return StatusEffectsService
