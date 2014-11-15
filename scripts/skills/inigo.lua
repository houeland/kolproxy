add_warning {
	message = "You might want to get a better accordion first.",
	path = "/runskillz.php",
	type = "extra",
	check = function()
		if tonumber(params.whichskill) == get_skillid("Inigo's Incantation of Inspiration") then
			return AT_song_duration() < 10
		end
	end,
}

