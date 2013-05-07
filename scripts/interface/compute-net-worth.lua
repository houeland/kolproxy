function compute_net_worth()
	local inventory, storage, closet = retrieve_all_item_locations()
	-- TODO(?): display case, mall
	local allitems = {}
	for a, b in pairs(inventory) do
		allitems[a] = (allitems[a] or 0) + b
	end
	for a, b in pairs(storage) do
		allitems[a] = (allitems[a] or 0) + b
	end
	for a, b in pairs(closet) do
		allitems[a] = (allitems[a] or 0) + b
	end

	local itemlines = {}
	local totalsum = 0
	for a, b in pairs(allitems) do
		table.insert(itemlines, { name = a, amount = b, value = estimate_mallbuy_cost(a) or 0 })
	end
	table.sort(itemlines, function(a, b)
		if a.value * a.amount ~= b.value * b.amount then
			return a.value * a.amount > b.value * b.amount
		elseif a.value ~= b.value then
			return a.value > b.value
		else
			return a.name < b.name
		end
	end)
	return itemlines
end

add_automation_script("custom-compute-net-worth", function()
	local itemlines = compute_net_worth()
	local tablerows = {}
	local totalsum = 0
	local function disp(x)
		return display_value(math.floor(x + 0.5))
	end
	for _, x in ipairs(itemlines) do
		table.insert(tablerows, string.format([[<tr><td style="text-align: right">%s</td><td>&nbsp;&nbsp;%s (%s)</td></tr>]], disp(x.value * x.amount), x.name, disp(x.amount)))
		totalsum = totalsum + x.value * x.amount
	end
	return make_kol_html_frame("<table>" .. string.format([[<tr><td style="text-align: right">%s</td><td>&nbsp;&nbsp;%s</td></tr>]], disp(totalsum), "<i>(Total)</i>") .. table.concat(tablerows, "\n") .. "</table>", "Approximate net worth (estimated cost to buy everything from the mall)"), requestpath
end)
