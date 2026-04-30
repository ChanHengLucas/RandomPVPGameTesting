--[[
	AutoEquipService
	Auto-manages melee Tools (sword/pickaxe/axe/spear) and armor (Head/Body/Legs/Feet) per player.

	Rules:
	- ONE tool per melee category; Angelic/Demonic prioritized.
	- Affinity state (Angelic/Demonic) per player (default Angelic); T key toggles; picks which of
	  Angelic/Demonic to equip when both are owned. Clears at round end.
	- Hotbar slot preferences per category; defaults sword=1, pickaxe=2, axe=3, spear=4.
	  RequestSetHotbarPref auto-swaps the conflicting category so every slot maps to one category.
	- Manual override lock per category/slot. Lock clears on round end, on R_* mid-round respawn,
	  or via "Auto" button (RequestClearManualLock remote).
	- Debounced via 0.25s Heartbeat tick (RunService) — one rebuild per tick per dirty player.
	- Guns/torch/shield/bucket are NEVER touched here (manual equip via RequestEquip only).

	Public API (also usable by EquipService / ArmorService to register manual choices):
		AutoEquipService.MarkDirty(player)
		AutoEquipService.MarkManual(player, categoryOrSlot)
		AutoEquipService.ClearManual(player, categoryOrSlot)
		AutoEquipService.GetAffinity(player)
		AutoEquipService.GetHotbarPrefs(player)
		AutoEquipService.GetManualLocks(player)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local CraftingTiers
local ArmorStats
local InventoryService
local ArmorService
local RoundService

local AutoEquipService = {}

----------------------------------------------------------------
-- Constants
----------------------------------------------------------------

-- Auto-managed melee categories. Also defines the default hotbar priority order.
local AUTO_CATEGORIES = { "sword", "pickaxe", "axe", "spear" }

local DEFAULT_HOTBAR_PREFS = { sword = 1, pickaxe = 2, axe = 3, spear = 4 }

-- Per-category item sets (regular tiers ascending, then Angelic / Demonic).
local CATEGORY_ITEMS = {
	sword = {
		"WoodSword", "StoneSword", "CopperSword", "IronSword", "GoldSword",
		"SapphireSword", "EmeraldSword", "RubySword", "DiamondSword",
		"AngelicSword", "DemonicSword",
	},
	pickaxe = {
		"WoodPickaxe", "StonePickaxe", "CopperPickaxe", "IronPickaxe", "GoldPickaxe",
		"SapphirePickaxe", "EmeraldPickaxe", "RubyPickaxe", "DiamondPickaxe",
		"AngelicPickaxe", "DemonicPickaxe",
	},
	axe = {
		"WoodAxe", "StoneAxe", "CopperAxe", "IronAxe", "GoldAxe",
		"SapphireAxe", "EmeraldAxe", "RubyAxe", "DiamondAxe",
		"AngelicAxe", "DemonicAxe",
	},
	spear = {
		"WoodSpear", "StoneSpear", "CopperSpear", "IronSpear", "GoldSpear",
		"SapphireSpear", "EmeraldSpear", "RubySpear", "DiamondSpear",
		"AngelicSpear", "DemonicSpear",
	},
}

local ARMOR_SLOTS = { "Head", "Body", "Legs", "Feet" }

-- Armor item name suffix per slot. Used to derive which armor items belong to which slot.
local ARMOR_SLOT_SUFFIX = { Head = "Helmet", Body = "Chestplate", Legs = "Leggings", Feet = "Boots" }

-- RespawnService grants these starter Tools directly to Backpack (no inventory entry).
-- AutoEquip only destroys them when an inventory-backed replacement becomes available
-- for that category; otherwise they are left in place.
local STARTER_TOOL_FOR_CATEGORY = {
	sword = "WoodSwordTool",
	pickaxe = "WoodPickaxeTool",
	axe = "WoodAxeTool",
	-- spear: no starter
}

local DEBOUNCE_INTERVAL = 0.25 -- seconds

----------------------------------------------------------------
-- Per-player state
----------------------------------------------------------------

local affinityState = {}   -- [player] = "Angelic" or "Demonic"
local hotbarPrefs = {}     -- [player] = { sword=1, pickaxe=2, axe=3, spear=4 }
local manualLocks = {}     -- [player] = { [categoryOrSlot] = true }
local managedTools = {}    -- [player] = { [category] = "XxxTool" } (what this service cloned)
local dirtyPlayers = {}    -- set of players waiting for rebuild on next tick

local affinityUpdateCallbacks = {}

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------

local function getAffinity(player)
	return affinityState[player] or "Angelic"
end

local function getHotbarPrefs(player)
	if not hotbarPrefs[player] then
		hotbarPrefs[player] = table.clone(DEFAULT_HOTBAR_PREFS)
	end
	return hotbarPrefs[player]
end

local function getManualLocks(player)
	if not manualLocks[player] then
		manualLocks[player] = {}
	end
	return manualLocks[player]
end

local function fireAffinityUpdate(player)
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return end
	local evt = remotes:FindFirstChild("AffinityStateUpdate")
	if evt and evt:IsA("RemoteEvent") then
		evt:FireClient(player, getAffinity(player))
	end
end

----------------------------------------------------------------
-- Best-item selection
----------------------------------------------------------------

local function findBestForCategory(player, category)
	local inv = InventoryService.GetInventory(player)
	local items = CATEGORY_ITEMS[category]
	if not items then return nil end

	local angelic, demonic
	local bestRegular, bestRegularTier = nil, -1
	for _, item in ipairs(items) do
		if (inv[item] or 0) > 0 then
			if item:find("Angelic") then
				angelic = item
			elseif item:find("Demonic") then
				demonic = item
			else
				local t = CraftingTiers.GetTier(item) or 0
				if t > bestRegularTier then
					bestRegular, bestRegularTier = item, t
				end
			end
		end
	end

	if angelic and demonic then
		return (getAffinity(player) == "Angelic") and angelic or demonic
	elseif angelic then
		return angelic
	elseif demonic then
		return demonic
	else
		return bestRegular
	end
end

local function findBestArmorForSlot(player, slot)
	local inv = InventoryService.GetInventory(player)
	local suffix = ARMOR_SLOT_SUFFIX[slot]
	if not suffix then return nil end

	local angelic, demonic
	local bestRegular, bestRegularTier = nil, -1
	for itemName in pairs(ArmorStats) do
		if itemName:sub(-#suffix) == suffix and (inv[itemName] or 0) > 0 then
			if itemName:find("Angelic") then
				angelic = itemName
			elseif itemName:find("Demonic") then
				demonic = itemName
			else
				local t = CraftingTiers.GetTier(itemName) or 0
				if t > bestRegularTier then
					bestRegular, bestRegularTier = itemName, t
				end
			end
		end
	end

	if angelic and demonic then
		return (getAffinity(player) == "Angelic") and angelic or demonic
	elseif angelic then
		return angelic
	elseif demonic then
		return demonic
	else
		return bestRegular
	end
end

----------------------------------------------------------------
-- Rebuild equipment for a player
----------------------------------------------------------------

local function destroyToolInContainers(toolName, containers)
	for _, container in ipairs(containers) do
		if container then
			local existing = container:FindFirstChild(toolName)
			while existing do
				if existing:IsA("Tool") then
					existing:Destroy()
				end
				existing = container:FindFirstChild(toolName)
				if existing and not existing:IsA("Tool") then break end
			end
		end
	end
end

local function rebuildEquipment(player)
	if not player or not player.Parent then return end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end
	local character = player.Character
	local containers = { backpack, character }

	local locks = getManualLocks(player)
	local prefs = getHotbarPrefs(player)
	managedTools[player] = managedTools[player] or {}

	-- 1. Compute desired item per unlocked category.
	local desired = {}
	for _, cat in ipairs(AUTO_CATEGORIES) do
		if not locks[cat] then
			desired[cat] = findBestForCategory(player, cat)
		end
	end

	-- 2. Destroy previously-managed tools (they'll be recloned if still desired, in new slot order).
	--    Locked categories: keep the managedTools entry so we don't destroy it; if the player later
	--    clears the lock, the next rebuild will destroy whatever the auto system had last.
	for cat, prevToolName in pairs(managedTools[player]) do
		if not locks[cat] then
			destroyToolInContainers(prevToolName, containers)
			managedTools[player][cat] = nil
		end
	end

	-- 3. Destroy starter tools for unlocked categories that have an inventory-backed replacement.
	for cat, itemName in pairs(desired) do
		if itemName then
			local starter = STARTER_TOOL_FOR_CATEGORY[cat]
			if starter then
				destroyToolInContainers(starter, containers)
			end
		end
	end

	-- 4. Clone desired tools in slot preference order (ascending).
	local ordered = {}
	for cat, itemName in pairs(desired) do
		if itemName then
			table.insert(ordered, { cat = cat, item = itemName, slot = prefs[cat] or 99 })
		end
	end
	table.sort(ordered, function(a, b) return a.slot < b.slot end)

	for _, entry in ipairs(ordered) do
		local toolName = entry.item .. "Tool"
		local template = ServerStorage:FindFirstChild(toolName)
		if template and template:IsA("Tool") then
			local clone = template:Clone()
			clone.Parent = backpack
			managedTools[player][entry.cat] = toolName
		end
	end

	-- 5. Armor per slot (unlocked slots only).
	for _, slot in ipairs(ARMOR_SLOTS) do
		if not locks[slot] then
			local piece = findBestArmorForSlot(player, slot)
			if piece then
				ArmorService.Equip(player, slot, piece)
			else
				ArmorService.Unequip(player, slot)
			end
		end
	end
end

----------------------------------------------------------------
-- Public API
----------------------------------------------------------------

function AutoEquipService.MarkDirty(player)
	if player and player:IsA("Player") then
		dirtyPlayers[player] = true
	end
end

function AutoEquipService.MarkManual(player, categoryOrSlot)
	if not player or not player:IsA("Player") or type(categoryOrSlot) ~= "string" then return end
	local locks = getManualLocks(player)
	locks[categoryOrSlot] = true
end

function AutoEquipService.ClearManual(player, categoryOrSlot)
	if not player or not player:IsA("Player") or type(categoryOrSlot) ~= "string" then return end
	local locks = getManualLocks(player)
	locks[categoryOrSlot] = nil
	dirtyPlayers[player] = true
end

function AutoEquipService.ClearAllManual(player)
	if not player or not player:IsA("Player") then return end
	manualLocks[player] = {}
	dirtyPlayers[player] = true
end

function AutoEquipService.GetAffinity(player)
	return getAffinity(player)
end

function AutoEquipService.GetHotbarPrefs(player)
	return table.clone(getHotbarPrefs(player))
end

function AutoEquipService.GetManualLocks(player)
	return table.clone(getManualLocks(player))
end

function AutoEquipService.GetManagedTool(player, category)
	local m = managedTools[player]
	return m and m[category] or nil
end

function AutoEquipService.OnAffinityChanged(callback)
	table.insert(affinityUpdateCallbacks, callback)
end

----------------------------------------------------------------
-- Remote handlers
----------------------------------------------------------------

local function setupRemotes()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		warn("[AutoEquipService] Remotes folder not found.")
		return
	end

	local RequestToggleAffinity = remotes:FindFirstChild("RequestToggleAffinity")
	if RequestToggleAffinity and RequestToggleAffinity:IsA("RemoteEvent") then
		RequestToggleAffinity.OnServerEvent:Connect(function(player)
			affinityState[player] = (getAffinity(player) == "Angelic") and "Demonic" or "Angelic"
			dirtyPlayers[player] = true
			fireAffinityUpdate(player)
			for _, cb in ipairs(affinityUpdateCallbacks) do
				task.spawn(cb, player, affinityState[player])
			end
		end)
	else
		warn("[AutoEquipService] RequestToggleAffinity remote missing.")
	end

	local RequestSetHotbarPref = remotes:FindFirstChild("RequestSetHotbarPref")
	if RequestSetHotbarPref and RequestSetHotbarPref:IsA("RemoteEvent") then
		RequestSetHotbarPref.OnServerEvent:Connect(function(player, category, slot)
			if type(category) ~= "string" or type(slot) ~= "number" then return end
			if slot < 1 or slot > 4 then return end
			local prefs = getHotbarPrefs(player)
			if prefs[category] == nil then return end -- unknown category
			local prev = prefs[category]
			-- Auto-swap: if another category already owns this slot, move it to category's previous slot.
			for otherCat, otherSlot in pairs(prefs) do
				if otherCat ~= category and otherSlot == slot then
					prefs[otherCat] = prev
					break
				end
			end
			prefs[category] = slot
			dirtyPlayers[player] = true
		end)
	else
		warn("[AutoEquipService] RequestSetHotbarPref remote missing.")
	end

	local RequestClearManualLock = remotes:FindFirstChild("RequestClearManualLock")
	if RequestClearManualLock and RequestClearManualLock:IsA("RemoteEvent") then
		RequestClearManualLock.OnServerEvent:Connect(function(player, categoryOrSlot)
			if type(categoryOrSlot) ~= "string" then return end
			AutoEquipService.ClearManual(player, categoryOrSlot)
		end)
	else
		warn("[AutoEquipService] RequestClearManualLock remote missing.")
	end

	-- Hook existing RequestEquip / RequestEquipArmor remotes for lock-on-manual-equip semantics.
	-- Note: EquipService/ArmorService also connect; our handler runs alongside theirs and just
	-- sets the lock. Ordering of the two handlers doesn't matter for correctness.
	local RequestEquip = remotes:FindFirstChild("RequestEquip")
	if RequestEquip and RequestEquip:IsA("RemoteEvent") then
		RequestEquip.OnServerEvent:Connect(function(player, itemName)
			if type(itemName) ~= "string" then return end
			local cat = CraftingTiers.GetCategory(itemName)
			if cat and (cat == "sword" or cat == "pickaxe" or cat == "axe" or cat == "spear") then
				-- Only lock if the player actually owns the item (i.e. the request will succeed).
				if InventoryService.HasItem(player, itemName, 1) then
					AutoEquipService.MarkManual(player, cat)
				end
			end
		end)
	end

	local RequestEquipArmor = remotes:FindFirstChild("RequestEquipArmor")
	if RequestEquipArmor and RequestEquipArmor:IsA("RemoteEvent") then
		RequestEquipArmor.OnServerEvent:Connect(function(player, slot, itemName)
			if type(slot) ~= "string" or type(itemName) ~= "string" then return end
			local validSlots = { Head = true, Body = true, Legs = true, Feet = true }
			if not validSlots[slot] then return end
			if InventoryService.HasItem(player, itemName, 1) then
				AutoEquipService.MarkManual(player, slot)
			end
		end)
	end
end

----------------------------------------------------------------
-- Init
----------------------------------------------------------------

local function init()
	CraftingTiers = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CraftingTiers"))
	ArmorStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ArmorStats"))
	InventoryService = require(script.Parent:FindFirstChild("InventoryService"))
	ArmorService = require(script.Parent:FindFirstChild("ArmorService"))
	RoundService = require(script.Parent:FindFirstChild("RoundService"))
end

init()

-- Mirror Tool templates from ServerStorage to ReplicatedStorage.ToolModels so that
-- the client BackpackGui can clone them into ViewportFrames for icons. Clones in
-- ReplicatedStorage are inert (LocalScripts do not run, no equip context).
local function ensureToolModelsMirror()
	local existing = ReplicatedStorage:FindFirstChild("ToolModels")
	if not existing then
		existing = Instance.new("Folder")
		existing.Name = "ToolModels"
		existing.Parent = ReplicatedStorage
	end
	local mirrored, skipped = 0, 0
	for _, child in ipairs(ServerStorage:GetChildren()) do
		if child:IsA("Tool") then
			if not existing:FindFirstChild(child.Name) then
				local ok, clone = pcall(function() return child:Clone() end)
				if ok and clone then
					-- Strip server scripts to keep the icon clone purely visual.
					for _, d in ipairs(clone:GetDescendants()) do
						if d:IsA("Script") or d:IsA("LocalScript") then
							d:Destroy()
						end
					end
					clone.Parent = existing
					mirrored = mirrored + 1
				else
					skipped = skipped + 1
				end
			end
		end
	end
	return mirrored, skipped
end

ensureToolModelsMirror()

-- Inventory change → dirty flag.
InventoryService.OnItemAdded(function(player)
	dirtyPlayers[player] = true
end)
InventoryService.OnItemRemoved(function(player)
	dirtyPlayers[player] = true
end)

-- Round-end reset: clear all manual locks and reset affinity to Angelic.
if RoundService.OnStateChanged then
	RoundService.OnStateChanged(function(_, newState)
		if newState == "EndRound" or newState == "Lobby" then
			for player, _ in pairs(manualLocks) do
				manualLocks[player] = {}
			end
			for player, _ in pairs(affinityState) do
				affinityState[player] = "Angelic"
				fireAffinityUpdate(player)
			end
			-- Players respawn at lobby; new character triggers rebuild via CharacterAdded hook.
		end
	end)
end

-- Per-player lifecycle.
local function onPlayerAdded(player)
	affinityState[player] = "Angelic"
	hotbarPrefs[player] = table.clone(DEFAULT_HOTBAR_PREFS)
	manualLocks[player] = {}
	managedTools[player] = {}

	player.CharacterAdded:Connect(function()
		-- Fresh character = fresh managed tools (backpack was reset by Roblox).
		managedTools[player] = {}
		-- R_* mid-round respawn: round time > 2s clears locks.
		if RoundService.IsRespawnMode and RoundService.IsRespawnMode() then
			local st = RoundService.GetState and RoundService.GetState() or ""
			local roundTime = RoundService.GetCurrentRoundTime and RoundService.GetCurrentRoundTime() or 0
			if (st == "ActiveRound" or st == "SuddenDeath") and roundTime > 2 then
				manualLocks[player] = {}
			end
		end
		-- Defer one frame so RespawnService's starter-tool grants land first.
		task.delay(0.1, function()
			if player and player.Parent then
				dirtyPlayers[player] = true
			end
		end)
	end)

	-- Send initial affinity to client.
	task.delay(0.5, function()
		if player and player.Parent then
			fireAffinityUpdate(player)
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	affinityState[player] = nil
	hotbarPrefs[player] = nil
	manualLocks[player] = nil
	managedTools[player] = nil
	dirtyPlayers[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

setupRemotes()

-- Debounced rebuild loop.
local lastTick = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastTick < DEBOUNCE_INTERVAL then return end
	lastTick = now

	local players = {}
	for player, _ in pairs(dirtyPlayers) do
		table.insert(players, player)
	end
	for _, player in ipairs(players) do
		dirtyPlayers[player] = nil
		local ok, err = pcall(rebuildEquipment, player)
		if not ok then
			warn("[AutoEquipService] rebuildEquipment failed for " .. tostring(player) .. ": " .. tostring(err))
		end
	end
end)

return AutoEquipService
