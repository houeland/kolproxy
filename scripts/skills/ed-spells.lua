local function capped_damage(dmg, cap)
	if cap and dmg > cap then
		return cap
	else
		return dmg
	end
end

local function add_combat_skill(tbl)
	add_spell_estimator(tbl.name, function()
		local dmg = tbl.damage()
		if dmg.element == "Prismatic" then
		else
			return { mpcost = tbl.mpcost, damage = { { probability = 1, sources = { hotdmg, colddmg } } } }
		end
	end)
end

local function ed_damage(mysmultmin, mysmultmax, cap, element)
	return function()
		local bonus = estimate_bonus("Spell Damage") + estimate_bonus("Damage to " .. element .. " Spells")
		local mindmg = capped_damage(math.floor(mysmultmin * buffedmysticality()) + bonus, cap)
		local maxdmg = capped_damage(math.floor(mysmultmax * buffedmysticality()) + bonus, cap)
		local median = capped_damage(math.floor((mysmultmin + mysmultmax) / 2 * buffedmysticality()) + bonus, cap)
		return { min = mindmg, max = maxdmg, element = element, median_estimate = median }
	end
end

--Mild Curse: 2-3 + 0.0x buffedmyst + spelldmg*0
--Fist of the Mummy: 0.75x-1.0x buffedmyst + spelldmg*1, cap 50
--Howl of the Jackal: 1.0x-1.25x buffedmyst + spelldmg*1, cap 100
--Roar of the Lion: 1.5x-2.0x buffedmyst + spelldmg*1, no cap
--Storm of the Scarab: around 0.075x-0.125x buffmyst + 1*spelldmg for each element, no cap

add_combat_skill {
	name = "Mild Curse",
	mpcost = 0,
	damage = { min = 2, max = 3, element = "Spooky" },
}

add_combat_skill {
	name = "Fist of the Mummy",
	mpcost = 5,
	damage = ed_damage(0.75, 1.0, 50, "Special"),
}

add_combat_skill {
	name = "Howl of the Jackal",
	mpcost = 10,
	damage = ed_damage(1.0, 1.25, 100, "Spooky"),
}

add_combat_skill {
	name = "Roar of the Lion",
	mpcost = 15,
	damage = ed_damage(1.5, 2.0, nil, "Hot"),
}

add_combat_skill {
	name = "Storm of the Scarab",
	mpcost = 8,
	damage = ed_damage(0.075, 0.125, nil, "Prismatic"),
}
