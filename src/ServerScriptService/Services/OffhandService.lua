--[[
	OffhandService
	Handles RequestOffhandUse: player uses offhand item (F).
	Validates: offhand slot has item, item supports use.
	Effects: Torch (light), Shield (block - future), etc.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OFFHAND_COOLDOWN = 0.5

local lastUse = {}
local offhandSlot = {} -- [player] = itemName
local InventoryService

local function init()
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
end

init()

local OFFHAND_ITEMS = {
	Torch = true,
	Shield = true,
	Bucket = true,
}

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestOffhandUse = remotes:FindFirstChild("RequestOffhandUse")
	if RequestOffhandUse and RequestOffhandUse:IsA("RemoteEvent") then
		RequestOffhandUse.OnServerEvent:Connect(function(player)
			local now = tick()
			if lastUse[player] and (now - lastUse[player]) < OFFHAND_COOLDOWN then
				return
			end
			lastUse[player] = now

			-- Offhand slot: for now, check if player has Torch/Shield/Bucket equipped in second tool slot or inventory
			-- Simplified: check Backpack for offhand tool (second tool)
			local backpack = player:FindFirstChild("Backpack")
			local offhandItem = nil
			if backpack then
				local tools = {}
				for _, child in ipairs(backpack:GetChildren()) do
					if child:IsA("Tool") then
						table.insert(tools, child)
					end
				end
				for _, tool in ipairs(tools) do
					local name = tool.Name:gsub("Tool$", "")
					if OFFHAND_ITEMS[name] then
						offhandItem = name
						break
					end
				end
			end
			if not offhandItem then
				for itemName in pairs(OFFHAND_ITEMS) do
					if InventoryService.HasItem(player, itemName, 1) then
						offhandItem = itemName
						break
					end
				end
			end
			if offhandItem then
				-- Fire to client for visual effect; server just validates
				local StatusEffectUpdate = remotes:FindFirstChild("OffhandUsed")
				if StatusEffectUpdate and StatusEffectUpdate:IsA("RemoteEvent") then
					StatusEffectUpdate:FireClient(player, offhandItem)
				end
			end
		end)
	end
end

return {}
