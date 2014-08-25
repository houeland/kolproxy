add_spell_estimator("Stream of Sauce", function()
	local hotdmg = calculate_spell_skill_damage(9, 11, 0.2, 24, "Hot")
	return { mpcost = 2, damage = { { probability = 1, sources = { hotdmg } } } }
end)

add_spell_estimator("Saucestorm", function()
	local hotdmg = calculate_spell_skill_damage(20, 24, 0.2, 50, "Hot")
	local colddmg = calculate_spell_skill_damage(20, 24, 0.2, 50, "Cold")
	return { mpcost = 6, damage = { { probability = 1, sources = { hotdmg, colddmg } } } }
end)

add_spell_estimator("Saucegeyser", function()
	local hotdmg = calculate_spell_skill_damage(60, 70, 0.4, nil, "Hot")
	local colddmg = calculate_spell_skill_damage(60, 70, 0.4, nil, "Cold")
	return { mpcost = 24, damage = {
		{ probability = 0.5, sources = { hotdmg } },
		{ probability = 0.5, sources = { colddmg } },
	} }
end)
