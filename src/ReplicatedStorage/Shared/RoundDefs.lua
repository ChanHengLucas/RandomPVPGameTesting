--[[
	RoundDefs.lua
	State names and timers for the round state machine.
	States: Lobby, Voting, Intermission, ActiveRound, SuddenDeath, EndRound
]]

return {
	States = {
		Lobby = "Lobby",
		Voting = "Voting",
		Intermission = "Intermission",
		ActiveRound = "ActiveRound",
		SuddenDeath = "SuddenDeath",
		EndRound = "EndRound",
	},

	-- State durations in seconds
	Timers = {
		LobbyInitial = 3,
		LobbyPostRound = 2,
		Voting = 15,
		Intermission = 5,
		ActiveRoundMax = 300,
		SuddenDeathMax = 60,
		EndRound = 4,
	},

	ROUND_LENGTH = 300,
	SUDDEN_DEATH_INVULNERABILITY_SECONDS = 3,
}
