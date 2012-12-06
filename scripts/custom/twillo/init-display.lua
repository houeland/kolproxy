-- TODO: ?

local function get_fam_init()
	if familiarid() == 159 then -- happy medium
		return buffedfamiliarweight()
	elseif familiarid() == 168 then -- oily woim
		return buffedfamiliarweight() * 2
	else
		return 0
	end
end

local function get_equipment_init__()
	local tw_init = 0	
	local equipmentarray = {
		["Brimstone Boxers"] = 50,
		["little round pebble"] = 50, 
		["Loathing Legion rollerblades"] = 50,
		["rickety old unicycle"] = 50, 
		["beaten-up Chucks"] = 40,
		["mostly rat-hide leggings"] = 40,
		["slime-covered compass"] = 40,
		["pink pinkslip slip"] = 35,
		["shark tooth necklace"] = 35, 
		["Mer-kin sneakmask"] = 30,
		["Bonerdagon necklace"] = 30,
		["costume sword"] = 30,
		["Crimbo pants"] = 30,
		["cyborg stompin' boot"] = 30,
		["furniture dolly"] = 30,
		["intergalactic pom poms"] = 30,
		["rusty compass"] = 30,
		["tortoboggan shield"] = 30,
		["Travoltan trousers"] = 30,
		["Tropical Crimbo Shorts"] = 30,
		["blackberry moccasins"] = 25,
		["crowbar"] = 25,
		["Greek Pasta of Peril"] = 25,
		["Lord Spookyraven's ear trumpet"] = 25,
		["plexiglass pants"] = 25,
		["teflon swim fins"] = 25,
		["Boris's Helm"] = 25,
		["Boris's Helm (askew)"] = 25,
		["chopsticks"] = 20,
		["crown-shaped beanie"] = 20,
		["Grimacite gat"] = 20,
		["Grimacite greaves"] = 20,
		["hors d'oeuvre tray"] = 20,
		["Mer-kin hookspear"] = 20,
		["penguin shorts"] = 20,
		["penguinskin mini-kilt"] = 20,
		["penguinskin mini-skirt"] = 20,
		["Rain-Doh red wings"] = 20,
		["star pants"] = 20,
		["Super Magic Power Sword X"] = 20,
		["tortoboggan"] = 20,
		["wiffle-flail"] = 20,
		["cold ninja mask"] = 15,
		["crowbarrr"] = 15,
		["evil flaming eyeball pendant"] = 15,
		["gnatwing earring"] = 15,
		["ice skates"] = 15,
		["origami riding crop"] = 15,
		["leotarrrd"] = 15,
		["makeshift skirt"] = 15,
		["Pasta of Peril"] = 15,
		["pin-stripe slacks"] = 15,
		["pixel sword"] = 15,
		["plastic guitar"] = 15,
		["sk8board"] = 15,
		["Spooky Putty leotard"] = 15,
		["stainless steel slacks"] = 15,
		["tail o' nine cats"] = 15,
		["Disco 'Fro Pick"] = 11,
		["boxing glove on a spring"] = 10,
		["clockwork pants"] = 10,
		["fire"] = 10,
		["infernal insoles"] = 10,
		["octopus's spade"] = 10,
		["pig-iron shinguards"] = 10,
		["propeller beanie"] = 10,
		["shiny hood ornament"] = 10,
		["wheel"] = 10,
		["1-ball"] = 5,
		["Colonel Mustard's Lonely Spades Club Jacket"] = 2,
		["Amulet of Yendor"] = -10,
		["antique greaves"] = -10,
		["antique helmet"] = -10,
		["antique shield"] = -10,
		["cement sandals"] = -10,
		["giant discarded plastic fork"] = -10,
		["grave robbing shovel"] = -10,
		["rusty grave robbing shovel"] = -10,
		["rusty metal greaves"] = -10,
		["slime-covered greaves"] = -10,
		["slime-covered shovel"] = -10,
		["wumpus-hair loincloth"] = -10,
		["jungle drum"] = -20,
		["outrageous sombrero"] = -20,
		["tap shoes"] = -20,
		["spangly mariachi vest"] = -25,
		["antique spear"] = -30,
		["buoybottoms"] = -30,
		["Slow Talkin' Elliot's dogtags"] = -30,
		["aerated diving helmet"] = -50,
		["rusty diving helmet"] = -50,
		["solid gold pegleg"] = -50,
		["velcro boots"] = -50,
		["makeshift SCUBA gear"] = -100,
		["tiny black hole"] = -200,
	}
	for initequip, bonus in pairs(equipmentarray) do 
		tw_init = tw_init + count_equipped(initequip) * bonus
	end
	return tw_init
end

local function get_skill_init()
	local tw_init = 0
	local skillarray = {
		["Legendary Impatience"] = 100,
		["Hunter's Sprint"] = 100,
		["Lust"] = 50,
		["Overdeveloped Sense of Self Preservation"] = 20,
		["Slimy Shoulders"] = 20,
		["Sloth"] = -25,
	}
	for skill, init in pairs(skillarray) do
		if have_skill(skill) then
			tw_init = tw_init + init
		end
	end
	return tw_init
end

function estimate_initiative_modifiers()
	local initmods = {}
	if moonsign() == "..." then
		initmods.background = (initmods.background or 0) + 0
	end
	initmods.skill = get_skill_init()
	initmods.familiar = get_fam_init()
	initmods.equipment = get_equipment_bonuses().initiative
	initmods.outfit = get_outfit_bonuses().initiative
	initmods.buff = get_buff_bonuses().initiative

	local ml = 0
	for mname, m in pairs(estimate_ML_modifiers()) do
		if mname ~= "mcd" then
			ml = ml + m
		end
	end

	local ml_init_penalty = 0
	if 20 < ml and ml <= 40 then
		ml_init_penalty = 0 + 1 * (ml - 20)
	elseif 40 < ml and ml <= 60 then
		ml_init_penalty = 20 + 2 * (ml - 40)
	elseif 60 < ml and ml <= 80 then
		ml_init_penalty = 60 + 3 * (ml - 60)
	elseif 80 < ml and ml <= 100 then
		ml_init_penalty = 120 + 4 * (ml - 80)
	elseif 100 < ml then
		ml_init_penalty = 200 + 5 * (ml - 100)
	end

	initmods.mlpenalty = -ml_init_penalty

	return initmods
end

add_printer("/charpane.php", function()
	if not setting_enabled("show modifier estimates") then return end

	local init = 0
	local total_init = 0
	local ml_init_penalty = 0
	for x, y in pairs(estimate_initiative_modifiers()) do
		init = init + y
		if x == "mlpenalty" then
			ml_init_penalty = -y
		else
			total_init = total_init + y
		end
	end

	local uncertaintystr = ""
	if not have_cached_data() then
		uncertaintystr = " ?"
	end
	print_charpane_value { normalname = "Initiative", compactname = "Init", value = string.format("%+d%%", init) .. uncertaintystr, tooltip = string.format("%+d%% initiative - %d%% ML penalty = %+d%% combined", total_init, ml_init_penalty, init) }
end)
