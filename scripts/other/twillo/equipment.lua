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

function add_modifier_bonuses(target, source)
	for a, b in pairs(source) do
		if b == "?" then
			target[a .. "_unknown"] = true
		elseif b == true then
			target[a] = true
		else
			target[a] = (target[a] or 0) + b
		end
	end
end

local add_bonuses = add_modifier_bonuses

function estimate_equipment_bonuses()
	local bonuses = {}

	local itemarray = {
		["Jekyllin hide belt"] = { ["Item Drops from Monsters"] = session["cached Jekyllin hide belt bonus"] or "?" },
		["little box of fireworks"] = { item_upto = 25 },
		["Colonel Mustard's Lonely Spades Club Jacket"] = { ["Combat Initiative"] = "?", ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?" }, -- 1-3%
		["stinky cheese eye"] = { ["Item Drops from Monsters"] = session["cached stinky cheese eye bonus"] or "?", ["Meat from Monsters"] = session["cached stinky cheese eye bonus"] or "?" },
		["Moonthril Cuirass"] = { ["Monster Level"] = session["cached Moonthril Cuirass bonus"] or "?" },
		["Grimacite gown"] = { ["Monster Level"] = session["cached Grimacite gown bonus"] or "?" },
		["hairshirt"] = { ["Monster Level"] = session["cached hairshirt bonus"] or "?" },
		["jalape&ntilde;o slices"] = { ["Meat from Monsters"] = 2 * fairy_bonus(10) },
		["navel ring of navel gazing"] = { item_upto = 20, meat_upto = 20 },
		["parasitic tentacles"] = { ["Combat Initiative"] = math.min(30, level() * 2) },

		["Mayflower bouquet"] = { item_upto = 10, meat_upto = 40, ["Item Drops from Monsters"] = "?" }, -- not sufficiently spaded
		["Tuesday's ruby"] = { ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?" }, -- varies by day
		["spooky little girl"] = { ["Item Drops from Monsters"] = "?" }, -- varies with grimacite

		["card sleeve"] = { ["Combat Initiative"] = "?", ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?" }, -- varies by card
	}

	if not equipment().weapon and not equipment().offhand then
		-- bonus for unarmed characters only
		itemarray["frosty halo"] = { ["Item Drops from Monsters"] = 25 }
	end

	if have_buff("Yuletide Mutations") then
		itemarray["parasitic tentacles"] = { ["Combat Initiative"] = math.min(45, level() * 3) }
	end

	if have_equipped_item("scratch 'n' sniff sword") or have_equipped_item("scratch 'n' sniff crossbow") then
		local scratchnsniff_bonuses = {}
		for _, x in pairs(applied_scratchnsniff_stickers()) do
			-- TODO: read from data file?
			if x == get_itemid("scratch 'n' sniff unicorn sticker") then
				add_bonuses(scratchnsniff_bonuses, { ["Item Drops from Monsters"] = 25 })
			elseif x == get_itemid("scratch 'n' sniff UPC sticker") then
				add_bonuses(scratchnsniff_bonuses, { ["Meat from Monsters"] = 25 })
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
		add_bonuses(bonuses, { ["Monster Level"] = 10 })
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
		add_bonuses(bonuses, { ["Item Drops from Monsters"] = math.pow(2, count_brimstone), ["Meat from Monsters"] = math.pow(2, count_brimstone), ["Monster Level"] = math.pow(2, count_brimstone) })
	end

	local count_mm = count_distinct_equipped_itemlist {
		"monstrous monocle",
		"musty moccasins",
		"molten medallion",
	}
	if count_mm == 2 then
		add_bonuses(bonuses, { ["Item Drops from Monsters"] = 10 })
	elseif count_mm == 3 then
		add_bonuses(bonuses, { ["Item Drops from Monsters"] = 30 })
	end

	local count_bb = count_distinct_equipped_itemlist {
		"bewitching boots",
		"bitter bowtie",
		"brazen bracelet",
	}
	if count_bb == 2 then
		add_bonuses(bonuses, { ["Meat from Monsters"] = 10 })
	elseif count_bb == 3 then
		add_bonuses(bonuses, { ["Meat from Monsters"] = 30 })
	end

	return bonuses
end
