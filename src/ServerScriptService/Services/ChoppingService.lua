--[[
	ChoppingService
	Handles RequestChop: player chops a tree node.
	Validates: part in workspace.Trees, distance <= 10, cooldown 0.45s, axe tier.
	Integer hits model: HITS_TO_BREAK per axe tier. On break: Wood [3,5], Apple 35%, Orange 20%.
	Supports both Model-based and BasePart-based tree nodes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CHOP_RANGE = 10
local CHOP_COOLDOWN = 0.45

local lastChop = {}
local nodeHitsRemaining = {}
local ChoppingDefs
local InventoryService

local treesFolder = nil

local function distance3D(a, b)
	return (a - b).Magnitude
end

-- Resolve a clicked BasePart to its parent tree node (Model or BasePart) in the Trees folder
local function resolveTreeNode(clickedPart)
	if not treesFolder then return nil, nil end
	local current = clickedPart
	while current and current ~= treesFolder do
		if current.Parent == treesFolder then
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
	local tierOrder = ChoppingDefs.TierOrder
	local toolTier = tierOrder[toolName]
	local minTierLevel = tierOrder[minTier]
	if not toolTier or not minTierLevel then
		return false
	end
	return toolTier >= minTierLevel
end

local function applyChoppingHit(player, part, def)
	local tool = getEquippedTool(player)
	if not tool then
		return false
	end
	local hitsToBreak = ChoppingDefs.HitsToBreak[tool.Name]
	if not hitsToBreak then
		return false
	end
	if not toolSatisfiesTier(tool.Name, def.minAxeTier) then
		return false
	end
	return true, hitsToBreak
end

local function awardDrops(player)
	local woodAmount = math.random(3, 5)
	InventoryService.AddItem(player, "Wood", woodAmount)
	if math.random() < 0.35 then
		InventoryService.AddItem(player, "Apple", 1)
	end
	if math.random() < 0.20 then
		InventoryService.AddItem(player, "Orange", 1)
	end
end

local function getNodeDef(partName)
	local defs = ChoppingDefs.NodeDefs
	if defs then
		return defs[partName] or defs.TreeNode
	end
	return nil
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
	awardDrops(breakerPlayer)
	setNodeVisible(node, false)
	respawnNode(node, def)
end

local function init()
	ChoppingDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ChoppingDefs"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	treesFolder = Workspace:FindFirstChild("Trees")
	if not treesFolder then
		warn("[ChoppingService] Workspace.Trees folder not found")
	end
end

init()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestChop = remotes:FindFirstChild("RequestChop")
	if RequestChop and RequestChop:IsA("RemoteEvent") then
		RequestChop.OnServerEvent:Connect(function(player, clickedPart)
			if not clickedPart or not clickedPart:IsA("BasePart") then
				return
			end

			local treeNode, nodePos = resolveTreeNode(clickedPart)
			if not treeNode then
				return
			end

			local def = getNodeDef(treeNode.Name)
			if not def then
				return
			end

			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp or not hrp:IsA("BasePart") then
				return
			end
			if distance3D(hrp.Position, nodePos) > CHOP_RANGE then
				return
			end

			local now = tick()
			if lastChop[player] and (now - lastChop[player]) < CHOP_COOLDOWN then
				return
			end
			lastChop[player] = now

			local canChop, hitsToBreak = applyChoppingHit(player, treeNode, def)
			if not canChop or not hitsToBreak then
				return
			end

			if nodeHitsRemaining[treeNode] == nil then
				nodeHitsRemaining[treeNode] = hitsToBreak
			end
			nodeHitsRemaining[treeNode] = nodeHitsRemaining[treeNode] - 1

			local broken = nodeHitsRemaining[treeNode] <= 0
			if broken then
				breakNode(treeNode, def, player)
			end

			-- Fire ChoppingHit remote so client can play server-confirmed hit sound
			local ChoppingHit = remotes:FindFirstChild("ChoppingHit")
			if ChoppingHit and ChoppingHit:IsA("RemoteEvent") then
				ChoppingHit:FireClient(player, {
					position = nodePos,
					broken = broken,
				})
			end
		end)
	end
end

return {}
