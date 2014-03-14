add_warning {
	message = "Remember to use a class-appropriate skill to trigger the Juju Mojo Mask gaze +stat/fight intrinsic you want.",
	type = "notice",
	check = function()
		if have_equipped_item("Juju Mojo Mask") and not have_intrinsic("Gaze of the Volcano God") and not have_intrinsic("Gaze of the Lightning God") and not have_intrinsic("Gaze of the Trickster God") then
			return true
		end
	end
}

add_warning {
	message = "Your Juju Mojo Mask gaze +stat/fight intrinsic does not correspond to your primary stat.",
	type = "extra",
	check = function()
		if level() >= 13 then return false end
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
	type = "extra",
	zone = "The Slime Tube",
	check = function()
		return have_equipped_item("Jarlsberg's pan (Cosmic portal mode)")
	end
}

add_processor("/fight.php", function()
	if have_buff("Everything Looks Yellow") then
		session["had everything looks yellow buff on turn"] = turnsthisrun()
	end
end)

add_warning {
	message = "Your Everything Looks Yellow buff has run out.",
	type = "notice",
	idgenerator = function()
		return session["had everything looks yellow buff on turn"]
	end,
	check = function()
		if not have_buff("Everything Looks Yellow") and session["had everything looks yellow buff on turn"] then
			return true
		end
	end
}

local have_war_quest = nil
add_warning {
	message = "You do not have the quest to start the war.",
	type = "warning",
	when = "ascension",
	check = function(zoneid)
		if have_war_quest then return end
		if zoneid == 26 or zoneid == 27 or zoneid == 131 or zoneid == 133 or zoneid == 134 or zoneid == 135 then
			if level() >= 12 then
				have_war_quest = get_page("/questlog.php", { which = 1 }):contains("<b>Make War, Not")
				return not have_war_quest
			end
		end
	end
}

add_warning {
	message = "You are still Consumed by Fear (click the face in the middle of the Mystic's Psychoses).",
	type = "warning",
	when = "ascension",
	check = function(zoneid)
		if not have_buff("Consumed by Fear") then return end
		return zoneid ~= 302
	end
}
