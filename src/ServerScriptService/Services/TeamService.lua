--[[
	TeamService
	Assigns teams for TDM modes (SL_TDM, R_TDM).
	Team 1 and Team 2. Assigned during Intermission.
]]

local Players = game:GetService("Players")

local playerTeam = {}

local TeamService = {}

function TeamService.GetTeam(player)
	if not player or not player:IsA("Player") then return nil end
	return playerTeam[player]
end

function TeamService.SetTeam(player, teamId)
	if not player or not player:IsA("Player") then return end
	playerTeam[player] = teamId
end

function TeamService.AssignTeamsForTDM()
	playerTeam = {}
	local players = Players:GetPlayers()
	for i, player in ipairs(players) do
		TeamService.SetTeam(player, (i % 2) == 1 and 1 or 2)
	end
end

function TeamService.ClearTeams()
	playerTeam = {}
end

Players.PlayerRemoving:Connect(function(player)
	playerTeam[player] = nil
end)

return TeamService
