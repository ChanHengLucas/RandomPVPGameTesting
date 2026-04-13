--[[
	MapLoadService
	Loads map from ServerStorage.Maps into Workspace.ActiveMap.
	Returns Center, SpawnPoints, PotionSpawnPoints, StormMaxRadius.
	Unloads previous map at EndRound.
]]

local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local MapLoadService = {}

local activeMap = nil
local centerPart = nil
local spawnPointsFFA = nil
local spawnPointsTeam1 = nil
local spawnPointsTeam2 = nil
local potionSpawnPoints = nil
local stormMaxRadius = nil

local function resolveStormMaxRadius(mapModel)
	if not mapModel then return nil end
	local attr = mapModel:GetAttribute("StormMaxRadius")
	if type(attr) == "number" and attr > 0 then
		return attr
	end
	local stormPart = mapModel:FindFirstChild("StormRadius")
	if stormPart and stormPart:IsA("BasePart") then
		local r = stormPart:GetAttribute("Radius")
		if type(r) == "number" and r > 0 then return r end
		return stormPart.Size.X / 2
	end
	return nil
end

function MapLoadService.LoadMap(mapId)
	MapLoadService.UnloadMap()

	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("[MapLoadService] ServerStorage.Maps not found")
		return nil, nil, nil, nil, nil
	end

	local template = mapsFolder:FindFirstChild(mapId)
	if not template or not template:IsA("Model") then
		warn("[MapLoadService] Map not found: " .. tostring(mapId))
		return nil, nil, nil, nil, nil
	end

	activeMap = template:Clone()
	activeMap.Name = "ActiveMap"
	activeMap.Parent = Workspace

	centerPart = activeMap:FindFirstChild("Center")
	if centerPart and not centerPart:IsA("BasePart") then
		centerPart = nil
	end
	if not centerPart then
		warn("[MapLoadService] Map '" .. mapId .. "' missing Center part")
	end

	local spawnPoints = activeMap:FindFirstChild("SpawnPoints")
	if spawnPoints then
		spawnPointsFFA = spawnPoints:FindFirstChild("FFA")
		spawnPointsTeam1 = spawnPoints:FindFirstChild("Team1")
		spawnPointsTeam2 = spawnPoints:FindFirstChild("Team2")
		if not spawnPointsFFA then warn("[MapLoadService] Map '" .. mapId .. "' missing SpawnPoints.FFA") end
		if not spawnPointsTeam1 then warn("[MapLoadService] Map '" .. mapId .. "' missing SpawnPoints.Team1") end
		if not spawnPointsTeam2 then warn("[MapLoadService] Map '" .. mapId .. "' missing SpawnPoints.Team2") end
	else
		warn("[MapLoadService] Map '" .. mapId .. "' missing SpawnPoints folder")
	end

	potionSpawnPoints = activeMap:FindFirstChild("PotionSpawnPoints")
	if not potionSpawnPoints then
		warn("[MapLoadService] Map '" .. mapId .. "' missing PotionSpawnPoints")
	end
	stormMaxRadius = resolveStormMaxRadius(activeMap)

	return activeMap, centerPart, spawnPointsFFA, spawnPointsTeam1, spawnPointsTeam2, potionSpawnPoints, stormMaxRadius
end

function MapLoadService.UnloadMap()
	if activeMap and activeMap.Parent then
		activeMap:Destroy()
	end
	activeMap = nil
	centerPart = nil
	spawnPointsFFA = nil
	spawnPointsTeam1 = nil
	spawnPointsTeam2 = nil
	potionSpawnPoints = nil
	stormMaxRadius = nil
end

function MapLoadService.GetActiveMap()
	return activeMap
end

function MapLoadService.GetCenter()
	return centerPart
end

function MapLoadService.GetSpawnPointsFFA()
	return spawnPointsFFA
end

function MapLoadService.GetSpawnPointsTeam1()
	return spawnPointsTeam1
end

function MapLoadService.GetSpawnPointsTeam2()
	return spawnPointsTeam2
end

function MapLoadService.GetPotionSpawnPoints()
	return potionSpawnPoints
end

function MapLoadService.GetStormMaxRadius()
	return stormMaxRadius
end

return MapLoadService
