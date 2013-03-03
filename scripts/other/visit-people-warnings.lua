-- add_extra_ascension_adventure_warning(function(zoneid)
-- 	if daysthisrun() == 1 then
-- 		return "If you're going to PvP in-run, you might want to break the hippy stone before adventuring anywhere and leveling up, to start at a low rank.", "break hippy stone"
-- 	end
-- end)

add_extra_ascension_adventure_warning(function(zoneid)
	if ascensionpathid() == 8 or ascensionpathid() == 10 or ascensionpath("Avatar of Jarlsberg") then return end
	if daysthisrun() == 1 or level() < 5 then
		if (zoneid == 114 and get_mainstat() == "Muscle") or (zoneid == 113 and get_mainstat() == "Mysticality") or (zoneid == 112 and get_mainstat() == "Moxie") then
			return "The guild quest is in your mainstat starting zone, you might want to start it first.", "pick up guild quest"
		end
	end
end)

add_ascension_adventure_warning(function(zoneid)
	if zoneid == 112 and get_mainstat() == "Moxie" and not equipment().pants then
		return "If you want to do the moxie class guild quest, you have to wear pants to be able to steal them.", "wear pants for moxie guild quest"
	end
end)

local have_degrassi = nil
add_extra_ascension_adventure_warning(function(zoneid)
	if not have_degrassi then
		local pt = get_page("/questlog.php", { which = 1 })
		have_degrassi = pt:contains("<b>Driven Crazy</b>")
	end
	if have_degrassi then return end
	if zoneid == 18 then
		return "The untinker quest is at the degrassi knoll. Make sure to pick it up first if you want to complete it.", "untinker quest"
	end
end)

add_extra_ascension_adventure_warning(function(zoneid)
	if ascensionpathid() == 10 then return end
	if daysthisrun() == 1 or level() < 5 then
		if zoneid == 112 or zoneid == 113 or zoneid == 114 then
			return "The prententious artist quest is in the starting zones. Make sure to pick it up first if you want to complete it.", "pretentious artist quest"
		end
	end
end)
