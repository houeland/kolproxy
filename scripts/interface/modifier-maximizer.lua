function maximize_equipment_slot_bonuses(slot, scoref)
	local options = {}

	for wornslot, itemid in pairs(equipment()) do
		local name = maybe_get_itemname(itemid)
		local d = maybe_get_itemdata(itemid)
		if name and d and d.equipment_slot == slot then
			local score = scoref(d.equip_bonuses or {})
			table.insert(options, { name = name, score = score, worn = true, wornslot = wornslot })
		end
	end
	for itemid, _ in pairs(inventory()) do
		local name = maybe_get_itemname(itemid)
		local d = maybe_get_itemdata(itemid)
		if name and d and d.equipment_slot == slot then
			local score = scoref(d.equip_bonuses or {})
			table.insert(options, { name = name, score = score, worn = false })
		end
	end
	table.sort(options, function(a, b)
		if a.score ~= b.score then
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

function maximize_buff_bonuses(scoref)
	local options = {}

	for id, _ in pairs(inventory()) do
		local d = maybe_get_itemdata(id)
		if d and d.use_effect then
			local b = datafile("buffs")[d.use_effect] or {}
			local score = scoref(b.bonuses or {})
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

local modifier_maximizer_href
modifier_maximizer_href = add_automation_script("custom-modifier-maximizer", function()
	local bonuses = {
		"Monsters will be more attracted to you",
		"Item Drops from Monsters",
		"Monster Level",
		"Combat Initiative",
		"Meat from Monsters",
		"HP & cold/spooky resistance",
	}

	local whichbonus = params.whichbonus or "Item Drops from Monsters"

	local scoref = function(bonuses)
		return bonuses[whichbonus] or 0
	end
	if whichbonus == "HP & cold/spooky resistance" then
		scoref = function(bonuses)
			-- TODO: HP % modifiers
			return (bonuses["Maximum HP"] or 0) + (bonuses["Muscle"] or 0) + (bonuses["Muscle %"] or 0)/100 * basemuscle() + (bonuses["Spooky Resistance"] or 0) * 20 + (bonuses["Cold Resistance"] or 0) * 20
		end
	end

	local equipmentlines = {}
	for _, slot in ipairs { "hat", "container", "shirt", "weapon", "offhand", "pants", "accessory" } do
		local items = maximize_equipment_slot_bonuses(slot, scoref)
		if items[1] then
			table.insert(equipmentlines, string.format("<tr><td>%s</td><td>%s (%+d)</td></tr>", slot, items[1].name, items[1].score))
		else
			table.insert(equipmentlines, string.format("<tr><td>%s</td><td>(none)</td></tr>", slot))
		end
		if slot == "accessory" and items[2] then
			table.insert(equipmentlines, string.format("<tr><td>%s</td><td>%s (%+d)</td></tr>", slot, items[2].name, items[2].score))
		end
		if slot == "accessory" and items[3] then
			table.insert(equipmentlines, string.format("<tr><td>%s</td><td>%s (%+d)</td></tr>", slot, items[3].name, items[3].score))
		end
	end

	local bufflines = {}
	local items = maximize_buff_bonuses(scoref)
	for _, x in ipairs(items) do
		if x.score > 0 and not have_buff(x.effect) then
			table.insert(bufflines, string.format("<tr><td>%s</td><td>%s (%+d)</td></tr>", x.name, x.effect, x.score))
		end
	end

	local links = {}
	for _, x in ipairs(bonuses) do
		table.insert(links, string.format([[<a href="%s">%s</a>]], modifier_maximizer_href { pwd = session.pwd, whichbonus = x }, x))
	end

	return make_kol_html_frame("<table>" .. table.concat(equipmentlines, "\n") .. "</table><br><table>" .. table.concat(bufflines, "\n") .. "</table><br>" .. table.concat(links, " | "), "Modifier maximizer (preview)"), requestpath
end)
