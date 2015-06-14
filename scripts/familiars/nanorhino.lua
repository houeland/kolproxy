add_processor("/fight.php", function()
	if text:contains("launch a blast of white hot atomic energy") then
		day["nanorhino banished monster"] = get_monstername()
	end
end)

add_tracked_variables_display("day", function()
	return { title = "Nanorhino banished monster", value = day["nanorhino banished monster"] }
end)

add_warning {
	message = "Remember to begin fighting with a class-appropriate skill to trigger the nanorhino effect you want.",
	type = "notice",
	check = function()
		return familiar("Nanorhino")
	end
}

add_warning {
	message = "You have autoattack enabled while using the nanorhino. You might want to do the fight manually to make sure you trigger the effect you want.",
	type = "extra",
	check = function()
		return familiar("Nanorhino") and autoattack_is_set()
	end
}
