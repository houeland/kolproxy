add_processor("/inv_eat.php", function()
	local cookienumbers = {}
	local num_cookies = 0
	local add_number = function(x)
		if x > 200 then return end -- A semirare is never further than 200 turns away
		if not cookienumbers[x] then cookienumbers[x] = 0 end
		cookienumbers[x] = cookienumbers[x] + 1
	end
	for a, b, c in text:gmatch(">Lucky numbers: ([0-9]+), ([0-9]+), ([0-9]+)<") do
		num_cookies = num_cookies + 1
		add_number(tonumber(a))
		if a ~= b then
			add_number(tonumber(b))
		end
		if b ~= c and a ~= c then
			add_number(tonumber(c))
		end
	end
	if num_cookies > 0 then -- TODO: Rewrite code differently
		newnumbers = {}
		for a, b in pairs(cookienumbers) do
--~ 			print(num_cookies, a, b)
			if b == num_cookies then
				newnumbers[turnsthisrun() + a] = true
			end
		end
		
		local SRnumbers = {}
		local any_valid = false
		for a, b in pairs(ascension["fortune cookie numbers"] or {}) do
			if newnumbers[b] then
				SRnumbers[b] = true
				any_valid = true
			end
		end

		if (not any_valid) then SRnumbers = newnumbers end

		local SRnumberlist = {}
		for x, _ in pairs(SRnumbers) do
			table.insert(SRnumberlist, x)
		end

		ascension["fortune cookie numbers"] = SRnumberlist
	end
end)

function get_semirare_info(turn)
	local isoxy = (ascensionpathname() == "Oxygenarian")

	local lastturn = tonumber(ascension["last semirare turn"])
	local is_first_semi = false
	local SRmin = nil
	local SRmax = nil
	if lastturn then
		if isoxy then
			SRmin = lastturn + 100 - turn
			SRmax = lastturn + 120 - turn
		else
			SRmin = lastturn + 160 - turn
			SRmax = lastturn + 200 - turn
		end
	elseif turn < 85 then
		SRmin = 70 - turn
		SRmax = 80 - turn
		is_first_semi = true
	end

	local all_numbers = {}
	local good_numbers = {}
	for a, b in pairs(ascension["fortune cookie numbers"] or {}) do
		t = tonumber(b) - turn
		table.insert(all_numbers, t)
		if t >= 0 then
			if SRmin and SRmax and SRmax >= 0 then
				if t >= SRmin and t <= SRmax then
					table.insert(good_numbers, t)
				end
			else
				table.insert(good_numbers, t)
			end
		end
	end
	table.sort(all_numbers)
	table.sort(good_numbers)

	local SRnow = nil
	for x in table.values(good_numbers) do
		if x == 0 then
			SRnow = true
		end
	end

	local lastsemi = ascension["last semirare encounter"]

	return SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi
end

add_printer("/charpane.php", function()
	local ttr = tonumber(text:match("var turnsthisrun = ([0-9]+);"))
	if not ttr then return end
	if text:contains("inf_small.gif") then return end

	local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info(ttr)

	value = ""
	color = nil
	if SRnow then
		color = "green"
	end

	if table.maxn(good_numbers) > 0 then
		value = good_numbers[1]
		for x, _ in pairs(good_numbers) do
			if x > 1 then
				value = value .. " +"
			end
		end
	else
		value = "?"
	end

	if (not lastsemi) and (not is_first_semi) then
		lastsemi = "?"
	end

	tooltip = ""
	if table.maxn(all_numbers) > 0 then
		tooltip = tooltip .. "Fortune cookie numbers: " .. table.concat(all_numbers, ", ")
	else
		tooltip = tooltip .. "Fortune cookie numbers: ?"
	end
	if SRmin and SRmax and SRmax >= 0 then
		if value == "?" then
			value = SRmin .. " to " .. SRmax
		end
		tooltip = tooltip .. ", range = " .. SRmin .. " to " .. SRmax
	else
		if value ~= "?" then
			value = value .. " ?"
		end
		tooltip = tooltip .. ", range = ?"
	end

	if lastsemi then
		tooltip = tooltip .. ", last semirare = " .. lastsemi
	end

	normalname = "Semirare"
	compactname = "SR"
	local isoxy = (ascensionpathname() == "Oxygenarian")
	if isoxy then
		normalname = normalname .. " (Oxy)"
		compactname = compactname .. " (O)"
		tooltip = tooltip .. ", on Oxygenarian path"
	end
	print_charpane_value({ normalname = normalname, compactname = compactname, value = value, tooltip = tooltip, color = color })

	if SRnow then
		text = text:gsub("<body bgcolor=white", [[<body style="background-color: lightgreen"]])
		if lastsemi then
			print_charpane_value { name = "Last SR", value = lastsemi }
		end
	end
end)

add_always_adventure_warning(function()
	SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info(turnsthisrun())

	if SRnow then
		if have("ten-leaf clover") then
			return "Your ten-leaf clover will override the semirare.", "clover-semirare"
		end
		local msg = "Next turn might be a semirare."
		if lastsemi then
			msg = msg .. "\n<br>Last semirare was " .. lastsemi .. "."
		end
		return msg, "semirare-" .. turnsthisrun(), "Disable the warning for turn " .. (turnsthisrun() + 1) .. " and adventure", "teal", "Semirare warning: "
	end
end)

add_always_warning("/shore.php", function()
	if params.whichtrip then
		SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info(turnsthisrun())
		for x in table.values(good_numbers) do
			if x >= 0 and x <= 2 then
				return "You might be shoring over a semirare", "shoring over semirare"
			end
		end
	end
end)
