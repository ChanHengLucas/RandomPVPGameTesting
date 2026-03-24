--[[
	ConsumableService
	Handles RequestConsume: player consumes food/beverage/potion.
	Validates: has item, in ConsumableDefs or PotionDefs, not on cooldown.
	Applies HP, stamina, or status effects. Removes item from inventory.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONSUME_COOLDOWN = 0.6
local HEAL_POTION_COOLDOWN = 10

local lastConsume = {}
local lastHealPotion = {}
local ConsumableDefs
local PotionDefs
local InventoryService
local StatusEffectsService

local function init()
	ConsumableDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConsumableDefs"))
	PotionDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PotionDefs"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	StatusEffectsService = require(script.Parent:FindFirstChild("StatusEffectsService"))
end

init()

local function applyConsumable(player, def)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if humanoid and def.hp and def.hp > 0 then
		humanoid.Health = math.min(humanoid.Health + def.hp, humanoid.MaxHealth)
	end
	if def.speedPercent and def.speedDuration and def.speedDuration > 0 then
		StatusEffectsService.AddEffect(player, "Speed:" .. tostring(def.speedPercent), def.speedDuration)
	end
end

local function applyPotion(player, def)
	if def.instant and def.hp then
		local character = player.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = math.min(humanoid.Health + def.hp, humanoid.MaxHealth)
		end
	elseif def.effectId and def.duration then
		StatusEffectsService.AddEffect(player, def.effectId, def.duration)
	end
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestConsume = remotes:FindFirstChild("RequestConsume")
	if RequestConsume and RequestConsume:IsA("RemoteEvent") then
		RequestConsume.OnServerEvent:Connect(function(player, itemName)
			if type(itemName) ~= "string" or itemName == "" then
				return
			end
			if not InventoryService.HasItem(player, itemName, 1) then
				return
			end

			local now = tick()
			if lastConsume[player] and (now - lastConsume[player]) < CONSUME_COOLDOWN then
				return
			end
			lastConsume[player] = now

			local def = ConsumableDefs[itemName]
			if def then
				if not InventoryService.RemoveItem(player, itemName, 1) then
					return
				end
				applyConsumable(player, def)
				return
			end

			def = PotionDefs[itemName]
			if def then
				if def.cooldown and def.cooldown > 0 then
					local last = lastHealPotion[player]
					if last and (now - last) < def.cooldown then
						return
					end
					lastHealPotion[player] = now
				end
				if not InventoryService.RemoveItem(player, itemName, 1) then
					return
				end
				applyPotion(player, def)
				return
			end
		end)
	end
end

return {}
