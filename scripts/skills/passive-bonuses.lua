add_automator("all pages", function()
	-- TODO: invalidate cache when using slimy skill-granting item
	for _, skillname in ipairs { "Slimy Sinews", "Slimy Synapses", "Slimy Shoulders" } do
		if have_skill(skillname) and not get_cached_modifier_bonuses("skill", skillname) then
			local pt = get_page("/desc_skill.php", { whichskill = get_skillid(skillname), self = "true" })
			set_cached_modifier_bonuses("skill", skillname, parse_modifier_bonuses_page(pt))
		end
	end
end)

function estimate_passive_bonuses(passivename)
	local passivearray = {
		["Expert Panhandling"] = { ["Meat from Monsters"] = 10 }, -- TODO: 15 when wearing a saucepan
		["Slimy Sinews"] = "cached",
		["Slimy Synapses"] = "cached",
		["Slimy Shoulders"] = "cached",
		["Skin of the Leatherback"] = { ["Damage Reduction"] = math.ceil(level() / 2) },
	}

	if passivearray[passivename] == "cached" then
		return make_bonuses_table(get_cached_modifier_bonuses("skill", passivename) or {})
	elseif passivearray[passivename] then
		return make_bonuses_table(passivearray[passivename])
	elseif datafile("passives")[passivename] then
		return make_bonuses_table(datafile("passives")[passivename].bonuses or {})
	else
		-- unknown
		return make_bonuses_table {}
	end
end

function estimate_current_passive_bonuses()
	local bonuses = make_bonuses_table {}
	for skill, _ in pairs(get_player_skills() or {}) do
		bonuses.add(estimate_passive_bonuses(skill))
	end
	return bonuses
end
