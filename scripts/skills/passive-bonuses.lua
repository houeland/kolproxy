function estimate_passive_bonuses(passivename)
	local passivearray = {
		["Expert Panhandling"] = { ["Meat from Monsters"] = 10 }, -- TODO: 15 when wearing a saucepan
		["Slimy Shoulders"] = { ["Combat Initiative"] = 20 }, -- TODO: Depends on number of sweat glands used
	}

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
	end
	return bonuses
end
