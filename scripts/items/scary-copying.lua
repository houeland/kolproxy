-- spooky putty sheet

add_processor("/fight.php", function()
	if text:match([[<img src="http://images.kingdomofloathing.com/itemimages/sputtysheet.gif" width=30 height=30 alt="Spooky Putty sheet" title="Spooky Putty sheet">.-You press the sheet of spooky putty against .- and make a perfect copy, which you shove into your sack..->You acquire an item: <b>Spooky Putty monster</b><]]) then
		increase_daily_counter("item.scary copies")
		increase_daily_counter("item.putty sheet.uses")
	end
end)

add_printer("/fight.php", function()
	if text:match([[<img src="http://images.kingdomofloathing.com/itemimages/sputtysheet.gif" width=30 height=30 alt="Spooky Putty sheet" title="Spooky Putty sheet">.-You press the sheet of spooky putty against .- and make a perfect copy, which you shove into your sack..->You acquire an item: <b>Spooky Putty monster</b><]]) then
		copies = get_daily_counter("item.scary copies")
		uses = get_daily_counter("item.putty sheet.uses")
		spoilertext = uses .. " / 5 copies today"
		if copies ~= uses then
			spoilertext = uses .. " / 5 copies today (" .. copies .. " / 6 scary copies total)"
		end
		text = text:gsub([[(<img src="http://images.kingdomofloathing.com/itemimages/sputtysheet.gif" width=30 height=30 alt="Spooky Putty sheet" title="Spooky Putty sheet">.-)(You press the sheet of spooky putty against .- and make a perfect copy, which you shove into your sack.[^<]-)(<)]], [[%1<span style="color: darkorange">%2</span> (]]..spoilertext..[[)%3]])
	end
end)

-- rain-doh black box

add_processor("/fight.php", function()
	if text:match([[<img src="http://images.kingdomofloathing.com/itemimages/raindohbox.gif" width=30 height=30 alt="Rain%-Doh black box" title="Rain%-Doh black box">.-You push the button on the side of the box.  It makes a scary noise,.->You acquire an item: <b>Rain%-Doh box full of monster</b><]]) then
		increase_daily_counter("item.scary copies")
		increase_daily_counter("item.black box.uses")
	end
end)

add_printer("/fight.php", function()
	if text:match([[<img src="http://images.kingdomofloathing.com/itemimages/raindohbox.gif" width=30 height=30 alt="Rain%-Doh black box" title="Rain%-Doh black box">.-You push the button on the side of the box.  It makes a scary noise,.->You acquire an item: <b>Rain%-Doh box full of monster</b><]]) then
		copies = get_daily_counter("item.scary copies")
		uses = get_daily_counter("item.black box.uses")
		spoilertext = uses .. " / 5 copies today"
		if copies ~= uses then
			spoilertext = uses .. " / 5 copies today (" .. copies .. " / 6 scary copies total)"
		end
		text = text:gsub([[(<img src="http://images.kingdomofloathing.com/itemimages/raindohbox.gif" width=30 height=30 alt="Rain%-Doh black box" title="Rain%-Doh black box">.-)(You push the button on the side of the box.  It makes a scary noise,[^<]-)(<)]], [[%1<span style="color: darkorange">%2</span> (]]..spoilertext..[[)%3]])
	end
end)
