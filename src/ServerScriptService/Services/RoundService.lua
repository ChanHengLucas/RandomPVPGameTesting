--[[
	RoundService
	Round state machine: Lobby → Voting → Intermission → ActiveRound → (SuddenDeath) → EndRound → Lobby.
	Manages gameMode, currentRoundTime, spawn protection, SuddenDeath invulnerability.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundService = {}

local RoundDefs
local ROUND_LENGTH = 300
local DEFAULT_RESPAWN_TIME = 5

local state = "Lobby"
local gameMode = "R_FFA"
local roundStartTime = nil
local roundActive = false
local bestTierAchieved = {}
local spawnProtectionUntil = {}
local suddenDeathInvulnUntil = {}
local currentMapId = nil
local stateChangeCallbacks = {}
local cycleTask = nil
local roundKills = {}
local roundTeamKills = {}
local roundDeaths = {}

local function init()
	RoundDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RoundDefs"))
	ROUND_LENGTH = RoundDefs.ROUND_LENGTH or 300
end

init()

local function fireStateChange(oldState, newState)
	for _, cb in ipairs(stateChangeCallbacks) do
		task.spawn(cb, oldState, newState)
	end
end

function RoundService.GetState()
	return state
end

function RoundService.SetState(newState)
	if not RoundDefs.States[newState] then return end
	local oldState = state
	state = newState
	fireStateChange(oldState, newState)
end

function RoundService.OnStateChanged(callback)
	table.insert(stateChangeCallbacks, callback)
end

function RoundService.GetGameMode()
	return gameMode
end

function RoundService.SetGameMode(mode)
	if mode == "SL_FFA" or mode == "SL_TDM" or mode == "R_FFA" or mode == "R_TDM" then
		gameMode = mode
	end
end

function RoundService.IsRespawnMode()
	return gameMode == "R_FFA" or gameMode == "R_TDM"
end

function RoundService.SetSpawnProtection(player, durationSeconds)
	if player and player:IsA("Player") then
		spawnProtectionUntil[player] = tick() + (durationSeconds or 1)
	end
end

function RoundService.HasSpawnProtection(player)
	if not player or not player:IsA("Player") then return false end
	if state == "SuddenDeath" then return false end
	local untilTime = spawnProtectionUntil[player]
	return untilTime and tick() < untilTime
end

function RoundService.SetSuddenDeathInvulnerability(player, durationSeconds)
	if player and player:IsA("Player") then
		suddenDeathInvulnUntil[player] = tick() + (durationSeconds or RoundDefs.SUDDEN_DEATH_INVULNERABILITY_SECONDS or 3)
	end
end

function RoundService.HasSuddenDeathInvulnerability(player)
	if not player or not player:IsA("Player") then return false end
	if state ~= "SuddenDeath" then return false end
	local untilTime = suddenDeathInvulnUntil[player]
	return untilTime and tick() < untilTime
end

function RoundService.HasAnyProtection(player)
	return RoundService.HasSpawnProtection(player) or RoundService.HasSuddenDeathInvulnerability(player)
end

function RoundService.GetBestTier(player, category)
	if not player or not player:IsA("Player") then return 0 end
	bestTierAchieved[player] = bestTierAchieved[player] or {}
	return bestTierAchieved[player][category] or 0
end

function RoundService.SetBestTier(player, category, tier)
	if not player or not player:IsA("Player") then return end
	bestTierAchieved[player] = bestTierAchieved[player] or {}
	local current = bestTierAchieved[player][category] or 0
	if tier > current then
		bestTierAchieved[player][category] = tier
	end
end

function RoundService.GetCurrentRoundTime()
	if not roundActive or not roundStartTime then
		return 0
	end
	return math.min(tick() - roundStartTime, ROUND_LENGTH)
end

function RoundService.StartRound()
	roundStartTime = tick()
	roundActive = true
end

-- Helper: strip every Tool from a player's Backpack and Character
local function stripTools(player)
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

-- Helper: find lobby spawn position
local function getLobbySpawnPosition()
	local lobby = game.Workspace:FindFirstChild("Lobby")
	if lobby then
		local spawn = lobby:FindFirstChild("LobbySpawn")
		if spawn and spawn:IsA("BasePart") then
			return spawn.Position + Vector3.new(0, 3, 0)
		end
	end
	return Vector3.new(-500, 55, 0) -- fallback lobby position
end

-- Grant starter tools to a player (event-based Backpack wait)
local function grantRoundTools(player)
	local backpack = player:WaitForChild("Backpack", 5)
	if not backpack then return end
	local ServerStorage = game:GetService("ServerStorage")
	for _, toolName in ipairs({"WoodPickaxeTool", "WoodAxeTool", "WoodSwordTool"}) do
		local existing = backpack:FindFirstChild(toolName)
		if existing then existing:Destroy() end
		local template = ServerStorage:FindFirstChild(toolName)
		if template and template:IsA("Tool") then
			template:Clone().Parent = backpack
		end
	end
	RoundService.SetBestTier(player, "pickaxe", 1)
	RoundService.SetBestTier(player, "axe", 1)
	RoundService.SetBestTier(player, "sword", 1)
end

-- Teleport a single winner's existing character to the lobby.
-- Uses PivotTo for reliable model teleport. No LoadCharacter — winners
-- are alive, so we just move their current character.
-- NOTE: Player.RespawnTime is NOT a valid property in this Roblox API
-- (assigning it errors), so we don't touch it. Dead players auto-respawn
-- at LobbySpawn via Players.RespawnTime (default 3s, service-level).
local function teleportWinnerToLobby(player, lobbyPos)
	pcall(function()
		stripTools(player)

		local char = player.Character
		if not char then return end

		local hum = char:FindFirstChild("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")

		if hrp then
			-- Zero velocity first so physics doesn't carry them away
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end

		-- PivotTo moves the entire character model
		char:PivotTo(CFrame.new(lobbyPos))

		-- Heal to full so they enter lobby in a clean state
		if hum and hum.Health > 0 then
			hum.Health = hum.MaxHealth
		end

		stripTools(player)
	end)
end

-- Teleport every winner in the list to the lobby.
-- Dead (losing) players are NOT touched — Roblox auto-respawn places
-- them at LobbySpawn within 3 seconds (the only SpawnLocation).
local function sendWinnersToLobby(winners)
	if not winners then return end
	local lobbyPos = getLobbySpawnPosition()
	for _, player in ipairs(winners) do
		if player and player:IsA("Player") then
			teleportWinnerToLobby(player, lobbyPos)
		end
	end
end

-- EndRound: data cleanup ONLY (no LoadCharacter, no teleport)
function RoundService.EndRound()
	roundActive = false
	roundStartTime = nil
	bestTierAchieved = {}
	spawnProtectionUntil = {}
	suddenDeathInvulnUntil = {}
	roundKills = {}
	roundTeamKills = {}
	roundDeaths = {}
	local TeamService = script.Parent:FindFirstChild("TeamService")
	if TeamService then
		local ts = require(TeamService)
		if ts.ClearTeams then ts.ClearTeams() end
	end
	local InventorySvc = script.Parent:FindFirstChild("InventoryService")
	if InventorySvc then
		local invSvc = require(InventorySvc)
		for _, player in ipairs(Players:GetPlayers()) do
			if invSvc.ClearInventory then invSvc.ClearInventory(player) end
		end
	end
end

function RoundService.IsRoundActive()
	return roundActive
end

function RoundService.GetRoundLength()
	return ROUND_LENGTH
end

function RoundService.GetMapId()
	return currentMapId
end

function RoundService.SetMapId(id)
	currentMapId = id
end

function RoundService.IsSuddenDeath()
	return state == "SuddenDeath"
end

function RoundService.GetTimeRemaining()
	if not roundActive or not roundStartTime then return 0 end
	local elapsed = tick() - roundStartTime
	return math.max(0, ROUND_LENGTH - elapsed)
end

function RoundService.RecordKill(killer, victim)
	if not killer or not killer:IsA("Player") then return end
	roundKills[killer] = (roundKills[killer] or 0) + 1
	local TeamService = script.Parent:FindFirstChild("TeamService")
	if TeamService then
		local ts = require(TeamService)
		local teamId = ts.GetTeam and ts.GetTeam(killer)
		if teamId then
			roundTeamKills[teamId] = (roundTeamKills[teamId] or 0) + 1
		end
	end
end

function RoundService.GetKills(player)
	return roundKills[player] or 0
end

function RoundService.GetTeamKills(teamId)
	return roundTeamKills[teamId] or 0
end

function RoundService.RecordDeath(player)
	if not player or not player:IsA("Player") then return end
	roundDeaths[player] = (roundDeaths[player] or 0) + 1
end

function RoundService.GetDeaths(player)
	return roundDeaths[player] or 0
end

local function fireRoundStateUpdate()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild("RoundStateUpdate")
	if not evt or not evt:IsA("RemoteEvent") then return end
	local timeLeft = RoundService.GetTimeRemaining()
	local isSD = state == "SuddenDeath"
	for _, player in ipairs(Players:GetPlayers()) do
		evt:FireClient(player, {
			state = state,
			mode = gameMode,
			timeLeft = timeLeft,
			mapId = currentMapId,
			isSuddenDeath = isSD,
		})
	end
end

-- Build and broadcast the leaderboard snapshot for all players.
-- FFA snapshot: list of { name, kills, deaths } sorted by kills desc.
-- TDM snapshot: team kill totals + per-player kills/deaths under each team.
local function fireLeaderboardUpdate()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild("LeaderboardUpdate")
	if not evt or not evt:IsA("RemoteEvent") then return end

	local ffa = {}
	local tdm = { team1 = 0, team2 = 0, team1Players = {}, team2Players = {} }

	local TeamService = script.Parent:FindFirstChild("TeamService")
	local ts = TeamService and require(TeamService) or nil

	for _, p in ipairs(Players:GetPlayers()) do
		local entry = {
			name = p.Name,
			kills = roundKills[p] or 0,
			deaths = roundDeaths[p] or 0,
		}
		table.insert(ffa, entry)
		local teamId = ts and ts.GetTeam and ts.GetTeam(p) or nil
		if teamId == 1 then
			table.insert(tdm.team1Players, entry)
		elseif teamId == 2 then
			table.insert(tdm.team2Players, entry)
		end
	end
	table.sort(ffa, function(a, b) return a.kills > b.kills end)
	tdm.team1 = roundTeamKills[1] or 0
	tdm.team2 = roundTeamKills[2] or 0

	local payload = {
		mode = gameMode,
		state = state,
		ffa = ffa,
		tdm = tdm,
	}

	for _, player in ipairs(Players:GetPlayers()) do
		evt:FireClient(player, payload)
	end
end

local function fireWinnerNotification(winnerPlayer, winnerTeamId)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild("WinnerNotification")
	if not evt or not evt:IsA("RemoteEvent") then return end
	for _, player in ipairs(Players:GetPlayers()) do
		evt:FireClient(player, {
			winner = winnerPlayer and winnerPlayer.Name or nil,
			winnerTeam = winnerTeamId,
		})
	end
end

local function countAlivePlayers()
	local n = 0
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if hum and hum.Health > 0 then
			n = n + 1
		end
	end
	return n
end

local function countAlivePerTeam()
	local t1, t2 = 0, 0
	local TeamService = script.Parent:FindFirstChild("TeamService")
	if not TeamService then return 0, 0 end
	local ts = require(TeamService)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChild("Humanoid")
		if hum and hum.Health > 0 then
			local teamId = ts.GetTeam and ts.GetTeam(player)
			if teamId == 1 then t1 = t1 + 1
			elseif teamId == 2 then t2 = t2 + 1 end
		end
	end
	return t1, t2
end

local function getTiedPlayersRFFA()
	local best = -1
	for _, player in ipairs(Players:GetPlayers()) do
		local k = roundKills[player] or 0
		if k > best then best = k end
	end
	local tied = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if (roundKills[player] or 0) == best then
			table.insert(tied, player)
		end
	end
	return tied
end

local function getTiedTeamsRTDM()
	local k1 = roundTeamKills[1] or 0
	local k2 = roundTeamKills[2] or 0
	if k1 ~= k2 then return nil end
	return { 1, 2 }
end

local function getWinnerRFFA()
	local best = -1
	local winner = nil
	for _, player in ipairs(Players:GetPlayers()) do
		local k = roundKills[player] or 0
		if k > best then best = k; winner = player end
	end
	return winner
end

local function getWinnerRTDM()
	local k1 = roundTeamKills[1] or 0
	local k2 = roundTeamKills[2] or 0
	if k1 > k2 then return 1 end
	if k2 > k1 then return 2 end
	return nil
end

local function runCycle()
	local timers = RoundDefs.Timers or {}
	local lobbyInitial = timers.LobbyInitial or 3
	local lobbyPostRound = timers.LobbyPostRound or 2
	local votingDuration = timers.Voting or 15
	local intermissionDuration = timers.Intermission or 5
	local endRoundDuration = timers.EndRound or 4
	local suddenDeathMax = timers.SuddenDeathMax or 60

	RoundService.SetState("Lobby")
	fireRoundStateUpdate()
	-- Countdown through lobby wait
	local lobbyEnd = tick() + lobbyInitial
	while tick() < lobbyEnd do
		fireRoundStateUpdate()
		task.wait(1)
	end

	local MIN_PLAYERS = 2

	while true do
		-- Wait for minimum players before starting a round
		while #Players:GetPlayers() < MIN_PLAYERS do
			RoundService.SetState("Lobby")
			fireRoundStateUpdate()
			for _, player in ipairs(Players:GetPlayers()) do
				stripTools(player)
			end
			task.wait(2)
		end
		-- Final strip right before voting starts
		for _, player in ipairs(Players:GetPlayers()) do
			stripTools(player)
		end

		local roundOk, roundErr = pcall(function()
		RoundService.SetState("Voting")
		fireRoundStateUpdate()
		local VotingService = script.Parent:FindFirstChild("VotingService")
		if VotingService then
			local vs = require(VotingService)
			if vs.StartVoting then
				vs.StartVoting()
			end
		end
		-- Countdown through voting
		local votingEnd = tick() + votingDuration
		while tick() < votingEnd do
			-- Send phaseTimeLeft so client can show countdown
			local remotes2 = ReplicatedStorage:FindFirstChild("Remotes")
			if remotes2 then
				local evt2 = remotes2:FindFirstChild("RoundStateUpdate")
				if evt2 and evt2:IsA("RemoteEvent") then
					for _, p in ipairs(Players:GetPlayers()) do
						evt2:FireClient(p, {
							state = "Voting",
							mode = gameMode,
							timeLeft = 0,
							mapId = currentMapId,
							isSuddenDeath = false,
							phaseTimeLeft = math.max(0, votingEnd - tick()),
						})
					end
				end
			end
			task.wait(1)
		end

		local mapId, mode = nil, "R_FFA"
		if VotingService then
			local vs = require(VotingService)
			if vs.GetMapWinner then mapId = vs.GetMapWinner() end
			if vs.GetModeWinner then mode = vs.GetModeWinner() end
		end
		mode = mode or "R_FFA"
		RoundService.SetGameMode(mode)
		RoundService.SetMapId(mapId)

		RoundService.SetState("Intermission")
		fireRoundStateUpdate()
		local MapLoadService = script.Parent:FindFirstChild("MapLoadService")
		if MapLoadService and mapId then
			local mls = require(MapLoadService)
			if mls.LoadMap then
				pcall(function() mls.LoadMap(mapId) end)
			end
		end
		local TeamService = script.Parent:FindFirstChild("TeamService")
		if TeamService and (mode == "SL_TDM" or mode == "R_TDM") then
			local ts = require(TeamService)
			if ts.AssignTeamsForTDM then ts.AssignTeamsForTDM() end
		end
		-- Countdown through intermission
		local intermEnd = tick() + intermissionDuration
		while tick() < intermEnd do
			local remotes3 = ReplicatedStorage:FindFirstChild("Remotes")
			if remotes3 then
				local evt3 = remotes3:FindFirstChild("RoundStateUpdate")
				if evt3 and evt3:IsA("RemoteEvent") then
					for _, p in ipairs(Players:GetPlayers()) do
						evt3:FireClient(p, {
							state = "Intermission",
							mode = mode,
							timeLeft = 0,
							mapId = mapId,
							isSuddenDeath = false,
							phaseTimeLeft = math.max(0, intermEnd - tick()),
						})
					end
				end
			end
			task.wait(1)
		end

		-- Spawn players at map positions (shuffled pools, no duplicates)
		if MapLoadService then
			local mls = require(MapLoadService)
			-- Build a shuffled pool of spawn positions from a folder
			local function shuffledPool(folder)
				local pool = {}
				if not folder or not folder:IsA("Folder") then return pool end
				for _, c in ipairs(folder:GetChildren()) do
					if c:IsA("BasePart") then
						table.insert(pool, c.Position)
					end
				end
				-- Fisher-Yates shuffle
				for i = #pool, 2, -1 do
					local j = math.random(1, i)
					pool[i], pool[j] = pool[j], pool[i]
				end
				return pool
			end

			local ffaPool = shuffledPool(mls.GetSpawnPointsFFA and mls.GetSpawnPointsFFA())
			local team1Pool = shuffledPool(mls.GetSpawnPointsTeam1 and mls.GetSpawnPointsTeam1())
			local team2Pool = shuffledPool(mls.GetSpawnPointsTeam2 and mls.GetSpawnPointsTeam2())
			local ffaIdx, t1Idx, t2Idx = 0, 0, 0
			local function nextFFA()
				if #ffaPool == 0 then return nil end
				ffaIdx = (ffaIdx % #ffaPool) + 1
				return ffaPool[ffaIdx]
			end
			local function nextT1()
				if #team1Pool == 0 then return nil end
				t1Idx = (t1Idx % #team1Pool) + 1
				return team1Pool[t1Idx]
			end
			local function nextT2()
				if #team2Pool == 0 then return nil end
				t2Idx = (t2Idx % #team2Pool) + 1
				return team2Pool[t2Idx]
			end

			for _, player in ipairs(Players:GetPlayers()) do
				local pos = nil
				if mode == "SL_FFA" or mode == "R_FFA" then
					pos = nextFFA()
				else
					local ts = TeamService and require(TeamService)
					local teamId = ts and ts.GetTeam and ts.GetTeam(player)
					if teamId == 1 then
						pos = nextT1()
					else
						pos = nextT2()
					end
				end
				if pos and player.LoadCharacter then
					player:LoadCharacter()
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if hrp and hrp:IsA("BasePart") then
						hrp.CFrame = CFrame.new(pos)
					end
				end
			end
		end

		local skipRound = false
		if (mode == "SL_FFA" or mode == "SL_TDM") and MapLoadService then
			local mls = require(MapLoadService)
			local stormRadius = mls.GetStormMaxRadius and mls.GetStormMaxRadius()
			if not stormRadius or stormRadius <= 0 then
				warn("[RoundService] SL_* round cannot start: StormMaxRadius not found on map. Skipping to EndRound.")
				RoundService.SetState("EndRound")
				fireRoundStateUpdate()
				task.wait(endRoundDuration)
				RoundService.SetState("Lobby")
				task.wait(lobbyPostRound)
				if MapLoadService then
					local mls2 = require(MapLoadService)
					if mls2.UnloadMap then mls2.UnloadMap() end
				end
				RoundService.EndRound()
				if VotingService then
					local vs = require(VotingService)
					if vs.SetLastPlayedMode then vs.SetLastPlayedMode(mode) end
				end
				skipRound = true
			end
		end

		if not skipRound then
		RoundService.SetState("ActiveRound")
		RoundService.StartRound()
		fireRoundStateUpdate()

		-- Explicitly grant starter tools + materials (event-based Backpack wait)
		local InventorySvc2 = script.Parent:FindFirstChild("InventoryService")
		local invMod = InventorySvc2 and require(InventorySvc2)
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function()
				grantRoundTools(player)
				if invMod then
					invMod.AddItem(player, "Wood", 5)
					invMod.AddItem(player, "Rock", 3)
				end
			end)
		end

		if mode == "SL_FFA" or mode == "SL_TDM" then
			while true do
				task.wait(0.5)
				fireRoundStateUpdate()
				local alive = countAlivePlayers()
				if mode == "SL_FFA" then
					if alive <= 1 then break end
				else
					local t1, t2 = countAlivePerTeam()
					if t1 == 0 or t2 == 0 then break end
				end
			end
		else
			-- Respawn mode: wait ROUND_LENGTH with periodic HUD updates
			local roundEnd = tick() + ROUND_LENGTH
			while tick() < roundEnd do
				fireRoundStateUpdate()
				task.wait(1)
			end
			local tied = false
			if mode == "R_FFA" then
				local tiedList = getTiedPlayersRFFA()
				tied = #tiedList > 1
			else
				tied = getTiedTeamsRTDM() ~= nil
			end

			if tied then
				RoundService.SetState("SuddenDeath")
				-- Note: Player.RespawnTime is not a valid property in this Roblox API.
				-- In sudden death, any losers who die auto-respawn at LobbySpawn (3s),
				-- which takes them out of the fight — acceptable behavior.
				local tiedPlayers = {}
				if mode == "R_FFA" then
					tiedPlayers = getTiedPlayersRFFA()
				else
					local teams = getTiedTeamsRTDM()
					for _, player in ipairs(Players:GetPlayers()) do
						local ts = TeamService and require(TeamService)
						local teamId = ts and ts.GetTeam and ts.GetTeam(player)
						if teamId and (teamId == teams[1] or teamId == teams[2]) then
							table.insert(tiedPlayers, player)
						end
					end
				end
				local mls = MapLoadService and require(MapLoadService)
				local function pickSpawn(folder)
					if not folder or not folder:IsA("Folder") then return nil end
					local parts = folder:GetChildren()
					if #parts == 0 then return nil end
					local part = parts[math.random(1, #parts)]
					return part:IsA("BasePart") and part.Position or part:GetPivot().Position
				end
				for _, p in ipairs(tiedPlayers) do
					RoundService.SetSuddenDeathInvulnerability(p, 3)
					if p.LoadCharacter then
						p:LoadCharacter()
						local pos = nil
						if mode == "R_FFA" then
							pos = pickSpawn(mls.GetSpawnPointsFFA and mls.GetSpawnPointsFFA())
						else
							local ts = TeamService and require(TeamService)
							local teamId = ts and ts.GetTeam and ts.GetTeam(p)
							pos = (teamId == 1) and pickSpawn(mls.GetSpawnPointsTeam1 and mls.GetSpawnPointsTeam1())
								or pickSpawn(mls.GetSpawnPointsTeam2 and mls.GetSpawnPointsTeam2())
						end
						if pos then
							local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
							if hrp and hrp:IsA("BasePart") then
								hrp.CFrame = CFrame.new(pos)
							end
						end
					end
				end
				fireRoundStateUpdate()
				local sdStart = tick()
				while (tick() - sdStart) < suddenDeathMax do
					task.wait(0.5)
					local alive = countAlivePlayers()
					if mode == "R_FFA" then
						if alive <= 1 then break end
					else
						local t1, t2 = countAlivePerTeam()
						if t1 == 0 or t2 == 0 then break end
					end
				end
			end
		end

		local winnerPlayer, winnerTeamId = nil, nil
		local fromSuddenDeath = state == "SuddenDeath"
		if mode == "SL_FFA" or (mode == "R_FFA" and fromSuddenDeath) then
			for _, p in ipairs(Players:GetPlayers()) do
				local hum = p.Character and p.Character:FindFirstChild("Humanoid")
				if hum and hum.Health > 0 then winnerPlayer = p break end
			end
		elseif mode == "SL_TDM" or (mode == "R_TDM" and fromSuddenDeath) then
			local t1, t2 = countAlivePerTeam()
			if t1 > 0 and t2 == 0 then winnerTeamId = 1
			elseif t2 > 0 and t1 == 0 then winnerTeamId = 2 end
		elseif mode == "R_FFA" then
			winnerPlayer = getWinnerRFFA()
		else
			winnerTeamId = getWinnerRTDM()
		end
		fireWinnerNotification(winnerPlayer, winnerTeamId)

		-- Build winner list for teleport. Dead losers are left to auto-respawn at LobbySpawn.
		local winners = {}
		if winnerPlayer then
			-- FFA winner (SL_FFA, R_FFA sudden death, or R_FFA by kill count)
			table.insert(winners, winnerPlayer)
		elseif winnerTeamId then
			-- TDM winner: all alive players on the winning team
			local TeamService = script.Parent:FindFirstChild("TeamService")
			if TeamService then
				local ts = require(TeamService)
				for _, p in ipairs(Players:GetPlayers()) do
					local hum = p.Character and p.Character:FindFirstChild("Humanoid")
					if hum and hum.Health > 0 then
						local tId = ts.GetTeam and ts.GetTeam(p)
						if tId == winnerTeamId then
							table.insert(winners, p)
						end
					end
				end
			end
		end

		-- === END-OF-ROUND CLEANUP ===

		-- 1) State transition
		RoundService.SetState("EndRound")
		fireRoundStateUpdate()

		-- 2) Teleport winner(s) to lobby BEFORE unloading the map so they
		--    have solid ground under them. Dead losers are untouched —
		--    Roblox auto-respawn sends them to LobbySpawn naturally.
		sendWinnersToLobby(winners)

		-- 3) Reset data (inventory, teams)
		RoundService.EndRound()

		-- 4) Unload map (winners already moved, losers auto-respawn elsewhere)
		local MapLoadSvc = script.Parent:FindFirstChild("MapLoadService")
		if MapLoadSvc then
			local mls2 = require(MapLoadSvc)
			if mls2.UnloadMap then mls2.UnloadMap() end
		end

		-- 5) Record last played mode
		if VotingService then
			local vs = require(VotingService)
			if vs.SetLastPlayedMode then vs.SetLastPlayedMode(mode) end
		end

		-- 6) Visible "ROUND OVER" pause — strip tools continuously
		local endRoundEnd = tick() + endRoundDuration
		while tick() < endRoundEnd do
			fireRoundStateUpdate()
			for _, p in ipairs(Players:GetPlayers()) do
				stripTools(p)
			end
			task.wait(1)
		end

		-- 7) Lobby phase — strip tools continuously
		RoundService.SetState("Lobby")
		local lobbyEnd2 = tick() + lobbyPostRound
		while tick() < lobbyEnd2 do
			fireRoundStateUpdate()
			for _, p in ipairs(Players:GetPlayers()) do
				stripTools(p)
			end
			task.wait(1)
		end
		end -- end if not skipRound
		end) -- end pcall
		if not roundOk then
			warn("[RoundService] Round cycle error: " .. tostring(roundErr))
			pcall(function()
				RoundService.SetState("EndRound")
				local MapLoadSvc = script.Parent:FindFirstChild("MapLoadService")
				if MapLoadSvc then
					local mls = require(MapLoadSvc)
					if mls.UnloadMap then mls.UnloadMap() end
				end
				RoundService.EndRound()
				-- No forced teleport on error — next round's Intermission LoadCharacter
				-- will place everyone at their team/FFA spawn. Any stuck players
				-- auto-respawn at LobbySpawn via default behavior.
			end)
			RoundService.SetState("Lobby")
			fireRoundStateUpdate()
			task.wait(3)
		end
	end
end

task.defer(function()
	cycleTask = task.spawn(runCycle)
end)

-- Periodic leaderboard broadcast (every 2s)
task.spawn(function()
	while true do
		task.wait(2)
		pcall(fireLeaderboardUpdate)
	end
end)

return RoundService
