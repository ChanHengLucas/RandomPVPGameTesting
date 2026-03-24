--[[
	ConsumableDefs.lua
	Single source of truth for consumable item effects.
	Use time 0.5s; consume cooldown 0.6s. Speed does not stack.
]]

return {
	RawMeat = { hp = 10 },
	CookedMeat = { hp = 20, speedPercent = 10, speedDuration = 15 },
	Apple = { hp = 10 },
	AppleJuice = { hp = 30 },
	Orange = { speedPercent = 10, speedDuration = 10 },
	OrangeJuice = { speedPercent = 20, speedDuration = 20 },
}
