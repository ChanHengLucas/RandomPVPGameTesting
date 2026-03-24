--[[
	ThrowingService
	Handles RequestThrow: player throws a throwable item (Q).
	Validates: has throwable in inventory, cooldown.
	Creates part with velocity, removes from inventory.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local THROW_COOLDOWN = 1.5
local THROW_VELOCITY = 50
local THROWABLE_ITEMS = { Rock = true }

local lastThrow = {}
local InventoryService

local function init()
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
end

init()

local function getThrowDirection(player)
	local character = player.Character
	if not character then
		return Vector3.new(0, 0, -1)
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return Vector3.new(0, 0, -1)
	end
	local cam = workspace.CurrentCamera
	if cam then
		local look = (cam.CFrame.LookVector + Vector3.new(0, 0.3, 0)).Unit
		return look
	end
	return -hrp.CFrame.LookVector
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
	local RequestThrow = remotes:FindFirstChild("RequestThrow")
	if RequestThrow and RequestThrow:IsA("RemoteEvent") then
		RequestThrow.OnServerEvent:Connect(function(player, itemName)
			if type(itemName) ~= "string" or not THROWABLE_ITEMS[itemName] then
				return
			end
			if not InventoryService.HasItem(player, itemName, 1) then
				return
			end
			local now = tick()
			if lastThrow[player] and (now - lastThrow[player]) < THROW_COOLDOWN then
				return
			end
			lastThrow[player] = now
			InventoryService.RemoveItem(player, itemName, 1)

			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local origin = hrp and hrp.Position + Vector3.new(0, 1, 0) or Vector3.new(0, 5, 0)
			local direction = getThrowDirection(player)

			local part = Instance.new("Part")
			part.Name = "Throwable" .. itemName
			part.Size = Vector3.new(1, 1, 1)
			part.Shape = Enum.PartType.Ball
			part.Material = Enum.Material.SmoothPlastic
			part.CanCollide = true
			part.Anchored = false
			part.Position = origin
			part.Parent = Workspace

			local bodyVel = Instance.new("BodyVelocity")
			bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			bodyVel.Velocity = direction * THROW_VELOCITY
			bodyVel.Parent = part

			task.delay(5, function()
				if part and part.Parent then
					part:Destroy()
				end
			end)
		end)
	end
end

return {}
