--- TODO ---
-- halos
-- buy items from NPCs
-- buy items in mall in aftercore

function maximize_equipment_slot_bonuses(slot, scoref_raw)
	function scoref(tbl)
		return scoref_raw(make_bonuses_table(tbl))
	end

	local options = {}

	local base_bonuses_without_slot = estimate_modifier_bonuses_base()
	local slot_eqitemid = equipment()[slot]
	if slot_eqitemid then
		subtract_modifier_bonuses(base_bonuses_without_slot, estimate_item_equip_bonuses_uncached(slot_eqitemid))
	end
	local bonuses_without_slot_with_synergy = make_bonuses_table(base_bonuses_without_slot)
	bonuses_without_slot_with_synergy.add(estimate_current_synergy(base_bonuses_without_slot))
	if slot_eqitemid then
		subtract_modifier_bonuses(bonuses_without_slot_with_synergy, estimate_item_synergy_bonuses(slot_eqitemid, bonuses_without_slot_with_synergy) or {})
	end
	local score_without_slot = scoref(bonuses_without_slot_with_synergy)
	local score_without_bonuses = scoref({})

	local function score_item(name)
		local item_bonuses = estimate_item_equip_bonuses_uncached(name)
		if item_bonuses["Smithsness"] == 0 then
			return scoref(item_bonuses) - score_without_bonuses
		end
		local base_bonuses = make_bonuses_table(base_bonuses_without_slot)
		base_bonuses.add(item_bonuses)
		local synergy_bonuses = estimate_current_synergy(base_bonuses)
		if slot_eqitemid then
			subtract_modifier_bonuses(synergy_bonuses, estimate_item_synergy_bonuses(slot_eqitemid, base_bonuses) or {})
		end
		synergy_bonuses.add(estimate_item_synergy_bonuses(name, base_bonuses) or {})
		base_bonuses.add(synergy_bonuses)
		return scoref(base_bonuses) - score_without_slot
	end

	local slot_type = slot
	if slot == "acc1" or slot == "acc2" or slot == "acc3" then
		slot_type = "accessory"
	end
	local previous_item_score = 0
	for wornslot, itemid in pairs(equipment()) do
		local name = maybe_get_itemname(itemid)
		local d = maybe_get_itemdata(itemid)
		if name and d and d.equipment_slot == slot_type and wornslot == slot then
			previous_item_score = score_item(name)
			table.insert(options, { name = name, score = score_item(name), worn = true, wornslot = wornslot, itemid = itemid, canwear = true })
		end
	end
	for itemid, _ in pairs(inventory()) do
		local name = maybe_get_itemname(itemid)
		local d = maybe_get_itemdata(itemid)
		if name and d and d.equipment_slot == slot_type then
			if d.equip_requirements and d.equip_requirements["You may not equip more than one of these at a time"] and have_equipped_item(name) then
			else
				table.insert(options, { name = name, score = score_item(name), worn = false, itemid = itemid, canwear = can_equip_item(name) })
			end
		end
	end
	table.insert(options, { name = "(none)", score = 0, worn = true, wornslot = "zzz1", canwear = true })
	table.insert(options, { name = "(none)", score = 0, worn = true, wornslot = "zzz2", canwear = true })
	table.insert(options, { name = "(none)", score = 0, worn = true, wornslot = "zzz3", canwear = true })
	table.sort(options, function(a, b)
		if a.canwear ~= b.canwear then
			return a.canwear
		elseif a.score ~= b.score then
			return a.score > b.score
		elseif a.worn ~= b.worn then
			return a.worn
		elseif a.wornslot ~= b.wornslot then
			return a.wornslot < b.wornslot
		else
			return a.name < b.name
		end
	end)
	return options, previous_item_score
end

function maximize_skill_bonuses(scoref)
	local base_bonuses = estimate_modifier_bonuses_base()
	local base_bonuses_with_synergy = make_bonuses_table(base_bonuses)
	base_bonuses_with_synergy.add(estimate_current_synergy(base_bonuses))
	local base_score = scoref(base_bonuses_with_synergy)

	local function score_buff(name)
		local bonuses = make_bonuses_table(base_bonuses)
		bonuses.add(estimate_buff_bonuses(name))
		local synergy_bonuses = estimate_current_synergy(bonuses)
		synergy_bonuses.add(estimate_buff_synergy_bonuses(name, bonuses) or {})
		bonuses.add(synergy_bonuses)
		return scoref(bonuses) - base_score
	end

	local options = {}

	for buffname, castname in pairs(datafile_buff_recast_skills) do
		local can_cast = have_skill(castname)
		if playerclass("Pastamancer") and castname:match("^Bind ") then
			-- TODO: Add line to switch pasta thrall
			can_cast = false
		elseif castname == "Turtle Power" or castname == "Spirit Boon" then
			can_cast = false
		elseif castname == "Blessing of the War Snapper" or castname == "Blessing of She-Who-Was" or castname == "Blessing of the Storm Tortoise" then
			if not playerclass("Turtle Tamer") and buffname:match("^Blessing ") then
				can_cast = false
			elseif playerclass("Turtle Tamer") and buffname:match("^Disdain ") then
				can_cast = false
			end
		elseif buffname == "Muffled" then
			can_cast = (sneaky_pete_motorcycle_upgrades()["Muffler"] == "Extra-Quiet Muffler")
		elseif buffname == "Unmuffled" then
			can_cast = (sneaky_pete_motorcycle_upgrades()["Muffler"] == "Extra-Loud Muffler")
		elseif castname == "Psychokinetic Hug" then
			can_cast = false
		end
		if can_cast then
			local score = score_buff(buffname)
			if score then
				table.insert(options, { name = castname, effect = buffname, score = score })
			end
		end
	end
	table.sort(options, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		elseif a.effect ~= b.effect then
			return a.effect < b.effect
		else
			return a.name < b.name
		end
	end)
	return options
end

function maximize_item_bonuses(scoref)
	local options = {}

	local base_bonuses = estimate_modifier_bonuses_base()
	local base_bonuses_with_synergy = make_bonuses_table(base_bonuses)
	base_bonuses_with_synergy.add(estimate_current_synergy(base_bonuses))
	local base_score = scoref(base_bonuses_with_synergy)

	local function score_buff(name)
		local bonuses = make_bonuses_table(base_bonuses)
		bonuses.add(estimate_buff_bonuses(name))
		local synergy_bonuses = estimate_current_synergy(bonuses)
		synergy_bonuses.add(estimate_buff_synergy_bonuses(name, bonuses) or {})
		bonuses.add(synergy_bonuses)
		return scoref(bonuses) - base_score
	end

	for id, _ in pairs(inventory()) do
		local d = maybe_get_itemdata(id)
		if d and d.use_effect then
			local score = score_buff(d.use_effect)
			if score then
				table.insert(options, { name = maybe_get_itemname(id), effect = d.use_effect, score = score })
			end
		end
	end
	table.sort(options, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		elseif a.effect ~= b.effect then
			return a.effect < b.effect
		else
			return a.name < b.name
		end
	end)
	return options
end

local registered_script_links = {}
function add_modifier_maximizer_script_link_function(f)
	table.insert(registered_script_links, f)
end

modifier_maximizer_href = add_automation_script("custom-modifier-maximizer", function()
	local resultpt = ""
	if params.equip_itemname and params.equip_slot then
		if params.equip_itemname == "(none)" then
			resultpt = unequip_slot(params.equip_slot)()
		else
			resultpt = equip_item(params.equip_itemname, params.equip_slot)()
		end
	elseif params.cast_skillname then
		resultpt = cast_skill(params.cast_skillname)()
	elseif params.use_itemname then
		resultpt = use_item(params.use_itemname)()
	end

	local bonuses = {
		"Monsters will be more attracted to you",
		"Monsters will be less attracted to you",
		"Item Drops from Monsters",
		"Monster Level",
		"Combat Initiative",
		"Meat from Monsters",
		"HP & cold/spooky resistance",
		"Familiar Weight",
		"Max HP",
		"Muscle",
		"Mysticality",
		"Moxie",
		"Adventures per day",
		"PvP fights per day",
		"All resistances",
		"Cold Resistance",
		"Hot Resistance",
		"Sleaze Resistance",
		"Spooky Resistance",
		"Stench Resistance",
		"Slime Resistance",
		"All weapon damage",
		"Cold Damage",
		"Hot Damage",
		"Sleaze Damage",
		"Spooky Damage",
		"Stench Damage",
	}

	local whichbonus = params.whichbonus
	if params.fuzzy then
		for _, x in ipairs(bonuses) do
			if x:lower():contains(params.fuzzy:lower()) then
				whichbonus = x
				break
			end
		end
	end
	whichbonus = whichbonus or "Item Drops from Monsters"

	local scoref = function(bonuses)
		return bonuses[whichbonus]
	end
	if whichbonus == "HP & cold/spooky resistance" then
		scoref = function(bonuses)
			return estimate_maxhp(bonuses) + bonuses["Spooky Resistance"] * 20 + bonuses["Cold Resistance"] * 20
		end
	elseif whichbonus == "Max HP" then
		scoref = function(bonuses)
			return estimate_maxhp(bonuses)
		end
	elseif whichbonus == "Max MP" then
		scoref = function(bonuses)
			return estimate_maxmp(bonuses)
		end
	elseif whichbonus == "Monsters will be less attracted to you" then
		scoref = function(bonuses)
			return -bonuses["Monsters will be more attracted to you"]
		end
	elseif whichbonus == "Muscle" then
		scoref = function(bonuses)
			return estimate_stat("Muscle", bonuses)
		end
	elseif whichbonus == "Mysticality" then
		scoref = function(bonuses)
			return estimate_stat("Mysticality", bonuses)
		end
	elseif whichbonus == "Moxie" then
		scoref = function(bonuses)
			return estimate_stat("Moxie", bonuses)
		end
	elseif whichbonus == "All resistances" then
		scoref = function(bonuses)
			return bonuses["Cold Resistance"] + bonuses["Hot Resistance"] + bonuses["Sleaze Resistance"] + bonuses["Spooky Resistance"] + bonuses["Stench Resistance"] + bonuses["Slime Resistance"]
		end
	elseif whichbonus == "All weapon damage" then
		scoref = function(bonuses)
			return bonuses["Weapon Damage"] + bonuses["Weapon Damage %"] / 2 + bonuses["Cold Damage"] + bonuses["Hot Damage"] + bonuses["Sleaze Damage"] + bonuses["Spooky Damage"] + bonuses["Stench Damage"]
		end
	end

	local equipmentlines = {}
	kolproxy_log_time_interval("DEBUG equipment", function()

	local previous_scores = {}
	local suggested_scores = {}
--	local item_in_outfit = {}
--	local chosen_outfit_score = 0
	local function add(slottitle, itemid, where)
		local item = { name = "(none)", score = 0 }
		local extra = ""
		if itemid then
			item = { name = maybe_get_itemname(itemid), score = suggested_scores[where] or 0 }
--			if item_in_outfit[itemid] then
--				extra = string.format("[outfit score: %+d]", chosen_outfit_score)
--			end
		end
		if equipment()[where] == itemid then
			table.insert(equipmentlines, string.format([[<tr style="color: gray"><td>%s</td><td>%s (%+d)</td><td>%s (%+d)</td><td>%s</td></tr>]], slottitle, item.name, item.score, item.name, item.score, extra))
		else
			table.insert(equipmentlines, string.format([[<tr><td>%s</td><td style="color: gray">%s (%+d)</td><td><a href="%s" style="color: green">%s</a> (%+d)</td><td>%s</td></tr>]], slottitle, maybe_get_itemname(equipment()[where]) or "", previous_scores[where], modifier_maximizer_href { pwd = session.pwd, whichbonus = params.whichbonus, equip_itemname = item.name, equip_slot = where }, item.name, item.score, extra))
		end
	end

	local suggested_equipment = {}
	for _, slot in ipairs { "hat", "container", "shirt", "weapon", "offhand", "pants", "acc1", "acc2", "acc3" } do
		local items, prevscore = 
kolproxy_log_time_interval("DEBUG eqslot:" .. slot, function()
return maximize_equipment_slot_bonuses(slot, scoref)
end)
		suggested_equipment[slot] = items[1].itemid
		suggested_scores[slot] = items[1].score
		previous_scores[slot] = prevscore
	end

--	if suggested_equipment.weapon and suggested_equipment.offhand and is_twohanded_weapon(suggested_equipment.weapon) then
--		local 2h_weapon_score = score_equiment_replacement(scoref, suggested_equipment.weapon, equipment().weapon, equipment().offhand)
--		local offhand_score = score_item(scoref, suggested_equipment.offhand)
--		local items = maximize_equipment_slot_bonuses("weapon", scoref)
--		for _, x in ipairs(items) do
--			if not x.itemid or not is_twohanded_weapon(x.itemid) then
--				if x.score + offhand_score >= weapon_score then
--					suggested_equipment.weapon = x.itemid
--				end
--				break
--			end
--		end
--	end

--	local best_outfit_items = {}
--	local best_outfit_score = 0
--	for xname, x in pairs(datafile("outfits")) do
--		local canuse = true
--		for _, y in ipairs(x.items) do
--			if not maybe_get_itemid(y) then
--				canuse = false
--			elseif not have_item(y) or not can_equip_item(y) then
--				canuse = false
--			end
--		end
--		if canuse then
--			local outfit_score = scoref(x.bonuses)
--			local outfit_item_score = 0
--			local current_score = 0
--			for _, y in ipairs(x.items) do
--				outfit_item_score = outfit_item_score + score_item(scoref, y)
--				current_score = current_score + score_item(scoref, suggested_equipment[get_itemdata(y).equipment_slot])
--				if is_twohanded_weapon(y) then
--					current_score = current_score + score_item(scoref, suggested_equipment.offhand)
--				end
--			end
--			if outfit_score + outfit_item_score - current_score > best_outfit_score and outfit_score > 0 then
--				best_outfit_score = outfit_score + outfit_item_score - current_score
--				best_outfit_items = x.items
--				chosen_outfit_score = outfit_score
--			end
--		end
--	end
--
--	for _, x in ipairs(best_outfit_items) do
--		local slot = get_itemdata(x).equipment_slot
--		if slot == "accessory" then slot = "acc3" end
--		suggested_equipment[slot] = get_itemid(x)
--		item_in_outfit[get_itemid(x)] = true
--	end

	if suggested_equipment.weapon and is_twohanded_weapon(suggested_equipment.weapon) then
		suggested_equipment.offhand = nil
	end

	for _, slot in ipairs { "hat", "container", "shirt", "weapon", "offhand", "pants", "acc1", "acc2", "acc3" } do
		add(slot, suggested_equipment[slot], slot)
	end

	end) -- DEBUG log time
	local bufflines = {}
	kolproxy_log_time_interval("DEBUG skills", function()

	for _, x in ipairs(maximize_skill_bonuses(scoref)) do
		if x.score > 0 then
			if have_buff(x.effect) then
				table.insert(bufflines, string.format([[<tr style="color: gray"><td>%s</td><td>%s (%+d)</td></tr>]], x.name, x.effect, x.score))
			else
				table.insert(bufflines, string.format([[<tr style="color: green"><td><a href="%s" style="color: green">%s</a></td><td>%s (%+d)</td></tr>]], modifier_maximizer_href { pwd = session.pwd, whichbonus = params.whichbonus, cast_skillname = x.name }, x.name, x.effect, x.score))
			end
		end
	end

	table.insert(bufflines, "<tr><td>&nbsp;</td></tr>")

	end) -- DEBUG log time
	kolproxy_log_time_interval("DEBUG items", function()

	for _, x in ipairs(maximize_item_bonuses(scoref)) do
		if x.score > 0 then
			if have_buff(x.effect) then
				table.insert(bufflines, string.format([[<tr style="color: gray"><td>%s</td><td>%s (%+d)</td></tr>]], x.name, x.effect, x.score))
			else
				table.insert(bufflines, string.format([[<tr style="color: green"><td><a href="%s" style="color: green">%s</a></td><td>%s (%+d)</td></tr>]], modifier_maximizer_href { pwd = session.pwd, whichbonus = params.whichbonus, use_itemname = x.name }, x.name, x.effect, x.score))
			end
		end
	end

	end) -- DEBUG log time

	local script_links = {}
	for _, f in ipairs(registered_script_links) do
		local name, href = f()
		if name and href then
			table.insert(script_links, string.format([[<a href="%s" style="color: green">{ %s }</a>]], href, name))
		end
	end

	local links = {}
	for _, x in ipairs(bonuses) do
		table.insert(links, string.format([[<a href="%s">%s</a>]], modifier_maximizer_href { pwd = session.pwd, whichbonus = x }, x))
	end

	local contents = make_kol_html_frame("<table><thead><tr><th>slot</th><th>current</th><th>suggested</th></tr></thead><tbody>" .. table.concat(equipmentlines, "\n") .. "</tbody></table><br><table>" .. table.concat(bufflines, "\n") .. "</table><br>" .. table.concat(script_links, "<br>") .. "<br><br>" .. table.concat(links, " | "), "Modifier maximizer (" .. whichbonus .. ")")

	return [[<html>
<head>
<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/window.20111231.js"></script>
</head>
<body>]] .. resultpt .. contents .. [[</body>
</html>]], requestpath
end)
