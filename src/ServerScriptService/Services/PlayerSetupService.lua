--[[
	PlayerSetupService
	Sets player HP to 100 on spawn.
	Out-of-combat regen: after 8s idle, heal 5 HP/s.
	Must run early (before CombatService records damage).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDefs
local lastDamageTime = {}

local function init()
	PlayerDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PlayerDefs"))
end

init()

local function setupCharacter(player, character)
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.MaxHealth = PlayerDefs.BaseHP
		humanoid.Health = PlayerDefs.BaseHP
	end
end

local function onCharacterAdded(player, character)
	setupCharacter(player, character)
	lastDamageTime[player] = tick()
end

local function connectPlayer(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

-- Called by CombatService/HazardsService when player takes or deals damage
local PlayerSetupService = {}
function PlayerSetupService.RecordCombat(player)
	if player and player:IsA("Player") then
		lastDamageTime[player] = tick()
	end
end

-- Regen loop: after RegenDelay seconds without combat, heal RegenRate HP/s
RunService.Heartbeat:Connect(function()
	local t = tick()
	for player, lastTime in pairs(lastDamageTime) do
		if not player.Parent then
			lastDamageTime[player] = nil
			continue
		end
		local char = player.Character
		local humanoid = char and char:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			continue
		end
		if t - lastTime >= PlayerDefs.RegenDelay then
			local heal = PlayerDefs.RegenRate * (1 / 60)
			humanoid.Health = math.min(humanoid.Health + heal, humanoid.MaxHealth)
		end
	end
end)

Players.PlayerAdded:Connect(connectPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.defer(function()
		connectPlayer(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	lastDamageTime[player] = nil
end)

return PlayerSetupService
