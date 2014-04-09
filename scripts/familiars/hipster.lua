local chances = { 50, 40, 30, 20, 10, 10, 10, 0 }

add_processor("/fight.php", function()
	if newly_started_fight and encounter_source == "Mini-Hipster" then
-- 		print("hipster fight!")
		increase_daily_counter("familiar.free combat encounters")
	end
end)

add_printer("/charpane.php", function()
	if familiarpicture() == "minihipster" then
		fights = get_daily_counter("familiar.free combat encounters")

		compact = string.format("%d / %d (%s%%)", fights, 7, chances[fights + 1] or "?")
		normal = string.format("%d / %d fights (%s%% chance)", fights, 7, chances[fights + 1] or "?")

		print_familiar_counter(compact, normal)
	end
end)

track_familiar_info("minihipster", function()
	local fights = get_daily_counter("familiar.free combat encounters")
	return {
		count = get_daily_counter("familiar.free combat encounters"),
		max = 7,
		type = "counter",
		info = "fights",
		extra_info = string.format("%s%% chance", chances[fights + 1] or "?")
	}
end)

add_extra_ascension_adventure_warning(function(zoneid)
	if familiar("Mini-Hipster") and level() < 13 and have_equipped_item("ironic moustache") then
		return "You might want to pawn the ironic moustache for a fixed-gear bicycle.", "pawn ironic moustache"
	end
end)
