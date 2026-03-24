--[[
	InputHandler.client.lua
	Keybinds: E inventory, Q throw, F offhand, R reload.
	Fires remotes for server-validated actions.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local requestThrow = remotes and remotes:FindFirstChild("RequestThrow")
local requestOffhandUse = remotes and remotes:FindFirstChild("RequestOffhandUse")
local requestReload = remotes and remotes:FindFirstChild("RequestReload")

local inventoryVisible = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- E: Toggle inventory
	if input.KeyCode == Enum.KeyCode.E then
		local gui = player:WaitForChild("PlayerGui", 5):FindFirstChild("InventoryGui")
		if gui then
			inventoryVisible = not inventoryVisible
			gui.Enabled = inventoryVisible
		end
		return
	end

	-- Q: Throw (Rock if available; server validates)
	if input.KeyCode == Enum.KeyCode.Q then
		if requestThrow and requestThrow:IsA("RemoteEvent") then
			requestThrow:FireServer("Rock")
		end
		return
	end

	-- F: Offhand use
	if input.KeyCode == Enum.KeyCode.F then
		if requestOffhandUse and requestOffhandUse:IsA("RemoteEvent") then
			requestOffhandUse:FireServer()
		end
		return
	end

	-- R: Reload gun
	if input.KeyCode == Enum.KeyCode.R then
		if requestReload and requestReload:IsA("RemoteEvent") then
			requestReload:FireServer()
		end
		return
	end
end)
