-- TODO: display this somewhere?

add_processor("/fight.php", function()
	if text:contains("launch a blast of white hot atomic energy") then
		day["nanorhino banished monster"] = monstername()
	end
end)

add_warning {
	message = "Make sure you use the correct skill to trigger the nanorhino.",
	type = "notice",
	check = function()
		return familiar("Nanorhino")
	end
}

add_warning {
	message = "You have autoattack enabled while using the nanorhino.",
	type = "extra",
	check = function()
		return familiar("Nanorhino") and autoattack_is_set()
	end
}
