-- To Do - make underwater separate. Wait for spading on e.g. 28% combat rate

function get_equipment_com__()
	local tw_com = 0
	local equipmentarray = {
		["monster bait"] = 5,
		["Dungeon Fist gauntlet"] = 5,
		["ring of conflict"] = -5,
		["Space Trip safety headphones"] = -5,
		["silent beret"] = -5,
	}
	for comequip, com in pairs(equipmentarray) do 
		if have_equipped(comequip) then
			tw_com = tw_com + com
		end
	end
	return tw_com
end
	
function get_underwater_com()
	local tw_com = 0
	if buff("Colorfully Concealed") then
		tw_com = tw_com + -5
	end
	if have_equipped("Mer-kin sneakmask") then
		tw_com = tw_com + -5
	end
	return tw_com
end

add_printer("/charpane.php", function()
	if not setting_enabled("show modifier estimates") then return end

	local tw_com = 0
	if familiarpicture() == "hounddog" then
		tw_com = tw_com + math.min(math.floor(buffedfamiliarweight() / 6), 5)
	end
	tw_com = tw_com + (get_buff_bonuses().combat or 0)
	tw_com = tw_com + (get_equipment_bonuses().combat or 0)
	tw_com = tw_com + (get_outfit_bonuses().combat or 0)
	if ascension["zone.manor.quartet song"] == "Sono Un Amante Non Un Combattente" then
		tw_com = tw_com - 5
	end
	if tw_com > 25 then
		tw_com = 25 + math.floor((tw_com - 25) / 5)	
	end
	if tw_com < -25 then
		tw_com = -25 + math.ceil((tw_com + 25) / 5)	
	end
	tw_com = tw_com + get_underwater_com()

	local uncertaintystr = ""
	if not have_cached_data() then
		uncertaintystr = " ?"
	end
	print_charpane_value { normalname = "(Non)combat", compactname = "C/NC", value = string.format("%+d%%", tw_com) .. uncertaintystr }
end)
