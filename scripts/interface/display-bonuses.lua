register_setting {
	name = "show modifier estimates",
	description = "Show modifier estimates (+item%, +ML, etc. <b>Not always accurate</b>)",
	group = "charpane",
	default_level = "standard",
	update_charpane = true,
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

function estimate_current_class_bonuses()
	local bonuses = make_bonuses_table {}
	if playerclass("Seal Clubber") or playerclass("Turtle Tamer") then
		bonuses.add { ["Maximum HP %"] = 50 }
	elseif playerclass("Pastamancer") or playerclass("Sauceror") then
		bonuses.add { ["Maximum MP %"] = 50 }
	end
	return bonuses
end

function estimate_modifier_bonuses_base()
	local bonuses = make_bonuses_table {}
	bonuses.add(estimate_current_equipment_bonuses())
	bonuses.add(estimate_current_outfit_bonuses())
	bonuses.add(estimate_current_buff_bonuses())
	bonuses.add(estimate_current_intrinsic_bonuses())
	bonuses.add(estimate_current_passive_bonuses())
	bonuses.add(estimate_current_familiar_bonuses())
	bonuses.add(estimate_current_companion_bonuses())
	bonuses.add(estimate_current_class_bonuses())
	bonuses.add(estimate_current_pastathrall_bonuses())
--	bonuses.add(estimate_current_moonsign_bonuses())
	bonuses.add(estimate_current_sneaky_pete_motorcycle_bonuses())
	bonuses.add(estimate_current_other_bonuses())
	return bonuses
end

--function estimate_modifier_bonuses_base()
--	return log_time_interval("estimate_modifier_bonuses_base()", function()
--	local bonuses = make_bonuses_table {}
--	bonuses.add(log_time_interval("equipment", estimate_current_equipment_bonuses))
--	bonuses.add(log_time_interval("outfit", estimate_current_outfit_bonuses))
--	bonuses.add(log_time_interval("buff", estimate_current_buff_bonuses))
--	bonuses.add(log_time_interval("intrinsic", estimate_current_intrinsic_bonuses))
--	bonuses.add(log_time_interval("passive", estimate_current_passive_bonuses))
--	bonuses.add(log_time_interval("familiar", estimate_current_familiar_bonuses))
--	bonuses.add(log_time_interval("companion", estimate_current_companion_bonuses))
--	bonuses.add(log_time_interval("class", estimate_current_class_bonuses))
--	bonuses.add(log_time_interval("pastathrall", estimate_current_pastathrall_bonuses))
--	bonuses.add(log_time_interval("sneaky_pete", estimate_current_sneaky_pete_motorcycle_bonuses))
--	bonuses.add(log_time_interval("other", estimate_current_other_bonuses))
--	return bonuses
--	end)
--end

local smithsness_synergy_bonus_itemid_cache = table.map_keys({
	["Meat Tenderizer is Murder"] = { "Muscle %", 2 },
	["Ouija Board, Ouija Board"] = { "Muscle %", 2 },
	["Hand that Rocks the Ladle"] = { "Mysticality %", 2 },
	["Saucepanic"] = { "Mysticality %", 2 },
	["Frankly Mr. Shank"] = { "Moxie %", 2 },
	["Shakespeare's Sister's Accordion"] = { "Moxie %", 2 },
	["Sheila Take a Crossbow"] = { "Combat Initiative", 1 },
	["Staff of the Headmaster's Victuals"] = nil,
	["Work is a Four Letter Sword"] = nil,
	["A Light that Never Goes Out"] = { "Item Drops from Monsters", 1 },
	["Half a Purse"] = { "Meat from Monsters", 2 },
	["Hairpiece On Fire"] = { "Maximum MP", 1 },
	["Vicar's Tutu"] = { "Maximum HP", 2 },
	["Hand in Glove"] = { "Monster Level", 1 },
}, get_itemid)

function estimate_item_synergy_bonuses(item, base_bonuses)
	local b = smithsness_synergy_bonus_itemid_cache[get_itemid(item)]
	if b then
		return { [b[1]] = base_bonuses["Smithsness"] * b[2] }
	end
end

function estimate_buff_synergy_bonuses(buff, base_bonuses)
	if buff == "Merry Smithsness" then
		return { ["Muscle %"] = base_bonuses["Smithsness"] * 1, ["Mysticality %"] = base_bonuses["Smithsness"] * 1, ["Moxie %"] = base_bonuses["Smithsness"] * 1 }
	end
end

function estimate_current_equipment_synergy(base_bonuses)
	local bonuses = make_bonuses_table {}
	for _, x in pairs(equipment()) do
		bonuses.add(estimate_item_synergy_bonuses(x, base_bonuses) or {})
	end
	return bonuses
end

function estimate_current_buff_synergy(base_bonuses)
	local bonuses = make_bonuses_table {}
	for _, x in ipairs { "Merry Smithsness" } do
		if have_buff(x) then
			bonuses.add(estimate_buff_synergy_bonuses(x, base_bonuses) or {})
		end
	end
	return bonuses
end

function estimate_current_synergy(base_bonuses)
	local bonuses = make_bonuses_table {}
	bonuses.add(estimate_current_equipment_synergy(base_bonuses))
	bonuses.add(estimate_current_buff_synergy(base_bonuses))
	return bonuses
end

function estimate_current_bonuses()
	return log_time_interval("estimate_current_bonuses()", function()
	local bonuses = estimate_modifier_bonuses_base()
	bonuses.add(estimate_current_synergy(bonuses))
	return bonuses
	end)
end

function estimate_bonus(name)
	return estimate_current_bonuses()[name]
end

add_charpane_line(function()
	if not setting_enabled("show modifier estimates") then return end

	local bonuses = estimate_current_bonuses()
	local ml_init_penalty = compute_monster_initiative_bonus(bonuses["Monster Level"])

	local com = bonuses["Monsters will be more attracted to you"]
	local item = bonuses["Item Drops from Monsters"]
	local ml = bonuses["Monster Level"]
	local initial_init = bonuses["Combat Initiative"]
	local adjusted_init = initial_init - ml_init_penalty
	local meat = bonuses["Meat from Monsters"]

	local plusmainstat = bonuses[get_mainstat_type() .. " Stats Per Fight"] + bonuses["Stats Per Fight"] / 2 + bonuses["Monster Level"] / 8

	local itemextras = {
		{ bonus = "Food Drops from Monsters", suffix = "food" },
		{ bonus = "Item Drops from Monsters (Dreadsylvania only)", suffix = "dread" },
		{ bonus = "Item Drops (Underwater only)", suffix = "underwater" },
		{ bonus = "Item Drops (KoL High School zones only)", suffix = "high school" },
	}

	local itemextrastrs = {}
	for _, x in ipairs(itemextras) do
		if bonuses[x.bonus] ~= 0 then
			table.insert(itemextrastrs, string.format(" (%+d%% %s)", bonuses[x.bonus], x.suffix))
		end
	end

	local initbonusstr = ""
	if ml_init_penalty ~= 0 then
		initbonusstr = string.format(" (from %+d%%)", initial_init)
	end

	-- TODO: redo without overwriting bonuses table
	bonuses["Monsters will be more attracted to you (base)"] = bonuses["Monsters will be more attracted to you"]
	bonuses["Monsters will be more attracted to you"] = adjust_combat(bonuses["Monsters will be more attracted to you"])

	-- TODO: Separate between combat and underwater combat?
	bonuses.add { ["Monsters will be more attracted to you"] = estimate_underwater_combat() }

	local ncbonusstr = ""
	if com ~= bonuses["Monsters will be more attracted to you (base)"] then
		ncbonusstr = string.format(" (from %+d%%)", bonuses["Monsters will be more attracted to you (base)"])
	end

	local function uncertaintystr(name)
		local uncertain = not have_cached_data() or bonuses[name .. "_unknown"] == true
		return uncertain and "?" or ""
	end

	local function mklink(whichbonus, text)
		return string.format([[<a target="mainpane" href="%s">%s</a>]], modifier_maximizer_href { pwd = session.pwd, whichbonus = whichbonus }, text)
	end

	return {
		{ normalname = "(" .. mklink("Monsters will be less attracted to you", "Non") .. ")" .. mklink("Monsters will be more attracted to you", "combat"), compactname = mklink("Monsters will be more attracted to you", "C") .. "/" .. mklink("Monsters will be less attracted to you", "NC"), value = string.format("%+d%%", com) .. uncertaintystr("Monsters will be more attracted to you") .. ncbonusstr, tooltip = "(Non)combat bonuses beyond &plusmn;25% are less effective" },
		{ normalname = "Item drops", compactname = "Item", value = string.format("%+.1f%%", floor_to_places(item, 1)) .. uncertaintystr("Item Drops from Monsters") .. table.concat(itemextrastrs), link = modifier_maximizer_href { pwd = session.pwd, whichbonus = "Item Drops from Monsters" }, link_name_only = true },
		{ normalname = "ML", compactname = "ML", value = string.format("%+d", ml) .. uncertaintystr("Monster Level"), link = modifier_maximizer_href { pwd = session.pwd, whichbonus = "Monster Level" }, link_name_only = true },
		{ normalname = "Initiative", compactname = "Init", value = string.format("%+d%%", adjusted_init) .. uncertaintystr("Combat Initiative") .. initbonusstr, tooltip = string.format("%+d%% initiative - %d%% ML penalty = %+d%% combined", initial_init, ml_init_penalty, adjusted_init), link = modifier_maximizer_href { pwd = session.pwd, whichbonus = "Combat Initiative" }, link_name_only = true },
		{ normalname = "Meat drops", compactname = "Meat", value = string.format("%+.1f%%", floor_to_places(meat, 1)) .. uncertaintystr("Meat from Monsters"), link = modifier_maximizer_href { pwd = session.pwd, whichbonus = "Meat from Monsters" }, link_name_only = true },
		{ normalname = "+" .. get_mainstat_type() .. "/fight", compactname = "+" .. get_mainstat_type(), value = floor_to_places(plusmainstat, 1) .. "?" },
	}
end)

function estimate_stat(statname, bonuses)
	bonuses = bonuses or estimate_current_bonuses()
	if statname == "Muscle" then
		return math.ceil(basemuscle() + bonuses["Muscle"] + bonuses["Muscle %"] / 100 * basemuscle())
	elseif statname == "Mysticality" then
		return math.ceil(basemysticality() + bonuses["Mysticality"] + bonuses["Mysticality %"] / 100 * basemysticality())
	elseif statname == "Moxie" then
		return math.ceil(basemoxie() + bonuses["Moxie"] + bonuses["Moxie %"] / 100 * basemoxie())
	end
end

function estimate_maxhp(bonuses)
	bonuses = bonuses or estimate_current_bonuses()
	local abshp = bonuses["Maximum HP"]
	local multiplier = 1 + bonuses["Maximum HP %"] / 100
	local muscle = estimate_stat("Muscle", bonuses)
	return math.ceil(abshp + multiplier * (muscle + 3))
end

function estimate_maxmp(bonuses)
	bonuses = bonuses or estimate_current_bonuses()
	local abshp = bonuses["Maximum MP"]
	local multiplier = 1 + bonuses["Maximum MP %"] / 100
	local mysticality = estimate_stat("Mysticality", bonuses)
	if have_equipped_item("Travoltan trousers") then
		mysticality = math.max(mysticality, estimate_stat("Moxie", bonuses))
	elseif have_equipped_item("moxie magnet") then
		mysticality = estimate_stat("Moxie", bonuses)
	end
	return math.ceil(abshp + multiplier * mysticality)
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
		if key == "add" then
			return function(extra)
				add_modifier_bonuses(tbl, extra)
			end
		end
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
