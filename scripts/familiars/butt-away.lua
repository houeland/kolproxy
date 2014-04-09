local function add_buttaway_message(pattern, runaways)
	text = text:gsub(pattern, [[>%1 <span style="color: green">(]]..make_plural(runaways, "free runaway", "free runaways")..[[ today.)</span><]])
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

add_processor("familiar message: stompboots", function()
	if text:contains("feet flying, heels stomping, buckles jangling") and text:contains("Thank goodness there wasn't a mudhole nearby.") then
		increase_daily_counter("familiar.pair of stomping boots.stomps")
		reset_ascension_counter("familiar.pair of stomping boots.charges")
	end
end)

add_printer("familiar message: stompboots", function()
	if text:contains("kicks you in the butt to speed your escape.") then
		add_buttaway_message(">([^<]* kicks you in the butt to speed your escape.-)<", get_daily_counter("familiar.free butt runaways"))
	end
end)


add_processor("/fight.php", function()
	if familiar("Pair of Stomping Boots") and text:contains(">You win the fight!<!--WINWINWIN--><") and not text:contains("feet flying, heels stomping, buckles jangling") and not text:contains("Thank goodness there wasn't a mudhole nearby.") then
		-- only increment counter when boots didn't stomp
		increase_ascension_counter("familiar.pair of stomping boots.charges")
	end
end)


add_printer("/charpane.php", function()
	if familiarpicture() == "bandersnatch" or familiarpicture() == "stompboots" then
		runaways = get_daily_counter("familiar.free butt runaways")

		compact = runaways.." / " .. math.floor(buffedfamiliarweight() / 5) .. " runs"
		normal = runaways.." / " .. math.floor(buffedfamiliarweight() / 5) .. " runaways"

		color = nil
		if familiarpicture() == "bandersnatch" and not have_buff("Ode to Booze") then
			color = "gray"
		end
		if familiarpicture() == "stompboots" then
			compact = compact .. string.format("<br>%d / 7 stomps", get_daily_counter("familiar.pair of stomping boots.stomps"))
			normal = normal .. string.format("<br>%d / 7 stomps", get_daily_counter("familiar.pair of stomping boots.stomps"))
		end
		print_familiar_value({ compactvalue = compact, normalvalue = normal, color = color })
	end
end)

track_familiar_info("stompboots", function()
	return {
		count = get_daily_counter("familiar.free butt runaways"),
		-- todo: this is only correct when this is the current fam
		max = math.floor(buffedfamiliarweight() / 5),
		type = "counter",
		info = "runaways",
	}
end)

track_familiar_info("stompboots", function()
	return {
		count = get_daily_counter("familiar.pair of stomping boots.stomps"),
		max = 7,
		type = "counter",
		info = "stomps",
		extra_info = string.format("%i / %i charges", get_ascension_counter("familiar.pair of stomping boots.charges"), get_daily_counter("familiar.pair of stomping boots.stomps") + 2)
	}
end)

track_familiar_info("bandersnatch", function()
	return {
		count = get_daily_counter("familiar.free butt runaways"),
		-- todo: this is only correct when this is the current fam
		max = math.floor(buffedfamiliarweight() / 5),
		type = "counter",
		info = "runaways"
	}
end)
