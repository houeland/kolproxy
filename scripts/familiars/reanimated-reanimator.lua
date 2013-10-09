local function set_obtuse_angel()
	if day["obtuse angel romantic arrow target"] and not day["obtuse angel romantic arrow next monster start"] then
		day["obtuse angel romantic arrow next monster start"] = turnsthisrun() + 15
	end
end

add_processor("/adventure.php", function()
	-- TODO: only for successful adventure.php loads?
	set_obtuse_angel()
end)

add_processor("/choice.php", function()
	if requestpath == "/adventure.php" then
		set_obtuse_angel()
	end
end)

add_processor("/fight.php", function()
	if requestpath == "/adventure.php" then
		set_obtuse_angel()
	end
end)

add_processor("familiar message: reanimator", function()
	if text:contains("nods and begins calculating how much glow-juice he'll need") then
-- 		print("fired romantic at", monster_name)
		day["obtuse angel romantic arrow target"] = monster_name
		day["obtuse angel romantic arrow next monster start"] = nil
		day["obtuse angel romantic arrow monsters remaining"] = 3
	end
end)

add_processor("/fight.php", function()
	if text:contains("You stop for a moment because you feel the hairs on the back of your neck stand up") then
		day["obtuse angel romantic arrow monsters remaining"] = (tonumber(day["obtuse angel romantic arrow monsters remaining"]) or 0) - 1
		day["obtuse angel romantic arrow next monster start"] = turnsthisrun() + 15
	end
end)
