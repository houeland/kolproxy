local last_cached_memorize = nil
function can_memorize_page()
	if not ascensionpath("Actually Ed the Undying") then return end
	if last_cached_memorize ~= level() and not locked() then
		last_cached_memorize = level()
		get_place("edbase", "edbase_book")
	end
	return session["cache ed can memorize pages"]
end

add_processor("/choice.php", function()
	if not text:contains("You read from the Book of the Undying.") then return end
	session["cache ed can memorize pages"] = not text:contains("You may memorize 0 more pages.")
end)

local last_cached_release = nil
function can_release_servant()
	if not ascensionpath("Actually Ed the Undying") then return end
	if last_cached_release ~= level() and not locked() then
		last_cached_release = level()
		get_place("edbase", "edbase_door")
	end
	return session["cache ed can release servant"]
end

add_processor("/choice.php", function()
	if not text:contains("The Servants' Quarters") then return end
	session["cache ed can release servant"] = not text:contains("You may release 0 more servants.")
end)

add_warning {
	message = "You can memorize a page from the Book of the Undying.",
	type = "warning",
	check = can_memorize_page,
}

add_warning {
	message = "You can release an entombed servant.",
	type = "warning",
	check = can_release_servant,
}

--http://127.0.0.1:18781/place.php?whichplace=edbase&action=edbase_door
--<p><b>Busy Servant</b>: <img src=http://images.kingdomofloathing.com/itemimages/edserv6.gif>Mekhotep, the Priest (lvl. 20, 422 XP)
