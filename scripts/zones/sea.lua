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

-- deepcity

add_processor("/sea_merkin.php", function()
	if text:contains("navigating the intense currents atop your trusty seahorse") then
		print("INFO: reached deepcity on seahorse")
		ascension["zones.sea.deepcity reached"] = true
	end
end)

add_extra_always_warning("/sea_merkin.php", function()
	if params.action == "temple" and have_equipped_item("Mer-kin scholar mask") and have_equipped_item("Mer-kin scholar tailpiece") then
		if count_equipped_item("Mer-kin prayerbeads") < 3 then
			return "You may want to wear 3 Mer-kin prayerbeads for the Yog-Urt fight.", "equip 3 prayerbeads for yog-urt"
		end
	end
end)
