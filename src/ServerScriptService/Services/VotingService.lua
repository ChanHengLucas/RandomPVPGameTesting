--[[
	VotingService
	Server-authoritative map and mode voting.
	Map: 4 options, one vote per player. Mode: 3 options (exclude lastPlayedMode), one vote per player.
	First round: lastPlayedMode = SL_TDM, options = { SL_FFA, R_FFA, R_TDM }.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MapDefs
local ModeDefs
local RoundService

local mapVotes = {}
local modeVotes = {}
local votingStartTime = nil
local votingStartTick = nil
local lastPlayedMode = "SL_TDM"
local mapOptions = {}
local modeOptions = {}
local playerJoinTimes = {}

local function init()
	MapDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MapDefs"))
	ModeDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ModeDefs"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
end

init()

local function getMapOptions()
	local opts = {}
	for mapId, _ in pairs(MapDefs) do
		table.insert(opts, mapId)
	end
	table.sort(opts, function(a, b)
		return (MapDefs[a] and MapDefs[a].order or 999) < (MapDefs[b] and MapDefs[b].order or 999)
	end)
	return opts
end

local function getModeOptions()
	local exclude = lastPlayedMode
	local opts = {}
	for modeId, _ in pairs(ModeDefs) do
		if modeId ~= exclude then
			table.insert(opts, modeId)
		end
	end
	table.sort(opts, function(a, b)
		return (ModeDefs[a] and ModeDefs[a].order or 999) < (ModeDefs[b] and ModeDefs[b].order or 999)
	end)
	return opts
end

local function isEligibleToVote(player)
	if not votingStartTick then return false end
	local joinTime = playerJoinTimes[player] or 0
	return joinTime < votingStartTick
end

local function fireVotingUpdate()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild("VotingUpdate")
	if not evt or not evt:IsA("RemoteEvent") then return end

	local timeLeft = 0
	if votingStartTime then
		timeLeft = math.max(0, 15 - (tick() - votingStartTime))
	end

	local mapTallies = {}
	for mapId, count in pairs(mapVotes) do
		mapTallies[mapId] = count
	end
	local modeTallies = {}
	for modeId, count in pairs(modeVotes) do
		modeTallies[modeId] = count
	end

	for _, player in ipairs(Players:GetPlayers()) do
		evt:FireClient(player, {
			state = "Voting",
			mapOptions = mapOptions,
			modeOptions = modeOptions,
			mapTallies = mapTallies,
			modeTallies = modeTallies,
			timeLeft = timeLeft,
		})
	end
end

function VotingService.StartVoting()
	mapVotes = {}
	modeVotes = {}
	votingStartTime = tick()
	votingStartTick = tick()
	mapOptions = getMapOptions()
	modeOptions = getModeOptions()
	fireVotingUpdate()
end

function VotingService.RecordMapVote(player, mapId)
	if RoundService.GetState() ~= "Voting" then return false end
	if not MapDefs[mapId] then return false end
	if not isEligibleToVote(player) then return false end
	if mapVotes[player] then return false end

	mapVotes[player] = mapId
	fireVotingUpdate()
	return true
end

function VotingService.RecordModeVote(player, modeId)
	if RoundService.GetState() ~= "Voting" then return false end
	local valid = false
	for _, m in ipairs(modeOptions) do
		if m == modeId then valid = true break end
	end
	if not valid then return false end
	if not isEligibleToVote(player) then return false end
	if modeVotes[player] then return false end

	modeVotes[player] = modeId
	fireVotingUpdate()
	return true
end

function VotingService.GetMapWinner()
	local tallies = {}
	for _, mapId in pairs(mapVotes) do
		tallies[mapId] = (tallies[mapId] or 0) + 1
	end
	local best = nil
	local bestCount = 0
	for mapId, count in pairs(tallies) do
		if count > bestCount then
			bestCount = count
			best = mapId
		elseif count == bestCount and best then
			local orderA = MapDefs[mapId] and MapDefs[mapId].order or 999
			local orderB = MapDefs[best] and MapDefs[best].order or 999
			if orderA < orderB then best = mapId end
		end
	end
	if best then return best end
	return mapOptions[1] or "ForestArena"
end

function VotingService.GetModeWinner()
	local tallies = {}
	for _, modeId in pairs(modeVotes) do
		tallies[modeId] = (tallies[modeId] or 0) + 1
	end
	local best = nil
	local bestCount = 0
	for modeId, count in pairs(tallies) do
		if count > bestCount then
			bestCount = count
			best = modeId
		elseif count == bestCount and best then
			local orderA = ModeDefs[modeId] and ModeDefs[modeId].order or 999
			local orderB = ModeDefs[best] and ModeDefs[best].order or 999
			if orderA < orderB then best = modeId end
		end
	end
	if best then return best end
	return modeOptions[1] or "R_FFA"
end

function VotingService.SetLastPlayedMode(mode)
	lastPlayedMode = mode or "SL_TDM"
end

function VotingService.GetLastPlayedMode()
	return lastPlayedMode
end

Players.PlayerAdded:Connect(function(player)
	playerJoinTimes[player] = tick()
end)
Players.PlayerRemoving:Connect(function(player)
	playerJoinTimes[player] = nil
	mapVotes[player] = nil
	modeVotes[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	playerJoinTimes[player] = tick()
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestVoteMap = remotes:FindFirstChild("RequestVoteMap")
	if RequestVoteMap and RequestVoteMap:IsA("RemoteEvent") then
		RequestVoteMap.OnServerEvent:Connect(function(player, payload)
			local mapId = type(payload) == "table" and payload.mapId or payload
			if type(mapId) ~= "string" then return end
			VotingService.RecordMapVote(player, mapId)
		end)
	end
	local RequestVoteMode = remotes:FindFirstChild("RequestVoteMode")
	if RequestVoteMode and RequestVoteMode:IsA("RemoteEvent") then
		RequestVoteMode.OnServerEvent:Connect(function(player, payload)
			local mode = type(payload) == "table" and payload.mode or payload
			if type(mode) ~= "string" then return end
			VotingService.RecordModeVote(player, mode)
		end)
	end
end

return VotingService
