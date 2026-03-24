--[[
	MobsService
	Manages mobs in workspace.Mobs.
	On load: configures pre-placed mobs (MaxHealth, Died handler).
	On death: grants drops to killer via DropsService, cleans up.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local DamageTracker
local DropsService
local MobDefs

local function init()
	DamageTracker = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DamageTracker"))
	DropsService = require(script.Parent:FindFirstChild("DropsService"))
	MobDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MobDefs"))
end

init()

local function setupMob(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local mobType = model.Name
	local def = MobDefs[mobType]
	if not def then
		return
	end
	humanoid.MaxHealth = def.health
	humanoid.Health = def.health
	CollectionService:AddTag(humanoid, "Mob")

	humanoid.Died:Connect(function()
		local killer = DamageTracker.GetKiller(humanoid)
		local dropsKey = def.dropsKey or mobType
		DropsService.GrantDrops(killer, dropsKey)
		DamageTracker.Clear(humanoid)
	end)
end

local function setupMobsFolder()
	local mobsFolder = Workspace:FindFirstChild("Mobs")
	if not mobsFolder then
		return
	end
	for _, child in ipairs(mobsFolder:GetChildren()) do
		if child:IsA("Model") then
			setupMob(child)
		end
	end
	mobsFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.defer(function()
				setupMob(child)
			end)
		end
	end)
end

setupMobsFolder()

return {}
