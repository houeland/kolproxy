add_printer("/charpane.php", function()
	if not familiar("Angry Jung Man") then return end

	local compact = ""
	local normal = ""
	if get_daily_counter("familiar.jungman.jar") > 0 then
		compact = "Dropped "
		normal = "Dropped today "
	end

	local x = get_ascension_counter("familiar.jungman.fights won")
	compact = compact .. "(" .. x .. " / 30)"
	normal = normal .. "(" .. x .. " / 30)"

	print_familiar_counter(compact, normal)
end)

track_familiar_info("jungman", function()
	return {count = get_daily_counter("familiar.jungman.jar"),
	        max = 1,
	        info = "jar",
	        type = "counter",
	        extra_info = string.format("%d/30 fights won", get_ascension_counter("familiar.jungman.fights won"))
	        }
	end)

add_processor("/fight.php", function()
	if familiar("Angry Jung Man") and text:contains(">You win the fight!<!--WINWINWIN--><") then
		increase_ascension_counter("familiar.jungman.fights won")
	end
end)

add_processor("familiar message: jungman", function()
	if text:contains("Take this, and try to pick up some of the slack, would you?") then
		increase_daily_counter("familiar.jungman.jar")
		reset_ascension_counter("familiar.jungman.fights won")
		increase_ascension_counter("familiar.jungman.fights won", -1)
	end
end)
