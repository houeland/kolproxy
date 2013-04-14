function shop_scan_item_rows(whichshop)
	local scanned_itemrows = {}
	local pt = get_page("/shop.php", { whichshop = whichshop })
	for row, name in pt:gmatch([[<input type=radio name=whichrow value=([0-9]+)>.-<b>(.-)</b>]]) do
		scanned_itemrows[name] = tonumber(row)
	end
	return scanned_itemrows
end

function shop_buyitem(items, whichshop)
	if type(items) == "string" then
		items = { [items] = 1 }
	end

	local itemrows = shop_scan_item_rows(whichshop)

	for x, y in pairs(items) do
		async_post_page("/shop.php", { pwd = session.pwd, whichshop = whichshop, action = "buyitem", whichrow = itemrows[x], quantity = y })
	end
end
