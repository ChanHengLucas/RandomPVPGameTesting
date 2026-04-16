--[[
	StormService
	SL_* only. Shrinking safe zone; true damage when outside (storm zone).
	safeRadius(t) = StormMaxRadius * (1 - min(t,300)/300)
	DPS(t) = 4 + 10 * (min(t,300)/300). DamagePerTick = DPS(t) * 0.5
	Tick interval 0.5s.

	Lobby exemption: players within LOBBY_EXEMPT_RADIUS studs of LobbySpawn
	never take storm damage (protects mid-round joiners and spectators).

	Client broadcast: fires StormUpdate remote every STORM_TICK with
	{ active, center, safeRadius, dps, inStorm } so clients can render
	a boundary visualizer and "IN STORM" warning.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundService
local MapLoadService
local DamagePipeline
local PlayerSetupService

local STORM_TICK = 0.5
local LOBBY_EXEMPT_RADIUS = 100
local lastStormTick = {}
local lastBroadcast = 0

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

local function getLobbySpawnPos()
	local lobby = game.Workspace:FindFirstChild("Lobby")
	local spawn = lobby and lobby:FindFirstChild("LobbySpawn")
	if spawn and spawn:IsA("BasePart") then return spawn.Position end
	return Vector3.new(-500, 52.5, 0)
end

local function isPlayerInLobby(hrpPosition)
	local lobbyPos = getLobbySpawnPos()
	return (hrpPosition - lobbyPos).Magnitude < LOBBY_EXEMPT_RADIUS
end

-- Returns true if player is currently in the danger zone (outside safe radius AND on the map).
local function isPlayerInStorm(player)
	if not isStormActive() then return false end
	local character = player.Character
	if not character then return false end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hum = character:FindFirstChild("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return false end
	if isPlayerInLobby(hrp.Position) then return false end
	local centerPos = getCenter()
	if not centerPos then return false end
	return (hrp.Position - centerPos).Magnitude > getSafeRadius()
end

local function checkStorm(player)
	if not isStormActive() then return end

	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then return end

	-- Lobby exemption: players in the lobby area never take storm damage
	if isPlayerInLobby(hrp.Position) then return end

	local centerPos = getCenter()
	if not centerPos then return end

	local safeR = getSafeRadius()
	local dist = (hrp.Position - centerPos).Magnitude

	if dist <= safeR then return end

	local now = tick()
	if lastStormTick[player] and (now - lastStormTick[player]) < STORM_TICK then return end
	lastStormTick[player] = now

	local dps = getDPS()
	local damage = dps * STORM_TICK
	DamagePipeline.ApplyTrueDamage(humanoid, damage)
	if PlayerSetupService and PlayerSetupService.RecordCombat then
		PlayerSetupService.RecordCombat(player)
	end
end

local function broadcastStormState()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild("StormUpdate")
	if not evt or not evt:IsA("RemoteEvent") then return end

	local active = isStormActive()
	local centerPos = active and getCenter() or nil
	local safeR = active and getSafeRadius() or 0
	local dps = active and getDPS() or 0

	for _, player in ipairs(Players:GetPlayers()) do
		evt:FireClient(player, {
			active = active,
			center = centerPos,
			safeRadius = safeR,
			dps = dps,
			inStorm = active and isPlayerInStorm(player) or false,
		})
	end
end

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			checkStorm(player)
		end)
	end
	-- Broadcast storm state every STORM_TICK seconds
	local now = tick()
	if now - lastBroadcast >= STORM_TICK then
		lastBroadcast = now
		broadcastStormState()
	end
end)

return {}
