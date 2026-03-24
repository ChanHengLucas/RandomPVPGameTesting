--[[
	PickupService
	Handles RequestPickup: player requests pickup of a part.
	Validates: part in workspace.Pickups, distance <= 10, cooldown ~0.15s.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PICKUP_RANGE = 10
local PICKUP_COOLDOWN = 0.15

local lastPickup = {}
local ItemDefs
local InventoryService

local function getRemotes()
	return ReplicatedStorage:FindFirstChild("Remotes")
end

local function distance3D(a, b)
	return (a - b).Magnitude
end

local function init()
	ItemDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemDefs"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
end

init()

local remotes = getRemotes()
if remotes then
	local RequestPickup = remotes:FindFirstChild("RequestPickup")
	if RequestPickup and RequestPickup:IsA("RemoteEvent") then
		RequestPickup.OnServerEvent:Connect(function(player, part)
			-- Validation: part is BasePart
			if not part or not part:IsA("BasePart") then
				return
			end

			-- Must be in workspace.Pickups
			local pickupsFolder = Workspace:FindFirstChild("Pickups")
			if not pickupsFolder or part.Parent ~= pickupsFolder then
				return
			end

			-- Distance check
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp or not hrp:IsA("BasePart") then
				return
			end
			if distance3D(hrp.Position, part.Position) > PICKUP_RANGE then
				return
			end

			-- Cooldown
			local now = tick()
			if lastPickup[player] and (now - lastPickup[player]) < PICKUP_COOLDOWN then
				return
			end
			lastPickup[player] = now

			-- ItemName attribute (GroundDrop, PotionPickup) or ItemDefs.Pickups
			local itemName, amount
			local attrItem = part:GetAttribute("ItemName")
			if type(attrItem) == "string" and attrItem ~= "" then
				itemName = attrItem
				amount = part:GetAttribute("Amount")
				amount = type(amount) == "number" and amount > 0 and amount or 1
			else
				local itemData = ItemDefs.Pickups and ItemDefs.Pickups[part.Name]
				if not itemData or type(itemData.itemName) ~= "string" then return end
				itemName = itemData.itemName
				amount = type(itemData.amount) == "number" and itemData.amount > 0 and itemData.amount or 1
			end

			InventoryService.AddItem(player, itemName, amount)
			part:Destroy()
		end)
	end
end

return {}
