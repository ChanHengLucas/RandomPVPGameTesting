--[[
	ChoppingClient.client.lua
	On click, if target is in workspace.Trees, fire RequestChop.
	Uses Mouse.Target for hit detection.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local requestChop = remotes and remotes:FindFirstChild("RequestChop")

local treesFolder = workspace:FindFirstChild("Trees")

local function isInTrees(instance)
	if not treesFolder then
		return false
	end
	local current = instance
	while current do
		if current == treesFolder then
			return true
		end
		current = current.Parent
	end
	return false
end

local function tryChop()
	if not requestChop or not requestChop:IsA("RemoteEvent") then
		return
	end
	local target = mouse.Target
	if target and target:IsA("BasePart") and isInTrees(target) then
		requestChop:FireServer(target)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		tryChop()
	end
end)
