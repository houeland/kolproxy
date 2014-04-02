--- TODO ---
-- halos
-- check if we can really cast buffs
-- buy items from NPCs
-- buy items in mall in aftercore

function maximize_equipment_slot_bonuses(slot, scoref_raw)
	function scoref(tbl)
		return scoref_raw(make_bonuses_table(tbl))
	end

	local options = {}

	for wornslot, itemid in pairs(equipment()) do
		local name = maybe_get_itemname(itemid)
		local d = maybe_get_itemdata(itemid)
		if name and d and d.equipment_slot == slot then
			local score = scoref(estimate_item_equip_bonuses(name))
			table.insert(options, { name = name, score = score, worn = true, wornslot = wornslot, itemid = itemid, canwear = true })
		end
	end
	for itemid, _ in pairs(inventory()) do
		local name = maybe_get_itemname(itemid)
		local d = maybe_get_itemdata(itemid)
		if name and d and d.equipment_slot == slot then
			local score = scoref(estimate_item_equip_bonuses(name))
			table.insert(options, { name = name, score = score, worn = false, itemid = itemid, canwear = can_equip_item(name) })
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
	return options
end

function maximize_item_bonuses(scoref)
	local options = {}

	for id, _ in pairs(inventory()) do
		local d = maybe_get_itemdata(id)
		if d and d.use_effect then
			local score = scoref(estimate_buff_bonuses(d.use_effect))
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

function maximize_skill_bonuses(scoref)
	local options = {}

	for buffname, castname in pairs(datafile_buff_recast_skills) do
		local can_cast = have_skill(castname)
		if playerclass("Pastamancer") and castname:match("^Bind ") then
			-- TODO: Add line to switch pasta thrall
			can_cast = false
		elseif buffname == "Muffled" then
			can_cast = (sneaky_pete_motorcycle_upgrades()["Muffler"] == "Extra-Quiet Muffler")
		elseif buffname == "Unmuffled" then
			can_cast = (sneaky_pete_motorcycle_upgrades()["Muffler"] == "Extra-Loud Muffler")
		end
		if can_cast then
			local score = scoref(estimate_buff_bonuses(buffname))
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

local function score_item(scoref, item)
	local itemid = maybe_get_itemid(item)
	if not itemid then
		return 0
	end
	return scoref(estimate_item_equip_bonuses(itemid))
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
		"Cold Resistance",
		"Hot Resistance",
		"Sleaze Resistance",
		"Spooky Resistance",
		"Stench Resistance",
		"Slime Resistance",
	}

	local whichbonus = params.whichbonus or "Item Drops from Monsters"

	local scoref = function(bonuses)
		bonuses = make_bonuses_table(bonuses)
		return bonuses[whichbonus] or 0
	end
	if whichbonus == "HP & cold/spooky resistance" then
		scoref = function(bonuses)
			bonuses = make_bonuses_table(bonuses)
			return estimate_maxhp_increases(bonuses) + bonuses["Spooky Resistance"] * 20 + bonuses["Cold Resistance"] * 20
		end
	elseif whichbonus == "Max HP" then
		scoref = function(bonuses)
			bonuses = make_bonuses_table(bonuses)
			return estimate_maxhp_increases(bonuses)
		end
	elseif whichbonus == "Monsters will be less attracted to you" then
		scoref = function(bonuses)
			bonuses = make_bonuses_table(bonuses)
			return -bonuses["Monsters will be more attracted to you"]
		end
	elseif whichbonus == "Muscle" then
		scoref = function(bonuses)
			bonuses = make_bonuses_table(bonuses)
			return bonuses["Muscle"] + bonuses["Muscle %"]/100 * basemuscle()
		end
	elseif whichbonus == "Mysticality" then
		scoref = function(bonuses)
			bonuses = make_bonuses_table(bonuses)
			return bonuses["Mysticality"] + bonuses["Mysticality %"]/100 * basemysticality()
		end
	elseif whichbonus == "Moxie" then
		scoref = function(bonuses)
			bonuses = make_bonuses_table(bonuses)
			return bonuses["Moxie"] + bonuses["Moxie %"]/100 * basemoxie()
		end
	end

	local equipmentlines = {}
	local item_in_outfit = {}
	local chosen_outfit_score = 0
	local function add(slot, itemid, where)
		local item = { name = "(none)", score = 0 }
		local extra = ""
		if itemid then
			item = { name = maybe_get_itemname(itemid), score = score_item(scoref, itemid) }
			if item_in_outfit[itemid] then
				extra = string.format("[outfit score: %+d]", chosen_outfit_score)
			end
		end
		if equipment()[where] == itemid then
			table.insert(equipmentlines, string.format([[<tr style="color: gray"><td>%s</td><td>%s (%+d)</td><td>%s</td></tr>]], slot, item.name, item.score, extra))
		else
			table.insert(equipmentlines, string.format([[<tr style="color: green"><td>%s</td><td><a href="%s" style="color: green">%s</a> (%+d)</td><td>%s</td></tr>]], slot, modifier_maximizer_href { pwd = session.pwd, whichbonus = params.whichbonus, equip_itemname = item.name, equip_slot = where }, item.name, item.score, extra))
		end
	end

	local suggested_equipment = {}
	for _, slot in ipairs { "hat", "container", "shirt", "weapon", "offhand", "pants", "accessory" } do
		local items = maximize_equipment_slot_bonuses(slot, scoref)
		if slot == "accessory" then
			suggested_equipment.acc1 = items[1].itemid
			suggested_equipment.acc2 = items[2].itemid
			suggested_equipment.acc3 = items[3].itemid
		else
			suggested_equipment[slot] = items[1].itemid
		end
	end

	if suggested_equipment.weapon and suggested_equipment.offhand and is_twohanded_weapon(suggested_equipment.weapon) then
		local weapon_score = score_item(scoref, suggested_equipment.weapon)
		local offhand_score = score_item(scoref, suggested_equipment.offhand)
		local items = maximize_equipment_slot_bonuses("weapon", scoref)
		for _, x in ipairs(items) do
			if not x.itemid or not is_twohanded_weapon(x.itemid) then
				if x.score + offhand_score >= weapon_score then
					suggested_equipment.weapon = x.itemid
				end
				break
			end
		end
	end

	local best_outfit_items = {}
	local best_outfit_score = 0
	for xname, x in pairs(datafile("outfits")) do
		local canuse = true
		for _, y in ipairs(x.items) do
			if not maybe_get_itemid(y) then
				canuse = false
			elseif not have_item(y) or not can_equip_item(y) then
				canuse = false
			end
		end
		if canuse then
			local outfit_score = scoref(x.bonuses)
			local outfit_item_score = 0
			local current_score = 0
			for _, y in ipairs(x.items) do
				outfit_item_score = outfit_item_score + score_item(scoref, y)
				current_score = current_score + score_item(scoref, suggested_equipment[get_itemdata(y).equipment_slot])
				if is_twohanded_weapon(y) then
					current_score = current_score + score_item(scoref, suggested_equipment.offhand)
				end
			end
			if outfit_score + outfit_item_score - current_score > best_outfit_score and outfit_score > 0 then
				best_outfit_score = outfit_score + outfit_item_score - current_score
				best_outfit_items = x.items
				chosen_outfit_score = outfit_score
			end
		end
	end

	for _, x in ipairs(best_outfit_items) do
		local slot = get_itemdata(x).equipment_slot
		if slot == "accessory" then slot = "acc3" end
		suggested_equipment[slot] = get_itemid(x)
		item_in_outfit[get_itemid(x)] = true
	end

	if suggested_equipment.weapon and is_twohanded_weapon(suggested_equipment.weapon) then
		suggested_equipment.offhand = nil
	end

	for _, slot in ipairs { "hat", "container", "shirt", "weapon", "offhand", "pants", "accessory" } do
		if slot == "accessory" then
			local newslots = reuse_equipment_slots {
				acc1 = suggested_equipment.acc1,
				acc2 = suggested_equipment.acc2,
				acc3 = suggested_equipment.acc3,
			}
			add(slot, newslots.acc1, "acc1")
			add(slot, newslots.acc2, "acc2")
			add(slot, newslots.acc3, "acc3")
		else
			add(slot, suggested_equipment[slot], slot)
		end
	end

	local bufflines = {}
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

	for _, x in ipairs(maximize_item_bonuses(scoref)) do
		if x.score > 0 then
			if have_buff(x.effect) then
				table.insert(bufflines, string.format([[<tr style="color: gray"><td>%s</td><td>%s (%+d)</td></tr>]], x.name, x.effect, x.score))
			else
				table.insert(bufflines, string.format([[<tr style="color: green"><td><a href="%s" style="color: green">%s</a></td><td>%s (%+d)</td></tr>]], modifier_maximizer_href { pwd = session.pwd, whichbonus = params.whichbonus, use_itemname = x.name }, x.name, x.effect, x.score))
			end
		end
	end

	local links = {}
	for _, x in ipairs(bonuses) do
		table.insert(links, string.format([[<a href="%s">%s</a>]], modifier_maximizer_href { pwd = session.pwd, whichbonus = x }, x))
	end

	local contents = make_kol_html_frame("<table>" .. table.concat(equipmentlines, "\n") .. "</table><br><table>" .. table.concat(bufflines, "\n") .. "</table><br>" .. table.concat(links, " | "), "Modifier maximizer (preview)")

	return [[<html style="margin: 0px; padding: 0px;">
<head>
<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/window.20111231.js"></script>
</head>
<body style="margin: 0px; padding: 0px;">]] .. resultpt .. contents .. [[</body>
</html>]], requestpath
end)
