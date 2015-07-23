local card_effects = {
{ "Particularly useful", {
	{ "XVI - The Tower", "Get a random tower key" },
	{ "Mine", "Get chrome ore, asbestos ore, and linoleum ore" },
	{ "Sheep", "Get 3 handfuls of stone wool" },
	{ "Ancestral Recall", "Learn Ancestral Recall (+3 Adventures)" },
	{ "X of Clubs", "Get 3 PvP fights" },
	{ "1952 Mickey Mantle", "Get 10000 Meat (sell card)" },
} },

{ "Buffs (20 Adventures)", {
	{ "X - The Wheel of Fortune", "+100% Item Drops from Monsters" },
	{ "The Race Card", "+200% Combat Initiative" },
	{ "XI - Strength", "+200% Muscle" },
	{ "I - The Magician", "+200% Mysticality" },
	{ "0 - The Fool", "+200% Moxie" },
} },

{ "Stat gain", {
	{ "XXI - The World", "Gain 500 Muscle" },
	{ "III - The Empress", "Gain 500 Mysticality" },
	{ "VI - The Lovers", "Gain 500 Moxie" },
} },

{ "Random results", {
	{ "X of Cups", "Get X random drinks" },
	{ "X of Swords", "Get X random swords" },
	{ "X of Wands", "Get X random effects" },
	{ "Year of Plenty", "Get 5 random foods" },
	{ "Laboratory", "Get 5 random potions" },
	{ "XVI - The Tower", "Get a random tower key" },
} },

{ "Specific items", {
	{ "Spare Tire", "Get tires" },
	{ "Extra Tank", "Get full meat tank" },
	{ "Gift Card", "Get gift card" },
	{ "Professor Plum", "Get 10 plums" },
	{ "X of Salads", "Get X bowls of delicious salad" },
	{ "X of Hearts", "Get X bubblegum hearts" },
	{ "X of Spades", "Get X grave robbing shovels" },
	{ "X of Diamonds", "Get X hyper-cubic zirconiae" },
	{ "X of Kumquats", "Get X kumquats" },
	{ "X of Papayas", "Get X papayas" },
	{ "X of Clubs", "Get X seal-clubbing clubs and 3 PvP fights" },
	{ "X of Coins", "Get X valuable coins" },
	{ "Sheep", "Get 3 handfuls of stone wool" },
	{ "Mine", "Get chrome ore, asbestos ore, and linoleum ore" },
	{ "1952 Mickey Mantle", "Get 1952 Mickey Mantle card (10000 Meat)" },
} },

{ "Skills and mana", {
	{ "Ancestral Recall", "Learn Ancestral Recall (+3 Adventures)" },
	{ "Island", "Get blue mana to cast Ancestral Recall" },
	{ "Giant Growth", "Learn Giant Growth (+300% stats for 1 Adventure)" },
	{ "Forest", "Get green mana to cast Giant Growth" },
	{ "Lightning Bolt", "Learn Lightning Bolt (Deal 3000 damage)" },
	{ "Mountain", "Get red mana to cast Lightning Bolt" },
	{ "Dark Ritual", "Learn Dark Ritual (+3000 MP)" },
	{ "Swamp", "Get black mana to cast Dark Ritual" },
	{ "Healing Salve", "Learn Healing Salve (+3000 HP)" },
	{ "Plains", "Get white mana to cast Healing Salve" },
} },

{ "Temporary weapons (1-handed, disappear at end of day)", {
	{ "Rope", "+2 Muscle/fight, +10 to Familiar Weight" },
	{ "Candlestick", "+2 Mysticality/fight, Mysticality +100%" },
	{ "Revolver", "+2 Moxie/fight, Combat Initiative +50%" },
	{ "Wrench", "Maximum MP +50, Spell Damage +100%" },
	{ "Lead Pipe", "Maximum HP +50, Muscle +100%" },
	{ "Knife", "+50% Meat from Monsters, Moxie +100%" },
} },

{ "Fight a specific monster", {
	{ "IV - The Emperor", "Fight The Emperor" },
	{ "IX - The Hermit", "Fight The Hermit" },
	{ "Green Card", "Fight a legal alien" },
} },

{ "Fight a random phylum-based monster", {
	{ "Werewolf", "Fight a random Beast" },
	{ "The Hive", "Fight a random Bug" },
	{ "XVII - The Star", "Fight a random Constellation" },
	{ "VII - The Chariot", "Fight a random Construct" },
	{ "XV - The Devil", "Fight a random Demon" },
	{ "V - The Hierophant", "Fight a random Dude" },
	{ "Fire Elemental", "Fight a random Elemental" },
	{ "Christmas Card", "Fight a random Elf" },
	{ "Go Fish", "Fight a random Fish" },
	{ "Goblin Sapper", "Fight a random Goblin" },
	{ "II - The High Priestess", "Fight a random Hippy" },
	{ "XIV - Temperance", "Fight a random Hobo" },
	{ "XVIII - The Moon", "Fight a random Horror" },
	{ "Hunky Fireman Card", "Fight a random Humanoid" },
	{ "Aquarius Horoscope", "Fight a random Mer-Kin" },
	{ "XII - The Hanged Man", "Fight a random Orc" },
	{ "Suit Warehouse Discount Card", "Fight a random Penguin" },
	{ "Pirate Birthday Card", "Fight a random Pirate" },
	{ "Plantable Greeting Card", "Fight a random Plant" },
	{ "Slimer Trading Card", "Fight a random Slime" },
	{ "XIII - Death", "Fight a random Undead" },
	{ "Unstable Portal", "Fight a random Weird" },
} },

}

add_printer("/choice.php", function()
	if not text:contains("You realize that if you fan the deck just right, you can see what card you're going to draw.") then return end
	local page_cards = {}
	for value, cardname in text:gmatch([[<option value="([0-9]+)">(.-)</option>]]) do
		page_cards[cardname] = tonumber(value)
	end

	local to_remove = {}
	local new_options = {}
	for _, category in ipairs(card_effects) do
		local label = category[1]
		local cards = category[2]
		table.insert(new_options, string.format([[<optgroup label="%s">]], label))
		for _, x in ipairs(cards) do
			local cardname, effect = x[1], x[2]
			local option = page_cards[cardname]
			if option then
				to_remove[cardname] = true
				table.insert(new_options, string.format([[<option value="%d">%s</option>]], option, effect))
			end
		end
		table.insert(new_options, [[</optgroup>]])
	end

	text = text:gsub([[<option value="([0-9]+)">(.-)</option>]], function(value, cardname)
		if tonumber(value) and page_cards[cardname] == tonumber(value) and to_remove[cardname] then
			return ""
		end
	end)

	text = text:gsub([[(<select name="which" id="which">.-)(</select>)]], function(prefix, suffix)
		return prefix .. table.concat(new_options) .. suffix
	end)
end)
