--[[
	HazardsService
	Handles lava DoT, water slow, void instant death.
	Workspace folders: Lava, Water, Void (or parts with matching names).
	Touch detection: player in part -> apply hazard.
]]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HazardDefs
local PlayerSetupService
local RoundService
local DamagePipeline
local lastLavaTick = {}
local LAVA_TICK = 0.5

local function init()
	HazardDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("HazardDefs"))
	PlayerSetupService = require(script.Parent:FindFirstChild("PlayerSetupService"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
	DamagePipeline = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamagePipeline"))
end

init()

local function getPartsInFolder(folderName)
	local folder = Workspace:FindFirstChild(folderName)
	if not folder then
		return {}
	end
	local parts = {}
	for _, child in ipairs(folder:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	return parts
end

local function isPositionInPart(pos, part)
	local size = part.Size
	local cf = part.CFrame
	local rel = cf:PointToObjectSpace(pos)
	local hx, hy, hz = size.X/2, size.Y/2, size.Z/2
	return math.abs(rel.X) <= hx and math.abs(rel.Y) <= hy and math.abs(rel.Z) <= hz
end

local function checkLava(player)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then return end
	if RoundService.HasSpawnProtection(player) then return end

	for _, part in ipairs(getPartsInFolder("Lava")) do
		if isPositionInPart(hrp.Position, part) then
			local def = HazardDefs.Lava
			local now = tick()
			if not lastLavaTick[player] or (now - lastLavaTick[player]) >= LAVA_TICK then
				lastLavaTick[player] = now
				local damage = (def.damagePerSecond or 25) * LAVA_TICK
				DamagePipeline.ApplyTrueDamage(humanoid, damage)
				PlayerSetupService.RecordCombat(player)
			end
			return
		end
	end
	lastLavaTick[player] = nil
end

local function checkVoid(player)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then return end
	if RoundService.HasSpawnProtection(player) then return end

	for _, part in ipairs(getPartsInFolder("Void")) do
		if isPositionInPart(hrp.Position, part) then
			DamagePipeline.ApplyTrueDamage(humanoid, math.huge)
			PlayerSetupService.RecordCombat(player)
			return
		end
	end
end

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			checkLava(player)
			checkVoid(player)
		end)
	end
end)

return {}
