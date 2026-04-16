--[[
	MiningService
	Handles RequestMine: player mines an ore node.
	Generic OreNode: drops determined by OreRngWeights.RollOreDrop at break.
	Validates: part in workspace.Ores, distance <= 10, cooldown 0.4s, tool tier.
	Supports both Model-based and BasePart-based ore nodes.
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

local oresFolder = nil

local function init()
	MiningDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MiningDefs"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	OreRngWeights = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OreRngWeights"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
	oresFolder = Workspace:FindFirstChild("Ores")
	if not oresFolder then
		warn("[MiningService] Workspace.Ores folder not found")
	end
end

init()

local function distance3D(a, b)
	return (a - b).Magnitude
end

-- Resolve a clicked BasePart to its parent ore node (Model or BasePart) in the Ores folder
local function resolveOreNode(clickedPart)
	if not oresFolder then return nil, nil end
	local current = clickedPart
	while current and current ~= oresFolder do
		if current.Parent == oresFolder then
			return current, current:IsA("Model") and current:GetPivot().Position or current.Position
		end
		current = current.Parent
	end
	return nil, nil
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

local function setNodeVisible(node, visible)
	if node:IsA("Model") then
		for _, child in ipairs(node:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = visible and 0 or 1
				child.CanCollide = visible
			end
		end
	elseif node:IsA("BasePart") then
		node.Transparency = visible and 0 or 1
		node.CanCollide = visible
	end
end

local function respawnNode(node, def)
	task.delay(def.respawnTime, function()
		if not node or not node.Parent then
			return
		end
		nodeHitsRemaining[node] = nil
		setNodeVisible(node, true)
	end)
end

local function breakNode(node, def, breakerPlayer)
	nodeHitsRemaining[node] = nil
	local roundTime = RoundService.GetCurrentRoundTime()
	awardOreDrops(breakerPlayer, roundTime)
	setNodeVisible(node, false)
	respawnNode(node, def)
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestMine = remotes:FindFirstChild("RequestMine")
	if RequestMine and RequestMine:IsA("RemoteEvent") then
		RequestMine.OnServerEvent:Connect(function(player, clickedPart)
			if not clickedPart or not clickedPart:IsA("BasePart") then
				return
			end

			local oreNode, nodePos = resolveOreNode(clickedPart)
			if not oreNode then
				return
			end

			local def = getNodeDef(oreNode.Name)
			if not def then
				return
			end

			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp or not hrp:IsA("BasePart") then
				return
			end
			if distance3D(hrp.Position, nodePos) > MINING_RANGE then
				return
			end

			local now = tick()
			if lastMine[player] and (now - lastMine[player]) < MINING_COOLDOWN then
				return
			end
			lastMine[player] = now

			local canMine, hitsToBreak = applyMiningHit(player, oreNode, def)
			if not canMine or not hitsToBreak then
				return
			end

			if nodeHitsRemaining[oreNode] == nil then
				nodeHitsRemaining[oreNode] = hitsToBreak
			end
			nodeHitsRemaining[oreNode] = nodeHitsRemaining[oreNode] - 1

			local broken = nodeHitsRemaining[oreNode] <= 0
			if broken then
				breakNode(oreNode, def, player)
			end

			-- Fire MiningHit remote so client can play server-confirmed hit sound
			local MiningHit = remotes:FindFirstChild("MiningHit")
			if MiningHit and MiningHit:IsA("RemoteEvent") then
				MiningHit:FireClient(player, {
					position = nodePos,
					broken = broken,
				})
			end
		end)
	end
end

return {}
