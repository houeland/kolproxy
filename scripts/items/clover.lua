add_always_adventure_warning(function()
	if have_item("ten-leaf clover") and have_buff("Teleportitis") then
		return "You have Teleportitis and a ten-leaf clover in inventory.", "teleportitis and clover"
	end
end)

add_extra_ascension_adventure_warning(function()
	if have_item("ten-leaf clover") then
		return "You have a ten-leaf clover in inventory.", "clover-verify-" .. turnsthisrun(), "OK, disable clover warning for turn " .. (turnsthisrun() + 1) .. " and adventure"
	end
end)
