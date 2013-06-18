function retrieve_standalone_cheese_banished_monsters()
	local banished = {}
	local pt = get_page("/desc_item.php", { whichitem = 806203565 })
	if pt:contains("5 charges left today") then
		return banished
	end

	local banishtext = pt:match(">The following monsters are currently banished:<br>.->Type: <")
	for x in banishtext:gmatch("&nbsp;&nbsp;(.-)<br>") do
		if x:match("[A-Za-z0-9]") then
			table.insert(banished, x)
		end
	end

	if not banished[1] then
		error "Failed to retrieve list of banished monsters"
	end
	return banished
end

function retrieve_cream_olfacted_monster()
	local pt = get_page("/desc_item.php", { whichitem = 792915061 })

	if pt:contains("5 charges left today") then
		return nil
	else
		return pt:match("You last used this staff on <b>(.-)</b>"):gsub("^[^ ]* ", "")
	end
end
