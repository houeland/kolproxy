-- <TODO>: move to different file
function add_modifier_bonuses(target, source)
	if not source then
		print("WARNING: no source for add_modifier_bonuses()")
		--error("no source")
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

function subtract_modifier_bonuses(target, source)
	if not source then
		print("WARNING: no source for subtract_modifier_bonuses()")
		--error("no source")
	end
	for a, b in pairs(source or {}) do
		if b == "?" then
		elseif b == true then
		else
			target[a] = (target[a] or 0) - b
		end
	end
end

function parse_modifier_bonuses_page(pt)
	local bonuses = make_bonuses_table {}
	bonuses.add { ["Item Drops from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Item Drops from Monsters<]])) }
	bonuses.add { ["Item Drops from Monsters (Dreadsylvania only)"] = tonumber(pt:match([[>([+-][0-9]+)%% Item Drops from Monsters %(Dreadsylvania only%)<]])) }
	bonuses.add { ["Item Drops (KoL High School zones only)"] = tonumber(pt:match([[>([+-][0-9]+)%% Item Drops %(KoL High School zones only%)<]])) }
	bonuses.add { ["Item Drops (Underwater only)"] = tonumber(pt:match([[>([+-][0-9]+)%% Item Drops %(Underwater only%)<]])) }
	bonuses.add { ["Food Drops from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Food Drops from Monsters<]])) }
	bonuses.add { ["Booze Drops from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Booze Drops from Monsters<]])) }
	bonuses.add { ["Meat from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Meat from Monsters<]])) }
	bonuses.add { ["Meat from Monsters"] = tonumber(pt:match([[>([+-][0-9]+)%% Meat Drops from Monsters<]])) }
	bonuses.add { ["Monster Level"] = tonumber(pt:match([[>([+-][0-9]+) to Monster Level<]])) }
	bonuses.add { ["Combat Initiative"] = tonumber(pt:match([[>Combat Initiative ([+-][0-9]+)%%<]])) }
	bonuses.add { ["Combat Initiative"] = tonumber(pt:match([[>([+-][0-9]+)%% Combat Initiative<]])) }

	bonuses.add { ["Adventures per day"] = tonumber(pt:match([[>([+-][0-9]+) Adventure%(s%) per day when equipped.?<]])) }
	bonuses.add { ["PvP fights per day"] = tonumber(pt:match([[>([+-][0-9]+) PvP fight%(s%) per day when equipped.?<]])) }
	bonuses.add { ["Familiar Weight"] = tonumber(pt:match([[>([+-][0-9]+) to Familiar Weight<]])) }

	bonuses.add { ["Cold Resistance"] = tonumber(pt:match([[ Cold Resistance %(([+-][0-9]+)%)<]])) }
	bonuses.add { ["Hot Resistance"] = tonumber(pt:match([[ Hot Resistance %(([+-][0-9]+)%)<]])) }
	bonuses.add { ["Sleaze Resistance"] = tonumber(pt:match([[ Sleaze Resistance %(([+-][0-9]+)%)<]])) }
	bonuses.add { ["Spooky Resistance"] = tonumber(pt:match([[ Spooky Resistance %(([+-][0-9]+)%)<]])) }
	bonuses.add { ["Stench Resistance"] = tonumber(pt:match([[ Stench Resistance %(([+-][0-9]+)%)<]])) }
	bonuses.add { ["Slime Resistance"] = tonumber(pt:match([[ Slime Resistance %(([+-][0-9]+)%)<]])) }
	local all_elements = tonumber(pt:match([[ Resistance to All Elements %(([+-][0-9]+)%)<]]))
	bonuses.add { ["Cold Resistance"] = all_elements, ["Hot Resistance"] = all_elements, ["Sleaze Resistance"] = all_elements, ["Spooky Resistance"] = all_elements, ["Stench Resistance"] = all_elements }

	bonuses.add { ["Spell Damage"] = tonumber(pt:match([[>Spell Damage ([+-][0-9]+)<]])) }
	bonuses.add { ["Spell Damage %"] = tonumber(pt:match([[>Spell Damage ([+-][0-9]+)%%<]])) }
	bonuses.add { ["Weapon Damage"] = tonumber(pt:match([[>Weapon Damage ([+-][0-9]+)<]])) }
	bonuses.add { ["Weapon Damage %"] = tonumber(pt:match([[>Weapon Damage ([+-][0-9]+)%%<]])) }
	bonuses.add { ["% Chance of Critical Hit"] = tonumber(pt:match([[>([+-][0-9]+)%% [Cc]hance of Critical Hit<]])) }
	bonuses.add { ["% Chance of Spell Critical Hit"] = tonumber(pt:match([[>([+-][0-9]+)%% [Cc]hance of Spell Critical Hit<]])) }

	bonuses.add { ["Muscle"] = tonumber(pt:match([[>Muscle ([+-][0-9]+)<]])) }
	bonuses.add { ["Muscle %"] = tonumber(pt:match([[>Muscle ([+-][0-9]+)%%<]])) }
	bonuses.add { ["Mysticality"] = tonumber(pt:match([[>Mysticality ([+-][0-9]+)<]])) }
	bonuses.add { ["Mysticality %"] = tonumber(pt:match([[>Mysticality ([+-][0-9]+)%%<]])) }
	bonuses.add { ["Moxie"] = tonumber(pt:match([[>Moxie ([+-][0-9]+)<]])) }
	bonuses.add { ["Moxie %"] = tonumber(pt:match([[>Moxie ([+-][0-9]+)%%<]])) }
	local all_attributes = tonumber(pt:match([[>All Attributes ([+-][0-9]+)<]]))
	local all_attributes_percent = tonumber(pt:match([[>All Attributes ([+-][0-9]+)%%<]]))
	bonuses.add { ["Muscle"] = all_attributes, ["Mysticality"] = all_attributes, ["Moxie"] = all_attributes }
	bonuses.add { ["Muscle %"] = all_attributes_percent, ["Mysticality %"] = all_attributes_percent, ["Moxie %"] = all_attributes_percent }

	bonuses.add { ["Maximum HP"] = tonumber(pt:match([[>Maximum HP ([+-][0-9]+)<]])) }
	bonuses.add { ["Maximum HP %"] = tonumber(pt:match([[>Maximum HP ([+-][0-9]+)%%<]])) }
	bonuses.add { ["Maximum MP"] = tonumber(pt:match([[>Maximum MP ([+-][0-9]+)<]])) }
	bonuses.add { ["Maximum MP %"] = tonumber(pt:match([[>Maximum MP ([+-][0-9]+)%%<]])) }
	local maxhpmp = tonumber(pt:match([[>Maximum HP/MP ([+-][0-9]+)<]]))
	bonuses.add { ["Maximum HP"] = maxhpmp, ["Maximum MP"] = maxhpmp }
-- TODO: add more bonuses

	if pt:contains(">Monsters will be more attracted to you.<") then
		bonuses.add { ["Monsters will be more attracted to you"] = 5 }
	end
	if pt:contains(">Monsters will be less attracted to you.<") then
		bonuses.add { ["Monsters will be more attracted to you"] = -5 }
	end
	return bonuses
end

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

function ensure_cached_modifier_bonuses(source, name, f)
	if not get_cached_modifier_bonuses(source, name) then
		set_cached_modifier_bonuses(source, name, f(name))
	end
end

-- </TODO>: move to different file

function parse_item_bonuses(item)
	local descid = have_item(item) and item_api_data(item).descid or (maybe_get_itemdata(item) or {}).descid
	if not descid then
		return {}
	end
	local pt = get_page("/desc_item.php", { whichitem = descid })
	local bonuses = parse_modifier_bonuses_page(pt)
	return bonuses
end

local function set_cached_item_bonuses(name, tbl)
	return set_cached_modifier_bonuses("item", get_itemid(name), tbl)
end

local function get_cached_item_bonuses(name)
	return get_cached_modifier_bonuses("item", get_itemid(name))
end

local function clear_cached_item_bonuses(name)
	return set_cached_modifier_bonuses("item", get_itemid(name), nil)
end

local function ensure_cached_item_bonuses(item)
	return ensure_cached_modifier_bonuses("item", get_itemid(item), parse_item_bonuses)
end

add_processor("/fight.php", function()
	if newly_started_fight then
		clear_cached_item_bonuses("stinky cheese eye")
		clear_cached_item_bonuses("stinky cheese diaper")
	end
end)

add_processor("/inv_equip.php", function()
	-- TODO: on non-ajax equipping too
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
	if text:contains("Adjust your 'Edpiece") or text:contains("Cool jewels") then
		clear_cached_item_bonuses("The Crown of Ed the Undying")
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
	["depleted Grimacite ninja mask"] = true,
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
	["Sword of Procedural Generation"] = true,
	["The Crown of Ed the Undying"] = true,
	["World's Best Adventurer sash"] = true,
}

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

function estimate_item_equip_bonuses_uncached(item)
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

	local unknown_table = { ["Combat Initiative"] = "?", ["Item Drops from Monsters"] = "?", ["Meat from Monsters"] = "?", ["Monster Level"] = "?", ["Monsters will be more attracted to you"] = "?" }
	local name = maybe_get_itemname(item)
	if not name then
		-- ..unknown..
		return make_bonuses_table(unknown_table) + make_bonuses_table(get_cached_item_bonuses(item) or {})
	elseif itemarray[name] == "cached" then
		return make_bonuses_table(get_cached_item_bonuses(name) or unknown_table)
	elseif itemarray[name] then
		return make_bonuses_table(itemarray[name])
	else
		local itemdata = maybe_get_itemdata(name)
		if itemdata then
			local bonuses = make_bonuses_table(itemdata.equip_bonuses or {})
			if itemdata.song_duration and have_skill("Accordion Appreciation") then
				bonuses.add(itemdata.equip_bonuses or {})
			end
			return bonuses
		else
			return make_bonuses_table {}
		end
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
