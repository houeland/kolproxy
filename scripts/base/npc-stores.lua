function shop_scan_item_rows(whichshop)
	local scanned_itemrows = {}
	local pt = get_page("/shop.php", { whichshop = whichshop })

	for row, name in pt:gmatch([[<input type=radio name=whichrow value=([0-9]+)>.-<b>(.-)</b>]]) do
		scanned_itemrows[name] = tonumber(row)
	end
	for tr in pt:gmatch([[<tr>.-</tr>]]) do
		local name, row = tr:match([[<b>(.-)</b>.-whichrow=([0-9]+)]])
		if name and tonumber(row) and not scanned_itemrows[name] then
			scanned_itemrows[name] = tonumber(row)
		end
	end

	return scanned_itemrows
end

local function shop_buy_many_items(itemlist, whichshop)
	local itemrows = shop_scan_item_rows(whichshop)
	local ptfs = {}
	for x, y in pairs(itemlist) do
		if not itemrows[x] then
			print("WARNING: couldn't find row for item", x)
			print("  itemrows:", itemrows)
			print("WARNING: couldn't find row for item", x)
		end
		table.insert(ptfs, async_post_page("/shop.php", { pwd = session.pwd, whichshop = whichshop, action = "buyitem", whichrow = itemrows[x], quantity = y }))
	end
	return ptfs
end

function shop_buyitem(items, whichshop)
	if type(items) == "string" then
		return shop_buy_many_items({ [items] = 1 }, whichshop)[1]
	else
		return shop_buy_many_items(items, whichshop)
	end
end
