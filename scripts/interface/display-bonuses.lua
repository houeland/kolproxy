register_setting {
	name = "show modifier estimates",
	description = "Show modifier estimates (+noncombat%, +item%, +ML. <b>Not always accurate</b>)",
	group = "charpane",
	default_level = "standard",
}

function estimate_companion_bonuses(jarlcompanion)
	local working_lunch = have_skill("Working Lunch") and 1 or 0
	if jarlcompanion == 1 then
		return make_bonuses_table { ["Item Drops from Monsters"] = 50 + 25 * working_lunch }
	elseif jarlcompanion == 2 then
		return make_bonuses_table { ["Combat Initiative"] = 50 + 25 * working_lunch }
	elseif jarlcompanion == 3 then
		return make_bonuses_table {}
	elseif jarlcompanion == 4 then
		return make_bonuses_table { ["Monster Level"] = 20 + 10 * working_lunch }
	else
		return make_bonuses_table {}
	end
end

function estimate_current_companion_bonuses()
	local jarlcompanion = tonumber(status().jarlcompanion)
	if not jarlcompanion then return {} end
	return estimate_companion_bonuses(jarlcompanion)
end

function estimate_current_other_bonuses()
	local bonuses = make_bonuses_table {
		["Monsters will be more attracted to you"] = estimate_other_combat(),
		["Item Drops from Monsters"] = estimate_other_item(),
		["Monster Level"] = estimate_other_ml(),
		["Combat Initiative"] = estimate_other_init(),
		["Meat from Monsters"] = estimate_other_meat(),
	}
	return bonuses
end

function estimate_bonus(name)
	return estimate_modifier_bonuses()[name]
end

function estimate_modifier_bonuses()
	local bonuses = make_bonuses_table {}
	bonuses = bonuses + estimate_current_equipment_bonuses()
	bonuses = bonuses + estimate_current_outfit_bonuses()
	bonuses = bonuses + estimate_current_buff_bonuses()
	bonuses = bonuses + estimate_current_companion_bonuses()
	bonuses = bonuses + estimate_current_other_bonuses()

	bonuses["Monsters will be more attracted to you"] = adjust_combat(bonuses["Monsters will be more attracted to you"])

	-- TODO: Separate between combat and underwater combat?
	bonuses = bonuses + make_bonuses_table { ["Monsters will be more attracted to you"] = estimate_underwater_combat() }

	return bonuses
end

add_printer("/charpane.php", function()
	if not setting_enabled("show modifier estimates") then return end

	local bonuses = estimate_modifier_bonuses()
	local ml_init_penalty = compute_monster_initiative_bonus(bonuses["Monster Level"])

	local com = bonuses["Monsters will be more attracted to you"]
	local item = bonuses["Item Drops from Monsters"]
	local ml = bonuses["Monster Level"]
	local initial_init = bonuses["Combat Initiative"]
	local adjusted_init = initial_init - ml_init_penalty
	local meat = bonuses["Meat from Monsters"]

	local foodbonusstr = ""
	if bonuses["Food Drops from Monsters"] ~= 0 then
		foodbonusstr = string.format(" (%+d%% food)", bonuses["Food Drops from Monsters"])
	end

	local initbonusstr = ""
	if ml_init_penalty ~= 0 then
		initbonusstr = string.format(" (from %+d%%)", initial_init)
	end

	local uncertaintystr = have_cached_data() and "" or "?"
	print_charpane_value { normalname = "(Non)combat", compactname = "C/NC", value = string.format("%+d%%", com) .. uncertaintystr }
	print_charpane_value { normalname = "Item drops", compactname = "Item", value = string.format("%+.1f%%", floor_to_places(item, 1)) .. uncertaintystr .. foodbonusstr, link = modifier_maximizer_href { pwd = session.pwd, whichbonus = "Item Drops from Monsters" }, link_name_only = true }
	print_charpane_value { normalname = "ML", compactname = "ML", value = string.format("%+d", ml) .. uncertaintystr, link = modifier_maximizer_href { pwd = session.pwd, whichbonus = "Monster Level" }, link_name_only = true }
	print_charpane_value { normalname = "Initiative", compactname = "Init", value = string.format("%+d%%", adjusted_init) .. uncertaintystr .. initbonusstr, tooltip = string.format("%+d%% initiative - %d%% ML penalty = %+d%% combined", initial_init, ml_init_penalty, adjusted_init), link = modifier_maximizer_href { pwd = session.pwd, whichbonus = "Combat Initiative" }, link_name_only = true }
	print_charpane_value { normalname = "Meat drops", compactname = "Meat", value = string.format("%+.1f%%", floor_to_places(meat, 1)) .. uncertaintystr, link = modifier_maximizer_href { pwd = session.pwd, whichbonus = "Meat from Monsters" }, link_name_only = true }
end)

function estimate_maxhp_increases(bonuses)
	bonuses = make_bonuses_table(bonuses)
	local abshp = bonuses["Maximum HP"]
	local multiplier = 1
	-- TODO: multiplier increases
	local muscle = bonuses["Muscle"] + bonuses["Muscle %"]/100 * basemuscle()
	return abshp + multiplier * muscle
end

function check_valid_modifier_name(name)
	-- TODO: verify names
	return true
end

local bonus_meta_table = {
	__add = function(a, b)
		local tbl = make_bonuses_table {}
		add_modifier_bonuses(tbl, a)
		add_modifier_bonuses(tbl, b)
		return tbl
	end,
	__index = function(tbl, key)
		check_valid_modifier_name(key)
		return 0
	end,
	__newindex = function(tbl, key, value)
		check_valid_modifier_name(key)
		rawset(tbl, key, value)
	end
}

function make_bonuses_table(tbl)
	local bonuses = {}
	setmetatable(bonuses, bonus_meta_table)
	if tbl then
		add_modifier_bonuses(bonuses, tbl)
	end
	return bonuses
end
