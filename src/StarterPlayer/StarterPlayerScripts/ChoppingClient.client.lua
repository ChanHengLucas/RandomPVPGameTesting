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

-- Listen for server-confirmed hits to play wood-chop sounds
local choppingHit = remotes and remotes:FindFirstChild("ChoppingHit")
if choppingHit and choppingHit:IsA("RemoteEvent") then
	local function playSoundAt(pos, id, vol)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Size = Vector3.new(0.1, 0.1, 0.1)
		part.Position = pos or player.Character and player.Character:GetPivot().Position or Vector3.zero
		part.Parent = workspace
		local sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = vol or 0.8
		sound.Parent = part
		sound:Play()
		sound.Ended:Connect(function() part:Destroy() end)
		task.delay(3, function() if part.Parent then part:Destroy() end end)
	end

	choppingHit.OnClientEvent:Connect(function(data)
		if not data then return end
		playSoundAt(data.position, "rbxassetid://7086597487", 0.7)
		if data.broken then
			playSoundAt(data.position, "rbxassetid://5810753638", 1.0)
		end
	end)
end
