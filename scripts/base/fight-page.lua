-- add_processor("/fight.php", function()
-- 	pattern = "<center><table class=\"item\" style=\"float: none\" rel=\"[^\"]*\"><tr><td><img src=\"http://images.kingdomofloathing.com/itemimages/[^\"]+.gif\" alt=\"([^\"]*)\" title=\"([^\"]*)\" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire an item: <b>([^<]+)</b></td></tr></table></center>"
-- 	for alt, title, item in text:gmatch(pattern) do
--~ 		print("item drop", alt, title, 1, item)
-- 	end
-- 	pattern = "<center><table class=\"item\" style=\"float: none\" rel=\"[^\"]*\"><tr><td><img src=\"http://images.kingdomofloathing.com/itemimages/[^\"]+.gif\" alt=\"([^\"]*)\" title=\"([^\"]*)\" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire <b>([0-9]+) ([^<]+)</b></td></tr></table></center>"
-- 	for alt, title, amount, item in text:gmatch(pattern) do
--~ 		print("item drop", alt, title, amount, item)
-- 	end
-- 	pattern = "<center><table class=\"item\" style=\"float: none\" rel=\"[^\"]*\"><tr><td><img src=\"http://images.kingdomofloathing.com/itemimages/[^\"]+.gif\" alt=\"([^\"]*)\" title=\"([^\"]*)\" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire <b>(11) ([^<]+)</b><br>%(That's ridiculous.  It's not even funny.%)</td></tr></table></center>"
-- 	for alt, title, amount, item in text:gmatch(pattern) do
--~ 		print("item drop", alt, title, amount, item)
-- 	end
-- end)

add_printer("/fight.php", function()
	text = text:gsub([[(<center><Table><tr><td><img src="http://images.kingdomofloathing.com/itemimages/mp.gif" height=30 width=30></td><td valign=center class=effect>)(You gain )([0-9,]+)( M[a-z]+ Points*.)(</td></tr></table></center>)]], [[%1<span style="color: darkblue">%2%3%4</span>%5]])
	text = text:gsub([[(<center><table><tr><td><img src="http://images.kingdomofloathing.com/itemimages/hp.gif" height=30 width=30></td><td valign=center class=effect>)(You gain )([0-9,]+)( hit points*.)(</td></tr></table></center>)]], [[%1<span style="color: darkred">%2%3%4</span>%5]])
end)


add_printer("/fight.php", function()
	local combat_round = nil
	for x in text:gmatch("var onturn = ([0-9]+);") do
		combat_round = tonumber(x)
	end
	if combat_round then
		text = text:gsub("(<b>)(Combat)(!</b>)", "%1%2 round " .. tostring(combat_round) .. "%3")
	end

	awesome_monsters = {
		[" Bob Racecar"] = "ketchup hound",
		["a gaudy pirate"] = "gaudy key",
		["some zombie waltzers"] = "dance card",
		["a blur"] = "drum machine",
		["a rampaging adding machine"] = "64735 scroll",
		["a cleanly pirate"] = "rigging shampoo",
		["a creamy pirate"] = "ball polish",
		["a curmudgeonly pirate"] = "mizzenmast mop",
		["a dairy goat"] = "goat cheese",
		["a Brainsweeper"] = "disembodied brain",
		["a Blooper"] = "white pixel",
		["a tomb rat"] = "tomb ratchet",
		["a lobsterfrogman"] = "barrel of gunpowder",
		["a Hellion"] = "hellion cube",
		["a dirty old lihc"] = "",
		["a rampaging adding machine"] = "",
		["The Astronomer"] = "star chart",
	}

-- 	other_item_dropping_monsters = {
-- 		["a bar"] = { "bar skin" },

-- 		["a drunken rat king"] = { "tangle of rat tails" },

-- 		["a baseball bat"] = { "sonar-in-a-biscuit", "baseball" },
-- 		["a briefcase bat"] = { "sonar-in-a-biscuit" },
-- 		["a doughbat"] = { "sonar-in-a-biscuit" },
-- 		["a perpendicular bat"] = { "sonar-in-a-biscuit" },
-- 		["a skullbat"] = { "sonar-in-a-biscuit", "broken skull", "loose teeth" },
-- 		["a vampire bat"] = { "sonar-in-a-biscuit" },
-- 		["a batrat"] = { "sonar-in-a-biscuit" },
-- 		["a ratbat"] = { "sonar-in-a-biscuit" },
-- 		["a beanbat"] = { "enchanted bean", "sonar-in-a-biscuit" },

-- 		["an off-duty Knob Goblin Elite Guard"] = { "Knob Goblin elite polearm", "Knob Goblin elite pants" },
-- 		["a Knob Goblin Elite Guard"] = { "Knob Goblin elite helm", "Knob Goblin elite pants" },
-- 		["a Knob Goblin Elite Guard Captain"] = { "Knob Goblin elite helm", "Knob Goblin elite pants", "Knob Goblin elite polearm" },
-- 		["a Knob Goblin Harem Girl"] = { "Knob Goblin harem pants", "Knob Goblin harem veil", "disease" },
-- 		["a Knob Goblin Madam"] = { "Knob Goblin perfume" },

-- 		["a G Imp"] = { "hot wing" },
-- 		["a P Imp"] = { "hot wing" },
-- 		["a W Imp"] = { "ruby W", "wussiness potion" },

-- 		["a spiny skelelton"] = { "evil eye", "skeleton bone", "smart skull" },
-- 		["a toothy sklelton"] = { "evil eye", "loose teeth", "loose teeth", "skeleton bone" },
-- 		["a giant skeelton"] = { "skeleton bone", "skeleton bone", "skeleton bone" },
-- 		["a senile lihc"] = { "shimmering tendrils" },
-- 		["a slick lihc"] = { "shimmering tendrils" },
-- 		["a corpulent zobmie"] = { "loose teeth", "cranberries", "cranberries" },
-- 		["a grave rober zmobie"] = { "dead guy's watch", "loose teeth", "paranormal ricotta" },

-- 		["a 7-Foot Dwarf"] = { "7-Foot Dwarven mattock", "miner's helmet", "miner's pants" },
-- 		["a 7-Foot Dwarf Foreman"] = { "7-Foot Dwarven mattock", "miner's helmet", "miner's pants" },
-- 		["a drunk goat"] = { "bottle of whiskey" },

-- 		["a 1335 HaXx0r"] = { "334 scroll" },
-- 		["an Anime Smiley"] = { "334 scroll", "Tasty Fun Good rice candy" },
-- 		["Some Bad ASCII Art"] = { "30669 scroll", "33398 scroll", "334 scroll", "334 scroll" },
-- 		["a Lamz0r n00b"] = { "33398 scroll", "plastic guitar" },
-- 		["a me4t begZ0r"] = { "meat vortex" },
-- 		["a Spam Witch"] = { "30669 scroll" },
-- 		["a XXX pr0n"] = { "lowercase N" },

-- 		["an Irritating Series of Random Encounters"] = { "soft green echo eyedrop antidote" },
-- 		["a MagiMechTech MechaMech"] = { "metallic A" },
-- 		["a protagonist"] = { "phonics down", "super-spiky hair gel" },
-- 		["a Quiet Healer"] = { "soft green echo eyedrop antidote" },
-- 		["an Alphabet Giant"] = { "heavy D", "original G" },
-- 		["a Furry Giant"] = { "furry fur" },
-- 		["a Goth Giant"] = { "awful poetry journal", "thin black candle", "Warm Subject gift certificate" },
-- 		["a Possibility Giant"] = { "chaos butterfly", "plot hole" },
-- 		["a Raver Giant"] = { "giant needle", "Mick's IcyVapoHotness Rub", "Angry Farmer candy" },
--		...hits...
--		...lvl11...
--		...lvl12...
-- 	}

	-- yossarian's tools / gremlins, TODO-future: move to lvl12 zone file
	local drop_uncertainty = {}
	if fight["gremlin.has tool"] == "yes" then
		awesome_monsters["a batwinged gremlin"] = "molybdenum hammer"
		awesome_monsters["an erudite gremlin"] = "molybdenum crescent wrench"
		awesome_monsters["a spider gremlin"] = "molybdenum pliers"
		awesome_monsters["a vegetable gremlin"] = "molybdenum screwdriver"
	elseif fight["gremlin.has tool"] ~= "no" then
		if adventure_zone == 182 then
			awesome_monsters["a batwinged gremlin"] = "molybdenum hammer"
			drop_uncertainty["a batwinged gremlin"] = true
		elseif adventure_zone == 184 then
			awesome_monsters["an erudite gremlin"] = "molybdenum crescent wrench"
			drop_uncertainty["an erudite gremlin"] = true
		elseif adventure_zone == 183 then
			awesome_monsters["a spider gremlin"] = "molybdenum pliers"
			drop_uncertainty["a spider gremlin"] = true
		elseif adventure_zone == 185 then
			awesome_monsters["a vegetable gremlin"] = "molybdenum screwdriver"
			drop_uncertainty["a vegetable gremlin"] = true
		end
	end

-- 	local color = "darkslategray"
	local color = nil
	local extra = ""
	if awesome_monsters[monster_name] then
		color = "royalblue"
		if awesome_monsters[monster_name] ~= "" then
			local numitems = count(awesome_monsters[monster_name])
			if monstername("Blooper") then
				numitems = count_item("white pixel") + math.min(count_item("red pixel"), count_item("green pixel"), count_item("blue pixel"))
			end
			if drop_uncertainty[monster_name] then
				extra = extra .. [[<br><center style="font-size: 75%%; color: green">?? []] .. awesome_monsters[monster_name] .. ":" .. numitems .. "] ??</center>"
			else
				extra = extra .. [[<br><center style="font-size: 75%%; color: green">[]] .. awesome_monsters[monster_name] .. ":" .. numitems .. "]</center>"
			end
		end
-- 	elseif other_item_dropping_monsters[monster_name] then
-- 		local dropdata = {}
-- 		for i table.values(other_item_dropping_monsters[monster_name]) do
-- 			table.insert(dropdata, i .. ":" .. count(i)
-- 		end
-- 		extra = extra .. [[<br><center style="font-size: 75%%; color: gray">[]] .. table.concat(dropdata, ", ") .. [[]</center>]]
	end

	-- TODO-future: This should be in pirates.lua, and preferably transfer zone to printer after fight state reset, and should actually be removed after that!
	loadzone = session["adventure.lastzone"]
	if loadzone == 157 then
		local tbl = ascension["zone.pirates.insults"] or {}
		extra = extra .. [[<br><center style="font-size: 75%%; color: green">]] .. table.maxn(tbl).." / 8 insults</center>"
	end

	-- TODO-future: this should be in lair.lua
	local tower_monster_items = {
		["a Beer Batter"] = "baseball",
		["a best-selling novelist"] = "plot hole",
		["a Big Meat Golem"] = "meat vortex",
		["a Bowling Cricket"] = "sonar-in-a-biscuit",
		["a Bronze Chef"] = "leftovers of indeterminate origin",
		["a concert pianist"] = "Knob Goblin firecracker",
		[" El Diablo"] = "mariachi G-string",
		["a fancy bath slug"] = "fancy bath salts",
		["a Flaming Samurai"] = "frigid ninja stars",
		["a giant fried egg"] = "black pepper",
		["a Giant Desktop Globe"] = "NG",
		["a malevolent crop circle"] = "bronzed locust",
		["a possessed pipe-organ"] = "powdered organs",
		["a Pretty Fly"] = "spider web",
		["a Tyrannosaurus Tex"] = "chaos butterfly",
		["a Vicious Easel"] = "disease",
		["an Electron Submarine"] = "photoprotoneutron torpedo",
		["an endangered inflatable white tiger"] = "pygmy blowgun",
		["an Ice Cube"] = "hair spray",
		["the darkness"] = "inkwell",
		["the Fickle Finger of F8"] = "razor-sharp can lid",

		["a collapsed mineshaft golem"] = "stick of dynamite",
		["a giant bee"] = "tropical orchid",
		["an Enraged Cow"] = "barbed-wire fence",
	}
	if tower_monster_items[monster_name] then
		local item_name = tower_monster_items[monster_name]
		local item_id = get_itemid(item_name)
		if have(item_name) then
			-- TODO: use make_href
			extra = extra .. [[<br><center style="font-size: 75%%; color: green">[<a href="fight.php?action=useitem&whichitem=]]..item_id..[[" style="color: green">Use ]] .. item_name .. [[</a>]</center>]] -- should be POST, not GET
		else
			extra = extra .. [[<br><center style="font-size: 75%%; color: grey">[Need ]] .. item_name .. [[]</center>]]
		end
	end

-- 	text = text:gsub("(<span id='monname')(>)([^<]+)(</span>)", [[%1 style="color: ]]..color..[["%2(%3)%4]] .. extra)
	local colorstr = ""
	if color then
		colorstr = [[ style="color: ]]..color..[["]]
	end
	text = text:gsub("(<span id='monname')(>)([^<]+)(</span>)", [[%1]]..colorstr..[[%2%3%4]] .. extra)
end)
