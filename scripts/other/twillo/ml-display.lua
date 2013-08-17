function estimate_other_ml()
	local ml = mcd()
	if familiarid() == 109 then -- purse rat
		ml = ml + math.floor(buffedfamiliarweight() / 2)
	end
	if ascension["zone.manor.quartet song"] == "Provare Compasione Per El Sciocco" then
		ml = ml + 5
	end
	return ml
end
