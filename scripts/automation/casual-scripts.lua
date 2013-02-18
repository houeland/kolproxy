local function nc_buffs()
	return { "The Sonata of Sneakiness", "Smooth Movements", "Fresh Scent", "Simply Invisible"}
	-- To Do - Shrug +combat effects
end


-- go("Comment", 157, combat_macro(), noncombattbl(), effectstbl(), "Fam", 30, { equipment = { hat = "eyepatch", pants = "swashbuckling pants", acc1 = "stuffed shoulder parrot" } })



local function c_buffs()
	return { "Carlweather's Cantata of Confrontation", "Musk of the Moose", "Hippy Stench", "Simply Irresistible"}
	-- To Do - Shrug -combat effects
end

local function nc_equip()
	return { equipment = { acc3 = "ring of conflict", acc2 = "Space Trip safety headphones" } }
	-- To Do - Remove +combat items
end

local function c_equip()
-- 	return { equipment = { acc3 = "monster bait", acc2 = "Dungeon Fist gauntlet" } }
	return { equipment = { acc3 = "monster bait" } }
	-- To Do - Remove -combat items
end

function get_casual_automation_scripts()
	local pwd = session.pwd -- inserting pwd, boo!
	local f = {}
	local macro_runaway_all = casual_macro_runaway_all
	local ensure_nc_buffs = nc_buffs
	local ensure_c_buffs = c_buffs
	local ensure_nc_equip = nc_equip
	local ensure_c_equip = c_equip
	local macro_pickpocket = casual_macro_pickpocket
	local macro_kill = casual_macro_kill
	local macro_runaway_most = casual_macro_runaway_most
	local script = get_automation_scripts()
	local fam = script.want_familiar
	local wear = script.wear
	local go = script.go
	local ensure_buffs = script.ensure_buffs
	local ensure_mp = script.ensure_mp

	function f.find_black_market()
		if have("black market map") and have("sunken eyes") and have("broken wings") then
			inform "locate black market"
			meatpaste_items("broken wings", "sunken eyes")
			async_get_page("/inv_familiar.php", { whichitem = get_itemid("reassembled blackbird"), ajax = 1, pwd = pwd })
			fam "Reassembled Blackbird"
			set_result(use_item("black market map"))
			did_action = not have("black market map")
		else
			go("Do Black Forest", 111, casual_macro_runaway_all(), {}, c_buffs(), "Jumpsuited Hound Dog", 45, c_equip())
		end
	end
		
	function f.do_tavern()
		if quest_text("You should head back to Bart") then
			result, resulturl = get_page("/tavern.php", { place = "barkeep" })
			did_action = have("Typical Tavern swill")
		elseif quest_text("Bart Ender wants you to head down") then
			cellarpt = get_page("/cellar.php")
			local function explore()
				tiles = { 4, 3, 2, 1, 6, 11, 16, 17, 21, 22 }
				for _, x in ipairs(tiles) do
					if cellarpt:contains("whichspot=" .. x .. ">") then
						inform("exploring rat cellar tile " .. x)
						return get_page("/cellar.php", { action = "explore", whichspot = x })
					end
				end
				critical "No suitable tile found for rat cellar"
			end
			fam "Rogue Program"
			script.heal_up()
			script.burn_mp(20)
			ensure_mp(5)
			ensure_buffs(nc_buffs())
			-- TODO - Ensure +damage buffs
			local pt, url = explore()
			-- TODO: handle barrels better?
			result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_stasis(), {
				["1984 Had Nothing on This Cellar"] = "Stink them out",
				["A Rat's Home..."] = "Scare them off",
				["Crate Expectations"] = "Burn the crates",
				["Staring Down the Barrel"] = "Freeze the Barrel",
				["Those Who Came Before You"] = "Search the body",
				["Of Course!"] = "Turn off the faucet",
			})
			if result:contains("You close the valve") or result:contains("Go back to the Typical Tavern Cellar") then
				did_action = true
			end
		else
			inform "do guild, talk to bartender"
			local guildpt = get_page("/guild.php")
			async_get_page("/guild.php", { place = "ocg" })
			async_get_page("/guild.php", { place = "ocg" })
			async_get_page("/guild.php", { place = "scg" })
			async_get_page("/guild.php", { place = "scg" })
			local pt = get_page("/tavern.php", { place = "susguy" })
			if pt:contains("First bottle's free") and pt:contains("for free!") then
				local m = meat()
				async_post_page("/tavern.php", { action = "buygoofballs" })
				if not have("goofballs") or meat() ~= m then
					critical "Error getting free goofballs"
				end
			end
			result, resulturl = get_page("/tavern.php", { place = "barkeep" })
			refresh_quest()
			did_action = quest_text("Bart Ender wants you to head down")
		end
		return result, resulturl, did_action
	end
		
	function f.friars()
	-- 		TODO: more buffs?
			if not have("dodecagram") then
				go("getting dodecagram", 239, casual_macro_runaway_all(), {}, nc_buffs(), "Hobo Monkey", 20, nc_equip())
			elseif not have("box of birthday candles") then
				go("getting candles", 238, casual_macro_runaway_all(), {}, nc_buffs(), "Hobo Monkey", 20, nc_equip())
			elseif not have("eldritch butterknife") then
				go("getting butterknife", 237, casual_macro_runaway_all(), {}, ensure_nc_buffs(), "Hobo Monkey", 20, nc_equip())
			else
				inform "do ritual"
				async_post_page("/friars.php", { pwd = pwd, action = "ritual" })
				async_post_page("/friars.php", { pwd = pwd, action = "buffs", bro = "1" })
				async_get_page("/pandamonium.php")
				refresh_quest()
				did_action = (not quest("Trial By Friar") and quest_text("this is Azazel in Hell"))
			end
		return result, resulturl, did_action
	end

	function f.do_orc_chasm()
			if have("64735 scroll") then
				inform "using scroll"
				set_result(use_item("64735 scroll"))
				did_action = have("facsimile dictionary")
			elseif quest_text("You must find your way past the Orc Chasm") then
				inform "unlock baron's valley"
				result, resulturl = post_page("/forestvillage.php", { pwd = pwd, action = "untinker", whichitem = get_itemid("abridged dictionary") })
				result, resulturl = get_page("/mountains.php", { pwd = pwd, orcs = 1 })
				refresh_quest()
				did_action = not quest_text("You must find your way past the Orc Chasm")
			elseif count("334 scroll") >= 2 and have("30669 scroll") and have("33398 scroll") then
				go("doing orc chasm", 80, casual_macro_orc_chasm(), {}, { "Ur-Kel's Aria of Annoyance" }, "Hobo Monkey", 50)
			else
				critical "Error while doing orc chasm"
			end
		end
		
	function f.get_flyers()
		inform "get rock band flyers"
		async_get_page("/bigisland.php", { place = "concert" })
		if have("rock band flyers") then
			did_action = true
		else
			inform "check if done with war prep"
			wear { hat = "beer helmet", pants = "distressed denim pants", acc1 = "bejeweled pledge pin" }
			local concertptf = async_get_page("/bigisland.php", { place = "concert" })
			local junkmanptf = async_get_page("/bigisland.php", { action = "junkman", pwd = pwd })
			local pyroptf = async_get_page("/bigisland.php", { place = "lighthouse", action = "pyro", pwd = pwd })
			if concertptf():contains("has already taken the stage") and junkmanptf():contains("next shipment of cars ready") and pyroptf():contains("gave you the big boom today") then
				inform "pick up padl phone"
				result, resulturl, advagain = autoadventure(132)
				did_action = have("PADL Phone")
			else
				stop "Not done with war prep when starting to fight war"
			end
		end
	end

	function f.do_manor_of_spooking()
		local manorpt = get_page("/manor.php")
		if not manorpt:match("To The Cellar") then
			go("unlock cellar", 109, casual_macro_runaway_all(), {
				["Curtains"] = "Watch the dancers",
				["Strung-Up Quartet"] = "&quot;Play nothing, please.&quot;",
			}, nc_buffs(), "Hobo Monkey", 30)
		elseif not have("Lord Spookyraven's spectacles") then
			go("get spectacles", 108, casual_macro_runaway_all(), {}, ensure_nc_buffs(), "Hobo Monkey", 50, { choice_function = function(advtitle, choicenum)
				if choicenum == 82 then
					return "Kick it and see what happens"
				elseif choicenum == 83 then
					return "Check the bottom drawer"
				elseif choicenum == 84 then
					return "Look behind the nightstand"
				elseif choicenum == 85 then
					return "Investigate the jewelry"
				end
			end })
		elseif not ascension["zone.manor.wines needed"] then
			inform "determine cellar wines"
			determine_cellar_wines()
			if ascension["zone.manor.wines needed"] then
				print("got wine state set now!")
				did_action = true
			end
		else
			local manor3pt = get_page("/manor3.php")
			local wines_needed_list = ascension["zone.manor.wines needed"]
			local need = 0
			local got = 0
			local missing = {}
			for wine in table.values(wines_needed_list) do
				need = need + 1
				if have(wine) then
					got = got + 1
				else
					missing[wine] = true
				end
			end
			if need ~= 3 then
				critical "Couldn't identify 3 wines needed for cellar"
			elseif manor3pt:match("Summoning Chamber") then
				inform "fight spookyraven"
				ensure_buffs { "Springy Fusilli", "Astral Shell", "Elemental Saucesphere", "Jaba&ntilde;ero Saucesphere", "Spirit of Bacon Grease", "Jalape&ntilde;o Saucesphere" }
				fam "Frumious Bandersnatch"
				use_hottub()
				ensure_mp(50)
				if buff("Astral Shell") then
					local pt, url = get_page("/manor3.php", { place = "chamber" })
					result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_kill())
				else
					stop "TODO: Beat Lord Spookyraven"
				end
			elseif got >= need then
				inform "open chamber"
				for _, wine in ipairs(wines_needed_list) do
					async_post_page("/manor3.php", { action = "pourwine", whichwine = get_itemid(wine) })
				end
				local manor3pt = get_page("/manor3.php")
				did_action = manor3pt:contains("Summoning Chamber")
			end
		end
	end

	function f.do_never_odd_or_even_quest()
		if not have("Talisman o' Nam") then
			wear { acc1 = "pirate fledges" }
			local covept = get_page("/cove.php")
			if not covept:match("Belowdecks") then
				go("do poop deck", 159, casual_macro_runaway_all(), { ["O Cap'm, My Cap'm"] = "Step away from the helm" }, nc_buffs(), "Rogue Program", 35, { equipment = { acc1 = "pirate fledges" } })
				if result:contains("It's Always Swordfish") then
					did_action = true
				end
			elseif count("snakehead charrrm") >= 2 then
				inform "pasting talisman"
				meatpaste_items("snakehead charrrm", "snakehead charrrm")
				did_action = have("Talisman o' Nam")
			elseif have("gaudy key") then
				inform "using gaudy key"
				local charms = count("snakehead charrrm")
				use_item("gaudy key")
				did_action = (count("snakehead charrrm") > charms)
			else
				go("get gaudy keys", 160, macro_runaway_most { "gaudy pirate" }, {}, { "Spirit of Bacon Grease" }, "Hobo Monkey", 40, { equipment = { acc1 = "pirate fledges" }, olfact = "gaudy pirate" })
			end
		else
			if have("Mega Gem") then
				go("fight dr awkward", 119, macro_noodleserpent(), { ["Dr. Awkward"] = "War, sir, is raw!" }, { "A Few Extra Pounds", "Spirit of Garlic" }, "Knob Goblin Organ Grinder", 60, { equipment = { acc1 = "Mega Gem", acc2 = "Talisman o' Nam" } })
			elseif quest_text("wants some wet stew in return") then
				if have("wet stunt nut stew") then
					inform "getting mega gem"
					result, resulturl, advagain = autoadventure(50)
					did_action = have("Mega Gem")
				elseif have("wet stew") then
					inform "cooking wet stunt nut stew"
					cook_items("wet stew", "stunt nuts")
					did_action = have("wet stunt nut stew")
				elseif have("bird rib") and have("lion oil") then
					inform "cooking wet stew"
					cook_items("bird rib", "lion oil")
					did_action = have("wet stew")
				end
			elseif quest_text("track down this Mr. Alarm guy") and have("stunt nuts") then
				go("track down mr. alarm", 50, macro_runaway_all(), {
					["Mr. Alarm, I Presarm"] = "Talk to him",
				}, ensure_nc_buffs(), "Hobo Monkey", 15, ensure_nc_equip())
			else
				-- HACK: doesn't appear until plains is loaded
				if not have_equipped("Talisman o' Nam") then
					print("must equip talisman")
					wear { acc1 = "Talisman o' Nam" }
					async_get_page("/plains.php")
				end
				if meat() < 500 and not (have("photograph of God") and have("hard rock candy")) and not have("&quot;I Love Me, Vol. I&quot;") then
					stop "Not enough meat for palindome"
				end
				go("do palindome", 119, macro_runaway_all(), {
					["No sir, away!  A papaya war is on!"] = "Give the men a pep talk",
					["Sun at Noon, Tan Us"] = "A little while",
					["Rod Nevada, Vendor"] = "Accept (500 Meat)",
					["Do Geese See God?"] = "Buy the photograph (500 meat)",
					["A Pre-War Dresser Drawer, Pa!"] = "Ignawer the drawer",
				}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling", 40, { equipment = { acc1 = "Talisman o' Nam" } })
				if result:contains("Drawn Onward") and resulturl:contains("palinshelves") then
					async_post_page("/palinshelves.php", { action = "placeitems", whichitem1 = get_itemid("photograph of God"), whichitem2 = get_itemid("hard rock candy"), whichitem3 = get_itemid("ketchup hound"), whichitem4 = get_itemid("hard-boiled ostrich egg") })
					if have("&quot;I Love Me, Vol. I&quot;") then
						use_hottub()
						did_action = true
					end
				end
			end
		end
	end

	function f.knob_king()
		script.wear { hat = "Knob Goblin harem veil", pants = "Knob Goblin harem pants" }
		if buff("Knob Goblin Perfume") then
			inform "fight king in harem girl outfit"
			script.ensure_mp(20)
			script.want_familiar "Frumious Bandersnatch"
			set_mcd(7) -- TODO: moxie-specific
			local pt, url = get_page("/cobbsknob.php", { action = "throneroom" })
			result, resulturl, advagain = handle_adventure_result(pt, url, "?", casual_macro_attack())
			-- TODO: auto-do these always
			set_mcd(10)
			script.wear {}
			did_action = advagain
		elseif have("Knob Goblin perfume") then
			use_item("Knob Goblin perfume")
			if buff("Knob Goblin Perfume") then
				did_action = true
			end
		end
	end

	function f.do_filthworms()
		if buff("Filthworm Guard Stench") then
			go("fight queen", 130, macro_kill(), {}, { "Spirit of Bacon Grease" }, "Hobo Monkey", 30, { equipment = { familiarequip = "sugar shield" } })
			if did_action then
				wear {}
			end
		elseif have("filthworm royal guard scent gland") then
			inform "using guard stench"
			use_item("filthworm royal guard scent gland")
			did_action = buff("Filthworm Guard Stench")
		elseif buff("Filthworm Drone Stench") then
			go("fight guard", 129, macro_pickpocket(), {}, { "Spirit of Bacon Grease", "Springy Fusilli", "Heavy Petting"}, "Hobo Monkey", 30, { equipment = { familiarequip = "sugar shield" } })
		elseif have("filthworm drone scent gland") then
			inform "using drone stench"
			use_item("filthworm drone scent gland")
			did_action = buff("Filthworm Drone Stench")
		elseif buff("Filthworm Larva Stench") then
			go("fight drone", 128, macro_pickpocket(), {}, { "Spirit of Bacon Grease", "Springy Fusilli", "Heavy Petting"}, "Hobo Monkey", 30, { equipment = { familiarequip = "sugar shield" } })
		elseif have("filthworm hatchling scent gland") then
			inform "using hatchling stench"
			use_item("filthworm hatchling scent gland")
			did_action = buff("Filthworm Larva Stench")
		else
			go("fight hatchling", 127, macro_pickpocket(), {}, { "Spirit of Bacon Grease", "Springy Fusilli", "Heavy Petting" }, "Hobo Monkey", 30, { equipment = { familiarequip = "sugar shield" } })
		end
	end

	function f.do_sonofa()
		if count("barrel of gunpowder") >= 5 then
			inform "talk to lighthouse guy"
			wear { hat = "beer helmet", pants = "distressed denim pants", acc1 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { place = "lighthouse", action = "pyro", pwd = pwd })
			async_get_page("/bigisland.php", { place = "lighthouse", action = "pyro", pwd = pwd })
			did_action = (have("tequila grenade") and have("molotov cocktail cocktail"))
		elseif have("Spooky Putty monster") then
			use_item("Spooky Putty monster")
		elseif have("Spooky Putty sheet") then
			go("do sonofa beach, " .. make_plural(count("barrel of gunpowder"), "barrel", "barrels"), 136, macro_putty(), {}, ensure_c_buffs(), "Jumpsuited Hound Dog for +combat", 50, ensure_c_equip())
			if buff("Beaten Up") then
				use_hottub()
				did_action = not buff("Beaten Up")
			end
		end
	end

	function f.make_meatcar()
		inform "build meatcar"
		if not have("meat stack") then
			async_get_page("/inventory.php", { quantity = 1, action = "makestuff", pwd = pwd, whichitem = get_itemid("meat stack"), ajax = 1 })
		end
		buy_item("cog", "5")
		buy_item("empty meat tank", "5")
		buy_item("tires", "5")
		buy_item("spring", "5")
		buy_item("sprocket", "5")
		buy_item("sweet rims", "m")
		meatpaste_items("empty meat tank", "meat stack")
		meatpaste_items("spring", "sprocket")
		meatpaste_items("sprocket assembly", "cog")
		meatpaste_items("cog and sprocket assembly", "full meat tank")
		meatpaste_items("tires", "sweet rims")
		meatpaste_items("meat engine", "dope wheels")
		if not have("bitchin' meatcar") then
			critical "Failed to build bitchin' meatcar"
		end
		inform "unlock beach"
		async_get_page("/forestvillage.php", { place = "untinker" })
		async_post_page("/forestvillage.php", { action = "screwquest" })
		async_get_page("/knoll.php", { place = "smith" })
		async_get_page("/forestvillage.php", { place = "untinker" })
		local rf = async_get_page("/guild.php", { place = "paco" }) -- TODO: need the topmenu refreshed from this
		use_item("Degrassi Knoll shopping list")
		local b = get_page("/beach.php")
		did_action = b:contains("shore.php")
		result, resulturl = rf()
		return result, resulturl, did_action
	end

	function f.do_pyramid()
		local pyramidpt = get_page("/pyramid.php")
		if pyramidpt:match("pyramid3a.gif") then
			use_item("tomb ratchet")
		else
	-- 			pyramid4_1.gif -> nuke
	-- 			pyramid4_2.gif -> turn
	-- 			pyramid4_3.gif -> bomb
	-- 			pyramid4_4.gif -> token
	-- 			pyramid4_5.gif -> turn
			if pyramidpt:match("pyramid4_1b.gif") then
				-- TODO: check if this will overlap with SR
				inform "fight ed"
				fam "Frumious Bandersnatch"
				script.heal_up()
				ensure_buffs { "Jalape&ntilde;o Saucesphere", "Jaba&ntilde;ero Saucesphere", "Spirit of Garlic", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds" }
				maybe_ensure_buffs { "Mental A-cue-ity" }
				ensure_mp(100)
				result, resulturl = get_page("/pyramid.php", { action = "lower" })
				result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_kill())
				while result:contains([[<!--WINWINWIN-->]]) and result:contains([[fight.php]]) do
					result, resulturl = get_page("/fight.php")
					result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_kill())
				end
				did_action = have("Holy MacGuffin")
			elseif pyramidpt:match("pyramid4_1.gif") and have("ancient bomb") then
				inform "use bomb"
				async_get_page("/pyramid.php", { action = "lower" })
				pyramidpt = get_page("/pyramid.php")
				did_action = pyramidpt:contains("pyramid4_1b.gif")
			elseif pyramidpt:match("pyramid4_3.gif") and not have("ancient bomb") and have("ancient bronze token") then
				inform "buy bomb"
				async_get_page("/pyramid.php", { action = "lower" })
				did_action = have("ancient bomb")
			elseif pyramidpt:match("pyramid4_4.gif") and not have("ancient bomb") and not have("ancient bronze token") then
				inform "get token"
				async_get_page("/pyramid.php", { action = "lower" })
				did_action = have("ancient bronze token")
			elseif pyramidpt:match("pyramid4_[12345].gif") then
				use_item("tomb ratchet")
				-- go("turn middle chamber wheel", 125, macro_noodleserpent(), {
					-- ["Wheel in the Pyramid, Keep on Turning"] = "Turn the wheel",
				-- }, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Bacon Grease" }, "Rogue Program", 45)
			end
		end
	end

	function f.do_oasis_and_desert()
		if not buff("Fortunate Resolve") then
			inform "Be luckier!"
			use_item("resolution: be luckier")
		end
		if have("worm-riding hooks") and have("drum machine") then
			inform "using drum machine"
			set_result(use_item("drum machine"))
			did_action = not have("worm-riding hooks")
		elseif quest_text("got your walking shoes on") then
			go("unlock oasis", 121, macro_runaway_all(), {
				["Let's Make a Deal!"] = "Haggle for a better price",
			}, { "Spirit of Bacon Grease" }, "Mini-Hipster", 45)
			if result:contains("find yourself near an oasis") then
				use_hottub()
				did_action = true
			end
		elseif not buff("Ultrahydrated") then
			inform "getting ultrahydrated"
			if not have("ten-leaf clover") then
				use_item("disassembled clover")
			end
			if have("ten-leaf clover") then
				result, resulturl, advagain = autoadventure(122)
				if buff("Ultrahydrated") or result:contains("You acquire an item") then
					did_action = advagain
				end
			else
				script.trade_for_clover()
				if have("ten-leaf clover") or have("disassembled clover") then
					did_action = true
				else
					stop "No clover for ultrahydrated"
				end
			end
		elseif quest_text("managed to stumble upon a hidden oasis") then
			go("find gnasir", 123, macro_runaway_all(), nil, { "Spirit of Bacon Grease" }, "Hobo Monkey", 45)
		elseif quest_text("tasked you with finding a stone rose") then
			if not (have("stone rose") and have("drum machine")) then
				go("get stone rose + drum machine", 122, macro_runaway_all(), nil, { "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling", 45)
			elseif not have("can of black paint") then
				inform "buying can of black paint"
				buy_item("can of black paint", "l")
				did_action = have("can of black paint")
			else
				go("return stone rose", 123, macro_runaway_all(), nil, { "Spirit of Bacon Grease" }, "Hobo Monkey", 45)
			end
		elseif quest_text("that's probably long enough") then
			go("return to gnasir after waiting", 123, macro_runaway_all(), nil, { "Spirit of Bacon Grease" }, "Hobo Monkey", 45)
		elseif quest_text("find fifteen missing pages") or quest_text("fourteen to go") or quest_text("thirteen to go") then
			go("find missing pages", 122, macro_runaway_all(), nil, { "Spirit of Bacon Grease" }, "Hobo Monkey", 45)
		elseif quest_text("Time to take them back") then
			go("return pages to gnasir", 123, macro_runaway_all(), nil, { "Spirit of Bacon Grease" }, "Hobo Monkey", 45)
		end
	end

	function f.unlock_city()
		go("unlock hidden city", 17, macro_kill(), {
			["At Least It's Not Full Of Trash"] = "Raise your hands up toward the heavens",
			["No Visible Means of Support"] = "Do nothing",
		}, {}, "Mini-Hipster", 25)

		if resulturl:match("/tiles.php") then
			print("doing temple tiles")
			result, resulturl = automate_tiles()
			did_action = result:contains("thank goodness that's over")
		end
		if result:contains("You mark its location on your map, and carefully climb down the side of the Temple, back to ground level.") then
			did_action = true
		end
	end

	function f.do_gotta_worship_them_all()
		local hiddencitypt = get_page("/hiddencity.php")
		local count_spheres_stones = count("cracked stone sphere") + count("mossy stone sphere") + count("rough stone sphere") + count("smooth stone sphere") + count("triangular stone")
		local altars = 0
		for x in hiddencitypt:gmatch("map_altar.gif") do
			altars = altars + 1
		end
		if count_spheres_stones == 4 and altars == 4 and hiddencitypt:contains("map_temple.gif") then
			if count("triangular stone") == 4 then
				inform "fight hidden city boss"
				local temple_which = nil
				for which, tiletext in hiddencitypt:gmatch([[<a href='hiddencity.php%?which=([0-9]+)'>(.-)</a>]]) do
					if tiletext:contains("map_temple.gif") then
						temple_which = which
					end
				end
				if temple_which then
					ensure_buffs(c_buffs())
					fam "Mini-Hipster"
					script.heal_up()
					script.burn_mp(90)
					ensure_mp(80)
					async_get_page("/hiddencity.php", { which = temple_which })
					async_post_page("/hiddencity.php", { action = "trisocket" })
					result, resulturl = get_page("/fight.php")
					result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_kill())
					did_action = have("ancient amulet")
				end
			else
				inform "use spheres, get stones..."
				local altar_solutions = get_stone_sphere_status().altars
				local pre_stones = count("triangular stone")
				for which, tiletext in hiddencitypt:gmatch([[<a href='hiddencity.php%?which=([0-9]+)'>(.-)</a>]]) do
					if tiletext:contains("map_altar.gif") then
	-- 								print("hiddencity altar", which, tiletext)
						local altarpt = get_page("/hiddencity.php", { which = which })
						if altarpt:contains("<form") then
							for a, b in pairs(altar_solutions) do
								if altarpt:match("<table><tr><td><table><tr><td valign=center><img src='http://images.kingdomofloathing.com/otherimages/hiddencity/altar[0-9].gif' alt='An altar with a carving of a god of "..a.."' title='An altar with a carving of a god of "..a.."'></td><td><b>Altared Perceptions</b><p>You discover a stone altar, elaborately carved with a depiction of what appears to be some kind of ancient god.</td></tr></table>The top of the altar features a bowl%-like depression %-%- it looks as though you're meant to put something into it. Probably something round.<p>") then
									print("put", b, get_itemid(b .. " stone sphere"), "in", which)
									result, resulturl = post_page("/hiddencity.php", { action = "roundthing", whichitem = get_itemid(b .. " stone sphere") })
									did_action = (count("triangular stone") > pre_stones)
									return result, resulturl, did_action
								end
							end
						end
					end
				end
			end
		else
			local which = hiddencitypt:match([[<a href='hiddencity.php%?which=([0-9]-)'><img src="http://images.kingdomofloathing.com/otherimages/hiddencity/map_unruins]])
			if which then
				inform("do hidden city (" .. which .. ")")
				ensure_buffs(c_buffs())
				fam "Mini-Hipster"
				script.heal_up()
				script.burn_mp(90)
				ensure_mp(60)
				local pt, url = get_page("/hiddencity.php", { which = which })
				result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_hiddencity())
				if advagain or result:match([[Altared Perceptions]]) or result:match([[Mansion House of the Black Friars]]) or result:match([[Dr. Henry "Dakota" Fanning, Ph.D., R.I.P.]]) then
					did_action = true
				elseif resulturl:match("/adventure.php") and result:match([[<a href="hiddencity.php">Go back to The Hidden City</a>]]) then
					did_action = true
				end
			else
				critical "Nothing to do in hidden city, but don't have all spheres"
			end
		end
	end

	function f.do_castle()
		-- TODO: buff +item% more?
		if quest("The Rain on the Plains is Mainly Garbage") then
			local plainspt = get_page("/plains.php")
			if plainspt:match("A Giant Pile of Coffee Grounds") then
				inform "do beanstalk"
				use_item("enchanted bean")
				plainspt = get_page("/plains.php")
				if not plainspt:match("A Giant Pile of Coffee Grounds") then
					did_action = true
				end
				return result, resulturl, did_action
			end
			if not beanstalkpt:match("Castle") then
				script.go("do airship", 81, runaway_all(), {
					["Random Lack of an Encounter"] = "Investigate the crew quarters",
					["Hammering the Armory"] = "Blow this popsicle stand",
				}, ensure_nc_buffs(), "Hobo Monkey", 35, ensure_nc_equip())
				go("do castle in the sky", 82, runaway_all(), ensure_nc_equip, ensure_nc_buffs(), "Hobo Monkey", 40, { choice_function = function(advtitle, choicenum)
					if advtitle == "Wheel in the Clouds in the Sky, Keep On Turning" then
						if choicenum == 9 then
							return "Turn the wheel counterclockwise"
						elseif choicenum == 12 then
							return "Leave the wheel alone"
						elseif choicenum == 11 then
							return "Leave the wheel alone"
						elseif choicenum == 10 then
							return "Leave the wheel alone"
						end
					end
				end })
			end
			refresh_quest()
		end
	end

	function f.do_barrr(insults)
		if insults >= 7 and have("Cap'm Caronch's Map") then
			inform "use cap'm's map"
			ensure_buffs { "Springy Fusilli", "Spirit of Peppermint" }
			fam "Hobo Monkey"
			script.heal_up()
			ensure_mp(40)
			use_item("Cap'm Caronch's Map")
			local pt, url = get_page("/fight.php")
			result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_noodlecannon())
		else
	-- 			print("map", have("Cap'm Caronch's Map"), "insults", insults)
			local function get_barrr_noncombattbl()
				if get_mainstat() == "Muscle" then
					return {
						["Yes, You're a Rock Starrr"] = "Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;",
						["A Test of Testarrrsterone"] = "Cheat",
						["That Explains All The Eyepatches"] = "Carefully throw the darrrt at the tarrrget",
					}
				elseif get_mainstat() == "Mysticality" then
					return {
						["Yes, You're a Rock Starrr"] = "Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;",
						["A Test of Testarrrsterone"] = "Cheat",
						["That Explains All The Eyepatches"] = "Pull one over on the pirates",
					}
				elseif get_mainstat() == "Moxie" then
					return {
						["Yes, You're a Rock Starrr"] = "Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;",
						["A Test of Testarrrsterone"] = "Wuss out",
						["That Explains All The Eyepatches"] = "Carefully throw the darrrt at the tarrrget",
					}
				end
			end
			if have("Cap'm Caronch's Map") then
				go("doing barrr", 157, macro_insults(), get_barrr_noncombattbl(), ensure_c_buffs(), "Hobo Monkey", 30, { equipment = { hat = "eyepatch", pants = "swashbuckling pants", acc1 = "stuffed shoulder parrot" } })
			else
				go("doing barrr", 157, macro_insults(), get_barrr_noncombattbl(), ensure_nc_buffs(), "Hobo Monkey", 30, { equipment = { hat = "eyepatch", pants = "swashbuckling pants", acc1 = "stuffed shoulder parrot" } })
			end
		end
	end

	function f.do_battlefield()
		if have("heart of the filthworm queen") then
			print("  trying to turn in filthworm heart")
			wear { hat = "beer helmet", pants = "distressed denim pants", acc1 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { place = "orchard", action = "stand", pwd = pwd })
			async_get_page("/bigisland.php", { place = "orchard", action = "stand", pwd = pwd })
		end
		go("fight on battlefield: " .. tostring(ascension["battlefield.kills.frat boy.min"]) .. " hippies killed", 132, macro_kill(), nil, { "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling even in fist", 80, { equipment = { hat = "beer helmet", pants = "distressed denim pants", acc1 = "bejeweled pledge pin" } })
		if result:contains("There are no hippy soldiers left") then
			local turnins = {
				"green clay bead",
				"pink clay bead",
				"purple clay bead",
				"communications windchimes",
			}
			for x in table.values(turnins) do
				if have(x) then
					async_get_page("/bigisland.php", { action = "turnin", pwd = pwd, whichcamp = 2, whichitem = get_itemid(x), quantity = count(x) })
				end
			end
			local camppt = get_page("/bigisland.php", { place = "camp", whichcamp = 2 })
			if camppt:contains("You don't have any quarters on file") then
				inform "fight hippy boss"
				fam "Frumious Bandersnatch"
				script.heal_up()
				ensure_mp(150)
				ensure_buffs { "Jalape&ntilde;o Saucesphere", "Jaba&ntilde;ero Saucesphere", "Spirit of Garlic", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds" }
				async_get_page("/bigisland.php", { place = "camp", whichcamp = 1 })
				result, resulturl = async_get_page("/bigisland.php", { action = "bossfight", pwd = pwd })()
				result, resulturl, did_action = handle_adventure_result(result, resulturl, "?", macro_kill())
			else
				if count("gauze garter") < 10 then
					inform "buying gauze garters"
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("gauze garter"), quantity = 10 })
					did_action = (count("gauze garter") >= 10)
				elseif count("superamplified boom box") < 2 then
					inform "buying boom boxes"
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("superamplified boom box"), quantity = 2 })
					did_action = (count("superamplified boom box") >= 2)
				else
					inform "spending remaining quarters"
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("superamplified boom box"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("gauze garter"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("gauze garter"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("superamplified boom box"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 32 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 16 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 8 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 4 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 2 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("superamplified boom box"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("gauze garter"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = pwd, whichcamp = 2, whichitem = get_itemid("sake bomb"), quantity = 1 })
					local newcamppt = get_page("/bigisland.php", { place = "camp", whichcamp = 2 })
					did_action = newcamppt:contains("You don't have any quarters on file")
				end
			end
		end
	end

	function f.do_crypt()
		local cyrpt = get_page("/cyrpt.php")
		if have("skeleton bone") and have("loose teeth") then
			meatpaste_items("skeleton bone", "loose teeth")
		end
		if have("evil eye") then
			use_item("evil eye")
		end
		local noncombattbl = {}
		noncombattbl["Turn Your Head and Coffin"] = "Leave them all be"
		noncombattbl["Skull, Skull, Skull"] = "Leave the skulls alone"
		noncombattbl["Urning Your Keep"] = "Turn away"
		noncombattbl["Death Rattlin'"] = "Open the rattling one"
		if cyrpt:match("Defiled Alcove") then
			-- TODO: hustlin pool buff?
			-- TODO: cletus +init?
			-- TODO: heart of yellow?
			go("do crypt alcove", 261, macro_runaway_most("modern zmobie"), noncombattbl, { "Sugar Rush", "Hiding in Plain Sight", "Ass Over Teakettle", "Springy Fusilli", "All Fired Up", "A Few Extra Pounds", "Springy Fusilli", "Spirit of Garlic" }, "Rogue Program", 20)
		elseif cyrpt:match("Defiled Cranny") then
			maybe_ensure_buffs { "Mental A-cue-ity" }
			go("do crypt cranny", 262, macro_runaway_most("swarm of ghuol whelps"), noncombattbl, ensure_nc_buffs + { "Mysteriously Handsome", "Juiced and Jacked", "Simply Irritable", "Contemptible Emanations", "Digitally Converted", "A Few Extra Pounds", "Ur-Kel's Aria of Annoyance" }, "Baby Bugged Bugbear", 35, ensure_nc_equip())
		elseif cyrpt:match("Defiled Niche") then
			go("do crypt niche", 263, make_cannonsniff_macro("dirty old lihc"), noncombattbl, { "Spirit of Garlic", "Butt-Rock Hair", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Rogue Program", 25, { olfact = "dirty old lihc" })
		elseif cyrpt:match("Defiled Nook") then
			go("do crypt nook", 264, macro_pickpocket_eye(), noncombattbl, { "Butt-Rock Hair", "A Few Extra Pounds"}, "Hobo Monkey", 15)
		else
			inform "kill bonerdagon"
			ensure_buffs { "A Few Extra Pounds", "Jalape&ntilde;o Saucesphere", "Jaba&ntilde;ero Saucesphere", "Springy Fusilli", "Spirit of Garlic", "Astral Shell", "Ghostly Shell" }
			maybe_ensure_buffs_in_fist { "A Few Extra Pounds", "Jalape&ntilde;o Saucesphere", "Jaba&ntilde;ero Saucesphere", "Astral Shell", "Ghostly Shell" }
			fam "Knob Goblin Organ Grinder"
			script.heal_up()
			ensure_mp(50)
			local pt, url = get_page("/crypt.php", { action = "heart" })
			result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_noodlegeyser(7), { ["The Haert of Darkness"] = "When I...  Yes?" })
		end
		return result, resulturl, did_action
	end


	function f.trapper()
		inform "talking to trapper"
		fam "Exotic Parrot"
		async_get_page("/trapper.php")
		async_get_page("/trapper.php")
		refresh_quest()
		if quest("Am I My Trapper's Keeper?") then
			critical "Failed to finish trapper quest."
		end	
	end
		
	function f.get_dinghy()
		inform "make dingy dinghy"
		if not have("dinghy plans") then
			inform "shore for dinghy plans"
			local trips = script.get_shore_trips()
			local function do_trip(tripid)
				result, resulturl = post_page("/shore.php", { pwd = pwd, whichtrip = tripid })
				local new_trips = script.get_shore_trips()
				did_action = (new_trips > trips)
			end
			local shore_tower_items = {
				["stick of dynamite"] = 1,
				["tropical orchid"] = 2,
				["barbed-wire fence"] = 3,
			}

			local tbl = session["zone.lair.itemsneeded"] or {}
			local need_item = nil
			local want_adv = nil
			for from, to in pairs(tbl) do
				if shore_tower_items[to] then
					need_item = to
					want_adv = shore_tower_items[to]
				end
			end
			if not need_item then
				critical "Don't know which shore tower item is needed."
			end
			if trips >= 1 and trips < 5 and have(need_item) then
				do_trip(3)
			end
		elseif not have("dingy planks") then
			inform "get dingy planks from hermit"
			script.ensure_worthless_item()
			buy_item("hermit permit", "m")
			result, resulturl = post_page("/hermit.php", { action = "trade", whichitem = get_itemid("dingy planks"), quantity = 1 })
			did_action = have("dingy planks")
		else
			set_result(use_item("dinghy plans"))
			did_action = have("dingy dinghy")
		end
	end
		
	function f.get_macguffin_diary()
		inform "shore for macguffin diary"
		if not have("forged identification documents") then
			buy_item("forged identification documents", "l")
			if not have("forged identification documents") then
				critical "Failed to buy identification documents"
			end
		end
		if have("forged identification documents") and not have("your father's MacGuffin diary") then
			result, resulturl = post_page("/shore.php", { pwd = pwd, whichtrip = "3" })
		end
		if have("your father's MacGuffin diary") then
			result, resulturl = get_page("/diary.php", { whichpage = "1" })
			did_action = true
		end
	end
		
		
	function f.spooky_forest()
		local woodspt = get_page("/woods.php")
		if woodspt:contains("The Hidden Temple") then return end
		fam "Hobo Monkey"
		if have("Spooky Temple map") and have("Spooky-Gro fertilizer") and have("spooky sapling") then
			inform "use spooky temple map"
			set_result(use_item("Spooky Temple map"))
			local newwoodspt = get_page("/woods.php")
			did_action = newwoodspt:contains("The Hidden Temple")
		else
			ensure_nc_buffs()
			if meat() < 100 and have("Spooky Temple map") and have("Spooky-Gro fertilizer") then
				stop "Not enough meat for spooky sapling"
			end
			go("Unlock Hidden Temple", 15, macro_runaway_all(), ensure_nc_equip(), { "Smooth Movements", "The Sonata of Sneakiness" }, "Hobo Monkey", 10, { choice_function = function(advtitle, choicenum)
				if advtitle == "Arboreal Respite" then
					if not have("Spooky Temple map") then
						if not have("tree-holed coin") then
							return "Explore the stream"
						else
							return "Brave the dark thicket"
						end
					elseif not have("Spooky-Gro fertilizer") then
						return "Brave the dark thicket"
					elseif not have("spooky sapling") then
						return "Follow the old road"
					end
				elseif advtitle == "Consciousness of a Stream" then
					if not have("Spooky Temple map") and not have("tree-holed coin") then
						inform "get coin"
						return "Squeeze into the cave"
					end
				elseif advtitle == "Through Thicket and Thinnet" then
					if not have("Spooky Temple map") then
						return "Follow the coin"
					elseif not have("Spooky-Gro fertilizer") then
						inform "get fertilizer"
						return "Investigate the dense foliage"
					end
				elseif advtitle == "O Lith, Mon" then
					inform "get map"
					return "Insert coin to continue"
				elseif advtitle == "The Road Less Traveled" then
					if not have("spooky sapling") then
						return "Talk to the hunter"
					end
				elseif advtitle == "Tree's Last Stand" then
					if not have("spooky sapling") then
						inform "buying sapling"
						return "Buy a tree for 100 Meat"
					else
						return "Take your leave"
					end
				end
			end, equipment = weareq, finalcheck = function()
			end })
			return result, resulturl, did_action
		end
	end


	function f.do_boss_bat()
		local batholept = get_page("/bathole.php")
		if not batholept:match("Boss") then
			if have("sonar-in-a-biscuit") then
				inform "using sonar"
				use_item("sonar-in-a-biscuit")
				did_action = true
			else
				stop "Buy Sonars"
			end
		else
			good_monsters = { "Boss Bat" }
			go("killing boss bat", 34, macro_runaway_most(good_monsters), {}, {}, "Hobo Monkey", 25)
		end
		return result, resulturl, did_action
	end

	function f.get_library_key()
		local townright = get_page("/town_right.php")
		if townright:match("The Haunted Pantry") then
			f.unlock_manor()
		else
			local manor = get_page("/manor.php")
			if manor:match("Stairs Up") then
				async_get_page("/manor.php", { place = "stairs" })
				did_action = true
			else
				if have("pool cue") and have("handful of hand chalk") and not buff("Chalky Hand") then
					use_item("handful of hand chalk")
				end
	-- 					TODO: act differently if you can't easily win with just autoattack?
				go("unlock library", 105, macro_stasis(), {
					["Minnesota Incorporeals"] = "Let the ghost break",
					["Broken"] = "Go for a solid",
					["A Hustle Here, a Hustle There"] = "Go for the 8-ball",
				}, ensure_nc_buffs(), "Stocking Mimic", 5, ensure_nc_equip())
			end
		end
		return result, resulturl, did_action
	end

	function f.get_ballroom_key()
		local manor = get_page("/manor.php")
		if not manor:match("Stairs Up") then
			go("unlock upstairs", 104, macro_runaway_all(), {}, ensure_nc_buffs, "Hobo Monkey", 25, { choice_function = function(advtitle, choicenum)
				if advtitle == "Take a Look, it's in a Book!" then
					return "", 99
				elseif advtitle == "Melvil Dewey Would Be Ashamed" then
					return "Gaffle the purple-bound book"
				end
			end })
		end
	end

	function f.unlock_manor()
		local townright = get_page("/town_right.php")
		if townright:match("The Haunted Pantry") then
			go("unlock manor", 113, macro_runaway_all(), {
				["Oh No, Hobo"] = "Give him a beating",
				["Trespasser"] = "Tackle him",
				["The Singing Tree"] = "&quot;No singing, thanks.&quot;",
				["The Baker's Dilemma"] = "&quot;Sorry, I'm busy right now.&quot;",
			}, ensure_c_buffs(), "Hobo Monkey", 15, ensure_c_equip())
			if result:contains("The Manor in Which You're Accustomed") then
				did_action = true
			end
		else
			local manor = get_page("/manor.php")
			if not manor:match("Stairs Up") then
				go("unlock upstairs", 104, macro_runaway_all(), {}, ensure_nc_buffs(), "Hobo Monkey", 25, { choice_function = function(advtitle, choicenum)
					if advtitle == "Take a Look, it's in a Book!" then
						return "", 99
					elseif advtitle == "Melvil Dewey Would Be Ashamed" then
						return "Leave without taking anything"
					end
				end })
			end
		end
	end

	function f.unlock_cobbs_knob()
		if have("Knob Goblin encryption key") then
			set_result(use_item("Cobb's Knob map"))
			refresh_quest()
			if not quest_text("haven't figured out how to decrypt it yet") then
				did_action = true
			end
		else
			go("get encryption key", 114, macro_runaway_all(), {
				["Up In Their Grill"] = "Grab the sausage, so to speak.  I mean... literally.",
				["Knob Goblin BBQ"] = "Kick the chef",
				["Ennui is Wasted on the Young"] = "&quot;Since you're bored, you're boring.  I'm outta here.&quot;",
				["Malice in Chains"] = "Plot a cunning escape",
				["When Rocks Attack"] = "&quot;Sorry, gotta run.&quot;",
			}, ensure_c_buffs(), "Hobo Monkey", 15, ensure_c_equip())
			if have("Knob Goblin encryption key") then
				did_action = true
			end
		end
	end

	return f
end
