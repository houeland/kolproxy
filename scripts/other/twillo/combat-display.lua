-- To Do - make underwater separate. Wait for spading on e.g. 28% combat rate

function estimate_underwater_com()
	local com = 0
	if buff("Colorfully Concealed") then
		com = com + -5
	end
	if have_equipped("Mer-kin sneakmask") then
		com = com + -5
	end
	return com
end

function estimate_other_com()
	local com = 0
	if familiarid() == 69 then -- jumpsuited hound dog
		com = com + math.min(math.floor(buffedfamiliarweight() / 6), 5)
	end
	if ascension["zone.manor.quartet song"] == "Sono Un Amante Non Un Combattente" then
		com = com - 5
	end
	com = com + estimate_underwater_com()
	return com
end

function adjust_com(com)
	if com > 25 then
		com = 25 + math.floor((com - 25) / 5)
	elseif com < -25 then
		com = -25 + math.ceil((com + 25) / 5)
	end
	return com
end
