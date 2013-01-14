function estimate_underwater_combat()
	local com = 0
	if buff("Colorfully Concealed") then
		com = com - 5
	end
	if have_equipped("Mer-kin sneakmask") then
		com = com - 5
	end
	return com
end

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

function adjust_combat(com)
	if com > 25 then
		return 25 + math.floor((com - 25) / 5)
	elseif com < -25 then
		return -adjust_combat(-com)
	else
		return com
	end
end
