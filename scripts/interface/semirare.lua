add_processor("/inv_eat.php", function()
	local cookienumbers = {}
	local num_cookies = 0
	local add_number = function(x)
		if x > 200 then return end -- A semirare is never further than 200 turns away
		cookienumbers[x] = (cookienumbers[x] or 0) + 1
	end
	for a, b, c in text:gmatch(">Lucky numbers: ([0-9]+), ([0-9]+), ([0-9]+)<") do
		print("INFO: Fortune cookie lucky numbers: ", a, b, c)
		a, b, c = tonumber(a), tonumber(b), tonumber(c)
		num_cookies = num_cookies + 1
		add_number(a)
		if b ~= a then
			add_number(b)
		end
		if c ~= b and c ~= a then
			add_number(c)
		end
	end
	if num_cookies == 0 then
		return
	end

	local newnumbers = {}
	for a, b in pairs(cookienumbers) do
		if b == num_cookies then
			newnumbers[turnsthisrun() + a] = true
		end
	end

	local SRnumbers = {}
	for a, b in pairs(ascension["fortune cookie numbers"] or {}) do
		if newnumbers[b] then
			SRnumbers[b] = true
		end
	end

	if not next(SRnumbers) then SRnumbers = newnumbers end

	local SRnumberlist = {}
	for x, _ in pairs(SRnumbers) do
		table.insert(SRnumberlist, x)
	end

	ascension["fortune cookie numbers"] = SRnumberlist
end)

add_processor("/clan_viplounge.php", function()
	local sr_turn = text:match([[you spontaneously burp%-speak the number <b>([0-9]+)</b>]])
	if sr_turn then
		ascension["fortune cookie numbers"] = { turnsthisrun() + tonumber(sr_turn) }
	end
end)

function get_semirare_info()
	local turn = turnsthisrun()
	local lastturn = tonumber((ascension["last semirare"] or {}).turn)
	local is_first_semi = false
	local SRmin = nil
	local SRmax = nil
	if lastturn then
		if ascensionpath("Oxygenarian") then
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
	for _, x in ipairs(good_numbers) do
		if x == 0 then
			SRnow = true
		end
	end

	local lastsemi = (ascension["last semirare"] or {}).encounter

	return SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi, lastturn
end

add_charpane_line(function()
	if setting_enabled("display counters as effects") then return end
	local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info()

	local value = good_numbers[1] and table.concat(good_numbers, ", ") or "?"
	local color = SRnow and "green" or "black"

	if not lastsemi and not is_first_semi then
		lastsemi = "?"
	end

	local tooltip = string.format("Fortune cookie numbers: %s", all_numbers[1] and table.concat(all_numbers, ", ") or "?")

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

	local lines = {}

	normalname = "Semirare"
	compactname = "Semirare"
	if ascensionpath("Oxygenarian") then
		normalname = normalname .. " (Oxy)"
		compactname = compactname .. " (O)"
		tooltip = tooltip .. ", on Oxygenarian path"
	end
	table.insert(lines, { normalname = normalname, compactname = compactname, value = value, tooltip = tooltip, color = color })

	if SRnow and lastsemi then
		table.insert(lines, { name = "Last SR", value = lastsemi })
	end
	return lines
end)

add_always_adventure_warning(function()
	local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info(turnsthisrun())

	if SRnow then
		if have_item("ten-leaf clover") then
			return "Your ten-leaf clover will override the semirare.", "clover-semirare"
		end
		local msg = "Next turn might be a semirare."
		if lastsemi then
			msg = msg .. "\n<br>Last semirare was " .. lastsemi .. ". (You cannot get the same one twice in a row.)"
		end
		return msg, "semirare-" .. turnsthisrun(), "Disable the warning for turn " .. (turnsthisrun() + 1) .. " and adventure", "teal", "Semirare warning: "
	end
end)

add_extra_always_adventure_warning(function()
	local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi, lastturn = get_semirare_info(turnsthisrun())

	if not next(good_numbers) and tonumber(SRmin) and tonumber(SRmin) <= 1 and tonumber(SRmax) and tonumber(SRmax) >= 0 then
		return "The semirare window will start soon (and you do not have fortune cookie numbers).", "semirare-range-" .. tostring(lastturn), "Disable the warning for this semirare window and adventure"
	end
end)

function semirare_in_next_N_turns(N)
	local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info()
	local result = nil
	for _, x in ipairs(good_numbers) do
		if x < N then
			return true
		end
		result = false
	end
	return result
end
