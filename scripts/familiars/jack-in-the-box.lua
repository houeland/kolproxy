add_processor("familiar message: jackinthebox", function()
	if text:contains("crank for a while") then
		day["familiar.jack-in-the-box.crank turns"] = 1
	elseif text:contains("crank some more") then
		day["familiar.jack-in-the-box.crank turns"] = 2
	end
end)

add_processor("/fight.php", function()
	if text:contains("all of a sudden a horrible grinning clown head emerges with a loud bang") then
		day["familiar.jack-in-the-box.crank turns"] = 0
	end
end)

add_printer("/charpane.php", function()
	if familiar("Jack-in-the-Box") then
		local normal = get_daily_counter("familiar.jack-in-the-box.crank turns") .. " / 2 turns"
		if get_daily_counter("familiar.jack-in-the-box.crank turns") ~= 2 then
			normal = [[<span style="color: gray">]] .. normal .. [[</span>]]
		end
		local compact = normal

		print_familiar_counter(compact, normal)
	end
end)
