-- TODO: move to another file
function estimate_underwater_combat()
	local com = 0
	if have_buff("Colorfully Concealed") then
		com = com - 5
	end
	if have_equipped_item("Mer-kin sneakmask") then
		com = com - 5
	end
	return com
end

-- TODO: handle differently
function estimate_other_combat()
	local com = 0
	if familiarid() == 69 then -- jumpsuited hound dog
		com = com + math.min(math.floor(buffedfamiliarweight() / 6), 5)
	end
	if ascension["zone.manor.quartet song"] == "Sono Un Amante Non Un Combattente" then
		com = com - 5
	end
	return com
end

-- TODO: move to another file
function adjust_combat(com)
	if com > 25 then
		return 25 + math.floor((com - 25) / 5)
	elseif com < -25 then
		return -adjust_combat(-com)
	else
		return com
	end
end
