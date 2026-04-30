--[[
	InputHandler.client.lua
	Keybinds:
		E  → toggle InventoryGui (Craft UI)
		~  → toggle BackpackGui
		T  → toggle affinity (Angelic <-> Demonic)
		5-8 → use quick-slot consumable (bound via BackpackGui; PlayerGui attributes)
		Q  → throw
		F  → offhand use
		R  → reload
	Fires remotes for server-validated actions.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")

local requestThrow = remotes and remotes:FindFirstChild("RequestThrow")
local requestOffhandUse = remotes and remotes:FindFirstChild("RequestOffhandUse")
local requestReload = remotes and remotes:FindFirstChild("RequestReload")
local requestToggleAffinity = remotes and remotes:FindFirstChild("RequestToggleAffinity")
local requestConsume = remotes and remotes:FindFirstChild("RequestConsume")

local inventoryVisible = false
local backpackVisible = false

local function toggleGui(guiName, state)
	local gui = playerGui:FindFirstChild(guiName)
	if gui then
		gui.Enabled = state
	end
	return gui
end

local function fireConsumeForSlot(slotNumber)
	if not requestConsume or not requestConsume:IsA("RemoteEvent") then return end
	local attrName = "QuickSlot" .. tostring(slotNumber)
	local itemName = playerGui:GetAttribute(attrName)
	if type(itemName) == "string" and itemName ~= "" then
		requestConsume:FireServer(itemName)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- E: Toggle craft/inventory UI
	if input.KeyCode == Enum.KeyCode.E then
		inventoryVisible = not inventoryVisible
		toggleGui("InventoryGui", inventoryVisible)
		return
	end

	-- ~ / `: Toggle backpack UI
	if input.KeyCode == Enum.KeyCode.Backquote or input.KeyCode == Enum.KeyCode.Tilde then
		backpackVisible = not backpackVisible
		toggleGui("BackpackGui", backpackVisible)
		return
	end

	-- T: Toggle affinity (Angelic ↔ Demonic)
	if input.KeyCode == Enum.KeyCode.T then
		if requestToggleAffinity and requestToggleAffinity:IsA("RemoteEvent") then
			requestToggleAffinity:FireServer()
		end
		return
	end

	-- 5-8: quick-slot consumables (item names bound via BackpackGui attributes)
	if input.KeyCode == Enum.KeyCode.Five then
		fireConsumeForSlot(5); return
	elseif input.KeyCode == Enum.KeyCode.Six then
		fireConsumeForSlot(6); return
	elseif input.KeyCode == Enum.KeyCode.Seven then
		fireConsumeForSlot(7); return
	elseif input.KeyCode == Enum.KeyCode.Eight then
		fireConsumeForSlot(8); return
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
