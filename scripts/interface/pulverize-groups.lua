function new_pulverize_groups()
	local order = {}
	local groups = {}
	for itemid in pairs(inventory()) do
		local result = get_pulverize_result(itemid)
		if result then
			if not groups[result] then
				table.insert(order, result)
				groups[result] = {}
			end
			groups[result][itemid] = true
		end
	end
	local simple_priority_lookup = {
		["3W"] = 9,
		["2W"] = 8,
		["1W"] = 7,
		["3N"] = 6,
		["2N"] = 5,
		["1N"] = 4,
		["3P"] = 3,
		["2P"] = 2,
		["1P"] = 1,
	}
	local function simple_priority(result)
		local match = result:match("^[123][WNP]")
		if not match then return end
		return simple_priority_lookup[match]
	end
	local function is_simple(result)
		return simple_priority(result) ~= nil
	end
	table.sort(order, function(a, b)
		if a == "useless powder" or b == "useless powder" then
			return b == "useless powder"
		end
		if is_simple(a) ~= is_simple(b) then
			return is_simple(b)
		end
		if not is_simple(a) then
			return a < b
		end
		return simple_priority(a) > simple_priority(b)
	end)
	local output = {}
	for _, result in ipairs(order) do
		table.insert(output, { label = result, items = groups[result] })
	end
	return output
end

add_printer("/craft.php", function()
	if text:contains([[<select name=smashitem>]]) then
		local groups = new_pulverize_groups()
		text = text:gsub([[(<select name=smashitem>)(.-)(</select>)]], function(preoptions, options, postoptions)
			optgroups = {}
			order = {}
			optgroups["Fake"] = {}
			table.insert(order, "Fake")
			for _, g in ipairs(groups) do
				optgroups[g.label] = {}
				table.insert(order, g.label)
			end
			optgroups["Unknown"] = {}
			table.insert(order, "Unknown")
			function place_item(id, opt)
				if id == 0 then
					table.insert(optgroups["Fake"], opt)
					return
				end
				for _, g in ipairs(groups) do
					if g.items[id] then
						table.insert(optgroups[g.label], opt)
						return
					end
				end
				table.insert(optgroups["Unknown"], opt)
			end
			for x, id, y in options:gmatch([[(<option[^>]-value=)([0-9]+)([^>]->[^<]-</option>)]]) do
				place_item(tonumber(id), x .. id .. y)
			end

			newoptions = ""
			for _, x in ipairs(order) do
				if #optgroups[x] > 0 then
					if x == "Fake" then
						newoptions = newoptions .. table.concat(optgroups[x])
					else
						newoptions = newoptions .. [[<optgroup label="]] .. x .. [[">]] .. table.concat(optgroups[x]) .. [[</optgroup>]]
					end
				end
			end

--~ 			print("options:", options)
			return preoptions .. newoptions .. postoptions
		end)
	end
end)
