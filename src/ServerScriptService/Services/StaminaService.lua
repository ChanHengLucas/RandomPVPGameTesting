--[[
	StaminaService
	Server-authoritative stamina per player.
	Default max 100. Sprint (Phase 8) drains; OrangeJuice restores.
	Exposes GetStamina, ModifyStamina, GetMaxStamina, SetMaxStamina (for Superiority buff).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DEFAULT_MAX = 100
local stamina = {}
local maxStamina = {}
local baseMaxStamina = {}

local remotes

local function getRemotes()
	if not remotes then
		remotes = ReplicatedStorage:FindFirstChild("Remotes")
	end
	return remotes
end

local function fireStaminaUpdate(player, current, max)
	local r = getRemotes()
	if r then
		local evt = r:FindFirstChild("StaminaUpdate")
		if evt and evt:IsA("RemoteEvent") then
			evt:FireClient(player, current, max)
		end
	end
end

local function ensureStamina(player)
	if not stamina[player] then
		stamina[player] = DEFAULT_MAX
		maxStamina[player] = DEFAULT_MAX
		baseMaxStamina[player] = DEFAULT_MAX
	end
	return stamina[player]
end

local StaminaService = {}

function StaminaService.GetStamina(player)
	if not player or not player:IsA("Player") then
		return 0
	end
	return ensureStamina(player)
end

function StaminaService.GetMaxStamina(player)
	if not player or not player:IsA("Player") then
		return DEFAULT_MAX
	end
	ensureStamina(player)
	return maxStamina[player]
end

function StaminaService.ModifyStamina(player, delta)
	if not player or not player:IsA("Player") or type(delta) ~= "number" then
		return false
	end
	ensureStamina(player)
	local current = stamina[player]
	local max = maxStamina[player]
	current = math.clamp(current + delta, 0, max)
	stamina[player] = current
	fireStaminaUpdate(player, current, max)
	return true
end

function StaminaService.SetMaxStamina(player, newMax)
	if not player or not player:IsA("Player") or type(newMax) ~= "number" or newMax < 1 then
		return
	end
	ensureStamina(player)
	baseMaxStamina[player] = newMax
	maxStamina[player] = newMax
	stamina[player] = math.min(stamina[player], newMax)
	fireStaminaUpdate(player, stamina[player], maxStamina[player])
end

function StaminaService.RestoreBaseMaxStamina(player)
	if not player or not player:IsA("Player") then
		return
	end
	if baseMaxStamina[player] then
		maxStamina[player] = baseMaxStamina[player]
	else
		maxStamina[player] = DEFAULT_MAX
	end
	stamina[player] = math.min(stamina[player], maxStamina[player])
	fireStaminaUpdate(player, stamina[player], maxStamina[player])
end

function StaminaService.ApplySuperiority(player, duration)
	if not player or not player:IsA("Player") then
		return
	end
	ensureStamina(player)
	local originalMax = maxStamina[player]
	maxStamina[player] = 150
	stamina[player] = 150
	fireStaminaUpdate(player, stamina[player], maxStamina[player])
	task.delay(duration, function()
		if not player.Parent then return end
		StaminaService.RestoreBaseMaxStamina(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	stamina[player] = nil
	maxStamina[player] = nil
	baseMaxStamina[player] = nil
end)

return StaminaService
