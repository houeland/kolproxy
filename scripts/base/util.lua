dofile("scripts/base/util/base-lua-functions.lua")
dofile("scripts/base/util/state.lua")
dofile("scripts/base/util/kolproxy-core-functions.lua")
dofile("scripts/base/util/script-functions.lua")
dofile("scripts/base/util/charpane.lua")
dofile("scripts/base/util/api.lua")



-- TODO: redo the rest of this code
function setup_variables()
	if path == "/charpane.php" then
	elseif path == "/kolproxy-quick-charpane-normal" or path == "/kolproxy-quick-charpane-compact" then
		using_kolproxy_quick_charpane = true
		kolproxy_custom_charpane_mode = "normal"
		if path == "/kolproxy-quick-charpane-compact" then
			kolproxy_custom_charpane_mode = "compact"
		end
		path = "/charpane.php" -- TODO: hack!
	end

	if path == "/fight.php" then
		monster_name = text:match("<span id='monname'>(.-)</span>")
		adventure_zone = tonumber(fight.zone)
		if not query:contains("ireallymeanit") then
			encounter_source = "other"
		elseif text:contains("hear a wolf whistle from behind you") then
			encounter_source = "Obtuse Angel"
		elseif text:contains("<td bgcolor=black align=center><font color=white size=1>") then
			encounter_source = "Mini-Hipster"
		elseif monster_name:contains("Black Crayon") then
			encounter_source = "Artistic Goth Kid"
		else
			encounter_source = "adventure"
		end
	end

	for x in text:gmatch([[<tr><td style="color: white;" align=center bgcolor=blue.-><b>([^<]*)</b></td></tr>]]) do
		if x ~= "Results:" then
			adventure_title = x
		end
	end
	choice_adventure_number = tonumber(text:match([[<input type=hidden name=whichchoice value=([0-9]+)>]]))
	adventure_result = text:match([[<td style="color: white;" align=center bgcolor=blue.-><b>Adventure Results:</b></td></tr><tr><td style="padding: 5px; border: 1px solid blue;"><center><table><tr><td><center><b>([^<]*)</b>]])
end











-- -- Should be in other files -- --

function faxbot_monsterlist()
	local popular_names = {
		"Bad ASCII Art",
		"Blooper",
		"dirty thieving brigand",
		"ghost",
		"Knob Goblin Elite Guard Captain",
		"lobsterfrogman",
		"rampaging adding machine",
		"sleepy mariachi",
	}
	local category_order = {
		"Most Popular",
		"Sorceress's Quest",
		"Misc Ascension",
		"Misc Aftercore",
		"Bounty Targets",
		"Crimbo 2009",
		"Crimbo 2010",
		"Rock Event",
		"Bigg's Dig",
		"The Shivering Timbers",
		"Skeleton Invasion",
		"Talk Like A Pirate Day",
		"Featured Butts",
	}
	local category_contents = {}
	for x in table.values(category_order) do
		category_contents[x] = {}
	end
	local count_names = {}
	for _, x in ipairs(get_faxbot_monsterlist()) do
		count_names[x.name] = (count_names[x.name] or 0) + 1
	end
	for _, x in ipairs(get_faxbot_monsterlist()) do
		if not category_contents[x.category] then
			category_contents[x.category] = {}
			table.insert(category_order, x.category)
		end
		local newx = nil
		if count_names[x.name] == 1 then
			newx = { name = x.name, command = x.command }
		else
			newx = { name = x.description, command = x.command }
		end
		table.insert(category_contents[x.category], newx)
		for z in table.values(popular_names) do
			if z == x.name then
				table.insert(category_contents["Most Popular"], newx)
			end
		end
	end
	for x in table.values(category_contents) do
		table.sort(x, function(a, b)
			return a.name:lower() < b.name:lower()
		end)
	end
	return category_contents, category_order
end


dod_potion_types = {
	"bubbly potion",
	"cloudy potion",
	"dark potion",
	"effervescent potion",
	"fizzy potion",
	"milky potion",
	"murky potion",
	"smoky potion",
	"swirly potion",
}

dod_potion_effects = {
	"acuity",
	"blessing",
	"booze",
	"confusion",
	"detection",
	"healing",
	"sleep",
	"strength",
	"teleportation",
}

function get_dod_potion_status()
	local tbl = ascension["zone.dod.potions"] or {}
	unknown_potions = {}
	for pot in table.values(dod_potion_types) do
		if not tbl[pot] then
			table.insert(unknown_potions, pot)
		end
	end

	found = {}
	for pot, eff in pairs(tbl) do
		found[eff] = pot
	end

	unknown_effects = {}
	for eff in table.values(dod_potion_effects) do
		if not found[eff] then
			table.insert(unknown_effects, eff)
		end
	end

	if table.maxn(unknown_effects) == 1 and table.maxn(unknown_potions) == 1 then -- only one missing effect and one missing potion
		tbl[unknown_potions[1]] = unknown_effects[1]
		return tbl, {}, {}
	else
		return tbl, unknown_potions, unknown_effects
	end
end










local function get_wine_cellar_permutations_and_quadrants(tbl)
	local quadrants = {
		{ ["dusty bottle of Marsala"] = true, ["dusty bottle of Merlot"] = true, ["dusty bottle of Muscat"] = true }, -- 1
		{ ["dusty bottle of Marsala"] = true, ["dusty bottle of Pinot Noir"] = true, ["dusty bottle of Zinfandel"] = true }, -- 2
		{ ["dusty bottle of Merlot"] = true, ["dusty bottle of Pinot Noir"] = true, ["dusty bottle of Port"] = true }, -- 3
		{ ["dusty bottle of Muscat"] = true, ["dusty bottle of Port"] = true, ["dusty bottle of Zinfandel"] = true }, -- 4
	}

	local permutations = {
		{ [178] = 1, [179] = 2, [180] = 3, [181] = 4 }, -- 1
		{ [178] = 1, [179] = 2, [180] = 4, [181] = 3 }, -- 2
		{ [178] = 1, [179] = 3, [180] = 2, [181] = 4 }, -- 3
		{ [178] = 1, [179] = 3, [180] = 4, [181] = 2 }, -- 4
		{ [178] = 1, [179] = 4, [180] = 2, [181] = 3 }, -- 5
		{ [178] = 1, [179] = 4, [180] = 3, [181] = 2 }, -- 6
		{ [178] = 2, [179] = 1, [180] = 3, [181] = 4 }, -- 7
		{ [178] = 2, [179] = 1, [180] = 4, [181] = 3 }, -- 8
		{ [178] = 2, [179] = 3, [180] = 1, [181] = 4 }, -- 9
		{ [178] = 2, [179] = 3, [180] = 4, [181] = 1 }, -- 10
		{ [178] = 2, [179] = 4, [180] = 1, [181] = 3 }, -- 11
		{ [178] = 2, [179] = 4, [180] = 3, [181] = 1 }, -- 12
		{ [178] = 3, [179] = 1, [180] = 2, [181] = 4 }, -- 13
		{ [178] = 3, [179] = 1, [180] = 4, [181] = 2 }, -- 14
		{ [178] = 3, [179] = 2, [180] = 1, [181] = 4 }, -- 15
		{ [178] = 3, [179] = 2, [180] = 4, [181] = 1 }, -- 16
		{ [178] = 3, [179] = 4, [180] = 1, [181] = 2 }, -- 17
		{ [178] = 3, [179] = 4, [180] = 2, [181] = 1 }, -- 18
		{ [178] = 4, [179] = 1, [180] = 2, [181] = 3 }, -- 19
		{ [178] = 4, [179] = 1, [180] = 3, [181] = 2 }, -- 20
		{ [178] = 4, [179] = 2, [180] = 1, [181] = 3 }, -- 21
		{ [178] = 4, [179] = 2, [180] = 3, [181] = 1 }, -- 22
		{ [178] = 4, [179] = 3, [180] = 1, [181] = 2 }, -- 23
		{ [178] = 4, [179] = 3, [180] = 2, [181] = 1 }, -- 24
	}

	for z, ztbl in pairs(tbl) do -- remove invalid permutations
		for name, _ in pairs(ztbl) do
			for i = 1, 24 do
				if permutations[i] then
					local qid = permutations[i][z]
					if not quadrants[qid][name] then
						permutations[i] = nil
					end
				end
			end
		end
	end
	return permutations, quadrants
end

function get_wine_cellar_data(known_tbl)
	local permutations, quadrants = get_wine_cellar_permutations_and_quadrants(known_tbl)

	local wines = {}
	local valid_permutations = 0

	for ptbl in table.values(permutations) do
		for z, qid in pairs(ptbl) do
			for name, _ in pairs(quadrants[qid]) do
				if not wines[z] then wines[z] = {} end
				wines[z][name] = (wines[z][name] or 0) + 1
			end
		end
		valid_permutations = valid_permutations + 1
	end
	return wines, valid_permutations
end



function determine_cellar_wines()
	if not ascension["zone.manor.wines needed"] and not session["tried determining wines"] then
		async_get_page("/desc_item.php", { whichitem = "278847834" })
		async_get_page("/desc_item.php", { whichitem = "163456429" })
		async_get_page("/desc_item.php", { whichitem = "147519269" })
		async_get_page("/desc_item.php", { whichitem = "905945394" })
		async_get_page("/desc_item.php", { whichitem = "289748376" })
		async_get_page("/desc_item.php", { whichitem = "625138517" })
		local goblet = get_page("/manor3.php", { place = "goblet" })
		session["tried determining wines"] = "yes"
		return goblet
	end
end

function automate_tiles()
	local function choose(tile)
		return async_post_page("/tiles.php", { action = "jump", whichtile = tile })
	end
	choose(4)
	choose(6)
	choose(3)
	choose(5)
	choose(7)
	choose(6)
	return choose(3)()
end
