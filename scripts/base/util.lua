dofile("scripts/base/base-lua-functions.lua")
dofile("scripts/base/state.lua")
dofile("scripts/base/kolproxy-core-functions.lua")
dofile("scripts/base/script-functions.lua")
dofile("scripts/base/charpane.lua")
dofile("scripts/base/api.lua")



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
		if x ~= "Results:" and x ~= "Adventure Again:" then
			adventure_title = x:gsub(" %(#[0-9]*%)$", "")
		end
	end
	choice_adventure_number = tonumber(text:match([[<input type=hidden name=whichchoice value=([0-9]+)>]]))
	adventure_result = text:match([[<td style="color: white;" align=center bgcolor=blue.-><b>Adventure Results:</b></td></tr><tr><td style="padding: 5px; border: 1px solid blue;"><center><table><tr><td><center><b>(.-)</b>]])
end

function monstername(name)
	if name then
		return name == monstername()
	end
	if monster_name then
		return monster_name:gsub("^a ", ""):gsub("^an ", ""):gsub("^ ", "")
	end
end









-- -- Should be in other files -- --

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
	if not session["zone.manor.wines needed"] and not session["tried determining wines"] then
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
