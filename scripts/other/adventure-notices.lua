add_warning {
	message = "Make sure you use the correct skill to trigger the Juju Mojo Mask.",
	severity = "notice",
	check = function()
		if have_equipped("Juju Mojo Mask") and not have_intrinsic("Gaze of the Volcano God") and not have_intrinsic("Gaze of the Lightning God") and not have_intrinsic("Gaze of the Trickster God") then
			return true
		end
	end
}

-- TODO: in-run only(?)
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

local have_war_quest = nil
add_warning {
	message = "You do not have the quest to start the war.",
	severity = "warning",
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
	severity = "warning",
	when = "ascension",
	check = function(zoneid)
		if not have_buff("Consumed by Fear") then return end
		return zoneid ~= 302
	end
}
