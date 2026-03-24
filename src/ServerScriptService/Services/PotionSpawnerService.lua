--[[
	PotionSpawnerService
	World potion spawns. Interval 25 - 15*(t/300) s. Max 3 in world. Despawn 60s.
	Positions: ActiveMap.PotionSpawnPoints. Weights: Regen 50, Heal 45, SuperiorityWeight(t).
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PotionSpawnWeights
local PotionDefs
local MapLoadService
local RoundService

local activePotions = {}
local spawnTask = nil

local function getRoundTime()
	return RoundService.GetCurrentRoundTime and RoundService.GetCurrentRoundTime() or 0
end

local function rollPotionType(t)
	local sw = PotionSpawnWeights
	local supW = sw.SuperiorityWeight(t)
	local total = sw.RegenPotion + sw.HealPotion + supW
	local r = math.random() * total
	if r < sw.RegenPotion then
		return "RegenPotion"
	end
	r = r - sw.RegenPotion
	if r < sw.HealPotion then
		return "HealPotion"
	end
	return "SuperiorityPotion"
end

local function spawnInterval(t)
	return math.max(10, 25 - 15 * (math.min(t, 300) / 300))
end

local function createPotionPart(position, itemName)
	local part = Instance.new("Part")
	part.Name = "PotionPickup"
	part.Size = Vector3.new(1, 1, 1)
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part:SetAttribute("ItemName", itemName)
	part:SetAttribute("Amount", 1)
	return part
end

local function countActivePotions()
	local n = 0
	for _ in pairs(activePotions) do
		n = n + 1
	end
	return n
end

local function spawnOne()
	local mapLoad = MapLoadService
	if not mapLoad then return end
	local points = mapLoad.GetPotionSpawnPoints and mapLoad.GetPotionSpawnPoints()
	if not points or not points:IsA("Folder") then return end

	local children = points:GetChildren()
	if #children == 0 then return end

	local pickups = Workspace:FindFirstChild("Pickups")
	if not pickups then return end

	if countActivePotions() >= 3 then return end

	local t = getRoundTime()
	local itemName = rollPotionType(t)
	local pos = children[math.random(1, #children)]
	local position = pos:IsA("BasePart") and pos.Position or pos:GetPivot().Position

	local part = createPotionPart(position, itemName)
	part.Parent = pickups

	local entry = { part = part }
	activePotions[part] = entry

	task.delay(60, function()
		if activePotions[part] then
			activePotions[part] = nil
			if part and part.Parent then
				part:Destroy()
			end
		end
	end)

	part.Destroying:Once(function()
		activePotions[part] = nil
	end)
end

local function runSpawnLoop()
	spawnTask = task.spawn(function()
		while true do
			local state = RoundService.GetState and RoundService.GetState()
			if state ~= "ActiveRound" and state ~= "SuddenDeath" then
				task.wait(5)
				continue
			end

			local t = getRoundTime()
			local interval = spawnInterval(t)
			task.wait(interval)
			spawnOne()
		end
	end)
end

local function clearAllPotions()
	for part in pairs(activePotions) do
		if part and part.Parent then
			part:Destroy()
		end
		activePotions[part] = nil
	end
end

local function init()
	PotionSpawnWeights = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PotionSpawnWeights"))
	PotionDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PotionDefs"))
	MapLoadService = require(script.Parent:FindFirstChild("MapLoadService"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
end

init()

if RoundService.OnStateChanged then
	RoundService.OnStateChanged(function(oldState, newState)
		if newState == "EndRound" then
			clearAllPotions()
		end
	end)
end

runSpawnLoop()

return {}
