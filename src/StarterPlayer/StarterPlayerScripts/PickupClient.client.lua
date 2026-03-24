--[[
	PickupClient.client.lua
	On click, if target is in workspace.Pickups, fire RequestPickup.
	Uses Mouse.Target for hit detection.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local requestPickup = remotes and remotes:FindFirstChild("RequestPickup")

local pickupsFolder = workspace:FindFirstChild("Pickups")

local function isInPickups(instance)
	if not pickupsFolder then
		return false
	end
	local current = instance
	while current do
		if current == pickupsFolder then
			return true
		end
		current = current.Parent
	end
	return false
end

local function tryPickup()
	if not requestPickup or not requestPickup:IsA("RemoteEvent") then
		return
	end
	local target = mouse.Target
	if target and target:IsA("BasePart") and isInPickups(target) then
		requestPickup:FireServer(target)
	end
end

-- Click to pickup
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryPickup()
	end
end)
