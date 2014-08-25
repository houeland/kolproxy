add_automator("all pages", function()
	-- TODO: invalidate cache when using slimy shoulders item
	if have_skill("Slimy Shoulders") and not get_cached_modifier_bonuses("skill", "Slimy Shoulders") then
		local pt = get_page("/desc_skill.php", { whichskill = datafile("skills")["Slimy Shoulders"].skillid, self = "true" })
		local bonuses = parse_modifier_bonuses_page(pt)
		set_cached_modifier_bonuses("skill", "Slimy Shoulders", bonuses)
	end
end)

function estimate_passive_bonuses(passivename)
	local passivearray = {
		["Expert Panhandling"] = { ["Meat from Monsters"] = 10 }, -- TODO: 15 when wearing a saucepan
		["Slimy Shoulders"] = get_cached_modifier_bonuses("skill", "Slimy Shoulders") or {},
		["Skin of the Leatherback"] = { ["Damage Reduction"] = math.ceil(level() / 2) },
	}

	if equipment().weapon or equipment().offhand then
		passivearray["Master of the Surprising Fist"] = {}
	end

	if passivearray[passivename] then
		return make_bonuses_table(passivearray[passivename])
	elseif datafile("passives")[passivename] then
		return make_bonuses_table(datafile("passives")[passivename].bonuses or {})
	else
		-- unknown
		return make_bonuses_table {}
	end
end

function estimate_current_passive_bonuses()
	local bonuses = {}
	for skill, _ in pairs(get_player_skills() or {}) do
		add_modifier_bonuses(bonuses, estimate_passive_bonuses(skill))
		local bb = estimate_passive_bonuses(skill)
	end
	return bonuses
end
