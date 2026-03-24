--[[
	MiningClient.client.lua
	On click, if target is in workspace.Ores, fire RequestMine.
	Uses Mouse.Target for hit detection. Does not interfere with PickupClient.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local requestMine = remotes and remotes:FindFirstChild("RequestMine")

local oresFolder = workspace:FindFirstChild("Ores")

local function isInOres(instance)
	if not oresFolder then
		return false
	end
	local current = instance
	while current do
		if current == oresFolder then
			return true
		end
		current = current.Parent
	end
	return false
end

local function tryMine()
	if not requestMine or not requestMine:IsA("RemoteEvent") then
		return
	end
	local target = mouse.Target
	if target and target:IsA("BasePart") and isInOres(target) then
		requestMine:FireServer(target)
	end
end

-- Click to mine
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryMine()
	end
end)
