-- TODO: make this work more like ascension-automation

local required_items_perclass = {
	{ lew = "Hammer of Smiting", ew = "Bjorn's Hammer", extra = "distilled seal blood", door = { "viking helmet", "insanely spicy bean burrito", "clown whip" } },
	{ lew = "Chelonian Morningstar", ew = "Mace of the Tortoise", extra = "turtle chain", door = { "viking helmet", "insanely spicy bean burrito", "clownskin buckler" } },
	{ lew = "Greek Pasta of Peril", ew = "Pasta of Peril", extra = "high-octane olive oil", door = { "stalk of asparagus", "insanely spicy enchanted bean burrito", "boring spaghetti" } },
	{ lew = "17-alarm Saucepan", ew = "5-Alarm Saucepan", extra = "Peppercorns of Power", door = { "stalk of asparagus", "insanely spicy enchanted bean burrito", "tomato juice of powerful power" } },
	{ lew = "Shagadelic Disco Banjo", ew = "Disco Banjo", extra = "vial of mojo", door = { "dirty hobo gloves", "insanely spicy jumping bean burrito", "fuzzbump" } },
	{ lew = "Squeezebox of the Ages", ew = "Rock and Roll Legend", extra = "golden reeds", door = { "dirty hobo gloves", "insanely spicy jumping bean burrito" } },
}

local rerun_workaround_counter = 0
local rerun_turn = nil

local function rerun_check()
	if turnsplayed() ~= rerun_turn then
		rerun_workaround_counter = 0
		rerun_turn = turnsplayed()
		return true
	elseif rerun_workaround_counter < 10 then
		rerun_workaround_counter = rerun_workaround_counter + 1
		return true
	else
		return false
	end
end

setup_turnplaying_script {
	name = "automate-nemesis",
	description = "Automate Nemesis quest (first part)",
	--can_automate_inrun = true,
	when = function() return not quest_completed("Me and My Nemesis") and not quest_completed("A Dark and Dank and Sinister Quest") end,
	macro = nil,
	preparation = function()
		local required_items = required_items_perclass[classid()]
		if not required_items then
			critical "Class not supported for nemesis script."
		end

		local need_items = { "clown whip", "clownskin buckler", "ring of conflict", "tenderizing hammer" }
		if not have_item(required_items.lew) then
			table.insert(need_items, required_items.ew)
		end
		for _, x in ipairs(required_items.door) do
			table.insert(need_items, x)
		end

		for _, x in ipairs(need_items) do
			maybe_pull_item(x, 1)
		end
	end,
	adventuring = function()

	script = get_automation_scripts()
	local required_items = required_items_perclass[classid()]

	local pwd = session.pwd
	local function dorefresh()
		scg = get_page("/guild.php", { place = "scg" })
		scg = get_page("/guild.php", { place = "scg" })
		refresh_quest()
	end
	dorefresh()

	if quest_text("for the Tomb of the Unknown") then
		script.wear {}
		script.ensure_mp(50)
		result, resulturl, advagain = autoadventure { zoneid = get_zoneid("The Unquiet Garves") }
	elseif quest_text("Find Beelzebozo in") then
		inform "make LEW"
		result = "make LEW"
		-- TODO: make robust
		-- wear stuff
		equip_item("clown whip")
		equip_item("clownskin buckler")
		equip_item("ring of conflict", 3)
		-- TODO: check that we're wearing them
		-- adventure repeatedly
		for i = 1, 100 do
			-- buff up
			if not have_buff("The Sonata of Sneakiness") then
				cast_skillid(6015, 2) -- sonata of sneakiness
			end
			if not have_buff("Smooth Movements") then
				cast_skillid(5017, 2) -- smooth moves
			end
			script.ensure_mp(50)
			result, resulturl, advagain = autoadventure { zoneid = 20, noncombatchoices = {
				["Adventurer, $1.99"] = "Push the nose",
				["Lurking at the Threshold"] = "Open the door",
			} }
			if result:contains("Clownlord Beelzebozo") then
				result, resulturl = cast_autoattack_macro()
			end
			if not advagain then
				break
			end
		end
		refresh_quest()
		advagain = not quest_text("Find Beelzebozo in")
	elseif not have_item(required_items.lew) and have_item(required_items.ew) and have_item(required_items.extra) then
		set_result(smith_items(required_items.ew, required_items.extra))
		if not have_item(required_items.lew) then
			smith_items(required_items.ew, required_items.extra)
		end
		if have_item(required_items.lew) then
			advagain = true
		else
			critical "Failed to smith Legendary Epic Weapon."
		end
	elseif scg:match([[Have you defeated your Nemesis yet]]) or scg:match([[We need you to defeat your Nemesis]]) or scg:match([[Haven't beat your Nemesis yet]]) then
		inform "do nemesis cave"
		result = "do nemesis cave"
		result, resulturl = get_page("/cave.php")

		script.wear {}

		if not result:contains("A Large Chamber") then
			-- TODO: check each step
			async_post_page("/cave.php", { action = "door1", pwd = session.pwd, action = "dodoor1", whichitem = get_itemid(required_items.door[1]) })
			async_post_page("/cave.php", { action = "door2", pwd = session.pwd, action = "dodoor2", whichitem = get_itemid(required_items.door[2]) })
			if required_items.door[3] then
				async_post_page("/cave.php", { action = "door3", pwd = session.pwd, action = "dodoor3", whichitem = get_itemid(required_items.door[3]) })
			else
				script.ensure_buffs { "Polka of Plenty" }
				async_get_page("/cave.php", { action = "door3", pwd = session.pwd })
			end
			result, resulturl = get_page("/cave.php")
		end

		local function need_paper_strips()
			for _, x in ipairs { "a creased paper strip", "a crinkled paper strip", "a crumpled paper strip", "a folded paper strip", "a ragged paper strip", "a ripped paper strip", "a rumpled paper strip", "a torn paper strip" } do
				if not have_item(x) then
					return true
				end
			end
			return false
		end

		script.want_familiar "Slimeling"

		for i = 1, 100 do
			if need_paper_strips() then
				script.ensure_buffs { "Leash of Linguini", "Empathy", "Fat Leon's Phat Loot Lyric" }
				script.ensure_mp(40)

				result, resulturl = get_page("/cave.php", { action = "cavern", pwd = session.pwd })
				result, resulturl, advagain = handle_adventure_result(result, resulturl, "?")
				if not advagain then break end
			else
				break
			end
		end

		if not need_paper_strips() then
			check_nemesis_paper_strips()
			local count, solution = determine_nemesis_paper_strips_password()
			async_post_page("/cave.php", { action = "door4", pwd = session.pwd, action = "dodoor4", say = solution })
			equip_item(required_items.lew)
			result, resulturl = get_page("/cave.php", { action = "sanctum", pwd = session.pwd })
			result, resulturl, advagain = handle_adventure_result(result, resulturl, "?")
			result, resulturl = cast_autoattack_macro()
		end

		dorefresh()
	elseif not quest("Me and My Nemesis") then
		result = "pick up quest"
		get_page("/guild.php", { place = "challenge" })
		local pt = get_page("/guild.php", { place = "challenge" })
		if pt:contains("You manage to steal your own pants yet") then
			if equipment().pants then
				result, resulturl, advagain = autoadventure { zoneid = 112, noncombatchoices = {
					["Now's Your Pants!  I Mean... Your Chance!"] = "Yoink!",
					["Aww, Craps"] = "Walk away",
					["Dumpster Diving"] = "Punch the hobo",
					["The Entertainer"] = "Introduce them to avant-garde",
					["Under the Knife"] = "Umm, no thanks.  Seriously.",
					["Please, Hammer"] = "&quot;Sure, I'll help.&quot;",
				} }
			else
				stop "TODO: Do moxie guild quest"
			end
		elseif pt:contains("Have you captured the poltersandwich") then
			result, resulturl, advagain = autoadventure { zoneid = 113, noncombatchoices = {
				["A Sandwich Appears!"] = "sudo exorcise me a sandwich",
				["Oh No, Hobo"] = "Give him a beating",
				["Trespasser"] = "Tackle him",
				["The Singing Tree"] = "&quot;No singing, thanks.&quot;",
				["The Baker's Dilemma"] = "&quot;Sorry, I'm busy right now.&quot;",
			} }
		elseif rerun_check() then
			advagain = true
		else
			stop "TODO: Wait for nemesis assassins??? Or missing guild quest? Or missing nemesis quest?"
		end
	elseif rerun_check() then
		inform "nothing to do, trying again"
		advagain = true
	else
		stop "TODO: Next quest step???"
	end
	__set_turnplaying_result(result, resulturl, advagain)
end
}

setup_turnplaying_script {
	name = "automate-nemesis-island",
	description = "Automate Nemesis quest (second part, beta version)",
	when = function() return have_item("secret tropical island volcano lair map") and not quest_completed("Me and My Nemesis") end,
	macro = macro_noodlecannon,
	preparation = function()
		local required_items = required_items_perclass[classid()]
		if not required_items then
			critical "Class not supported for nemesis script."
		end

		local need_items = { "clown whip", "clownskin buckler", "ring of conflict" }
		if not have_item(required_items.lew) then
			table.insert(need_items, required_items.ew)
		end
		for _, x in ipairs(required_items.door) do
			table.insert(need_items, x)
		end

		for _, x in ipairs(need_items) do
			maybe_pull_item(x, 1)
		end
	end,
	adventuring = function()
		if quest_text("found a map to the secret tropical island") then
			set_result(use_item("secret tropical island volcano lair map"))
			refresh_quest()
			advagain = not quest_text("found a map to the secret tropical island")
		elseif quest_text("put a stop to this Nemesis nonsense") or (quest("Me and My Nemesis") and have_item("secret tropical island volcano lair map")) then
			if playerclass("Seal Clubber") then
				if not have_item("hellseal disguise") then
					stop "TODO: Automate seal clubber island"
				end
				try_killing_SC_nemesis()
			elseif playerclass("Turtle Tamer") then
				automate_TT_nemesis_island()
			elseif playerclass("Pastamancer") then
				automate_P_nemesis_island()
			elseif playerclass("Sauceror") then
				automate_S_nemesis_island()
			elseif playerclass("Disco Bandit") then
				automate_DB_nemesis_island()
				result, resulturl = text, url
			elseif playerclass("Accordion Thief") then
				automate_AT_nemesis_island()
				result, resulturl = text, url
			end
		else
			stop "TODO: Next quest step???"
		end
		__set_turnplaying_result(result, resulturl, advagain)
	end
}

function nemesis_try_sauceror_potions()
	if have_buff("Slimeform") then
		return true
	end
	local goal_potions = {
		["vial of amber slime"] = { "vial of yellow slime", "vial of orange slime" },
		["vial of chartreuse slime"] = { "vial of yellow slime", "vial of green slime" },
		["vial of indigo slime"] = { "vial of blue slime", "vial of violet slime" },
		["vial of purple slime"] = { "vial of red slime", "vial of violet slime" },
		["vial of teal slime"] = { "vial of blue slime", "vial of green slime" },
		["vial of vermilion slime"] = { "vial of red slime", "vial of orange slime" },
	}
	local secondary_potions = {
		["vial of green slime"] = { "vial of blue slime", "vial of yellow slime" },
		["vial of orange slime"] = { "vial of red slime", "vial of yellow slime" },
		["vial of violet slime"] = { "vial of blue slime", "vial of red slime" },
	}
	local known_potion_effects = ascension["nemesis.sauceror potions"] or {}
	for x, y in pairs(known_potion_effects) do
		if y == "Slimeform" then
			stop("Slimeform already found: use a " .. x)
		end
	end
	for x, y in pairs(goal_potions) do
		if not known_potion_effects[x] then
			if have_item(x) then
				local bl = buffslist()
				use_item(x)()
				for a, b in pairs(buffslist()) do
					if b > (bl[a] or 0) then
						print("potion effect", x, "=", a)
						known_potion_effects[x] = a
						ascension["nemesis.sauceror potions"] = known_potion_effects
						return nemesis_try_sauceror_potions()
					end
				end
				critical("Failed to detect " .. x .. " effect")
			end
			local z = secondary_potions[y[2]]
			if count_item(y[1]) >= 2 and have_item(z[1]) and have_item(z[2]) then
				cook_items(z[1], z[2])
				cook_items(y[1], y[2])
				return nemesis_try_sauceror_potions()
			end
		end
	end
	return false
end

local function check_volcanomaze()
	if result:contains([[value="Continue"]]) then
		result, resulturl = get_page("/volcanomaze.php", { start = 1 })
		automate_volcanomaze()
		script.ensure_buffs {}
		script.heal_up()
		script.ensure_mp(100)
		result, resulturl = get_page("/volcanomaze.php")
		advagain = false
	end
end

function try_killing_SC_nemesis()
	script.bonus_target { "easy combat" }
	script.ensure_buffs {}
	script.wear { weapon = "Hammer of Smiting" }
	script.heal_up()
	script.ensure_mp(50)
	local fought = false
	result, resulturl = get_page("/volcanoisland.php", { pwd = session.pwd, action = "tniat" })
	print("DEBUG: lock url cont", locked(), resulturl, result:contains([[value="Continue"]]))
	if locked() or not resulturl:contains("volcanoisland.php") or result:contains([[value="Continue"]]) then
		fought = true
	end
	result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_noodleserpent)
	print("DEBUG: lock url advagain", locked(), resulturl, advagain)
	check_volcanomaze()
	return fought
end

function try_killing_TT_nemesis()
	script.bonus_target { "easy combat" }
	script.ensure_buffs {}
	script.wear { weapon = "Chelonian Morningstar" }
	script.heal_up()
	script.ensure_mp(50)
	local fought = false
	result, resulturl = get_page("/volcanoisland.php", { pwd = session.pwd, action = "tniat" })
	print("DEBUG: lock url cont", locked(), resulturl, result:contains([[value="Continue"]]))
	if locked() or not resulturl:contains("volcanoisland.php") or result:contains([[value="Continue"]]) then
		fought = true
	end
	result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_noodleserpent)
	print("DEBUG: lock url advagain", locked(), resulturl, advagain)
	check_volcanomaze()
	return fought
end

function automate_TT_nemesis_island()
	if not have_item("fouet de tortue-dressage") then
		get_page("/volcanoisland.php", { pwd = session.pwd, action = "npc" })
	end

	async_get_page("/volcanoisland.php", { pwd = session.pwd, action = "npc" })
	local ptnpc = get_page("/volcanoisland.php", { pwd = session.pwd, action = "npc" })
	if ptnpc:contains("watch his turtles practice their backflips") then
		try_killing_TT_nemesis()
		return
	end

	script.bonus_target { "easy combat" }
	script.ensure_buffs {}
	script.wear { weapon = "fouet de tortue-dressage" }
	script.want_familiar "Baby Gravy Fairy"
	script.heal_up()
	script.ensure_mp(50)
	local function macro_nemesis_turtletamer()
		return [[
scrollwhendone

abort pastround 20
abort hppercentbelow 50

if match "frenchturtle"
  cast tortue
  cast tortue
  if hasskill Shell Up
    cast Shell Up
  endif
  cast tortue
  repeat
endif

]] .. macro_noodleserpent()
	end
	local pt, url = get_page("/volcanoisland.php", { pwd = session.pwd, action = "tuba" })
	result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_nemesis_turtletamer)
	if result:contains("escort it out of the compound") then
		advagain = true
	end
end

function try_killing_P_nemesis()
	script.bonus_target { "easy combat" }
	script.ensure_buffs {}
	script.wear { weapon = "Greek Pasta of Peril" }
	script.ensure_mp(50)
	fought = false
	local had_cult_robe = have_equipped_item("spaghetti cult robe")
	result, resulturl = get_page("/volcanoisland.php", { pwd = session.pwd, action = "tniat" })
	print("DEBUG: lock url cont", locked(), resulturl, result:contains([[value="Continue"]]))
	if locked() or not resulturl:contains("volcanoisland.php") or result:contains([[value="Continue"]]) then
		fought = true
	end
	if had_cult_robe and not have_equipped_item("spaghetti cult robe") then
		fought = true
	end
	result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_noodleserpent)
	print("DEBUG: lock url advagain", locked(), resulturl, advagain)
	check_volcanomaze()
	return fought
end

function automate_P_nemesis_island()
	if not have_item("encoded cult documents") then
		get_page("/volcanoisland.php", { pwd = session.pwd, action = "npc" })
	end
	if try_killing_P_nemesis() then
		print("DEBUG: killing nemesis...")
		return
	end
	stop "TODO: Automate pastamancer island"
end

				-- farm and use 5 "cult memo" if don't have skill, use "decoded cult documents"
				-- cast thrall
				-- use fatten-item if available
				-- fight until heavy if not
				-- fight with heavy thrall
				-- equip "spaghetti cult robe", go to lair
				-- equip "Greek Pasta of Peril", do lair and maze
				-- kill boss, cast noodles a lot
function automation_step(tbl)
end

automation_step {
	provides = {
	},
	requires = {
	},
	action = function()
	end,
}

--need disguise
--  fight with thrall
--  need thrall lvl X
--    use fatten-item if available
--    need thrall
--      need skill
--        need docs
--          use pages
--            need pages
--              farm pages

function try_killing_S_nemesis()
	script.bonus_target { "easy combat" }
	script.ensure_buffs {}
	script.wear { weapon = "17-alarm Saucepan" }
	script.ensure_mp(50)
	fought = false
	local had_slimeform = have_buff("Slimeform")
	result, resulturl = get_page("/volcanoisland.php", { pwd = session.pwd, action = "tniat" })
	print("DEBUG: lock url cont", locked(), resulturl, result:contains([[value="Continue"]]))
	if locked() or not resulturl:contains("volcanoisland.php") or result:contains([[value="Continue"]]) then
		fought = true
	end
	if had_slimeform and not have_buff("Slimeform") then
		fought = true
	end
	result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_noodleserpent)
	if fought then
		advagain = true
	end
	print("DEBUG: lock url advagain", locked(), resulturl, advagain)
	if result:contains([[value="Continue"]]) then
		result, resulturl = get_page("/volcanomaze.php", { start = 1 })
		automate_volcanomaze()
		script.ensure_buffs { "Jalape&ntilde;o Saucesphere", "Elemental Saucesphere", "Antibiotic Saucesphere", "Scarysauce" }
		script.ensure_mp(100)
		script.heal_up()
		local buffs = 0
		for _, x in ipairs { "Jalape&ntilde;o Saucesphere", "Elemental Saucesphere", "Antibiotic Saucesphere" } do
			if have_buff(x) then
				buffs = buffs + 1
			end
		end
		if buffs >= 2 then
			result, resulturl = get_page("/volcanomaze.php", { move = "6,6" })
			result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_noodleserpent)
			advagain = false
		end
	end
	return fought
end

function automate_S_nemesis_island()
	if try_killing_S_nemesis() then
		print("DEBUG: killing nemesis...")
		return
	end
	if locked() then
		print("DEBUG: locked nemesis")
		return
	end
	if have_buff("Slimeform") then
		critical "TODO: kill nemesis"
	end
	nemesis_try_sauceror_potions()
	if have_buff("Slimeform") then
		advagain = true
		return
	end
	if not have_item("bottle of G&uuml;-Gone") then
		get_page("/volcanoisland.php", { pwd = session.pwd, action = "npc" })
	end
	get_page("/account.php", { action = "autoattack", whichattack = 0, ajax = 1, pwd = session.pwd }) -- unset autoattack, bleh
	script.bonus_target { "easy combat" }
	script.ensure_buffs {}
	script.wear { acc1 = first_wearable { "Space Trip safety headphones" } }
	script.want_familiar "Baby Gravy Fairy"
	local function macro_nemesis_sauceror()
		return [[

use 3898
repeat

]]
	end
	local pt, url = get_page("/volcanoisland.php", { pwd = session.pwd, action = "tuba" })
	result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_nemesis_sauceror)
	if result:contains([[several of the slimes take notice of you and begin to quiver agitatedly]]) then
		advagain = true
	end
end

function automate_DB_nemesis_island()
			text = "automate DB island!"
			local pwd = session.pwd
			get_page("/account.php", { action = "autoattack", whichattack = "0", ajax = "1", pwd = pwd }) -- unset autoattack, bleh

	local npcpt = get_page("/volcanoisland.php", { pwd = session.pwd, action = "npc" })
	if npcpt:contains("I saw you got inside,") then
		script.bonus_target { "easy combat" }
		script.ensure_buffs {}
		script.wear { weapon = "Shagadelic Disco Banjo" }
		script.ensure_mp(50)
		result, resulturl = get_page("/volcanoisland.php", { pwd = session.pwd, action = "tniat" })
		local fought = false
		print("DEBUG: lock url cont", locked(), resulturl, result:contains([[value="Continue"]]))
		if locked() or not resulturl:contains("volcanoisland.php") or result:contains([[value="Continue"]]) then
			fought = true
		end
		result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_noodleserpent)
		print("DEBUG: lock url advagain", locked(), resulturl, advagain)
		check_volcanomaze()
		text = result
		return
	end

			local skillnames = { "Break It On Down", "Pop and Lock It", "Run Like the Wind" }
			if have_skill("Gothy Handwave") then
				if have_skill("Break It On Down") and have_skill("Pop and Lock It") and have_skill("Run Like the Wind") then
					local function learn_move(test_it)
						text = "test " .. tostring(test_it)
						local macro_test_db_move = [[
scrollwhendone

abort pastround 28
abort hppercentbelow 50

if hascombatitem rock band flyers
  use rock band flyers
endif

if (monstername running man) || (monstername breakdancing raver) || (monstername pop-and-lock raver)
  cast ]] .. skillnames[tonumber(test_it:sub(1, 1))] .. [[

  cast ]] .. skillnames[tonumber(test_it:sub(2, 2))] .. [[

  cast ]] .. skillnames[tonumber(test_it:sub(3, 3))] .. [[

  use seal tooth
endif
]]
						local pt, url = get_page("/volcanoisland.php", { pwd = pwd, action = "tuba" })
						result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_test_db_move)
						if not advagain then
							if result:contains("You finish your chain of attacks") or result:contains("You complete your rave combo") or result:contains("You finish off your dance combo") then
								local learned = nil
								if result:contains("Your dance routine leaves you feeling particularly groovy and at one with the universe.") then
									learned = "Rave Nirvana"
								elseif result:contains("Your dance routine leaves you feeling extra-focused and in the zone.") then
									learned = "Rave Concentration"
								elseif result:contains("Your savage beatdown seems to have knocked loose some treasure.") then
									learned = "Rave Steal"
								elseif result:contains("you feel pretty good about the extra dance practice you're getting.") then
									learned = "Rave Stats"
								elseif result:contains("seems to be temporarily unconscious") then
									learned = "Rave Stun"
								elseif result:contains("bleeds from various wounds you've inflicted") then
									learned = "Rave Bleed"
								end
								text = result
								if learned then
									local moves = ascension["nemesis.db.moves"] or {}
									moves[test_it] = learned
									ascension["nemesis.db.moves"] = moves
									print("learned", test_it, "=", learned)
									local macro_finish_kill = [[
scrollwhendone

abort pastround 28
abort hppercentbelow 50

while !times 3
  cast Stringozzi Serpent
endwhile
]]
									result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_finish_kill)
									text = result
								else
									print(result:match([[You're fighting.-<a name="end">]]))
									critical "don't know what we learned"
								end
							else
								print(result:match([[You're fighting.-<a name="end">]]))
								critical "didn't learn anything"
							end
						end
					end
					text = "pickpocket DB items"
					for i = 1, 100 do
						local moves = ascension["nemesis.db.moves"] or {}
						local test_it = nil
						for x in table.values { "123", "132", "213", "231", "312", "321" } do
							if not moves[x] then
								test_it = x
								break
							end
						end
						if test_it then
							learn_move(test_it)
						else
							local raveosity = 0
							local rave_items = {
								["rave visor"] = 2,
								["baggy rave pants"] = 2,
								["pacifier necklace"] = 2,
								["teddybear backpack"] = 1,
								["glowstick on a string"] = 1,
								["candy necklace"] = 1,
								["rave whistle"] = 1,
							}
							if not have_item("rave whistle") then
								pull_storage_item("rave whistle")
							end
							for name, value in pairs(rave_items) do
								if have_item(name) then
									print("have", name, ": ", value)
									raveosity = raveosity + value
								end
							end
							print("can get", raveosity, "raveosity")
							if raveosity >= 7 then
								local eq = equipment()
								text = "got enough raveosity, wear it"
								set_equipment {}
								equip_item("rave visor")
								equip_item("baggy rave pants")
								equip_item("rave whistle")
								equip_item("glowstick on a string")
								equip_item("pacifier necklace", 1)
								equip_item("teddybear backpack", 2)
								equip_item("candy necklace", 3)
								local pt = get_page("/volcanoisland.php", { pwd = pwd, action = "tniat", action2 = "try" })
								set_equipment(eq)
								text = pt
								if pt:contains("shrugs and politely opens the door for you") then
									-- TODO: automate more?
-- 									"a daft punk" at action = "tniat"
								end
								break
							else
								local steal_order = nil
								local moves = ascension["nemesis.db.moves"] or {}
								for x, y in pairs(moves) do
									if y == "Rave Steal" then
										steal_order = x
									end
								end
								local macro_steal_db_items = [[
scrollwhendone

abort pastround 28
abort hppercentbelow 50

if hascombatitem rock band flyers
  use rock band flyers
endif

sub do_kill
  while !times 3
    cast Stringozzi Serpent
  endwhile
endsub

if (monstername running man) || (monstername breakdancing raver) || (monstername pop-and-lock raver)
  cast ]] .. skillnames[tonumber(steal_order:sub(1, 1))] .. [[

  cast ]] .. skillnames[tonumber(steal_order:sub(2, 2))] .. [[

  cast ]] .. skillnames[tonumber(steal_order:sub(3, 3))] .. [[

  call do_kill
endif
]]
								local pt, url = get_page("/volcanoisland.php", { pwd = pwd, action = "tuba" })
								result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_steal_db_items)
								if not advagain then
									break
								end
							end
						end
					end
				else
					-- TODO: choose equipment
					-- TODO: turn off autoattack
					local macro_learn_db_moves = [[
scrollwhendone

abort pastround 28
abort hppercentbelow 50

if hascombatitem rock band flyers
  use rock band flyers
endif

sub do_kill
  while !times 3
    cast Stringozzi Serpent
  endwhile
endsub

if monstername running man
  while (!match "The raver turns*anywhere") && (!pastround 25)
    use seal tooth
  endwhile
  cast Gothy Handwave
  call do_kill
endif

if monstername breakdancing raver
  while (!match "raver drops to the ground") && (!pastround 25)
    use seal tooth
  endwhile
  cast Gothy Handwave
  call do_kill
endif

if monstername pop-and-lock raver
  while (!match "movements suddenly become spastic and jerky") && (!pastround 25)
    use seal tooth
  endwhile
  cast Gothy Handwave
  call do_kill
endif
]]
					text = "learn DB skills"
					for i = 1, 100 do
						local pt, url = get_page("/volcanoisland.php", { pwd = pwd, action = "tuba" })
						result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_learn_db_moves)
						if not advagain then
							break
						end
						if have_skill("Break It On Down") and have_skill("Pop and Lock It") and have_skill("Run Like the Wind") then
							break
						end
						print("DB skills:", have_skill("Break It On Down"), have_skill("Pop and Lock It"), have_skill("Run Like the Wind"))
					end
					text = result
				end
			else
				get_page("/volcanoisland.php", { pwd = pwd, action = "npc" })
			end
end

function automate_AT_nemesis_island()
	get_page("/volcanoisland.php", { pwd = session.pwd, action = "npc" })
	if count_item("hacienda key") >= 5 then
		for i = 1, 20 do
			script.bonus_target { "easy combat" }
			script.ensure_buffs {}
			script.wear { weapon = "Squeezebox of the Ages" }
			script.ensure_mp(50)
			result, resulturl = get_page("/volcanoisland.php", { pwd = session.pwd, action = "tniat" })
			result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_noodleserpent)
			if not advagain and locked() then
				break
			end
		end
		text = result
	else
		text = "explore barracks"
		for i = 1, 100 do
			print("exploring barracks...", i)
			if have_buff("Beaten Up") then
				cast_skillid(1010) -- tongue of the walrus
				cast_skillid(3012) -- cocoon
			end
			if count_item("hacienda key") >= 5 then
				break
			end
			if not have_buff("The Sonata of Sneakiness") then
				cast_skillid(6015, 2) -- sonata of sneakiness
			end
			if not have_buff("Smooth Movements") then
				cast_skillid(5017, 2) -- smooth moves
			end
			local visited = ascension["nemesis.at.visited"] or {}
			local want = {
				{ "Head down the hall to the left", {
					{ "Enter the kitchen", { "Check the cupboards", "Check the pantry", "Check the fridges" } },
					{ "Enter the dining room", { "Search the tables", "Search the sideboard", "Search the china cabinets" } },
					{ "Enter the storeroom", { "Search the crates", "Search the workbench", "Search the gun cabinet" } },
				} },
				{ "Head down the hall to the right", {
					{ "Enter the bedroom", { "Search the beds", "Search the dressers", "Search the bathroom" } },
					{ "Enter the library", { "Search the bookshelves", "Search the chairs", "Examine the chess set" } },
					{ "Enter the parlour", { "Examine the pool table", "Examine the bar", "Examine the fireplace" } },
				} },
			}
			local choice_name = nil
			local choice_list = nil
			for _, x in ipairs(want) do
				for _, y in ipairs(x[2]) do
					for _, z in ipairs(y[2]) do
						local name = tostring(x[1]) .. ":" .. tostring(y[1]) .. ":" .. tostring(z)
						if not visited[name] then
							choice_name = name
							choice_list = { x[1], y[1], z }
						end
					end
				end
			end
			script.ensure_mp(50)
			print("volcano:tuba")
			local pt, url = get_page("/volcanoisland.php", { pwd = session.pwd, action = "tuba" })
			if not choice_name then
				stop "Explored all of nemesis AT barracks"
			end
			result, resulturl, advagain = handle_adventure_result(pt, url, 220, nil, {}, function(advtitle, choicenum)
				print("visiting", choice_name)
				visited[choice_name] = "yes"
				ascension["nemesis.at.visited"] = visited
				if advtitle == "The Island Barracks" then
					return "Continue"
				elseif choice_list[1] then
					return table.remove(choice_list, 1)
				end
			end)
			if not advagain and result:contains("fight.php") then
				print("volcano:tuba:fight")
				pt, url = get_page("/fight.php")
				result, resulturl, advagain = handle_adventure_result(pt, url, 220, macro_ppnoodlecannon)
			end
			if not advagain then
				if have_buff("Beaten Up") then
					print("beaten up...")
					cast_skillid(1010) -- tongue
					cast_skillid(3012) -- cocoon
					if have_buff("Beaten Up") then
						break
					end
				elseif result:contains("You slink away, dejected and defeated") and result:contains("You lose an effect") then
				else
					break
				end
			end
		end
		text = result
	end
end
