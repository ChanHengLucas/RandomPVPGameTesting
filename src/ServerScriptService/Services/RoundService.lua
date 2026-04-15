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

function RoundService.EndRound()
	roundActive = false
	roundStartTime = nil
	bestTierAchieved = {}
	spawnProtectionUntil = {}
	suddenDeathInvulnUntil = {}
	roundKills = {}
	roundTeamKills = {}
	local TeamService = script.Parent:FindFirstChild("TeamService")
	if TeamService then
		local ts = require(TeamService)
		if ts.ClearTeams then ts.ClearTeams() end
	end

	-- Clear all inventories
	local InventorySvc = script.Parent:FindFirstChild("InventoryService")
	if InventorySvc then
		local invSvc = require(InventorySvc)
		for _, player in ipairs(Players:GetPlayers()) do
			if invSvc.ClearInventory then invSvc.ClearInventory(player) end
		end
	end

	-- Send every player back to lobby with a clean character
	local lobbyPos = getLobbySpawnPosition()
	for _, player in ipairs(Players:GetPlayers()) do
		player.RespawnTime = DEFAULT_RESPAWN_TIME
		stripTools(player)
		pcall(function()
			player:LoadCharacter()
			-- Explicit teleport to lobby (don't rely on SpawnLocation selection)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(lobbyPos)
			end
			-- Strip tools AGAIN after LoadCharacter in case onSpawn granted them
			stripTools(player)
		end)
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
			task.wait(2)
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

		-- Spawn players at map positions
		if MapLoadService then
			local mls = require(MapLoadService)
			local function pickSpawn(folder)
				if not folder or not folder:IsA("Folder") then return nil end
				local parts = folder:GetChildren()
				if #parts == 0 then return nil end
				local p = parts[math.random(1, #parts)]
				return p:IsA("BasePart") and p.Position or p:GetPivot().Position
			end
			for _, player in ipairs(Players:GetPlayers()) do
				local pos = nil
				if mode == "SL_FFA" or mode == "R_FFA" then
					pos = pickSpawn(mls.GetSpawnPointsFFA and mls.GetSpawnPointsFFA())
				else
					local ts = TeamService and require(TeamService)
					local teamId = ts and ts.GetTeam and ts.GetTeam(player)
					if teamId == 1 then
						pos = pickSpawn(mls.GetSpawnPointsTeam1 and mls.GetSpawnPointsTeam1())
					else
						pos = pickSpawn(mls.GetSpawnPointsTeam2 and mls.GetSpawnPointsTeam2())
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

		-- Grant starter tools + materials now that state is ActiveRound
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function()
				local backpack = player:FindFirstChild("Backpack")
				if not backpack then return end
				local ServerStorage = game:GetService("ServerStorage")
				for _, toolName in ipairs({"WoodPickaxeTool", "WoodAxeTool", "WoodSwordTool"}) do
					local template = ServerStorage:FindFirstChild(toolName)
					if template and template:IsA("Tool") then
						local clone = template:Clone()
						clone.Parent = backpack
					end
				end
				RoundService.SetBestTier(player, "pickaxe", 1)
				RoundService.SetBestTier(player, "axe", 1)
				RoundService.SetBestTier(player, "sword", 1)
				local InventorySvc2 = script.Parent:FindFirstChild("InventoryService")
				local invMod = InventorySvc2 and require(InventorySvc2)
				if invMod then
					invMod.AddItem(player, "Wood", 5)
					invMod.AddItem(player, "Rock", 3)
				end
			end)
		end

		if mode == "SL_FFA" or mode == "SL_TDM" then
			while true do
				task.wait(1)
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
				for _, p in ipairs(Players:GetPlayers()) do
					p.RespawnTime = math.huge
				end
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

		-- === END-OF-ROUND CLEANUP (same skipRound block) ===

		-- 1) Set state so onSpawn won't grant tools
		RoundService.SetState("EndRound")
		fireRoundStateUpdate()
		-- 2) Unload map BEFORE respawning so LoadCharacter only finds lobby spawn
		local MapLoadSvc = script.Parent:FindFirstChild("MapLoadService")
		if MapLoadSvc then
			local mls = require(MapLoadSvc)
			if mls.UnloadMap then mls.UnloadMap() end
		end
		-- 3) Full cleanup: clear inv, strip tools, respawn everyone at lobby
		RoundService.EndRound()
		if VotingService then
			local vs = require(VotingService)
			if vs.SetLastPlayedMode then vs.SetLastPlayedMode(mode) end
		end
		-- Countdown through EndRound
		local endRoundEnd = tick() + endRoundDuration
		while tick() < endRoundEnd do
			fireRoundStateUpdate()
			task.wait(1)
		end

		RoundService.SetState("Lobby")
		-- Countdown through Lobby post-round
		local lobbyEnd2 = tick() + lobbyPostRound
		while tick() < lobbyEnd2 do
			fireRoundStateUpdate()
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

return RoundService
