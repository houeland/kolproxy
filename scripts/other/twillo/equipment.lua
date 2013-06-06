add_processor("/familiar.php", function()
	session["cached enthroned familiar"] = nil
end)

function cache_enthroned_familiar()
	local pt = get_page("/desc_item.php", { whichitem = 239178788 })
	local line = pt:match([[>Current Occupant.-<br>]])
	local famtype = line:match("<b>.+, the (.-)</b><br>")
	if line:match([[<b>Nobody</b>]]) then
		famtype = "none"
	end
	session["cached enthroned familiar"] = famtype
end

add_automator("all pages", function()
	if have_equipped("Crown of Thrones") and not session["cached enthroned familiar"] then
		cache_enthroned_familiar()
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
	if not source then
		print("WARNING: no source for add_modifier_bonuses()")
	end
	for a, b in pairs(source or {}) do
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

function estimate_item_equip_bonuses(item)
	-- TODO: force session bonus computations

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
		["parasitic tentacles"] = { ["Combat Initiative"] = math.min(15, level()) * (2 + (have_buff("Yuletide Mutations") and 1 or 0)) },
		["Snow Suit"] = { ["Item Drops from Monsters"] = session["cached Snow Suit bonus"] or "?" },

		["Mayflower bouquet"] = { item_upto = 10, meat_upto = 40, ["Item Drops from Monsters"] = "?" }, -- not sufficiently spaded
		["Tuesday's ruby"] = { ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?" }, -- varies by day
		["spooky little girl"] = { ["Item Drops from Monsters"] = "?" }, -- varies with grimacite

		["card sleeve"] = { ["Combat Initiative"] = "?", ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?" }, -- varies by card

		["frosty halo"] = { ["Item Drops from Monsters"] = (not equipment().weapon and not equipment().offhand) and 25 or nil },
	}

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

	local name = maybe_get_itemname(item)
	if not name then
		-- ..unknown..
		return {}
	elseif itemarray[name] then
		return itemarray[name]
	elseif datafile("items")[name] then
		return datafile("items")[name].equip_bonuses or {}
	else
		return {}
	end
end

function estimate_current_equipment_bonuses()
	local bonuses = {}

	for _, itemid in pairs(equipment()) do
		add_bonuses(bonuses, estimate_item_equip_bonuses(itemid))
	end

	-- TODO: hobo power

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
