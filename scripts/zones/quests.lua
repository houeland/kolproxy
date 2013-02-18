function set_quest_status(zone, id, value)
	print("setting quest status", zone, id, " => ", value)
	set_ascension_state("quest." .. zone .. "." .. id, value)
end

add_processor("/fight.php", function()
	print("quests check: fight", adventure_title, monster_name, adventure_result)
end)

add_processor("/adventure.php", function()
	print("quests check: adventure", adventure_title, monster_name, adventure_result)
	if adventure_result == "F-F-Fantastic!" then
		set_quest_status("beanstalk", "airship status", "unlocked castle")
	end
end)

add_processor("/choice.php", function()
	print("quests check: choice", adventure_title, monster_name, adventure_result)
end)
