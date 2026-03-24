--[[
	AIController
	Basic AI for hostile mobs: chase nearest player when in range.
	RunService.Heartbeat: move mob toward target; simple pathfinding via MoveTo.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MobDefs
local CHASE_RANGE = 40
local UPDATE_INTERVAL = 0.1

local function init()
	MobDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MobDefs"))
end

init()

local function distance3D(a, b)
	return (a - b).Magnitude
end

local function getNearestPlayer(position)
	local nearest = nil
	local nearestDist = CHASE_RANGE
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local humanoid = char:FindFirstChild("Humanoid")
			if hrp and humanoid and humanoid.Health > 0 then
				local d = distance3D(position, hrp.Position)
				if d < nearestDist then
					nearestDist = d
					nearest = player
				end
			end
		end
	end
	return nearest
end

local lastUpdate = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastUpdate < UPDATE_INTERVAL then
		return
	end
	lastUpdate = now

	local mobsFolder = Workspace:FindFirstChild("Mobs")
	if not mobsFolder then
		return
	end

	for _, model in ipairs(mobsFolder:GetChildren()) do
		if model:IsA("Model") then
			local def = MobDefs[model.Name]
			if def and def.hostile then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				local hrp = model:FindFirstChild("HumanoidRootPart")
				if humanoid and humanoid.Health > 0 and hrp then
					local targetPlayer = getNearestPlayer(hrp.Position)
					if targetPlayer then
						local targetHrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
						if targetHrp then
							humanoid:MoveTo(targetHrp.Position)
						end
					end
				end
			end
		end
	end
end)

return {}
