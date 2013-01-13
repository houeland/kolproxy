add_processor("/familiar.php", function()
	session["cached enthroned familiar"] = nil
end)

add_automator("all pages", function()
	if have_equipped("Crown of Thrones") and not session["cached enthroned familiar"] then
		local pt = get_page("/desc_item.php", { whichitem = 239178788 })
		local line = pt:match([[>Current Occupant.-<br>]])
		local famtype = line:match("<b>.+, the (.-)</b><br>")
		if line:match([[<b>Nobody</b>]]) then
			famtype = "none"
		end
		session["cached enthroned familiar"] = famtype
	end
end)

local function count_distinct_equipped_itemlist(itemlist)
	local c = 0
	for _, name in ipairs(itemlist) do
		if have_equipped_item(name) then
			c = c + 1
		end
	end
	return c
end

local function add_bonuses(target, source)
	for a, b in pairs(source) do
		if b == "?" then
			target[a .. "_unknown"] = true
		else
			target[a] = (target[a] or 0) + b
		end
	end
end

function get_equipment_bonuses()
	local bonuses = {combat = 0, item = 0, initiative = 0, ml = 0, meat = 0}

	local itemarray = {
		["Jekyllin hide belt"] = { item = session["cached Jekyllin hide belt bonus"] or "?" },
		["little box of fireworks"] = { item_upto = 25 },
		["Colonel Mustard's Lonely Spades Club Jacket"] = { initiative = "?", item = "?", meat = "?" }, -- 1-3%
		["stinky cheese eye"] = { item = session["cached stinky cheese eye bonus"] or "?", meat = session["cached stinky cheese eye bonus"] or "?" },
		["Moonthril Cuirass"] = { ml = session["cached Moonthril Cuirass bonus"] or "?" },
		["Grimacite gown"] = { ml = session["cached Grimacite gown bonus"] or "?" },
		["hairshirt"] = { ml = session["cached hairshirt bonus"] or "?" },
		["jalape&ntilde;o slices"] = { meat = 2 * fairy_bonus(10) },
		["navel ring of navel gazing"] = { item_upto = 20, meat_upto = 20 },
		["parasitic tentacles"] = { init = math.min(30, level() * 2) },

		["Mayflower bouquet"] = { item_upto = 10, meat_upto = 40, item = "?" }, -- not sufficiently spaded
		["Tuesday's ruby"] = { item = "?", meat = "?" }, -- varies by day
		["spooky little girl"] = { item = "?" }, -- varies with grimacite
	}

	if not equipment().weapon and not equipment().offhand then
		-- bonus for unarmed characters only
		itemarray["frosty halo"] = { item = 25 }
	end

	if have_buff("Yuletide Mutations") then
		itemarray["parasitic tentacles"] = { init = math.min(45, level() * 3) }
	end

	if have_equipped_item("scratch 'n' sniff sword") or have_equipped_item("scratch 'n' sniff crossbow") then
		local scratchnsniff_bonuses = {}
		for _, x in pairs(applied_scratchnsniff_stickers()) do
			-- TODO: read from data file?
			if x == get_itemid("scratch 'n' sniff unicorn sticker") then
				add_bonuses(scratchnsniff_bonuses, { item = 25 })
			elseif x == get_itemid("scratch 'n' sniff UPC sticker") then
				add_bonuses(scratchnsniff_bonuses, { meat = 25 })
			end
		end
		itemarray["scratch 'n' sniff sword"] = scratchnsniff_bonuses
		itemarray["scratch 'n' sniff crossbow"] = scratchnsniff_bonuses
	end

	if have_equipped_item("Crown of Thrones") then
		local famtype = session["cached enthroned familiar"]
		if famtype and famtype ~= "none" then
			itemarray["Crown of Thrones"] = datafile("enthroned familiars")[famtype]
		end
	end

	-- TODO: hobo power

	for _, itemid in pairs(equipment()) do
		local name = maybe_get_itemname(itemid)
		if not name then
			-- ..unknown..
		elseif itemarray[name] then
			add_bonuses(bonuses, itemarray[name])
		elseif datafile("items")[name] then
			add_bonuses(bonuses, datafile("items")[name].equip_bonuses or {})
		end
	end

	if have_equipped_item("snake shield") and have_equipped_item("serpentine sword") then
		add_bonuses(bonuses, { ml = 10 })
	end

	local count_brimstone = count_distinct_equipped_itemlist {
		"Brimstone Bunker",
		"Brimstone Brooch",
		"Brimstone Boxers",
		"Brimstone Beret",
		"Brimstone Bludgeon",
		"Brimstone Bracelet",
	}
	if count_brimstone > 0 then
		add_bonuses(bonuses, { item = math.pow(2, count_brimstone), meat = math.pow(2, count_brimstone), ml = math.pow(2, count_brimstone) })
	end

	local count_mm = count_distinct_equipped_itemlist {
		"monstrous monocle",
		"musty moccasins",
		"molten medallion",
	}
	if count_mm == 2 then
		add_bonuses(bonuses, { item = 10 })
	elseif count_mm == 3 then
		add_bonuses(bonuses, { item = 30 })
	end

	local count_bb = count_distinct_equipped_itemlist {
		"bewitching boots",
		"bitter bowtie",
		"brazen bracelet",
	}
	if count_bb == 2 then
		add_bonuses(bonuses, { meat = 10 })
	elseif count_bb == 3 then
		add_bonuses(bonuses, { meat = 30 })
	end

	return bonuses
end
