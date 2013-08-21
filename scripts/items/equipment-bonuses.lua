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

function parse_item_bonuses(itemname)
-- C/NC
-- init

	local descid = item_api_data(itemname).descid
	local pt = get_page("/desc_item.php", { whichitem = descid })
	local bonuses = make_bonuses_table {}
	bonuses = bonuses + { ["Item Drops from Monsters"] = tonumber(pt:match([[>%+([0-9]+)%% Item Drops from Monsters<]])) }
	bonuses = bonuses + { ["Meat from Monsters"] = tonumber(pt:match([[>%+([0-9]+)%% Meat from Monsters<]])) }
	bonuses = bonuses + { ["Meat from Monsters"] = tonumber(pt:match([[>%+([0-9]+)%% Meat Drops from Monsters<]])) }
	bonuses = bonuses + { ["Monster Level"] = tonumber(pt:match([[>%+([0-9]+) to Monster Level<]])) }
	return bonuses
end

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
	if have_equipped_item("Crown of Thrones") and not session["cached enthroned familiar"] then
		cache_enthroned_familiar()
	end
end)

function set_cached_item_bonuses(name, tbl)
	session["cached item bonuses: " .. name] = tbl
end

function get_cached_item_bonuses(name)
	local tbl = session["cached item bonuses: " .. name]
	if tbl then
		return make_bonuses_table(tbl)
	end
end

function clear_cached_item_bonuses(name)
	return set_cached_item_bonuses(name, nil)
end

add_processor("/fight.php", function()
	if newly_started_fight then
		clear_cached_item_bonuses("stinky cheese eye")
	end
end)

add_processor("/inv_equip.php", function()
	clear_cached_item_bonuses("stinky cheese eye")
end)

add_processor("/choice.php", function()
	if text:contains("snow suit") then
		clear_cached_item_bonuses("Snow Suit")
	end
	if text:contains("folder") and text:contains("holder") then
		clear_cached_item_bonuses("over-the-shoulder Folder Holder")
	end
end)

add_processor("/inventory.php", function()
	if text:contains("Your card sleeve") then
		clear_cached_item_bonuses("card sleeve")
	end
end)

add_automator("all pages", function()
	for _, itemname in ipairs { "stinky cheese eye", "Jekyllin hide belt", "Grimacite gown", "Moonthril Cuirass", "hairshirt", "over-the-shoulder Folder Holder", "Tuesday's ruby", "spooky little girl", "card sleeve" } do
		if have_equipped_item(itemname) and not get_cached_item_bonuses(itemname) then
			set_cached_item_bonuses(itemname, parse_item_bonuses(itemname))
		end
	end
end)

add_automator("all pages", function()
	if have_equipped_item("Snow Suit") and not get_cached_item_bonuses("Snow Suit") then
		local pt = get_page("/charpane.php")
		set_cached_item_bonuses("Snow Suit", { ["Item Drops from Monsters"] = pt:contains("/snowface3.gif") and 10 or 0 })
	end
end)

function estimate_item_equip_bonuses(item)
	local itemarray = {
		["parasitic tentacles"] = { ["Combat Initiative"] = math.min(15, level()) * (2 + (have_buff("Yuletide Mutations") and 1 or 0)) },
		["frosty halo"] = { ["Item Drops from Monsters"] = (not equipment().weapon and not equipment().offhand) and 25 or nil },

		["little box of fireworks"] = { item_upto = 25 },
		["jalape&ntilde;o slices"] = { ["Meat from Monsters"] = 2 * fairy_bonus(10) },
		["navel ring of navel gazing"] = { item_upto = 20, meat_upto = 20 },

		["Jekyllin hide belt"] = "cached",
		["Moonthril Cuirass"] = "cached",
		["Grimacite gown"] = "cached",
		["hairshirt"] = "cached",
		["Tuesday's ruby"] = "cached",
		["spooky little girl"] = "cached",

		["stinky cheese eye"] = "cached",
		["Snow Suit"] = "cached",
		["card sleeve"] = "cached",
		["over-the-shoulder Folder Holder"] = "cached",

		["Mayflower bouquet"] = { item_upto = 10, meat_upto = 40, ["Item Drops from Monsters"] = "?" }, -- not sufficiently spaded
		["Colonel Mustard's Lonely Spades Club Jacket"] = { ["Combat Initiative"] = "?", ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?" }, -- 1-3%
	}

	if have_equipped_item("scratch 'n' sniff sword") or have_equipped_item("scratch 'n' sniff crossbow") then
		local scratchnsniff_bonuses = {}
		for _, x in pairs(applied_scratchnsniff_stickers()) do
			-- TODO: read from data file?
			if x == get_itemid("scratch 'n' sniff unicorn sticker") then
				add_modifier_bonuses(scratchnsniff_bonuses, { ["Item Drops from Monsters"] = 25 })
			elseif x == get_itemid("scratch 'n' sniff UPC sticker") then
				add_modifier_bonuses(scratchnsniff_bonuses, { ["Meat from Monsters"] = 25 })
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

	local unknown_table = { ["Combat Initiative"] = "?", ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?", ["Monster Level"] = "?", ["Monsters will be more attracted to you"] = "?" }
	local name = maybe_get_itemname(item)
	if not name then
		-- ..unknown..
		return make_bonuses_table(unknown_table)
	elseif itemarray[name] == "cached" then
		return make_bonuses_table(get_cached_item_bonuses(name) or unknown_table)
	elseif itemarray[name] then
		return make_bonuses_table(itemarray[name])
	elseif datafile("items")[name] then
		return make_bonuses_table(datafile("items")[name].equip_bonuses or {})
	else
		return make_bonuses_table {}
	end
end

function estimate_current_equipment_bonuses()
	local bonuses = {}
	for _, itemid in pairs(equipment()) do
		add_modifier_bonuses(bonuses, estimate_item_equip_bonuses(itemid))
	end
	return bonuses
end

local function count_distinct_equipped_itemlist(itemlist)
	local c = 0
	for _, name in ipairs(itemlist) do
		if have_equipped_item(name) then
			c = c + 1
		end
	end
	return c
end

function estimate_current_outfit_bonuses()
	local bonuses = {}
	for _, x in pairs(datafile("outfits")) do
		local wearing = true
		for _, y in ipairs(x.items) do
			if not maybe_get_itemid(y) then
				-- WORKAROUND: Sometimes checks for unknown items.
				-- TODO: Make this never happen using solid consistency checks and synchronized datafile loading.
				wearing = false
			elseif not have_equipped(y) then
				wearing = false
			end
		end
		if wearing then
			add_modifier_bonuses(bonuses, x.bonuses)
		end
	end

	-- TODO: hobo power

	if have_equipped_item("snake shield") and have_equipped_item("serpentine sword") then
		add_modifier_bonuses(bonuses, { ["Monster Level"] = 10 })
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
		add_modifier_bonuses(bonuses, {
			["Item Drops from Monsters"] = math.pow(2, count_brimstone),
			["Meat from Monsters"] = math.pow(2, count_brimstone),
			["Monster Level"] = math.pow(2, count_brimstone),
		})
	end

	local count_loathing = count_distinct_equipped_itemlist {
		"Goggles of Loathing",
		"Stick-Knife of Loathing",
		"Scepter of Loathing",
		"Jeans of Loathing",
		"Treads of Loathing",
		"Belt of Loathing",
		"Pocket Square of Loathing",
	}
	if count_loathing > 0 then
		add_modifier_bonuses(bonuses, {
			["Item Drops from Monsters"] = math.pow(2, count_loathing - 1),
			["Meat from Monsters"] = math.pow(2, count_loathing),
		})
	end

	local count_mm = count_distinct_equipped_itemlist {
		"monstrous monocle",
		"musty moccasins",
		"molten medallion",
	}
	if count_mm == 2 then
		add_modifier_bonuses(bonuses, { ["Item Drops from Monsters"] = 10 })
	elseif count_mm == 3 then
		add_modifier_bonuses(bonuses, { ["Item Drops from Monsters"] = 30 })
	end

	local count_bb = count_distinct_equipped_itemlist {
		"bewitching boots",
		"bitter bowtie",
		"brazen bracelet",
	}
	if count_bb == 2 then
		add_modifier_bonuses(bonuses, { ["Meat from Monsters"] = 10 })
	elseif count_bb == 3 then
		add_modifier_bonuses(bonuses, { ["Meat from Monsters"] = 30 })
	end

	return bonuses
end
