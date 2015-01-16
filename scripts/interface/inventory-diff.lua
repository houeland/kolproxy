add_interceptor("/main.php", function()
	if not session["cached initial session data"] then
		print("INFO: caching inventory at start of session")
		local str_inv = {}
		for a, b in pairs(inventory()) do
			str_inv[tostring(a)] = b
		end
		session["cached initial session data"] = { inventory = str_inv, equipment = equipment(), meat = meat() }
	end
end)

local href = add_automation_script("custom-inventory-diff", function()
	local cached_data = session["cached initial session data"]
	if not cached_data then
		error "Unknown inventory at start of session."
	end

	local function build_items(inv, eq)
		local items = {}
		for a, b in pairs(inv) do
			items[tonumber(a)] = b
		end
		for _, x in pairs(eq) do
			items[x] = (items[x] or 0) + 1
		end
		return items
	end

	local original_items = build_items(cached_data.inventory, cached_data.equipment)
	local current_items = build_items(inventory(), equipment())

	local itemids = {}
	for a, _ in pairs(original_items) do
		itemids[a] = true
	end
	for a, _ in pairs(current_items) do
		itemids[a] = true
	end

	local changes = {}
	for itemid, _ in pairs(itemids) do
		local amount = (current_items[itemid] or 0) - (original_items[itemid] or 0)
		if amount ~= 0 then
			local value = estimate_mallsell_profit(itemid, amount) or 0
			table.insert(changes, { itemid = itemid, amount = amount, name = maybe_get_itemname(itemid) or ("{ itemid: " .. tostring(itemid) .. " }"), value = value })
		end
	end
	table.sort(changes, function(a, b)
		if math.sign(a.amount) ~= math.sign(b.amount) then
			return math.sign(a.amount) > math.sign(b.amount)
		end
		if a.value ~= b.value then
			return a.value > b.value
		end
		if type(a.name) ~= type(b.name) then
			return type(a.name) < type(b.name)
		end
		if a.name and b.name then
			return a.name < b.name
		end
		return a.itemid < b.itemid
	end)

	local lines = {}
	local item_sum = 0
	for _, x in ipairs(changes) do
		table.insert(lines, string.format("%+dx %s (%s Meat)", x.amount, x.name, display_signed_integer(x.value)))
		item_sum = item_sum + x.value
	end

	table.insert(lines, "")
	table.insert(lines, string.format("Meat value of items: %s Meat", display_signed_integer(item_sum)))
	table.insert(lines, "")
	local meat_change = meat() - (cached_data.meat or 0)
	table.insert(lines, string.format("Current Meat: %s (%s)", meat(), display_signed_integer(meat_change)))
	table.insert(lines, string.format("Combined total: %s Meat", display_signed_integer(item_sum + meat_change)))

	return make_kol_html_frame("Inventory changes this session:<br><br>" .. table.concat(lines, "<br>"), "Inventory changes"), requestpath
end)
