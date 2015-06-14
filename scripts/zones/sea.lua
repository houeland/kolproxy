-- The Dive Bar

add_processor("/choice.php", function()
	if text:contains("You head down the tunnel into the cave, and manage to find another seaode.  Sweet!  I mean... salty!") then
		increase_daily_counter("zone.The Dive Bar.seaodes")
	end
end)

add_printer("/choice.php", function()
	if text:contains("You head down the tunnel into the cave, and manage to find another seaode.  Sweet!  I mean... salty!") then
		seaodes = get_daily_counter("zone.The Dive Bar.seaodes")
		text = text:gsub("(You head down the tunnel into the cave, and manage to find another seaode.  Sweet!  I mean... salty!)", [[<span style="color: darkorange">%1</span> (]]..seaodes.." / 3 seaodes today)")
	end
end)

-- Outpost

add_processor("item drop: Mer-kin lockkey", function()
	print("Mer-kin lockkey dropped from", get_monstername())
	ascension["zones.sea.outpost lockkey monster"] = get_monstername()
end)

add_printer("/seafloor.php", function()
	if ascension["zones.sea.outpost lockkey monster"] then
		if text:contains("currents") then
			text = text:gsub([[</body>]], [[<center style="color: gray">]] .. "Mer-kin lockkey dropped by: " .. tostring(ascension["zones.sea.outpost lockkey monster"]) .. [[ (already opened stashbox)</center>%0]])
		else
			text = text:gsub([[</body>]], [[<center style="color: green">]] .. "Mer-kin lockkey dropped by: " .. tostring(ascension["zones.sea.outpost lockkey monster"]) .. [[</center>%0]])
		end
	end
end)

-- deepcity

local function learn_dreadscroll_word(word, source)
	if word then
		local words = ascension["zones.sea.dreadscroll words"] or {}
		words[source] = word
		print("INFO: learning dreadscroll word: " .. word .. " from source " .. tostring(source))
		ascension["zones.sea.dreadscroll words"] = words
	end
end

add_processor("/fight.php", function()
	local healword = text:match("tentacles squirming along the ocean floor, a magnificent <b>(.-)</b>, smiling warmly in the distance")
	local killword = text:match("You actually <i>did</i> recognize one of them: <b>&quot;(.-)&quot;</b>.")
	learn_dreadscroll_word(healword, "Mer-kin healscroll")
	learn_dreadscroll_word(killword, "Mer-kin killscroll")
end)

add_processor("/choice.php", function()
	local creature = text:match("a lot of references to <b>(.-)</b> creatures")
	local phrase = text:match("consists of the phrase <b>(.-)</b> over and over")
	local scrawl = text:match("somebody has scrawled &quot;<b>(.-)</b>&quot; on the inside of the front cover")
	learn_dreadscroll_word(creature, "Noncombat creature")
	learn_dreadscroll_word(phrase, "Noncombat phrase")
	learn_dreadscroll_word(scrawl, "Noncombat scrawl")
end)

add_processor("/runskillz.php", function()
	if text:contains("close your eyes and let Deep visions wash over you") then
		local substr = text:match("close your eyes and let Deep visions wash over you.-center>") or ""
		local house = substr:match("<b>(.-)</b>")
		learn_dreadscroll_word(house, "Vision house")
	end
end)

-- TODO: change to "use item: ..."
add_processor("/inv_use.php", function()
	if text:contains("You roll the bone, over and over, and every time it hits the ground, it bounces straight") then
		local substr = text:match("You roll the bone, over and over, and every time it hits the ground, it bounces straight .+ You get so weirded out") or ""
		local direction = substr:match("<b>(.-)</b>")
		learn_dreadscroll_word(direction, "Direction")
	end
end)

add_printer("/choice.php", function()
	if text:contains("You unroll the dreadscroll and look it over") then
		-- TODO: fill in choices
		local lines = {}
		local order = { "Noncombat scrawl", "Mer-kin healscroll", "Vision house", "Direction", "Mer-kin killscroll", "Noncombat creature", "worktea", "Noncombat phrase" }
		local words = ascension["zones.sea.dreadscroll words"] or {}
		for _, name in ipairs(order) do
			if words[name] then
				table.insert(lines, string.format([[%s: <b>%s</b>]], name, words[name]))
			end
		end
		text = text:gsub("</body>", [[<center style="color: green">]] .. table.concat(lines, "<br>") .. [[</center>%0]])
	end
end)

-- temple

add_extra_always_warning("/sea_merkin.php", function()
	if params.action == "temple" and have_equipped_item("Mer-kin scholar mask") and have_equipped_item("Mer-kin scholar tailpiece") then
		if count_equipped_item("Mer-kin prayerbeads") < 3 then
			return "You may want to wear 3 Mer-kin prayerbeads for the Yog-Urt fight.", "equip 3 prayerbeads for yog-urt"
		end
	end
end)

function solve_dad_sea_monkee_puzzle(text)
	local rounds = {}

	local clue1, clue2, clue3, clue4and5, clue6, clue7 = text:match(" ([A-Za-z]+) forms ([A-Za-z]+) in the darkness, each more ([A-Za-z]+) than the last. ([A-Za-z ]+), ([A-Za-z]+) revealing ([0-9]+)%-dimensional monstrosities.")
	local clue8, clue9, clue10 = text:match("your ([A-Za-z ]-) betraying you%? As if on cue, ([0-9]+)%-sided triangles materialize and then disappear. So impossible that your ([A-Za-z]+) throbs.")
	local clue4, clue5
	if clue4and5 then
		local first = clue4and5:match("^([A-Za-z]+)")
		if first == "The" then
			clue4, clue5 = clue4and5:match("(The [A-Za-z]+) ([A-Za-z]+)")
		else
			clue4, clue5 = clue4and5:match("([A-Za-z]+) ([A-Za-z]+)")
		end
	end
	clue7 = tonumber(clue7)
	clue9 = tonumber(clue9)
	print("DEBUG", tostring { clue1 = clue1, clue2 = clue2, clue3 = clue3, clue4 = clue4, clue5 = clue5, clue6 = clue6, clue7 = clue7, clue8 = clue8, clue9 = clue9, clue10 = clue10 })
	if clue1 and clue2 and clue3 and clue4 and clue5 and clue6 and clue7 and clue8 and clue9 and clue10 then
		--print("DEBUG: Got all dad sea monkee clues!")
	end

	local clue1tbl = {
		Chaoatic = "Hot",
		Horrifying = "Spooky",
		Pulpy = "Physical",
		Rigid = "Cold",
		Rotting = "Stench",
		Slimy = "Sleaze",
	}
	rounds[1] = clue1tbl[clue1]

	local clue2tbl = {
		float = "Spooky",
		ooze = "Stench",
		shamble = "Cold",
		skitter = "Hot",
		swim = "Physical",
		slither = "Sleaze",
	}
	rounds[2] = clue2tbl[clue2]

	local clue3tbl = {
		awful = "Cold",
		bloated = "Sleaze",
		curious = "Physical",
		frightening = "Spooky",
		putrescent = "Stench",
		terrible = "Hot",
	}
	rounds[3] = clue3tbl[clue3]

	local clue4tbl = {
		["Space"] = "Cold",
		["The blackness"] = "Hot",
		["The darkness"] = "Spooky",
		["The emptiness"] = "Sleaze",
		["The portal"] = "Physical",
		["The void"] = "Stench",
	}
	rounds[5] = clue4tbl[clue4]

	local clue5tbl = {
		cracks = "Physical",
		shakes = "Spooky",
		shifts = "Cold",
		shimmers = "Stench",
		warps = "Hot",
		wobbles = "Sleaze",
	}
	rounds[4] = clue5tbl[clue5]

	local element_values = {
		Hot = 1,
		Cold = 2,
		Stench = 3,
		Spooky = 4,
		Sleaze = 5,
		Physical = 6,
	}
	for e1, v1 in pairs(element_values) do
		for e2, v2 in pairs(element_values) do
			if v1 <= v2 and clue7 and (2 ^ v1 + 2 ^ v2) / 2 == clue7 then
				if clue6 == "suddenly" then
					rounds[6] = e1
					rounds[7] = e2
				elseif clue6 == "slowly" then
					rounds[6] = e2
					rounds[7] = e1
				end
			end
		end
	end

	local clue8_values = {
		brain = 2,
		mind = 3,
		reason = 4,
		sanity = 5,
		["grasp on reality"] = 6,
		["sixth sense"] = 7,
		eyes = 8,
		thoughts = 9,
		senses = 10,
		memories = 11,
		fears = 12,
	}
	for e, v in pairs(element_values) do
		if rounds[1] and v + element_values[rounds[1]] == clue8_values[clue8] then
			rounds[8] = e
		end
	end

	if rounds[2] and rounds[3] and rounds[4] and rounds[5] then
		for e, v in pairs(element_values) do
			if element_values[rounds[2]] + element_values[rounds[3]] + element_values[rounds[4]] + element_values[rounds[5]] - v + 4 == clue9 then
				rounds[9] = e
			end
		end
	end

	local clue10_values = {
		spleen = 1,
		stomach = 2,
		skull = 3,
		forehead = 4,
		brain = 5,
		mind = 6,
		heart = 7,
		throat = 8,
		chest = 9,
		head = 10,
	}
	if clue10 == "head" then
		local counts = {}
		for i = 1, 9 do
			if rounds[i] then
				counts[rounds[i]] = (counts[rounds[i]] or 0) + 1
			end
		end
		local candidates = {}
		for e, _ in pairs(element_values) do
			if (counts[e] or 0) == 0 then
				table.insert(candidates, e)
			end
		end
		if candidates[1] and not candidates[2] then
			rounds[10] = candidates[1]
		end
	else
		rounds[10] = rounds[clue10_values[clue10]]
	end

	local strrounds = {}
	for a, b in pairs(rounds) do
		strrounds[tostring(a)] = b
	end
	return strrounds
end

add_processor("/fight.php", function()
	if text:contains("Dad Sea Monkee") and text:contains("The room is the machine occupies the room contains the machine") then
		local rounds = solve_dad_sea_monkee_puzzle(text)
		print("INFO: Dad Sea Monkee rounds: ", rounds)
		fight["zone.sea.dad sea monkee rounds"] = rounds
	end
end)

add_printer("/fight.php", function()
	local combat_round = nil
	for x in text:gmatch("var onturn = ([0-9]+);") do
		combat_round = tonumber(x)
	end
	if combat_round then
		local rounds = fight["zone.sea.dad sea monkee rounds"] or {}
		local got_all_rounds = true
		for i = 1, 10 do
			if not rounds[tostring(i)] then
				got_all_rounds = false
			end
		end
		local elem = rounds[tostring(combat_round)]
		if elem then
			local want_spells = {
				Hot = "Awesome Balls of Fire",
				Cold = "Snowclone",
				Stench = "Eggsplosion",
				Spooky = "Raise Backup Dancer",
				Sleaze = "Grease Lightning",
				Physical = "Toynado",
			}
			local spellid = nil
			local spellid_override = nil
			for x in text:gmatch("<option.-</option>") do
				if x:contains(want_spells[elem]) then
					spellid = tonumber(x:match([[value="([0-9]+)"]]))
				end
				if elem == "Hot" and have_item("volcanic ash") and x:contains("Volcanometeor Showeruption") then
					spellid_override = tonumber(x:match([[value="([0-9]+)"]]))
				end
			end
			spellid = spellid_override or spellid
			if got_all_rounds and spellid then
				text = text:gsub([[id='monname'.-</span>]], [[%0 <a href="]]..make_href("/fight.php", { action = "skill", whichskill = spellid })..[[" style="color: green">{ Vulnerability: ]] .. elem .. [[ }</a>]])
			else
				text = text:gsub([[id='monname'.-</span>]], [[%0 <span style="color: darkorange">{ Vulnerability: ]] .. elem .. [[ }</span>]])
			end
		end
	end
end)

