--[[
	StormService
	SL_* only. Shrinking safe zone; true damage when outside (storm zone).
	safeRadius(t) = StormMaxRadius * (1 - min(t,300)/300)
	DPS(t) = 4 + 10 * (min(t,300)/300). DamagePerTick = DPS(t) * 0.5
	Tick interval 0.5s.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundService
local MapLoadService
local DamagePipeline
local PlayerSetupService

local STORM_TICK = 0.5
local lastStormTick = {}

local function init()
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
	MapLoadService = require(script.Parent:FindFirstChild("MapLoadService"))
	DamagePipeline = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamagePipeline"))
	PlayerSetupService = require(script.Parent:FindFirstChild("PlayerSetupService"))
end

init()

local function isStormActive()
	local state = RoundService.GetState()
	local mode = RoundService.GetGameMode()
	if state ~= "ActiveRound" and state ~= "SuddenDeath" then return false end
	return mode == "SL_FFA" or mode == "SL_TDM"
end

local function getSafeRadius()
	local maxR = MapLoadService.GetStormMaxRadius()
	if not maxR or maxR <= 0 then return 0 end
	local t = RoundService.GetCurrentRoundTime()
	local ratio = math.min(t, 300) / 300
	return maxR * (1 - ratio)
end

local function getDPS()
	local t = RoundService.GetCurrentRoundTime()
	local ratio = math.min(t, 300) / 300
	return 4 + 10 * ratio
end

local function getCenter()
	local center = MapLoadService.GetCenter()
	if not center then return nil end
	return center.Position
end

local function checkStorm(player)
	if not isStormActive() then return end

	local mode = RoundService.GetGameMode()
	if mode ~= "SL_FFA" and mode ~= "SL_TDM" then return end

	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then return end

	local centerPos = getCenter()
	if not centerPos then return end

	local safeR = getSafeRadius()
	local dist = (hrp.Position - centerPos).Magnitude

	if dist <= safeR then
		return
	end

	local now = tick()
	if lastStormTick[player] and (now - lastStormTick[player]) < STORM_TICK then
		return
	end
	lastStormTick[player] = now

	local dps = getDPS()
	local damage = dps * STORM_TICK
	DamagePipeline.ApplyTrueDamage(humanoid, damage)
	if PlayerSetupService and PlayerSetupService.RecordCombat then
		PlayerSetupService.RecordCombat(player)
	end
end

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			checkStorm(player)
		end)
	end
end)

return {}
