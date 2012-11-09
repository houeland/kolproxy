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

function get_equipment_ML()
	local tw_ml = 0	
	if have_equipped("snake shield") and have_equipped("serpentine sword") then
		tw_ml = tw_ml + 10
	end
	local function count_distinct_equipped(items)
		local c = 0
		for item in table.values(items) do
			if have_equipped(item) then
				c = c + 1
			end
		end
		return c
	end
	local count_bs = count_distinct_equipped {
		"Brimstone Bunker",
		"Brimstone Brooch",
		"Brimstone Boxers",
		"Brimstone Beret",
		"Brimstone Bludgeon",
		"Brimstone Bracelet",
	}
	if count_bs > 0 then
		tw_ml = tw_ml + math.pow(2, count_bs)
	end

	local equipmentarray = {
		["Moonthril Cuirass"] = session["cached Moonthril Cuirass bonus"] or 40,
		["Grimacite gown"] = session["cached Grimacite gown bonus"] or 40,
		["hairshirt"] = session["cached hairshirt bonus"] or 40,
		["old patched suit-pants"] = 40,
		["hockey stick of furious angry rage"] = 30, 
		["vinyl shield"] = 25,
		["bone spurs"] = 20, 
		["astral belt"] = 20,
		["stainless steel scarf"] = 20,
		["bugged balaclava"] = 20,
		["Uncle Hobo's stocking cap"] = 20,
		["cane-mail shirt"] = 20, 
		["C.A.R.N.I.V.O.R.E. button"] = 15,
		["ice sickle"] = 15,
		["creepy-ass club"] = 15,
		["evil-ass club"] = 15,
		["frigid-ass club"] = 15,
		["hot-ass club"] = 15,
		["nasty-ass club"] = 15,
		["bad-ass club"] = 15,
		["Boris's Helm (askew)"] = 15,
		["dreadlock whip"] = 10,
		["hippo whip"] = 10,
		["rave whistle"] = 10,
		["serpentine sword"] = 10,
		["hipposkin poncho"] = 10,
		["cheap plastic kazoo"] = 10,
		["spiky turtle helmet"] = 8,
		["curmudgel"] = 8,
		["grumpy old man charrrm bracelet"] = 7,
		["buoybottoms"] = 7,
		["squeaky staff"] = 7,
		["goth kid t-shirt"] = 5,
		["bat whip"] = 5,
		["rattail whip"] = 5,
		["beer bong"] = 5,
		["world's smallest violin"] = 5,
		["giant needle"] = 5,
		["tail o' nine cats"] = 5,
		["Victor, the Insult Comic Hellhound Puppet"] = 5,
		["broken clock"] = 5,
		["tin star"] = 5,
		["ring of aggravate monster"] = 5,
		["annoying pitchfork"] = 5,
		["flaming familiar doppelg&auml;nger"] = 5,
		["magic whistle"] = 4,
		["can cannon"] = 3,
		["Frost&trade; brand sword"] = 3,
		["styrofoam crossbow"] = 3,
		["styrofoam sword"] = 3,
		["nasty rat mask"] = -5,
		["Drowsy Sword"] = -10,
		["pocketwatch on a chain"] = -10,
		["Space Trip safety headphones"] = -100,
	}
	for mlequip, bonus in pairs(equipmentarray) do 
		tw_ml = tw_ml + count_equipped(mlequip) * bonus
	end
	return tw_ml
end

function estimate_ML_modifiers()
	local mlmods = {}
	mlmods.mcd = mcd()
	if familiarid() == 109 then -- purse rat
		mlmods.familiar = math.floor(buffedfamiliarweight() / 2)
	end
	if ascension["zone.manor.quartet song"] == "Provare Compasione Per El Sciocco" then
		mlmods.background = 5
	end
	mlmods.equipment = get_equipment_ML()
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
