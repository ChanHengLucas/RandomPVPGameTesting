--[[
	ChoppingService
	Handles RequestChop: player chops a tree node.
	Validates: part in workspace.Trees, distance <= 10, cooldown 0.45s, axe tier.
	Integer hits model: HITS_TO_BREAK per axe tier. On break: Wood [3,5], Apple 35%, Orange 20%.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CHOP_RANGE = 10
local CHOP_COOLDOWN = 0.45

local lastChop = {}
local nodeHitsRemaining = {}
local ChoppingDefs
local InventoryService

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
	awardDrops(breakerPlayer)
	part.Transparency = 1
	part.CanCollide = false
	respawnNode(part, def)
end

local function init()
	ChoppingDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ChoppingDefs"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
end

init()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestChop = remotes:FindFirstChild("RequestChop")
	if RequestChop and RequestChop:IsA("RemoteEvent") then
		RequestChop.OnServerEvent:Connect(function(player, treePart)
			if not treePart or not treePart:IsA("BasePart") then
				return
			end

			local treesFolder = Workspace:FindFirstChild("Trees")
			if not treesFolder or treePart.Parent ~= treesFolder then
				return
			end

			local def = getNodeDef(treePart.Name)
			if not def then
				return
			end

			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp or not hrp:IsA("BasePart") then
				return
			end
			if distance3D(hrp.Position, treePart.Position) > CHOP_RANGE then
				return
			end

			local now = tick()
			if lastChop[player] and (now - lastChop[player]) < CHOP_COOLDOWN then
				return
			end
			lastChop[player] = now

			local canChop, hitsToBreak = applyChoppingHit(player, treePart, def)
			if not canChop or not hitsToBreak then
				return
			end

			if nodeHitsRemaining[treePart] == nil then
				nodeHitsRemaining[treePart] = hitsToBreak
			end
			nodeHitsRemaining[treePart] = nodeHitsRemaining[treePart] - 1

			if nodeHitsRemaining[treePart] <= 0 then
				breakNode(treePart, def, player)
			end
		end)
	end
end

return {}
