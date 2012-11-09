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
