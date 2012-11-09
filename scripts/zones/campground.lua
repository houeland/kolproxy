add_processor("/campground.php", function()
	if text:contains("You gaze into the depths of space") or text:contains("You've already peered into the Heavens today.") then
		day["zone.campground.telescope.gazed"] = "yes"
	end
end)

add_always_warning("/campground.php", function()
	if params.action == "rest" then
		local camppt = get_page("/campground.php")
		local restlink = camppt:match([[<a href="campground.php%?action=rest">.-</a>]])
		if not restlink:contains("free.gif") then
			if hp() == 0 and buff("Beaten Up") then
				return "You have no free rests left. You don't have to rest just because you get beaten up - it is usually better to restore HP in other ways.", "campground-free-rest"
			else
				return "You have no free rests left.", "campground-free-rest"
			end
		end
	end
end)
