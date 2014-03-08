add_warning {
	message = "The guild quest is in your mainstat starting zone. You might want to start it first.",
	type = "notice",
	when = "ascension",
	check = function(zoneid)
		if ascensionpath("Avatar of Boris") or ascensionpath("Zombie Slayer") or ascensionpath("Avatar of Jarlsberg") then return false end
		if daysthisrun() == 1 or level() < 5 then
			if (zoneid == 114 and mainstat_type("Muscle")) or (zoneid == 113 and mainstat_type("Mysticality")) or (zoneid == 112 and mainstat_type("Moxie")) then
				return true
			end
		end
	end,
}

add_warning {
	message = "If you want to do the moxie class guild quest, you have to wear pants to be able to steal them.",
	type = "warning",
	when = "ascension",
	check = function(zoneid)
		if zoneid == 112 and mainstat_type("Moxie") and not equipment().pants then
			return true
		end
	end,
}

local have_degrassi = nil
add_warning {
	message = "The untinker quest is at the degrassi knoll. Make sure to pick it up first if you want to complete it.",
	type = "warning",
	when = "ascension",
	zone = "The Degrassi Knoll Garage",
	check = function(zoneid)
		if not have_degrassi then
			local pt = get_page("/questlog.php", { which = 1 })
			have_degrassi = pt:contains("<b>Driven Crazy</b>")
		end
		if not have_degrassi then
			return true
		end
	end,
}

add_warning {
	message = "The pretentious artist quest is in the starting zones. Make sure to pick it up first if you want to complete it.",
	type = "notice",
	when = "ascension",
	check = function(zoneid)
		if ascensionpath("Zombie Slayer") then return end
		if daysthisrun() == 1 or level() < 5 then
			if zoneid == 112 or zoneid == 113 or zoneid == 114 then
				return true
			end
		end
	end
}
