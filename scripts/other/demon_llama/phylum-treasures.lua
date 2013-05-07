--v.2.1a

local phylumTreasureEffects = {
	["beast"] = {
		siphon = {
			name = "Rampage!",
			summary = "+50% Weapon Damage",
		},
		paste = {
			name = "Beastly Flavor",
			summary = "+3 Familiar Weight",
		},
	},
	["bug"] = {
		siphon = {
			name = "Cockroach Scurry",
			summary = "+50% Combat Initiative",
		},
		paste = {
			name = "Buggy Flavor",
			summary = "25% chance of poisoning opponent",
		},
	},
	["plant"] = {
		siphon = {
			name = "none",
			summary = "Restores MP",
		},
		paste = {
			name = "Chlorophyll Flavor",
			summary = "Regenerate 1-3 MP per Adventure",
		},
	},
	["constellation"] = {
		siphon = {
			name = "none",
			summary = "Restores MP",
		},
		paste = {
			name = "Cosmic Flavor",
			summary = "+10% to critical spell chance",
		},
	},
	["crimbo"] = {
		siphon = {
			name = "Holiday Bliss",
			summary = "+20% item & meat drops",
		},
		paste = {
			name = "Crimbo Flavor",
			summary = "Spell Damage +30",
		},
	},
	["demon"] = {
		siphon = {
			name = "Heart Aflame",
			summary = "+50 Hot Damage",
		},
		paste = {
			name = "Demonic Flavor",
			summary = "+10 Hot Damage, So-So Hot Resistance",
		},
	},
	["undead"] = {
		siphon = {
			name = "Creepypasted",
			summary = "+50 Spooky Damage",
		},
		paste = {
			name = "Spooky Flavor",
			summary = "+10 Spooky Damage, So-So Spooky Resistance",
		},
	},
	["elemental"] = {
		siphon = {
			name = "Elemental Mastery",
			summary = "+5 Prismatic damage",
		},
		paste = {
			name = "Elemental Flavor",
			summary = "+5 prismatic damage",
		},
	},
	["fish"] = {
		siphon = {
			name = "Fishy",
			summary = "-1 Adventure cost underwater",
		},
		paste = {
			name = "Fishy",
			summary = "-1 Adventure cost underwater",
		},
	},
	["goblin"] = {
		siphon = {
			name = "Gutterminded",
			summary = "+50 Sleaze Damage",
		},
		paste = {
			name = "Gobliny Flavor",
			summary = "5 Damage Reduction",
		},
	},
	["dude"] = {
		siphon = {
			name = "none",
			summary = "Restores HP",
		},
		paste = {
			name = "none",
			summary = "none",
		},
	},
	["humanoid"] = {
		siphon = {
			name = "World's Shortest Giant",
			summary = "So-so Resistance to all elements",
		},
		paste = {
			name = "Greasy Flavor",
			summary = "Weapon Damage +30",
		},
	},
	["hippy"] = {
		siphon = {
			name = "Transcendental Wind",
			summary = "+50 Mysticality",
		},
		paste = {
			name = "Hippy Flavor",
			summary = "Mysticality +15",
		},
	},
	["hobo"] = {
		siphon = {
			name = "Mo' Hobo",
			summary = "+10 Hobo Power",
		},
		paste = {
			name = "Hobo Flavor",
			summary = "+10 Stench Damage, So-So Stench Resistance",
		},
	},
	["horror"] = {
		siphon = {
			name = "Void Between the Stars",
			summary = "+50 Cold Damage",
		},
		paste = {
			name = "Indescribable Flavor",
			summary = "Spell Damage +30",
		},
	},
	["mer-kin"] = {
		siphon = {
			name = "Fishy",
			summary = "-1 Adventure cost underwater",
		},
		paste = {
			name = "Mer-kinny Flavor",
			summary = "Lets you breathe underwater",
		},
	},
	["construct"] = {
		siphon = {
			name = "Mortarfied",
			summary = "+100 Damage Absorption",
		},
		paste = {
			name = "Oily Flavor",
			summary = "Muscle +15",
		},
	},
	["orc"] = {
		siphon = {
			name = "Orc Chops",
			summary = "+50 Muscle",
		},
		paste = {
			name = "Fratty Flavor",
			summary = "Moxie +15",
		},
	},
	["penguin"] = {
		siphon = {
			name = "Fishy",
			summary = "-1 Adventure cost underwater",
		},
		paste = {
			name = "Penguinny Flavor",
			summary = "+10 Cold Damage, So-So Cold Resistance",
		},
	},
	["pirate"] = {
		siphon = {
			name = "Arresistible",
			summary = "+50 Moxie",
		},
		paste = {
			name = "Piratey Flavor",
			summary = "2x chance of critical hit",
		},
	},
	["slime"] = {
		siphon = {
			name = "In the Slimelight",
			summary = "+50 Stench Damage",
		},
		paste = {
			name = "Slimy Flavor",
			summary = "+10 Sleaze Damage, So-So Sleaze Resistance",
		},
	},
	["strange"] = {
		siphon = {
			name = "Heisenberglary",
			summary = "+/- Stats Randomly",
		},
		paste = {
			name = "Weird Flavor",
			summary = "???",
		},
	},
}

local phylumTreasureQualities = {
	blue = {
		["quality"] = "Good",
		["color"] = "blue",
		["min adventures"] = 4,
		["max adventures"] = 5,
		["level requirement"] = 0,
		["effect duration"] = 5,
	},
	orange = {
		["quality"] = "Awesome",
		["color"] = "orange",
		["min adventures"] = 6,
		["max adventures"] = 7,
		["level requirement"] = 4,
		["effect duration"] = 10,
	},
	red = {
		["quality"] = "Awesome",
		["color"] = "red",
		["min adventures"] = 8,
		["max adventures"] = 9,
		["level requirement"] = 8,
		["effect duration"] = 15,
	},
	paste = {
		["min adventures"] = 5,
		["max adventures"] = 10,
		["level requirement"] = 4,
		["effect duration"] = 10,
	},
}

local phylumTreasureNames = {
	["beast"] = {
		siphon = {
			blue = "Zoodriver",
			orange = "Sloe Comfortable Zoo",
			red = "Sloe Comfortable Zoo on Fire",
		},
		paste = "beastly paste",
	},
	["bug"] = {
		siphon = {
			blue = "Grasshopper",
			orange = "Locust",
			red = "Plague of Locusts",
		},
		paste = "bug paste",
	},
	["plant"] = {
		siphon = {
			blue = "Green Velvet",
			orange = "Green Muslin",
			red = "Green Burlap",
		},
		paste = "chlorophyll paste",
	},
	["constellation"] = {
		siphon = {
			blue = "Dark & Starry",
			orange = "Black Hole",
			red = "Event Horizon",
		},
		paste = "cosmic paste",
	},
	["crimbo"] = {
		siphon = {
			blue = "Lollipop Drop",
			orange = "Candy Alexander",
			red = "Candicaine",
		},
		paste = "Crimbo paste",
	},
	["demon"] = {
		siphon = {
			blue = "Suffering Sinner",
			orange = "Suppurating Sinner",
			red = "Sizzling Sinner",
		},
		paste = "demonic paste",
	},
	["undead"] = {
		siphon = {
			blue = "Drac & Tan",
			orange = "Transylvania Sling",
			red = "Shot of the Living Dead",
		},
		paste = "ectoplasmic paste",
	},
	["elemental"] = {
		siphon = {
			blue = "Firewater",
			orange = "Earth and Firewater",
			red = "Earth, Wind and Firewater",
		},
		paste = "elemental paste",
	},
	["fish"] = {
		siphon = {
			blue = "Caipiranha",
			orange = "Flying Caipiranha",
			red = "Flaming Caipiranha",
		},
		paste = "fishy paste",
	},
	["goblin"] = {
		siphon = {
			blue = "Buttery Knob",
			orange = "Slippery Knob",
			red = "Flaming Knob",
		},
		paste = "goblin paste",
	},
	["dude"] = {
		siphon = {
			blue = "Humanitini",
			orange = "More Humanitini than Humanitini",
			red = "Oh, the Humanitini",
		},
		paste = "gooey paste",
	},
	["humanoid"] = {
		siphon = {
			blue = "Red Dwarf",
			orange = "Golden Mean",
			red = "Green Giant",
		},
		paste = "greasy paste",
	},
	["hippy"] = {
		siphon = {
			blue = "Fauna Libre",
			orange = "Chakra Libre",
			red = "Aura Libre",
		},
		paste = "hippy paste",
	},
	["hobo"] = {
		siphon = {
			blue = "Mohobo",
			orange = "Moonshine Mohobo",
			red = "Flaming Mohobo",
		},
		paste = "hobo paste",
	},
	["horror"] = {
		siphon = {
			blue = "Great Old Fashioned",
			orange = "Fuzzy Tentacle",
			red = "Crazymaker",
		},
		paste = "indescribably horrible paste",
	},
	["mer-kin"] = {
		siphon = {
			blue = "Punchplanter",
			orange = "Doublepunchplanter",
			red = "Haymaker",
		},
		paste = "Mer-kin paste",
	},
	["construct"] = {
		siphon = {
			blue = "Cement Mixer",
			orange = "Jackhammer",
			red = "Dump Truck",
		},
		paste = "oily paste",
	},
	["orc"] = {
		siphon = {
			blue = "Sazerorc",
			orange = "Sazuruk-hai",
			red = "Flaming Sazerorc",
		},
		paste = "orc paste",
	},
	["penguin"] = {
		siphon = {
			blue = "Herring Daquiri",
			orange = "Herring Wallbanger",
			red = "Herringtini",
		},
		paste = "penguin paste",
	},
	["pirate"] = {
		siphon = {
			blue = "Aye Aye",
			orange = "Aye Aye, Captain",
			red = "Aye Aye, Tooth Tooth",
		},
		paste = "pirate paste",
	},
	["slime"] = {
		siphon = {
			blue = "Slimosa",
			orange = "Extra-slimy Slimosa",
			red = "Slimebite",
		},
		paste = "slimy paste",
	},
	["strange"] = {
		siphon = {
			blue = "Drunken Philosopher",
			orange = "Drunken Neurologist",
			red = "Drunken Astrophysicist",
		},
		paste = "strange paste",
	},
}

function get_phylum_treasure(phylum)
	if not phylum then return nil end
	return {
		siphon = {
			blue = {
				name = phylumTreasureNames[phylum].siphon.blue,
				effect = phylumTreasureEffects[phylum].siphon,
				quality = phylumTreasureQualities.blue,
			},
			orange = {
				name = phylumTreasureNames[phylum].siphon.orange,
				effect = phylumTreasureEffects[phylum].siphon,
				quality = phylumTreasureQualities.orange,
			},
			red = {
				name = phylumTreasureNames[phylum].siphon.red,
				effect = phylumTreasureEffects[phylum].siphon,
				quality = phylumTreasureQualities.red,
			},
		},
		paste = {
			name = phylumTreasureNames[phylum].paste,
			effect = phylumTreasureEffects[phylum].paste,
			quality = phylumTreasureQualities.paste,
		}
	}
end
