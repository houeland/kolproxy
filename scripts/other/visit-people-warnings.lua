add_warning {
	message = "The guild quest is in your mainstat starting zone. You might want to start it first.",
	severity = "notice",
	when = "ascension",
	check = function(zoneid)
		if ascensionpathid() == 8 or ascensionpathid() == 10 or ascensionpath("Avatar of Jarlsberg") then return false end
		if daysthisrun() == 1 or level() < 5 then
			if (zoneid == 114 and get_mainstat() == "Muscle") or (zoneid == 113 and get_mainstat() == "Mysticality") or (zoneid == 112 and get_mainstat() == "Moxie") then
				return true
			end
		end
	end,
}

add_warning {
	message = "If you want to do the moxie class guild quest, you have to wear pants to be able to steal them.",
	severity = "warning",
	when = "ascension",
	check = function(zoneid)
		if zoneid == 112 and get_mainstat() == "Moxie" and not equipment().pants then
			return true
		end
	end,
}

local have_degrassi = nil
add_warning {
	message = "The untinker quest is at the degrassi knoll. Make sure to pick it up first if you want to complete it.",
	severity = "warning",
	when = "ascension",
	zone = "Degrassi Knoll",
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
	message = "The prententious artist quest is in the starting zones. Make sure to pick it up first if you want to complete it.",
	severity = "notice",
	when = "ascension",
	check = function(zoneid)
		if ascensionpathid() == 10 then return end
		if daysthisrun() == 1 or level() < 5 then
			if zoneid == 112 or zoneid == 113 or zoneid == 114 then
				return true
			end
		end
	end
}
