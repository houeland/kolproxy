-- TODO: Reorganize, move to other files

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

function estimate_other_combat()
	local com = 0
	if ascension["zone.manor.quartet song"] == "Sono Un Amante Non Un Combattente" then
		com = com - 5
	end
	return com
end

function estimate_other_init()
	local init = 0
	if moonsign("Vole") then
		init = init + 20
	end
	return init
end

function estimate_other_item()
	local item = 0
	if ascension["zone.manor.quartet song"] == "Le Mie Cose Favorite" then
		item = item + 5
	end
	if moonsign("Packrat") then
		item = item + 10
	end
	return item
end

function estimate_other_meat()
	local meat = 0
	if moonsign("Wombat") then
		meat = meat + 20
	end
	return meat
end

function estimate_other_ml()
	local ml = mcd()
	if ascension["zone.manor.quartet song"] == "Provare Compasione Per El Sciocco" then
		ml = ml + 5
	end
	return ml
end
