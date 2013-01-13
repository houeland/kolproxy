-- TO DO: CoT, Handsomeness potion for men, card sleeve, furry suit, Tiny Plastic Commons, El Vibrato

add_automator("all pages", function()
	if have_equipped("Grimacite gown") and not session["cached Grimacite gown bonus"] then
		local pt = get_page("/desc_item.php", { whichitem = 528443762 })
		local bonus = pt:match([[>%+([0-9]+) to Monster Level<]])
		session["cached Grimacite gown bonus"] = bonus
	end
end)

add_automator("all pages", function()
	if have_equipped("Moonthril Cuirass") and not session["cached Moonthril Cuirass bonus"] then
		local pt = get_page("/desc_item.php", { whichitem = 534033050 })
		local bonus = pt:match([[>%+([0-9]+) to Monster Level<]])
		session["cached Moonthril Cuirass bonus"] = bonus
	end
end)

add_automator("all pages", function()
	if have_equipped("hairshirt") and not session["cached hairshirt bonus"] then
		local pt = get_page("/desc_item.php", { whichitem = 326755469 })
		local bonus = pt:match([[>%+([0-9]+) to Monster Level<]])
		session["cached hairshirt bonus"] = bonus
	end
end)

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

function estimate_ml()
	local ml = get_equipment_bonuses().ml
	ml = ml + get_outfit_bonuses().ml
	ml = ml + get_buff_bonuses().ml
	ml = ml + estimate_other_ml()
	return ml
end
