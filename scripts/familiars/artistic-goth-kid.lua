add_processor("/fight.php", function()
	if newly_started_fight and encounter_source == "Artistic Goth Kid" then
-- 		print("goth kid fight!")
		increase_daily_counter("familiar.free combat encounters")
	end
end)

add_printer("/charpane.php", function()
	if familiarpicture() == "crayongoth" then
		fights = get_daily_counter("familiar.free combat encounters")
		chances = { 50, 40, 30, 20, 10, 10, 10, 0 }

		compact = string.format("%d / %d (%s%%)", fights, 7, chances[fights + 1] or "?")
		normal = string.format("%d / %d fights (%s%% chance)", fights, 7, chances[fights + 1] or "?")

		print_familiar_counter(compact, normal)
	end
end)
