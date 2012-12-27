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

function estimate_ML_modifiers()
	local mlmods = {}
	mlmods.mcd = mcd()
	if familiarid() == 109 then -- purse rat
		mlmods.familiar = math.floor(buffedfamiliarweight() / 2)
	end
	if ascension["zone.manor.quartet song"] == "Provare Compasione Per El Sciocco" then
		mlmods.background = 5
	end
	mlmods.equipment = get_equipment_bonuses().ml
	mlmods.outfit = get_outfit_bonuses().ml
	mlmods.buff = get_buff_bonuses().ml
	return mlmods
end

add_printer("/charpane.php", function()
	if not setting_enabled("show modifier estimates") then return end

	local mlmods = estimate_ML_modifiers()
	local ml = 0
	for _, m in pairs(mlmods) do
		ml = ml + m
	end
	
	local uncertaintystr = ""
	if not have_cached_data() then
		uncertaintystr = " ?"
	end
	print_charpane_value { normalname = "ML", compactname = "ML", value = string.format("%+d", ml) .. uncertaintystr }
end)
