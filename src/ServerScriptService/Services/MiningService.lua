--[[
	MiningService
	Handles RequestMine: player mines an ore node.
	Generic OreNode: drops determined by OreRngWeights.RollOreDrop at break.
	Validates: part in workspace.Ores, distance <= 10, cooldown 0.4s, tool tier.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MINING_RANGE = 10
local MINING_COOLDOWN = 0.4

local lastMine = {}
local nodeHitsRemaining = {}
local MiningDefs
local InventoryService
local OreRngWeights
local RoundService

local function init()
	MiningDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningDefs"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	OreRngWeights = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OreRngWeights"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
end

init()

local function distance3D(a, b)
	return (a - b).Magnitude
end

local function getEquippedTool(player)
	local character = player.Character
	if not character then
		return nil
	end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			return child
		end
	end
	return nil
end

local function toolSatisfiesTier(toolName, minTier)
	local tierOrder = MiningDefs.TierOrder
	local toolTier = tierOrder[toolName]
	local minTierLevel = tierOrder[minTier]
	if not toolTier or not minTierLevel then
		return false
	end
	return toolTier >= minTierLevel
end

local function applyMiningHit(player, part, def)
	local tool = getEquippedTool(player)
	if not tool then
		return false
	end
	local hitsToBreak = MiningDefs.HitsToBreak[tool.Name]
	if not hitsToBreak then
		return false
	end
	if not toolSatisfiesTier(tool.Name, def.minPickaxeTier) then
		return false
	end
	return true, hitsToBreak
end

local function getNodeDef(partName)
	local defs = MiningDefs.NodeDefs
	if defs then
		return defs[partName] or defs.OreNode
	end
	return nil
end

local function awardOreDrops(player, roundTime)
	local dropCount = math.random(3, 5)
	for _ = 1, dropCount do
		local itemName, amount = OreRngWeights.RollOreDrop(roundTime)
		InventoryService.AddItem(player, itemName, amount)
	end
end

local function respawnNode(part, def)
	task.delay(def.respawnTime, function()
		if not part or not part.Parent then
			return
		end
		nodeHitsRemaining[part] = nil
		part.Transparency = 0
		part.CanCollide = true
	end)
end

local function breakNode(part, def, breakerPlayer)
	nodeHitsRemaining[part] = nil
	local roundTime = RoundService.GetCurrentRoundTime()
	awardOreDrops(breakerPlayer, roundTime)
	part.Transparency = 1
	part.CanCollide = false
	respawnNode(part, def)
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestMine = remotes:FindFirstChild("RequestMine")
	if RequestMine and RequestMine:IsA("RemoteEvent") then
		RequestMine.OnServerEvent:Connect(function(player, orePart)
			if not orePart or not orePart:IsA("BasePart") then
				return
			end

			local oresFolder = Workspace:FindFirstChild("Ores")
			if not oresFolder or orePart.Parent ~= oresFolder then
				return
			end

			local def = getNodeDef(orePart.Name)
			if not def then
				return
			end

			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp or not hrp:IsA("BasePart") then
				return
			end
			if distance3D(hrp.Position, orePart.Position) > MINING_RANGE then
				return
			end

			local now = tick()
			if lastMine[player] and (now - lastMine[player]) < MINING_COOLDOWN then
				return
			end
			lastMine[player] = now

			local canMine, hitsToBreak = applyMiningHit(player, orePart, def)
			if not canMine or not hitsToBreak then
				return
			end

			if nodeHitsRemaining[orePart] == nil then
				nodeHitsRemaining[orePart] = hitsToBreak
			end
			nodeHitsRemaining[orePart] = nodeHitsRemaining[orePart] - 1

			if nodeHitsRemaining[orePart] <= 0 then
				breakNode(orePart, def, player)
			end
		end)
	end
end

return {}
