function get_ascension_automation_settings(want_bonus)
	local tbl = {
		should_wear_weapons = playerclass("Accordion Thief") or
				challenge == "zombie" or
				challenge == "jarlsberg" or
				have_item("Jarlsberg's pan (Cosmic portal mode)") or
				have_item("Operation Patriot Shield") or
				have_item("Sneaky Pete's basket") or
				have_item("Brimstone Bludgeon") or
				have_item("Brimstone Bunker") or
				have_item("astral shield") or
				have_item("right bear arm") or
				have_item("left bear arm") or
				have_item("Meat Tenderizer is Murder") or
				have_item("A Light that Never Goes Out") or
				have_item("Staff of the Headmaster's Victuals") or
				have_item("Saucepanic") or
				have_item("Frankly Mr. Shank"),
		ignore_buffs = {},
		slimeling_feed_items = {
			"snapdragon pistil", "elephant stinger",
			"spooky stick",
			"diamond-studded cane", "leather mask", "flaming crutch", "infernal insoles", "infernal fife",
			"Knob Goblin scimitar", "Knob Goblin pants", "Knob Goblin tongs", "viking helmet",
			"spiked femur", "lihc face", "rusty grave robbing shovel", "bone flute",
			"knob bugle",
			"cornuthaum", "vorpal blade", "magic whistle", "ninja hot pants",
			"ASCII shirt",
			"crowbarrr", "Jolly Roger charrrm bracelet",
			"magilaser blastercannon", "armgun", "ridiculously huge sword", "ocarina of space",
			"rave whistle",
			"black helmet", "black sword", "black greaves",
			"leotarrrd", "grassy cutlass",
			"batblade",
			"antique helmet", "antique spear", "antique shield", "antique greaves",
			"broken sword",
		},
		slimeling_feed_except_one = {
			{ "leather chaps", },
			{ "wonderwall shield", },
			{ "black shield", },
			{ "snake shield", },
			{ "oversized pizza cutter", "huge spoon", },
			{ "hors d'oeuvre tray", },
			{ "hot plate", "coffin lid", },
			{ "tap shoes", },
			{ "worn tophat", "wolf mask", "cornuthaum", },
			{ "dead guy's watch", },
			{ "disturbing fanfic", },
			{ "4-dimensional guitar", },
			{ "mesh cap", },
		},
		use_items = {
			"pork elf goodies sack",
			"can of Rain-Doh",
			"Knob Goblin lunchbox",
			"chest of the Bonerdagon",
			"small box", "dead mimic",
			"canopic jar",
			"old coin purse", "old leather wallet",
			"Warm Subject gift certificate",
			"black pension check", "black picnic basket",
			"fat wallet",
			"ancient vinyl coin purse",
			"briefcase",
			"astral hot dog dinner", "astral six-pack", "carton of astral energy drinks",
			"CSA discount card",
			"Squat-Thrust Magazine",
			"O'RLY manual",
			"Ye Olde Bawdy Limerick",
		},
		use_except_one = {
			"large box",
		},
		sell_items = {
			"baconstone", "hamethyst", "porquoise",
			"meat stack", "dense meat stack",
			"magicalness-in-a-can", "concentrated magicalness pill",
			"moxie weed", "giant moxie weed",
			"strongness elixir", "enchanted barbell",
			"bit-o-cactus", "handful of moss", "suntan lotion of moxiousness", "ancient protein powder",
			"Mad Train wine",
			"ironic jogging shorts",
			"spooky shrunken head", "bowl of cottage cheese",
			"fat stacks of cash",
			"rat appendix", "batgut", "catgut", "bat guano", "bat wing",
			"Imp Ale", "hot katana blade", "demon skin", "cast",
			"8-ball",
			"gator skin", "decaying goldfish liver", "sewer nuggets", "bottle of sewage schnapps",
			"ghuol ears", "lihc eye", "smart skull", "ghuol egg", "ghuol guolash", "cranberries",
			"grouchy restless spirit",
			"stone of eXtreme power",
			"cocoa eggshell fragment",
			"towel", "gob of wet hair", "cardboard wakizashi",
			"phat turquoise bead", "beach glass bead", "clay peace-sign bead",
			"sunken chest", "pirate pelvis",
			"ballroom blintz", "royal jelly", "unidentified jerky", "mind flayer corpse",
			"procrastination potion", "probability potion",
			"drab sonata",
			"cat appendix",
			"baby killer bee",
			"rocky raccoon", "Tuesday's ruby", "mother's little helper", "happiness",
			"tip jar", "barrrnacle", "grumpy old man charrrm", "tarrrnish charrrm", "all-purpose cleaner",
			"empty Cloaca-Cola bottle", "valuable trinket",
			"enormous belt buckle",
			"flimsy clipboard", "stolen office supplies",
			"awful poetry journal", "furry fur",
			"commemorative war stein",
		},
		sell_except_one = {
			"yeti fur",
			"fancy bath salts",
			"leathery bat skin", "leathery cat skin", "leathery rat skin",
			"photoprotoneutron torpedo",
			"Angry Farmer candy", "plot hole", "chaos butterfly",
			"metallic A",
			"original G",
		},
		default_equipment = {
			hat = {
				{ name = "silent beret", check = function() return want_bonus.noncombat end },
				"Crown of Thrones",
				{ name = "spangly sombrero", check = function() return (mainstat_type("Moxie") and level() < 13) end },
				{ name = "Boris's Helm (askew)", check = function() return (level() < 13) end },
				{ name = "Spooky Putty mitre", check = function() return (level() < 13) end },
				"Boris's Helm",
				"Brimstone Beret",
				"astral chapeau",
				"Hairpiece On Fire",
				{ name = "miner's helmet", check = function() return want_bonus.extraplusitems end },
				"double-ice cap",
				{ name = "filthy knitted dread sack", check = function() return want_bonus.elemental_weapon_damage end },
				"reinforced beaded headband",
				{ name = "beer helmet", check = function() return (not want_bonus.extraplusitems) end },
				"Jarlsberg's hat",
				"fuzzy busby",
				"worn tophat",
				"fuzzy earmuffs",
				"powdered wig",
				"miner's helmet",
				"Van der Graaf helmet",
				"chef's hat",
				"Crown of the Goblin King",
				"cornuthaum",
				"Knob Goblin elite helm",
				"mariachi hat",
				"helmet turtle",
				"snorkel",
			},
			container = {
				{ name = "Rain-Doh red wings", check = function() return want_bonus.plusinitiative end },
				{ name = "Camp Scout backpack", check = function() return not want_bonus.easy_combat end },
				"Buddy Bjorn",
				"Misty Cape",
				"Misty Cloak",
				"Misty Robe",
				"Rain-Doh red wings",
				"Camp Scout backpack",
				"barskin cloak",
				"giant gym membership card",
			},
			shirt = {
				{ name = "flaming pink shirt", check = function() return want_bonus.plusitems end },
				"Sneaky Pete's leather jacket (collar popped)",
				"Sneaky Pete's leather jacket",
				{ name = "cane-mail shirt", check = function() return (level() < 13) end },
				"astral shirt",
				"flaming pink shirt",
				{ name = "sugar shirt", check = function() return (level() < 13) end },
				{ name = "hipposkin poncho", check = function() return (level() < 13) end },
				"yak anorak",
				{ name = "goth kid t-shirt", check = function() return (level() < 13) end },
				"Grateful Undead T-shirt",
				"punk rock jacket",
				"souvenir ski t-shirt",
				"harem girl t-shirt",
				"ASCII shirt",
				"Knob Goblin elite shirt",
				"eXtreme Bi-Polar Fleece Vest",
			},
			pants = {
				"Pantsgiving",
				{ name = "stinky cheese diaper", check = function() return not want_bonus.easy_combat end },
				"Brimstone Boxers",
				"spangly mariachi pants",
				"astral shorts",
				"astral trousers",
				"Vicar's Tutu",
				{ name = "buoybottoms", check = function() return (level() < 13) end },
				"Greatest American Pants",
				{ name = "Whoompa Fur Pants", check = function() return want_bonus.elemental_weapon_damage end },
				{ name = "giant discarded torn-up glove", check = function() return want_bonus.elemental_weapon_damage end },
				{ name = "filthy corduroys", check = function() return want_bonus.elemental_weapon_damage end },
				"big pants",
				"leather chaps",
				"distressed denim pants",
				"bullet-proof corduroys",
				"miner's pants",
				"swashbuckling pants",
				"Boss Bat britches",
				"stylish swimsuit",
				"Knob Goblin elite pants",
				"ninja hot pants",
				"Knob Goblin pants",
				"old sweatpants",
			},
			accessories = {
				{ name = "Fuzzy Slippers of Hatred", check = function() return want_bonus.noncombat end },
				{ name = "Space Trip safety headphones", check = function() return want_bonus.noncombat end },
				{ name = "ring of conflict", check = function() return want_bonus.noncombat end },
				{ name = "Juju Mojo Mask", check = function() return (level() < 13 and not want_bonus.extraplusitems) end },
				{ name = "plastic vampire fangs", check = function() return (level() < 6 and not want_bonus.extraplusitems) end },
				{ name = "Jekyllin hide belt", check = function() return want_bonus.plusitems end },
				{ name = "Mr. Accessory Jr.", check = function() return want_bonus.plusitems end },
				{ name = "astral mask", check = function() return want_bonus.plusitems end },
				{ name = "stinky cheese eye", check = function() return want_bonus.plusitems end },
				{ name = "Baron von Ratsworth's monocle", check = function() return want_bonus.plusitems end },
				{ name = "Loathing Legion rollerblades", check = function() return want_bonus.plusinitiative end },
				{ name = "Juju Mojo Mask", check = function() return level() < 13 end },
				{ name = "Brimstone Brooch", check = function() return not ascensionstatus("Aftercore") end },
				{ name = "Brimstone Bracelet", check = function() return not ascensionstatus("Aftercore") end },
				{ name = "plastic vampire fangs", check = function() return (mp() < 60 or level() < 9) end },
				{ name = "hockey stick of furious angry rage", check = function() return level() < 13 end },
				"over-the-shoulder Folder Holder",
				"astral ring",
				"astral mask",
				{ name = "astral belt", check = function() return (level() >= 7 or (challenge == "fist" and fist_level > 0) or highskill_at_run or ascensionstatus() ~= "Hardcore") and (level() < 13) end }, -- How early should we wear this?
				{ name = "Loathing Legion necktie", check = function() return level() < 13 end },
				{ name = "C.A.R.N.I.V.O.R.E. button", check = function() return level() < 13 end },
				{ name = "frosty halo", check = function() return want_bonus.plusitems and not equipment().weapon end },
				{ name = "furry halo", check = function() return want_bonus.plusitems and not equipment().weapon end },
				{ name = "shining halo", check = function() return level() < 13 and not equipment().weapon end },
				{ name = "imp unity ring", check = function() return want_bonus.elemental_weapon_damage end },
				{ name = "badge of authority", check = function() return level() < 13 end },
				{ name = "ring of aggravate monster", check = function() return level() < 13 end },
				"Juju Mojo Mask",
				"plastic vampire fangs",
				"Jekyllin hide belt",
				"Mr. Accessory Jr.",
				"stinky cheese eye",
				"Mr. Accessory",
				"Nickel Gamma of Frugality",
				{ name = "furry halo", check = function() return not want_bonus.easy_combat and not equipment().weapon end },
				{ name = "frosty halo", check = function() return not want_bonus.easy_combat and not equipment().weapon end },
				{ name = "observational glasses", check = function() return not want_bonus.easy_combat end },
				"bejeweled pledge pin",
				"pirate fledges",
				"Codpiece of the Goblin King",
				"baconstone pendant",
				"baconstone ring",
				"badass belt",
				"shiny ring",
			}
		}
	}
	if tbl.should_wear_weapons or not can_wear_weapons() then
		tbl.default_equipment.weapon = {
			"Trusty",
			{ name = "Staff of Simmering Hatred", check = function() return not want_bonus.not_casting_spells end },
			{ name = "Staff of the Walk-In Freezer", check = function() return not want_bonus.not_casting_spells end },
			{ name = "Staff of the Woodfire", check = function() return not want_bonus.not_casting_spells end },
			{ name = "Staff of Queso Escusado", check = function() return not want_bonus.not_casting_spells end },
			{ name = "Staff of the Kitchen Floor", check = function() return not want_bonus.not_casting_spells end },
			{ name = "Staff of the Black Kettle", check = function() return not want_bonus.not_casting_spells end },
			{ name = "Staff of the Soupbone", check = function() return not want_bonus.not_casting_spells end },
			"Brimstone Bludgeon",
			"ice sickle",
			"haiku katana",
			"right bear arm",
			{ name = "Staff of the Standalone Cheese", check = function() return want_bonus.plusinitiative end },
			{ name = "Staff of the Light Lunch", check = function() return want_bonus.plusinitiative end },
			{ name = "Staff of the All-Steak", check = function() return want_bonus.easy_combat end },
			{ name = "Staff of the Cream of the Cream", check = function() return want_bonus.easy_combat end },
			"Staff of the Staff of Life",
			"Staff of the All-Steak",
			"Staff of the Healthy Breakfast",
			"Staff of Fruit Salad",
			"Shakespeare's Sister's Accordion",
			{ name = "Staff of the Headmaster's Victuals", check = function() return not want_bonus.not_casting_spells end },
			"alarm accordion",
			"peace accordion",
			"Squeezebox of the Ages",
			"Rock and Roll Legend",
			"accordion file",
			"baritone accordion",
			"stolen accordion",
			"Saucepanic",
			"Frankly Mr. Shank",
			"Meat Tenderizer is Murder",
			"Sneaky Pete's basket",
			"hilarious comedy prop",
			"ironic battle spoon",
			"rubber band gun",
			"seal-clubbing club",
			"turtle totem",
		}
		tbl.default_equipment.offhand = {
			"Jarlsberg's pan (Cosmic portal mode)",
			"Jarlsberg's pan",
			{ name = "Operation Patriot Shield", check = function() return level() < 13 end },
			"Bag o' Tricks",
			{ name = "Rain-Doh green lantern", check = function() return not want_bonus.not_casting_spells end },
			"Operation Patriot Shield",
			"astral shield",
			"Brimstone Bunker",
			"A Light that Never Goes Out",
			"Ouija Board, Ouija Board",
			"left bear arm",
			{ name = "hot plate", check = function() return want_bonus.elemental_weapon_damage end },
			{ name = "Victor, the Insult Comic Hellhound Puppet", check = function() return want_bonus.monster_level end },
			"wicker shield",
			"giant clay ashtray",
			"hot plate",
			"magical ice cubes",
		}
	end
	function tbl.canwear_itemname(x)
		local itemname = nil
		if type(x) == "string" then
			if have_item(x) and can_equip_item(x) then
				itemname = x
			end
		elseif type(x) == "table" then
			if have_item(x.name) and x.check and x.check() and can_equip_item(x.name) then
				if want_bonus.easy_combat and datafile("items")[x.name] and ((datafile("items")[x.name].equip_bonuses or {})["Monster Level"] or 0) > 0 then
				else
					itemname = x.name
				end
			end
		end
		return itemname
	end

	if tbl.canwear_itemname("powdered wig") then
		table.insert(tbl.sell_items, "Van der Graaf helmet")
	end
	if have_item("pirate fledges") then
		table.insert(tbl.sell_items, "The Big Book of Pirate Insults")
	end
	if count_item("meat paste") >= 10 or (moonsign_area() == "Degrassi Knoll" and challenge ~= "zombie") then
		table.insert(tbl.sell_items, "meat paste")
	end

	local maybe_ignore_skills = datafile("buff-recast-skills")

	maybe_ignore_skills["Spirit of Bacon Grease"] = "Flavour of Magic"
	maybe_ignore_skills["Spirit of Garlic"] = "Flavour of Magic"
	maybe_ignore_skills["Spirit of Peppermint"] = "Flavour of Magic"
	maybe_ignore_skills["Spirit of Cayenne"] = "Flavour of Magic"
	maybe_ignore_skills["Spirit of Wormwood"] = "Flavour of Magic"

	for x, y in pairs(maybe_ignore_skills) do
		if have_skill(y) == false then
			tbl.ignore_buffs[x] = true
		end
	end

	return tbl
end
