add_processor("won fight", function()
	if not familiar("Slimeling") then return end
	local monstername = text:match("<span id='monname'>(.-)</span>")
	local items = {}
	for x in text:gmatch("You acquire an item: <b>(.-)</b>") do
		table.insert(items, x)
	end
	local disgorged = text:contains("looks up at you guiltily before disgorging") and "disgorged" or "nodisgorge"

	local msg = "slimeling spading: weight[" .. buffedfamiliarweight() .. "], equipment[" .. tostring(equipment().familiarequip) .. "], monster[" .. tostring(monstername) .. "], items[" .. table.concat(items, ":") .. "], " .. disgorged

	print(msg)
	local f = io.open("slimeling-spading-log.txt", "a+")
	f:write(msg.."\n")
	f:close()
end)
