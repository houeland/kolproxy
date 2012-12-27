-- track Bear Hugs in Zombie Slayer

add_processor("/fight.php", function()
	if text:contains("with your filthy rotting arms") then
		increase_daily_counter("zombie.bear arm Bear Hugs used")
	end
end)

add_printer("/fight.php", function()
	if text:contains("with your filthy rotting arms") then
		local hugsleft = 10 - get_daily_counter("zombie.bear arm Bear Hugs used")
		local hugmsg = [[<span style="color: green">{ ]] .. make_plural(hugsleft, "zombifying Bear Hug", "zombifying Bear Hugs") .. [[ left. }</span>]]
		text = text:gsub("dutifully joins? your horde%.", "%0 " .. hugmsg)
	end
end)
