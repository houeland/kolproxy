-- the haunted pantry
add_choice_text("Trespasser", { -- choice adventure number: 117
	["Tackle him"] = { text = "Fight Knob Goblin Assistant Chef", good_choice = true },
	["Challenge him to a magical duel"] = "Gain 4-8 mysticality",
	["Wait and see what happens"] = "Get 1-5 starting area items",
})

add_choice_text("The Singing Tree", { -- choice adventure number: 116
	["&quot;Sing a sad song&quot;"] = "Gain 4-5 mysticality",
	["&quot;Sing a happy song&quot;"] = "Gain 4-5 moxie",
	["&quot;Sing whatever you want&quot;"] = "Get 7-8 mysticality or a whiskey and soda",
	["&quot;No singing, thanks.&quot;"] = { leave_noturn = true, good_choice = true },
})

add_choice_text("Oh No, Hobo", { -- choice adventure number: 115
	["Give him a beating"] = { text = "Fight a drunken half-orc hobo", good_choice = true },
	["Give him some Meat"] = "Get Good Karma or nothing",
	["Give him the business"] = "Get 5-10 meat and 3-4 mysticality and 3-4 moxie",
})

add_choice_text("The Baker's Dilemma", { -- choice adventure number: 114
	["&quot;I'll see what I can do.&quot;"] = "Get unlit birthday cake",
	["&quot;Sorry, I'm busy right now.&quot;"] = { leave_noturn = true, good_choice = true },
	["&quot;Hey, what's that over there?&quot;"] = { text = "Gain 4-5 moxie", getmeatmin = 15, getmeatmax = 20 },
})

-- gallery stuff

add_printer("/place.php", function()
	if params.whichplace ~= "spookyraven1" then return end
	local galtext = [[<span style="color: darkorange">Gallery locked</span>]]
	if have_item("Spookyraven gallery key") then
		galtext = [[<span style="color: green">Gallery unlocked</span>]]
	else
		local galkeytext = [[<span style="color: darkorange">Visit library to unlock gallery key</span>]]
		if ascension["zone.conservatory.gallery key"] == "unlocked" then
			galkeytext = [[<span style="color: green">Gallery key available</span>]]
		end
		text = text:gsub([[<div id=sr1_conservatory]], [[<div style="position: absolute; top: 0px; left: 305px; width: 100px; height: 100px;"><table style="height: 100px; vertical-align: middle;"><tr><td>]] .. galkeytext .. [[</td></tr></table></div>%0]])
	end
	text = text:gsub([[<div id=sr1_gallery]], [[<div style="position: absolute; top: 0px; left: -105px; width: 100px; height: 100px;"><table style="width: 100px; height: 100px; vertical-align: middle; text-align: right;"><tr><td>]] .. galtext .. [[</td></tr></table></div>%0]])
end)

-- billiards room

add_ascension_zone_check(105, function()
	if have_item("pool cue") and not have_buff("Chalky Hand") and not have_item("Spookyraven library key") and have_item("handful of hand chalk") then
		return "You need to use hand chalk to get the library key."
	end
end)


-- library

add_printer("/place.php", function()
	if params.whichplace ~= "spookyraven1" then return end
	local libtext = [[<span style="color: darkorange">Visit billiards room to unlock</span>]]
	if have_item("Spookyraven library key") then
		libtext = [[<span style="color: green">Library unlocked</span>]]
	end
	text = text:gsub([[<div id=sr1_library]], [[%1<div style="position: absolute; top: 200px; left: -105px; width: 100px; height: 100px;"><table style="width: 100px; height: 100px; vertical-align: middle; text-align: right;"><tr><td>]] .. libtext .. [[</td></tr></table></div>%0]])
	-- TODO: recheck line below
	text = text:gsub([[(<td width=100 height=100>)(<a href="manor.php%?place=library">.-)(</td>)]], [[%1<div style="position: relative;"><div style="position: absolute; left: -105px; width: 100px; height: 100px;"><table style="width: 100px; height: 100px; vertical-align: middle; text-align: right;"><tr><td>]] .. libtext .. [[</td></tr></table></div>%2</div>%3]])
end)

add_choice_text("Take a Look, it's in a Book!", {
	["Read &quot;The Rise of the House of Spookyraven&quot;"] = { text = "Read stories...", disabled = true },
	["Read &quot;The Better Haunted Homes and Conservatories Cookbook&quot;"] = "Get a random cooking recipe",
	["Read &quot;Ancient Forbidden Unspeakable Evil, a Love Story&quot;"] = "Gain myst or mox or myst spookyraven skill...",
	["Reading is for losers.  I'm outta here."] = { leave_noturn = true },

	["Read &quot;The Fall of the House of Spookyraven&quot;"] = { text = "Read stories...", disabled = true },
	["Read &quot;To Serve Man... Delicious Cocktails&quot;"] = "Get a random mixing recipe",
	["Read &quot;Ancient Forbidden Unspeakable Yoga, a Beginner's Guide&quot;"] = "Gain muscle and take damage",
})

add_choice_text("Naughty, Naughty...", {
	["Read Chapter 1:  Tuesdays with Abhorrent Fiends"] = "Gain myst",
	["Read Chapter 2:  The Nether Planes on 350 Meat a Day"] = "Gain mox",
	["Read Chapter 3:  Twisted, Curdled, Corrupt Energy and You"] = "Gain myst spookyraven skill or take damage",
})

add_choice_text("Melvil Dewey Would Be Ashamed", { -- choice adventure number: 163
	["Hork the gray-bound volume"] = { text = "Get spooky spellbook (sells for 2000 Meat)" },
	["Yoink the green-bound tome"] = { text = "Get stinky spellbook (sells for 2000 Meat)" },
	["Gaffle the purple-bound book"] = { text = "Get sleazy spellbook (sells for 2000 Meat)" },
	["Leave without taking anything"] = { leave_noturn = true },
})

-- bathroom

add_choice_text("Having a Medicine Ball", function() -- choice adventure number: 105
	local tbl = {
		["Gaze deeply into the mirror"] = { text = "Gain mysticality", good_choice = true },
		["Open it and see what's inside"] = { text = "Get item or leave" },
		["Say &quot;Guy made of bees.&quot;"] = { text = string.format("Repeat 5 times to fight The Guy Made Of Bees (%d/5)", get_ascension_counter("spookyraven.bathroom.said guy made of bees")) },
	}
	if get_ascension_counter("spookyraven.bathroom.said guy made of bees") == 4 then
		tbl["Gaze deeply into the mirror"].good_choice = false
		tbl["Say &quot;Guy made of bees.&quot;"].good_choice = true
	end
	return tbl
end)

add_choice_text("Don't Hold a Grudge", { -- choice adventure number: 402
	["Armwrestle it"] = { text = "Gain muscle" },
	["Declare a thumb war"] = { text = "Gain mysticality", good_choice = true },
	["Shake it"] = { text = "Gain moxie" },
})

add_processor("/choice.php", function()
	if text:contains(">You look into the mirror and say &quot;Guy made of bees.&quot;  Nothing happens.<") then
		increase_ascension_counter("spookyraven.bathroom.said guy made of bees")
	end
end)

-- bedroom

add_choice_text("One Mahogany Nightstand", {
	["Check the top drawer"] = function() return (not ascension["spookyraven.halfmemo obtained"]) and "Get either 'half of a memo' or 'old coin purse'" or { getitem = "old coin purse" } end,
	["Check the bottom drawer"] = { text = "Take damage", disabled = true },
	["Look under the nightstand"] = function() return have_equipped_item("Lord Spookyraven's spectacles") and "Start Spookyraven skill quest" or "Need Lord Spookyraven's spectacles equipped" end,
	["Use a ghost key"] = { getmeatmin = 900, getmeatmax = 1100 },
	["Ignore it"] = "Nothing",
})

add_choice_text("One Ornate Nightstand", {
	["Open the top drawer"] = { getmeatmin = 400, getmeatmax = 600 },
	["Open the bottom drawer"] = "Gain 50-200 mysticality",
	["Look behind the nightstand"] = function() return not have_item("Lord Spookyraven's spectacles") and { text = "Get spectacles", good_choice = true } or { text = "Nothing", disabled = true } end,
	["Look under the nightstand"] = function() return { getitem = "disposable instant camera", good_choice = not have_item("disposable instant camera") } end,
	["Use a ghost key"] = "Gain 200 mysticality",
	["Ignore it"] = "Nothing",
})

add_choice_text("One Rustic Nightstand", {
	["Check the top drawer"] = "Gain 50-200 moxie",
	["Check the bottom drawer"] = "Get grouchy restless spirit or nothing",
	["Investigate the jewelry"] = "Fight remains of a jilted mistress",
	["Use a ghost key"] = "Gain 200 moxie",
	["Ignore it"] = "Nothing",
})

add_choice_text("One Elegant Nightstand", {
	["Open the single drawer"] = function() return (ascension["spookyraven.bedroom.gown obtained"]) and "Nothing" or { text = "Get quest item", good_choice = true } end,
	["Break a leg (off of the nightstand)"] = { getitem = "elegant nightstick" },
	["Use a ghost key"] = "Gain 100 all stats",
	["Ignore it"] = "Nothing",
})

add_choice_text("One Simple Nightstand", {
	["Check the top drawer"] = { getitem = "old leather wallet" },
	["Check the bottom drawer"] = "Gain 50-200 muscle",
	["Use a ghost key"] = "Gain 200 muscle",
	["Ignore it"] = "Nothing",
})

add_processor("/choice.php", function()
	if text:contains("You open the elegant drawer of the elegant nightstand") or text:contains("ephemeral elegance residue") then
		ascension["spookyraven.bedroom.gown obtained"] = true
	elseif (text:contains("You open the drawer and find a scrap of paper") or have_item("half of a memo")) then
		ascension["spookyraven.halfmemo obtained"] = true
	end
end)

-- ballroom

add_choice_text("Strung-Up Quartet", {
	["&quot;Play 'Provare Compasione Per El Sciocco'&quot;"] = "Set song to +5 ML",
	["&quot;Play 'Sono Un Amanten Non Un Combattente'&quot;"] = "Set song to +5% non-combats",
	["&quot;Play 'Le Mie Cose Favorite'&quot;"] = "Set song to +5% items",
	["&quot;Play nothing, please.&quot;"] = "Disable song (does not cost an adventure)",
})

add_choice_text("Curtains", {
	["Investigate the organ"] = "Fight an organist or get moxie spookyraven skill",
	["Watch the dancers"] = "Gain moxie",
	["Pay no attention to the stuff in front of the curtain"] = { leave_noturn = true },
})

add_itemdrop_counter("dance card", function(c)
	return "{ " .. make_plural(c, "dance card", "dance cards") .. " in inventory. }"
end)

add_processor("use item: dance card", function()
	if text:contains("You pencil your name in on the last line of the dance card, and it evaporates in a puff of ectoplasm.") then
		dance_turn = turnsthisrun() + 3
		ascension["dance card turn"] = dance_turn
	end
end)

local function get_dance_card_data()
	local dance_card_turn = tonumber(ascension["dance card turn"])
	if dance_card_turn then
		local turnsleft = dance_card_turn - turnsthisrun()
		if turnsleft >= 0 then
			color = nil
			link = nil
			if turnsleft == 0 then
				color = "green"
				link = "adventure.php?snarfblat=" .. get_zoneid("The Haunted Ballroom")
			end
			return { name = "Dance card", value = turnsleft, color = color, link = link }
		end
	end
end

add_counter_effect(function()
	local data = get_dance_card_data()
	if data then
		return { title = "Dance card", duration = data.value, imgname = "guildapp", group = "effect" }
	end
end)

add_charpane_line(function()
	if setting_enabled("display counters as effects") then return end
	return get_dance_card_data()
end)

add_always_adventure_warning(function(zoneid)
	if tonumber(ascension["dance card turn"]) == turnsthisrun() then
		if zoneid ~= get_zoneid("The Haunted Ballroom") then
			return "Next turn is a possible dance in the ballroom", "dance card-wrong zone"
		elseif have_item("ten-leaf clover") then
			return "Your ten-leaf clover will override the ballroom dance.", "dance card-clover"
		end
	end
end)

-- gallery
add_choice_text("Out in the Garden", { -- choice adventure number: 89
	["The first knight"] = "Get SC skill / fight knight (+spooky damage)",
	["The second knight"] = "Get TT skill / <b>fight knight (+ML)</b>",
	["The two maidens"] = "Get Dreams and Lights or lose HP",
	["None of the above"] = { text = "Leave (does not cost an adventure, and removes Out in the Garden encounter for 10 adventures)", good_choice = true },
})

add_processor("/choice.php", function()
	if text:contains("You wander off in search of some more modern art to talk to") then
		ascension["zone.gallery.out in the garden banish"] = turnsthisrun() + 10
	end
end)

add_charpane_line(function()
	local banish_turn = ascension["zone.gallery.out in the garden banish"]
	if banish_turn then
		local turns = banish_turn - turnsthisrun()
		if turns > 0 then
			return { name = "Garden", value = turns, tooltip = "Out in the Garden encounter temporarily banished from The Haunted Gallery" }
		end
	end
end)

local lastlouvre = nil

-- louvre
add_processor("/choice.php", function()
	if (adventure_title or ""):contains("Louvre It or Leave It") then
-- 		print("louvre", choice_adventure_number, table_to_str(params))
		whichchoice = params.whichchoice
		option = params.option
		if whichchoice == "" then whichchoice = nil else whichchoice = tonumber(whichchoice) end
		if option == "" then option = nil else option = tonumber(option) end
		if choice_adventure_number and whichchoice and option then
			if choice_adventure_number ~= 91 then -- TODO: Hmm, bit hardcoded, check for some text instead?
				ascension["louvre.adventure." .. whichchoice .. ".choice." .. option] = "choice " .. choice_adventure_number
			end
		end
		lastlouvre = choice_adventure_number
	else
-- 		print("not-louvre", choice_adventure_number, table_to_str(params), "|" .. tostring(adventure_title) .. "|")
-- 		print("lastlouvre", lastlouvre, type(lastlouvre))
		if lastlouvre then
			whichchoice = tonumber(params.whichchoice)
			option = tonumber(params.option)
-- 			print("which, opt", whichchoice, option, type(whichchoice))
			if whichchoice and option and tostring(lastlouvre) == tostring(whichchoice) then
-- 				print("louvre-result", choice_adventure_number, table_to_str(params), adventure_title)
				results = {}
				results["&quot;Hey, Wayne,&quot; he replies."] = "Muscle"
				results["the scene fills you with new insight as to the nature of the universe"] = "Mysticality"
				results["only playing for dog biscuits"] = "Moxie"
				results["Nothing better than a picnic on a bright summer day such as this"] = "Manetwich"
				results["a burly bearded guy in a wifebeater and straw hat gives you a funny look"] = "bottle of Pinot Renoir"
				results["bed and inspect the awkwardly slanted nightstand"] = "bottle of Vangoghbitussin"
				for a, b in pairs(results) do
					if text:contains(a) then
						ascension["louvre.adventure." .. whichchoice .. ".choice." .. option] = "result " .. b
-- 						print("setting result", whichchoice, option, "result", b)
					end
				end
			end
		end
	end
end)

function compute_louvre_paths(fromchoice)
	found = {}
	reached = {}
	available = {}
	available[fromchoice] = -1000
	for i = 1, 1000 do
		old_available = available
		available = {}
		found_any = false
		for choicenum, source in pairs(old_available) do
			found_any = true
			reached[choicenum] = source
			for initialc = 1, 3 do
				initialto = ascension["louvre.adventure." .. choicenum .. ".choice." .. initialc]
				if initialto then
					tochoice = tonumber(initialto:match("^choice ([0-9]+)$"))
					toresult = initialto:match("^result (.+)$")
					if tochoice then
						if not reached[tochoice] and not available[tochoice] then
							available[tochoice] = { whichchoice = choicenum, option = initialc }
						end
					end
					if toresult then
						if not found[toresult] then
							found[toresult] = { whichchoice = choicenum, option = initialc }
						end
					end
				end
			end
		end
		if not found_any then
			break
		end
	end
	return found, reached
end

local function create_D_value()
	local D = {}
	for id = 92, 104 do
		for option = 1, 3 do
			local r = ascension["louvre.adventure." .. id .. ".choice." .. option]
			if r then
				for c = 92, 104 do
					if r == "choice " .. c then
						table.insert(D, { choiceid = id, branch = option, result = c })
					end
				end
				for i in table.values { "Muscle", "Mysticality", "Moxie", "bottle of Pinot Renoir", "bottle of Vangoghbitussin", "Manetwich" } do
					if r:contains("result") and r:lower():contains(i:lower()) then
						table.insert(D, { choiceid = id, branch = option, result = i })
					end
				end
			end
		end
	end
	return D
end

function louvre_automate_looking_for_muscle(pwd)
	local function pickopt(whichchoice)
		if not whichchoice then
		elseif whichchoice == 91 then
			return 1
		elseif whichchoice >= 92 and whichchoice <= 104 then
			local D = create_D_value()
			return louvre_policy_escherval(0.5)(whichchoice, D)
		end
	end
	local pt, pturl = get_page("/choice.php")
	for timeout = 1, 100 do
		whichchoice = tonumber(pt:match([[<input type=hidden name=whichchoice value=([0-9]+)>]]))
		local opt = pickopt(whichchoice)
		if whichchoice and opt then
			pt, pturl = post_page("/choice.php", { pwd = pwd, whichchoice = whichchoice, option = opt })
		end
	end
	return pt, pturl
end

local automate_looking_for_muscle_href = add_automation_script("automate-louvre-looking-for-muscle", function()
	return louvre_automate_looking_for_muscle(params.pwd)
end)

local function get_louvre_automation_links()
	found, reached = compute_louvre_paths(choice_adventure_number)
	choice_tbl = {}
	for result, source in pairs(found) do
		function trace(source, tbl)
			if source == -1000 then
				return {}
			else
				tbl = trace(reached[source.whichchoice])
				table.insert(tbl, source)
				return tbl
			end
		end
		local t = trace(source)
		choice_string = text:match([[<input type=hidden name=whichchoice value=]] .. choice_adventure_number .. [[><input type=hidden name=option value=]] .. t[1].option .. [[><input class=button type=submit value="([^"]+)">]])
		if not choice_tbl[choice_string] then
			choice_tbl[choice_string] = {}
		end
		local tparams = {}
		tparams.pwd = text:match([[<input type=hidden name=pwd value='([0-9a-f]+)'>]])
		for a, b in pairs(t) do
			tparams[string.format("choice%d", a)] = string.format("%d-%d", b.whichchoice, b.option)
		end
		local pwd = text:match([[<input type=hidden name=pwd value='([0-9a-f]+)'>]])
		if result == "Gain muscle" then
			result = "<b>" .. result .. "</b>"
		elseif result == "Muscle" then
			have_muscle_result = true
		end
		table.insert(choice_tbl[choice_string], [[<a href="]]..automate_noncombat_href(tparams)..[[" style="color: green">]] .. result .. [[</a>]])
	end
	if not found["Muscle"] then
		if not choice_tbl["Enter the drawing"] then
			choice_tbl["Enter the drawing"] = {}
		end
		table.insert(choice_tbl["Enter the drawing"], [[<a href="]]..automate_looking_for_muscle_href { pwd = session.pwd }..[[" style="color: green">Automate looking for muscle</a>]])
	end
	for a, b in pairs(choice_tbl) do
		choice_tbl[a] = table.concat(b, ", ")
	end
	return choice_tbl
end

add_choice_text("Louvre It or Leave It ", function()
	if not choice_adventure_number then return end
	if choice_adventure_number == 91 then
		local tbl = get_louvre_automation_links()
		local extratext = ""
		if tbl["Enter the drawing"] then
			extratext = [[<br><span style="color: green">{ Get: ]] .. tbl["Enter the drawing"] .. [[ }</span>]]
		end
		return {
			["Enter the drawing"] = { text = "Go to Louvre start (Relativity)" .. extratext, good_choice = true },
			["Pass on by"] = { leave_noturn = true },
		}
	end
	local D = create_D_value()
	local probabilities = predict_louvre(choice_adventure_number, D)
	local function display_probabilities(p)
--		print(p)
		local descriptions = {
			[92] = "Entrance",
			[93] = "Entrance",
			[94] = "Entrance",
			[95] = "Entrance",
			[96] = "Moxious Mondrian",
			[97] = "Muscular Scream",
			[98] = "Mystical Venus",
			[99] = "Moxious Adam",
			[100] = "Moxious Socrates",
			[101] = "Muscular Nighthawks",
			[102] = "Muscular Sunday Afternoon",
			[103] = "Mystical Supper",
			[104] = "Mystical Memory",
			["Muscle"] = "Gain muscle",
			["Mysticality"] = "Gain mysticality",
			["Moxie"] = "Gain moxie",
			["bottle of Pinot Renoir"] = "Get bottle of Pinot Renoir",
			["bottle of Vangoghbitussin"] = "Get bottle of Vangoghbitussin",
			["Manetwich"] = "Get Manetwich",
		}
		local p_display = {}
		local p_display_order = {}
		for a, b in pairs(p) do
			if b > 0 then
				local desc = descriptions[a]
				if not p_display[desc] then
					p_display[desc] = 0
					table.insert(p_display_order, desc)
				end
				p_display[desc] = p_display[desc] + b
			end
		end
		table.sort(p_display_order, function(a, b)
			return p_display[a] > p_display[b]
		end)
		local display_tbl = {}
		for x in table.values(p_display_order) do
			if p_display[x] > 0.999999 then
				table.insert(display_tbl, x)
			else
				table.insert(display_tbl, string.format("%s (%.1f%%)", x, p_display[x] * 100))
			end
		end
		return table.concat(display_tbl, ", ")
	end
	return {
		["Take the stairs up"] = display_probabilities(probabilities[1]),
		["Take the stairs down"] = display_probabilities(probabilities[2]),
		["Take the stairs sideways"] = display_probabilities(probabilities[3]),
	}
end)

add_printer("/choice.php", function()
	if (adventure_title or ""):contains("Louvre It or Leave It") then
		text = text:gsub([[</head>]], [[
<style type="text/css">
.kolproxy_louvremapimage span { position: relative; }
span .fullmap { position: absolute; display: none; }
.kolproxy_louvremapimage span:hover .fullmap { top: -100px; left: -200px; width: 500px; height: 500px; border: 2px solid; display: inline; }
</style>
%0]])
		text = text:gsub([[<img src="http://images.kingdomofloathing.com/adventureimages/gp[^.]*.gif" width=100 height=100>]], [[<div class="kolproxy_louvremapimage"><span>%0<img src="http://i224.photobucket.com/albums/dd259/abeaS_oyR/kollouvre.jpg" class="fullmap" width="300" height="300"><br><a href="http://kol.coldfront.net/thekolwiki/index.php/Louvre_Map" target="_blank" style="color: green">{ Show map }</a></span></div>]])
	end
end)

add_processor("/choice.php", function()
	if text:contains("As you open the top drawer, you hear a clinking sound from deeper inside the nightstand.") or text:contains("In the top drawer of the nightstand, you find a paperback of the") then
		ascension["zone.manor.unlocked ballroom key"] = "yes"
	end
end)

add_processor("/choice.php", function()
	if text:contains("The quartet begins to play a lively, saucy song.") then
		ascension["zone.manor.quartet song"] = "Provare Compasione Per El Sciocco"
	elseif text:contains("The quartet begins to play a mellow, relaxing tune.") then
		ascension["zone.manor.quartet song"] = "Sono Un Amante Non Un Combattente"
	elseif text:contains("The quartet begins to play a lovely waltz, fast but not too fast.") then
		ascension["zone.manor.quartet song"] = "Le Mie Cose Favorite"
	elseif text:contains("I'm not really in the mood for any music") and text:contains("Maybe later") then
		ascension["zone.manor.quartet song"] = nil
	elseif text:contains("Maybe you guys should take a break") and text:contains("stretch your necks") then
		ascension["zone.manor.quartet song"] = nil
	end
	if text:contains("&quot;Just keep playing what you've been playing.&quot;") then
		if tonumber(params.option) == 1 then
			ascension["zone.manor.quartet song"] = "Provare Compasione Per El Sciocco"
		elseif tonumber(params.option) == 2 then
			ascension["zone.manor.quartet song"] = "Sono Un Amante Non Un Combattente"
		elseif tonumber(params.option) == 3 then
			ascension["zone.manor.quartet song"] = "Le Mie Cose Favorite"
		end
	end
end)

add_processor("/fight.php", function()
	local music_songs = {
		lively = "Provare Compasione Per El Sciocco",
		mellow = "Sono Un Amante Non Un Combattente",
		lovely = "Le Mie Cose Favorite",
	}
	local music = text:match(">You hear strains of ([a-z]*) music in the distance.<")
	if music and music_songs[music] then
		print("INFO: Quartet song fight message:", music, "->", music_songs[music])
		ascension["zone.manor.quartet song"] = music_songs[music]
	end
end)

add_printer("/manor2.php", function()
	brtext = [[<span style="color: darkorange">Visit bedroom to unlock</span>]]
	if have_item("Spookyraven ballroom key") then
		songspoilers = {
			["Provare Compasione Per El Sciocco"] = "+5 ML",
			["Sono Un Amante Non Un Combattente"] = "-5%% combat",
			["Le Mie Cose Favorite"] = "+5%% item",
		}
		song = ascension["zone.manor.quartet song"]
		brtext = [[<span style="color: green">Quartet not playing</span>]]
		if song then
			brtext = [[<span style="color: green">Quartet playing: ]]..songspoilers[song]..[[</span>]]
		end
	end
	text = text:gsub([[(<td rowspan=2 width=100 height=200>)(<a href="adventure.php%?snarfblat=109">.-)(</td>)]], [[%1<div style="position: relative;"><div style="position: absolute; left: 105px; width: 100px; height: 100px;"><table style="height: 100px; vertical-align: middle;"><tr><td>]] .. brtext .. [[</td></tr></table></div>%2</div>%3]], 1)
end)
