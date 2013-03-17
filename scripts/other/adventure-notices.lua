add_warning {
	message = "Make sure you use the correct skill to trigger the nanorhino.",
	severity = "notice",
	check = function()
		return familiar("Nanorhino")
	end
}

add_warning {
	message = "Make sure you use the correct skill to trigger the Juju Mojo Mask.",
	severity = "notice",
	check = function()
		if have_equipped("Juju Mojo Mask") and not have_intrinsic("Gaze of the Volcano God") and not have_intrinsic("Gaze of the Lightning God") and not have_intrinsic("Gaze of the Trickster God") then
			return true
		end
	end
}

add_warning {
	message = "Your Juju Mojo Mask gaze does not correspond to your primary stat.",
	severity = "extra",
	check = function()
		if have_intrinsic("Gaze of the Volcano God") and not mainstat_type("Muscle") then
			return true
		elseif have_intrinsic("Gaze of the Lightning God") and not mainstat_type("Mysticality") then
			return true
		elseif have_intrinsic("Gaze of the Trickster God") and not mainstat_type("Moxie") then
			return true
		end
	end
}

add_warning {
	message = "Having Jarlsberg's pan in Cosmic portal mode will consume the Slime Tube drops.",
	severity = "extra",
	zone = "The Slime Tube",
	check = function()
		return have_equipped("Jarlsberg's pan (Cosmic portal mode)")
	end
}

add_processor("/fight.php", function()
	if have_buff("Everything Looks Yellow") then
		session["had everything looks yellow buff on turn"] = turnsthisrun()
	end
end)

add_warning {
	message = "Your Everything Looks Yellow buff ran out.",
	severity = "notice",
	idgenerator = function()
		return session["had everything looks yellow buff on turn"]
	end,
	check = function()
		if not have_buff("Everything Looks Yellow") and session["had everything looks yellow buff on turn"] then
			return true
		end
	end
}
