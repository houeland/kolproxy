local grind_messages = {
	{ bit = "normal", message = "rummages around in.*picking a few choice bits to put in his grinder" },
	{ bit = "hot", message = "grabs a bit of.*squealing something about burning" },
	{ bit = "cold", message = "shivers as he rummages for grindable organs, muttering" },
	{ bit = "spooky", message = "shudders as he plunders.*for organs to grind, chattering" },
	{ bit = "stench", message = "holds his nose.*picks some organs" },
	{ bit = "sleaze", message = "blushes a little as he rummages in.*for organs to grind" },
	{ bit = "fish", message = "squelches around in.*for some grinder fodder, muttering" },
	{ bit = "boss", message = "Blimey.*harvests a few choice bits for his grinder." },
}

add_processor("familiar message: organgoblin", function() -- doesn't work with haiku state of mind
	for x in table.values(grind_messages) do
		if text:match(x.message) then
-- 			print("organ grinding", x.bit)
			increase_daily_counter("familiar.organ grinder.bits")
			tbl = ascension["familiar.organ grinder.bit types"] or {}
			tbl[x.bit] = true
			ascension["familiar.organ grinder.bit types"] = tbl
		end
	end

	pie = text:match("You acquire an item: <b>(.-)</b>")
	if pie then
		increase_daily_counter("familiar.organ grinder.pies")
		reset_daily_counter("familiar.organ grinder.bits")
		ascension["familiar.organ grinder.bit types"] = {}
-- 		print("got a pie", pie)
	end
end)

add_printer("/charpane.php", function()
	if familiarpicture() == "organgoblin" then
		bits = get_daily_counter("familiar.organ grinder.bits")
		pies = get_daily_counter("familiar.organ grinder.pies")
		needbits = "?"
		if pies <= 6 then
			amounts = { 5, 10, 16, 23, 31, 40, 50 }
			needbits = amounts[pies + 1]
		else
			needbits = 50
		end
		if needbits > 5 and have_equipped_item("microwave stogie") then
			needbits = needbits - 5
		end
		tbl = ascension["familiar.organ grinder.bit types"] or {}
		types = ""
		if tbl.fish then
			types = "shoo-fish pie"
		elseif tbl.boss then
			types = "badass pie"
		else
			element_list = {}
			for _, x in ipairs(grind_messages) do
				if tbl[x.bit] and x.bit ~= "normal" then
					table.insert(element_list, x.bit)
				end
			end
			if table.maxn(element_list) > 0 then
				types = table.concat(element_list, ", ")
			else
				types = "liver and let pie"
			end
		end

		compact = string.format([[<span title="%s">%d / %d</span>]], types, bits, needbits)
		normal = string.format([[<span title="%s">%d / %d bits</span>]], types, bits, needbits)

		print_familiar_counter(compact, normal)
	end
end)
