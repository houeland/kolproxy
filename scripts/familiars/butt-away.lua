local function add_buttaway_message(pattern, runaways)
	if runaways == 1 then
		text = text:gsub(pattern, [[>%1 <span style="color: green">(]]..runaways..[[ free runaway today.)</span><]])
	else
		text = text:gsub(pattern, [[>%1 <span style="color: green">(]]..runaways..[[ free runaways today.)</span><]])
	end
end

add_processor("familiar message: bandersnatch", function()
	if text:contains("snatches you up in his jaws, tosses you onto his back, and flooms away, weaving slightly and hiccelping fire.") then
		increase_daily_counter("familiar.free butt runaways")
	end
end)

add_printer("familiar message: bandersnatch", function()
	if text:contains("snatches you up in his jaws, tosses you onto his back, and flooms away, weaving slightly and hiccelping fire.") then
		add_buttaway_message(">([^<]* snatches you up in his jaws, tosses you onto his back, and flooms away.-)<", get_daily_counter("familiar.free butt runaways"))
	end
end)

add_processor("familiar message: stompboots", function()
	if text:contains("kicks you in the butt to speed your escape.") then
		increase_daily_counter("familiar.free butt runaways")
	end
end)

add_printer("familiar message: stompboots", function()
	if text:contains("kicks you in the butt to speed your escape.") then
		add_buttaway_message(">([^<]* kicks you in the butt to speed your escape.-)<", get_daily_counter("familiar.free butt runaways"))
	end
end)

add_printer("/charpane.php", function()
	if familiarpicture() == "bandersnatch" or familiarpicture() == "stompboots" then
		runaways = get_daily_counter("familiar.free butt runaways")

		compact = runaways.." / " .. math.floor(buffedfamiliarweight() / 5)
		normal = runaways.." / " .. math.floor(buffedfamiliarweight() / 5) .. " runaways"

		color = nil
		if familiarpicture() == "bandersnatch" and not buff("Ode to Booze") then
			color = "gray"
		end
		print_familiar_value({ compactvalue = compact, normalvalue = normal, color = color })
	end
end)
