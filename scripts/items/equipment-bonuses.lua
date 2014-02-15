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

function parse_modifier_bonuses_page(pt)
	local bonuses = make_bonuses_table {}
	bonuses = bonuses + { ["Item Drops from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Item Drops from Monsters<]])) }
	bonuses = bonuses + { ["Item Drops from Monsters (Dreadsylvania only)"] = tonumber(pt:match([[>([+-][0-9]+)%% Item Drops from Monsters %(Dreadsylvania only%)<]])) }
	bonuses = bonuses + { ["Item Drops (KoL High School zones only)"] = tonumber(pt:match([[>([+-][0-9]+)%% Item Drops %(KoL High School zones only%)<]])) }
	bonuses = bonuses + { ["Item Drops (Underwater only)"] = tonumber(pt:match([[>([+-][0-9]+)%% Item Drops %(Underwater only%)<]])) }
	bonuses = bonuses + { ["Food Drops from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Food Drops from Monsters<]])) }
	bonuses = bonuses + { ["Booze Drops from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Booze Drops from Monsters<]])) }
	bonuses = bonuses + { ["Meat from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Meat from Monsters<]])) }
	bonuses = bonuses + { ["Meat from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Meat Drops from Monsters<]])) }
	bonuses = bonuses + { ["Monster Level"] = tonumber(pt:match([[>([+-][0-9]+) to Monster Level<]])) }
	bonuses = bonuses + { ["Combat Initiative"] = tonumber(pt:match([[>Combat Initiative ([+-][0-9]+)%%<]])) }
	bonuses = bonuses + { ["Combat Initiative"] = tonumber(pt:match([[>([+-][0-9]+)%% Combat Initiative<]])) }
	bonuses = bonuses + { ["Adventures per day"] = tonumber(pt:match([[>([+-][0-9]+) Adventure%(s%) per day when equipped.?<]])) }
	bonuses = bonuses + { ["Familiar Weight"] = tonumber(pt:match([[>([+-][0-9]+) to Familiar Weight<]])) }

	if pt:contains(">Monsters will be more attracted to you.<") then
		bonuses = bonuses + { ["Monsters will be more attracted to you"] = 5 }
	end
	if pt:contains(">Monsters will be less attracted to you.<") then
		bonuses = bonuses + { ["Monsters will be more attracted to you"] = -5 }
	end
	return bonuses
end

function parse_item_bonuses(item)
	local descid = item_api_data(item).descid
	local pt = get_page("/desc_item.php", { whichitem = descid })
	local bonuses = parse_modifier_bonuses_page(pt)
	return bonuses
end

--add_processor("/familiar.php", function()
--	session["cached enthroned familiar"] = nil
--end)

--function cache_enthroned_familiar()
--	local pt = get_page("/desc_item.php", { whichitem = 239178788 })
--	local line = pt:match([[>Current Occupant.-<br>]])
--	local famtype = line:match("<b>.+, the (.-)</b><br>")
--	if line:match([[<b>Nobody</b>]]) then
--		famtype = "none"
--	end
--	session["cached enthroned familiar"] = famtype
--end

--add_automator("all pages", function()
--	if have_equipped_item("Crown of Thrones") and not session["cached enthroned familiar"] then
--		cache_enthroned_familiar()
--	end
--end)

--add_processor("/familiar.php", function()
--	session["cached bjornified familiar"] = nil
--end)

--function cache_bjornified_familiar()
--	local pt = get_page("/desc_item.php", { whichitem = 697608546 })
--	local line = pt:match([[>Current Occupant.-<br>]])
--	local famtype = line:match("<b>.+, the (.-)</b><br>")
--	if line:match([[<b>Nobody</b>]]) then
--		famtype = "none"
--	end
--	session["cached bjornified familiar"] = famtype
--end

--add_automator("all pages", function()
--	if have_equipped_item("Buddy Bjorn") and not session["cached bjornified familiar"] then
--		cache_bjornified_familiar()
--	end
--end)

-- TODO: move to different file

function set_cached_modifier_bonuses(source, name, tbl)
	session["cached "..source.." bonuses: " .. tostring(name)] = tbl
end

function get_cached_modifier_bonuses(source, name)
	local tbl = session["cached "..source.." bonuses: " .. tostring(name)]
	if tbl then
		return make_bonuses_table(tbl)
	end
end

function clear_cached_modifier_bonuses(source, name)
	return set_cached_modifier_bonuses(source, name, nil)
end

-- TODO: remove/inline

function set_cached_item_bonuses(name, tbl)
	return set_cached_modifier_bonuses("item", get_itemid(name), tbl)
end

function get_cached_item_bonuses(name)
	return get_cached_modifier_bonuses("item", get_itemid(name))
end

function clear_cached_item_bonuses(name)
	return set_cached_modifier_bonuses("item", get_itemid(name), nil)
end

add_processor("/fight.php", function()
	if newly_started_fight then
		clear_cached_item_bonuses("stinky cheese eye")
		clear_cached_item_bonuses("stinky cheese diaper")
	end
end)

add_processor("/inv_equip.php", function()
	clear_cached_item_bonuses("stinky cheese eye")
	clear_cached_item_bonuses("stinky cheese diaper")
end)

add_processor("/familiar.php", function()
	clear_cached_item_bonuses("Crown of Thrones")
	clear_cached_item_bonuses("Buddy Bjorn")
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

local items_to_cache = {
	["stinky cheese eye"] = true,
	["stinky cheese diaper"] = true,
	["Jekyllin hide belt"] = true,
	["Grimacite gown"] = true,
	["Moonthril Cuirass"] = true,
	["hairshirt"] = true,
	["over-the-shoulder Folder Holder"] = true,
	["Tuesday's ruby"] = true,
	["spooky little girl"] = true,
	["card sleeve"] = true,
	["Yearbook Club Camera"] = true,
	["Frown Exerciser"] = true,
	["Crown of Thrones"] = true,
	["Buddy Bjorn"] = true,
}

local function ensure_cached_item_bonuses(item)
	if not get_cached_item_bonuses(item) then
		set_cached_item_bonuses(item, parse_item_bonuses(item))
	end
end

add_automator("all pages", function()
	for itemname, _ in pairs(items_to_cache) do
		if have_equipped_item(itemname) then
			ensure_cached_item_bonuses(itemname)
		end
	end
	for _, itemid in pairs(equipment()) do
		if not maybe_get_itemname(itemid) and not get_cached_item_bonuses(itemid) then
			ensure_cached_item_bonuses(itemid)
		end
	end
end)

add_automator("all pages", function()
	if have_equipped_item("Snow Suit") and not get_cached_item_bonuses("Snow Suit") then
		local pt = get_page("/charpane.php")
		set_cached_item_bonuses("Snow Suit", { ["Item Drops from Monsters"] = pt:contains("/snowface3.gif") and 10 or 0 })
	end
end)

local function estimate_item_equip_bonuses_uncached(item)
	local itemarray = {
		["parasitic tentacles"] = { ["Combat Initiative"] = math.min(15, level()) * (2 + (have_buff("Yuletide Mutations") and 1 or 0)) },
		["frosty halo"] = { ["Item Drops from Monsters"] = (not equipment().weapon and not equipment().offhand) and 25 or nil },

		["little box of fireworks"] = { item_upto = 25 },
		["jalape&ntilde;o slices"] = { ["Meat from Monsters"] = 2 * fairy_bonus(10) },
		["navel ring of navel gazing"] = { item_upto = 20, meat_upto = 20 },

		["Snow Suit"] = "cached",

		["Mayflower bouquet"] = { item_upto = 10, meat_upto = 40, ["Item Drops from Monsters"] = "?" }, -- not sufficiently spaded
		["Colonel Mustard's Lonely Spades Club Jacket"] = { ["Combat Initiative"] = "?", ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?" }, -- 1-3%
	}

	for itemname, _ in pairs(items_to_cache) do
		itemarray[itemname] = "cached"
	end

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

--	if have_equipped_item("Crown of Thrones") then
--		local famtype = session["cached enthroned familiar"]
--		if famtype and famtype ~= "none" then
--			itemarray["Crown of Thrones"] = datafile("enthroned familiars")[famtype]
--		end
--	end

--	if have_equipped_item("Buddy Bjorn") then
--		local famtype = session["cached bjornified familiar"]
--		if famtype and famtype ~= "none" then
--			itemarray["Buddy Bjorn"] = datafile("enthroned familiars")[famtype]
--		end
--	end

	local unknown_table = { ["Combat Initiative"] = "?", ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?", ["Monster Level"] = "?", ["Monsters will be more attracted to you"] = "?" }
	local name = maybe_get_itemname(item)
	if not name then
		-- ..unknown..
		return make_bonuses_table(unknown_table) + make_bonuses_table(get_cached_item_bonuses(item) or {})
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

function estimate_item_equip_bonuses(item)
	if items_to_cache[maybe_get_itemname(item)] then
		ensure_cached_item_bonuses(item)
	end
	return estimate_item_equip_bonuses_uncached(item)
end

-- TODO: always cache bonuses first here
function estimate_current_equipment_bonuses()
	local bonuses = {}
	for _, itemid in pairs(equipment()) do
		add_modifier_bonuses(bonuses, estimate_item_equip_bonuses_uncached(itemid))
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
			elseif not have_equipped_item(y) then
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
