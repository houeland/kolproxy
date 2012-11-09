local function check_summons()
	for x in text:gmatch("You acquire an item: <b>BRICKO eye brick</b>") do
		increase_daily_counter("skill.summon brickos.eye bricks")
	end
	for x in text:gmatch("You acquire an item: <b>divine champagne popper</b>") do
		increase_daily_counter("skill.summon party favor.rares")
	end
	for x in text:gmatch("You acquire an item: <b>divine champagne flute</b>") do
		increase_daily_counter("skill.summon party favor.rares")
	end
	for x in text:gmatch("You acquire an item: <b>divine cracker</b>") do
		increase_daily_counter("skill.summon party favor.rares")
	end
end

add_processor("/skills.php", function()
	check_summons()
end)

add_processor("/campground.php", function()
	check_summons()
end)

add_printer("/skills.php", function()
	text = text:gsub("Summon BRICKOs", function(x) return x .. string.format(" {%s/3 eyes}", get_daily_counter("skill.summon brickos.eye bricks")) end)
	text = text:gsub("Summon Party Favor", function(x) return x .. string.format(" {%s rares}", get_daily_counter("skill.summon party favor.rares")) end)
end)

add_printer("/topmenu.php", function()
	text = text:gsub([[<iframe width=325 name='skillpane']], [[<iframe width=400 name='skillpane']])
end)
