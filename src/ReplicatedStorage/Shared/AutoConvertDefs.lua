--[[
	AutoConvertDefs.lua
	Recipes for automatic conversion. No client remotes.
	One timer per player per recipe. Start when inputs present. Cancel if inputs drop.
]]

return {
	{
		inputs = { RawMeat = 1 },
		output = { CookedMeat = 1 },
		duration = 20,
	},
	{
		inputs = { Apple = 2 },
		output = { AppleJuice = 1 },
		duration = 20,
	},
	{
		inputs = { Orange = 2 },
		output = { OrangeJuice = 1 },
		duration = 20,
	},
}
