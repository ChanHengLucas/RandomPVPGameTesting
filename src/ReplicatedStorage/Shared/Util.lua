--[[
	Util.lua
	Shared utilities for FastCraft PvP.
]]

local Util = {}

Util.DEBUG = false

function Util.log(...)
	if Util.DEBUG then
		print("[FastCraft]", ...)
	end
end

function Util.distance3D(a, b)
	return (a - b).Magnitude
end

function Util.assertInstance(obj, className)
	if not obj or not obj:IsA(className) then
		return false
	end
	return true
end

return Util
