--[[
	MobDefs.lua
	Single source of truth for mob definitions.
	Map mobType (model name) -> { health, damage?, dropsKey?, hostile?, affinity? }
	Mobs must be tagged "Mob" via CollectionService for PvE 2.5x multiplier.
	affinity: "angelic" | "demonic" for Angelic/Demonic combat
]]

return {
	Cow = { health = 20, damage = 0, dropsKey = "Cow", hostile = false },
	Pig = { health = 15, damage = 0, dropsKey = "Pig", hostile = false },
	Zombie = { health = 100, damage = 8, dropsKey = "Zombie", hostile = true },
	Spider = { health = 120, damage = 6, dropsKey = "Spider", hostile = true },
	Soldier = { health = 250, damage = 12, dropsKey = "Soldier", hostile = true },
	Angel = { health = 500, damage = 15, dropsKey = "Angel", hostile = true, affinity = "angelic" },
	Demon = { health = 500, damage = 15, dropsKey = "Demon", hostile = true, affinity = "demonic" },
}
