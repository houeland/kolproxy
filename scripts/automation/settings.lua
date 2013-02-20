function get_ascension_automation_settings(want_bonus)
	local tbl = {
		should_wear_weapons = challenge ~= "fist" and (
				have_item("Operation Patriot Shield") or
				have_item("Trusty") or
				challenge == "zombie" or
				have_item("Brimstone Bludgeon") or
				have_item("Brimstone Bunker") or
				have_item("right bear arm") or
				have_item("left bear arm")
			),
		ignore_buffs = {
			["A Fake Kolproxy Buff To Ignore"] = true,
			["Another Example Kolproxy Buff"] = true,
		},
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
			"glowing red eye", "magilaser blastercannon", "titanium assault umbrella", "armgun", "ridiculously huge sword", "ocarina of space", "amulet of extreme plot significance",
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
-- 			"large box",
			"canopic jar",
			"old coin purse", "old leather wallet",
			"Warm Subject gift certificate",
			"black pension check", "black picnic basket",
			"fat wallet",
			"ancient vinyl coin purse",
			"briefcase",
			"astral hot dog dinner", "astral six-pack", "carton of astral energy drinks",
			"CSA discount card",
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
		-- TODO: add a non-hardcoded place to look up equip requirements
		default_equipment = {
			hat = {
				{ name = "spangly sombrero", check = function() return (get_mainstat() == "Moxie" and level() < 13) end },
				{ name = "Boris's Helm (askew)", check = function() return (level() < 13) end },
				{ name = "Spooky Putty mitre", check = function() return (level() < 13) end },
				"Boris's Helm",
				"double-ice cap",
				"reinforced beaded headband",
				"beer helmet",
--				"Jarlsberg's hat",
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
				"snorkel",
			},
			container = {
				{ name = "Rain-Doh red wings", check = function() return want_bonus.plusinitiative end },
				"Camp Scout backpack",
				"Misty Cape",
				"Misty Cloak",
				"Misty Robe",
				"Rain-Doh red wings",
				"barskin cloak",
				"vampire cape",
			},
			shirt = {
				{ name = "cane-mail shirt", check = function() return (level() < 13) end },
				"astral shirt",
				{ name = "sugar shirt", check = function() return (level() < 13) end },
				{ name = "hipposkin poncho", check = function() return (level() < 13) end },
				"yak anorak",
				{ name = "goth kid t-shirt", check = function() return (level() < 13) end },
				"Grateful Undead T-shirt",
				"souvenir ski t-shirt",
				"ASCII shirt",
				"Knob Goblin elite shirt",
			},
			pants = {
				"stinky cheese diaper",
				"spangly mariachi pants",
				"astral shorts",
				"astral trousers",
				{ name = "buoybottoms", check = function() return (level() < 13) end },
				"Greatest American Pants",
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
				{ name = "Juju Mojo Mask", check = function() return (level() < 13 and not want_bonus.extraplusitems) end },
				{ name = "plastic vampire fangs", check = function() return (level() < 6 and not want_bonus.extraplusitems) end },
				{ name = "Jekyllin hide belt", check = function() return want_bonus.plusitems end },
				{ name = "Mr. Accessory Jr.", check = function() return want_bonus.plusitems end },
				{ name = "astral mask", check = function() return want_bonus.plusitems end },
				{ name = "stinky cheese eye", check = function() return want_bonus.plusitems end },
				{ name = "Baron von Ratsworth's monocle", check = function() return want_bonus.plusitems end },
				{ name = "Loathing Legion rollerblades", check = function() return want_bonus.plusinitiative end },
				"Juju Mojo Mask",
				{ name = "plastic vampire fangs", check = function() return (mp() < 60 or level() < 9) end },
				{ name = "hockey stick of furious angry rage", check = function() return level() < 13 end },
				"astral ring",
				"astral mask",
				{ name = "astral belt", check = function() return (level() >= 7 or (challenge == "fist" and fist_level > 0) or highskill_at_run or ascensionstatus() ~= "Hardcore") and (level() < 13) end }, -- How early should we wear this?
				{ name = "Loathing Legion necktie", check = function() return level() < 13 end },
				{ name = "C.A.R.N.I.V.O.R.E. button", check = function() return level() < 13 end },
				{ name = "shining halo", check = function() return (level() < 13 and not equipment().weapon) end },
				{ name = "badge of authority", check = function() return level() < 13 end },
				{ name = "ring of aggravate monster", check = function() return level() < 13 end },
				"Juju Mojo Mask",
				"plastic vampire fangs",
				"Jekyllin hide belt",
				"Mr. Accessory Jr.",
				"stinky cheese eye",
				"Mr. Accessory",
				"Nickel Gamma of Frugality",
				"observational glasses",
				"pirate fledges",
				"Codpiece of the Goblin King",
				"baconstone pendant",
				"baconstone ring",
				"badass belt",
				"shiny ring",
			}
		}
	}
	if tbl.should_wear_weapons then
		tbl.default_equipment.weapon = {
			"Trusty",
			"Brimstone Bludgeon",
			"ice sickle",
			"haiku katana",
			"right bear arm",
			"Staff of the Healthy Breakfast",
			"hilarious comedy prop",
			"rubber band gun",
		}
		tbl.default_equipment.offhand = {
			"Operation Patriot Shield",
			"Brimstone Bunker",
			"left bear arm",
			"giant clay ashtray",
			"hot plate",
		}
	end
	if not have_skill("Torso Awaregness") then
		tbl.default_equipment.shirt = nil
	end
	function tbl.canwear_itemname(x)
		local itemname = nil
		if type(x) == "string" then
			if have_item(x) and can_equip_item(x) then
				itemname = x
			end
		elseif type(x) == "table" then
			if have(x.name) and x.check and x.check() and can_equip_item(x.name) then
				itemname = x.name
			end
		end
		return itemname
	end

	if have("powdered wig") and basemoxie() >= 20 then
		table.insert(tbl.sell_items, "Van der Graaf helmet")
	end
	if have("pirate fledges") then
		table.insert(tbl.sell_items, "The Big Book of Pirate Insults")
	end
	if meat() < 2000 then
		table.insert(tbl.sell_items, "commemorative war stein")
	end
	if count("meat paste") >= 10 or (moonsign_area() == "Degrassi Knoll" and challenge ~= "zombie") then
		table.insert(tbl.sell_items, "meat paste")
	end

	local maybe_ignore_skills = {
		["Musk of the Moose"] = "Musk of the Moose",
		["A Few Extra Pounds"] = "Holiday Weight Gain",
		["Ghostly Shell"] = "Ghostly Shell",
		["Astral Shell"] = "Astral Shell",
		["Empathy"] = "Empathy of the Newt",
		["Curiosity of Br'er Tarrypin"] = "Curiosity of Br'er Tarrypin",
		["Pasta Oneness"] = "Manicotti Meditation",
		["Leash of Linguini"] = "Leash of Linguini",
		["Spirit of Bacon Grease"] = "Flavour of Magic",
		["Spirit of Garlic"] = "Flavour of Magic",
		["Spirit of Peppermint"] = "Flavour of Magic",
		["Spirit of Cayenne"] = "Flavour of Magic",
		["Spirit of Wormwood"] = "Flavour of Magic",
		["Springy Fusilli"] = "Springy Fusilli",
		["Saucemastery"] = "Sauce Contemplation",
		["Elemental Saucesphere"] = "Elemental Saucesphere",
		["Jalape&ntilde;o Saucesphere"] = "Jalape&ntilde;o Saucesphere",
		["Jaba&ntilde;ero Saucesphere"] = "Jaba&ntilde;ero Saucesphere",
		["Scarysauce"] = "Scarysauce",
		["Smooth Movements"] = "Smooth Movement",
		["The Moxious Madrigal"] = "The Moxious Madrigal",
		["The Magical Mojomuscular Melody"] = "The Magical Mojomuscular Melody",
		["Power Ballad of the Arrowsmith"] = "The Power Ballad of the Arrowsmith",
		["Polka of Plenty"] = "The Polka of Plenty",
		["Fat Leon's Phat Loot Lyric"] = "Fat Leon's Phat Loot Lyric",
		["Ode to Booze"] = "The Ode to Booze",
		["The Sonata of Sneakiness"] = "The Sonata of Sneakiness",
		["Carlweather's Cantata of Confrontation"] = "Carlweather's Cantata of Confrontation",
		["Ur-Kel's Aria of Annoyance"] = "Ur-Kel's Aria of Annoyance",
	}
	for x, y in pairs(maybe_ignore_skills) do
		if have_skill(y) == false then
			tbl.ignore_buffs[x] = true
		end
	end

	return tbl
end
