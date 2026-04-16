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

-- Listen for server-confirmed hits to play rock sounds
local miningHit = remotes and remotes:FindFirstChild("MiningHit")
if miningHit and miningHit:IsA("RemoteEvent") then
	-- Hit sound at character position
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

	miningHit.OnClientEvent:Connect(function(data)
		if not data then return end
		-- Hit sound on every confirmed hit
		playSoundAt(data.position, "rbxassetid://7086598143", 0.7)
		-- Bigger break sound when node breaks
		if data.broken then
			playSoundAt(data.position, "rbxassetid://3112290440", 1.0)
		end
	end)
end
