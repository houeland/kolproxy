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
	print("Mer-kin lockkey dropped from", monstername())
	ascension["zones.sea.outpost lockkey monster"] = monstername()
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

add_processor("/skills.php", function()
	if text:contains("close your eyes and let Deep visions wash over you") then
		local substr = text:match("close your eyes and let Deep visions wash over you.-center>") or ""
		local house = substr:match("<b>(.-)</b>")
		learn_dreadscroll_word(house, "Vision house")
	end
end)

add_printer("/choice.php", function()
	if text:contains("You unroll the dreadscroll and look it over") then
		local lines = {}
		for a, b in pairs(ascension["zones.sea.dreadscroll words"] or {}) do
			table.insert(lines, string.format([[%s: <b>%s</b>]], a, b))
		end
		text = text:gsub("</body>", [[<center style="color: green">]] .. table.concat(lines, "<br>") .. [[</center>%0]])
	end
end)

add_extra_always_warning("/sea_merkin.php", function()
	if params.action == "temple" and have_equipped_item("Mer-kin scholar mask") and have_equipped_item("Mer-kin scholar tailpiece") then
		if count_equipped_item("Mer-kin prayerbeads") < 3 then
			return "You may want to wear 3 Mer-kin prayerbeads for the Yog-Urt fight.", "equip 3 prayerbeads for yog-urt"
		end
	end
end)
