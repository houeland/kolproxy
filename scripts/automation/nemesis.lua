-- TODO: use automation script framework
-- quest_completed("Me and My Nemesis")

-- TODO: make this work more like ascension-automation

local href = add_automation_script("automate-nemesis", function ()
	if not autoattack_is_set() then
		stop "Set a macro on autoattack to use for scripting this quest."
	end
-- TODO: continue after successfully completing one step
	text, url = "??? Nothing to do right now ???", requestpath
	local pwd = get_session_state("pwd") -- inserting pwd, boo!
	-- pull stuff
	--~ posting page /storage.php params: Just [("pwd","c52682cbfb2ed7825b5b479e76b36c35"),("action","take"),("howmany1","1"),("whichitem1","4508"),("howmany2","1"),("whichitem2","3137")]
	local function dorefresh()
		scg = get_page("/guild.php", { place = "scg" })
		scg = get_page("/guild.php", { place = "scg" })
		questlog = get_page("/questlog.php", { which = 1 })
	end
	dorefresh()
	if scg:match([[Have you not completed your Epic Weapon yet]]) or scg:match([[not yet completed your Epic Weapon]]) or scg:match([[delay on that Epic Weapon]]) then
		text = "pulling items"
--~ 		TODO: make it if you can't pull it, or at least warn that it's missing!
		ews = {
			[1] = "Bjorn's Hammer",
			[2] = "Mace of the Tortoise",
			[3] = "Pasta of Peril",
			[4] = "5-Alarm Saucepan",
			[5] = "Disco Banjo",
			[6] = "Rock and Roll Legend",
		}
		needew = ews[classid()]
		pull_storage_items { needew }
		dorefresh()
	end
	if scg:match([[How goes your quest to restore the Legendary Epic Weapon]]) or scg:match([[acquire the Legendary Epic Weapon soon]]) or scg:match([[going with that Legendary Epic Weapon]]) then
		text = "make LEW"
		if questlog:match("you must defeat Beelzebozo") then
	--~ 		TODO: make robust
			text = "adventuring at clown house"
			pull_storage_items { 2477, 2478, 1298 }
-- 			"Peppercorns of Power"
			if have("clown whip") and have("clownskin buckler") and have("ring of conflict") then
				-- wear stuff
				equip_item("clown whip")
				equip_item("clownskin buckler")
				equip_item("ring of conflict", 3)
				-- buff up
				if not buff("The Sonata of Sneakiness") then
					cast_skillid(6015, 2) -- sonata of sneakiness
				end
				if not buff("Smooth Movements") then
					cast_skillid(5017, 2) -- smooth moves
				end
				-- adventure repeatedly
				for i = 1, 100 do
					text, url, advagain = autoadventure { zoneid = 20 }
					if not url:match("fight.php") or not advagain then
						break
					end
				end
			else
				stop("Error: Clown items not found")
			end
		else
			stop("TODO: Make LEW")
		end
		dorefresh()
	end
	if scg:match([[Have you defeated your Nemesis yet]]) or scg:match([[We need you to defeat your Nemesis]]) or scg:match([[Haven't beat your Nemesis yet]]) then
		text = "pass cave doors"
		pull_storage_items { 37, 560, 565, 316, 319, 1256, 2478, 2477, 420, 579, 799 }
		cast_skillid(6006) -- polka of plenty
		text, url = get_page("/cave.php")
-- 		TODO: pass caves automatically
--~ 		TODO: farm scraps and stuff
--~ 		TODO: equip weapon and fight nemesis
		dorefresh()
	end
	if questlog:contains "found a map to the secret tropical island" then
		text = "do poop deck"
		-- wear stuff
		equip_item("pirate fledges", 2)
		equip_item("ring of conflict", 3)
		-- buff up
		if not buff("The Sonata of Sneakiness") then
			cast_skillid(6015, 2) -- sonata of sneakiness
		end
		if not buff("Smooth Movements") then
			cast_skillid(5017, 2) -- smooth moves
		end
		-- adventure repeatedly
		for i = 1, 100 do
			text, url, advagain = autoadventure { zoneid = 159 }
-- choice	O Cap'm, My Cap'm	189
-- opt	1	Front the meat and take the wheel
-- opt	2	Step away from the helm
-- opt	3	Show the tropical island volcano lair map to the navigator
			if not url:match("fight.php") or not advagain then
				break
			end
		end
		dorefresh()
	end
	if questlog:contains("put a stop to this Nemesis nonsense") then
		text = "automate class-specific island!"
		if classid() == 1 then -- seal clubber
		elseif classid() == 2 then -- turtle tamer
			if not have("fouet de tortue-dressage") then
				get_page("/volcanoisland.php", { pwd = pwd, action = "npc" })
			end
		elseif classid() == 3 then -- pastamancer
			if not have("encoded cult documents") then
				get_page("/volcanoisland.php", { pwd = pwd, action = "npc" })
			end
-- "proxy:/volcanoisland.php?pwd=a412cd1e0a0d040806269162e564fcb1&action=tuba"  Nothing (get info)
-- "proxy:/volcanoisland.php?pwd=a412cd1e0a0d040806269162e564fcb1&action=tuba"  Nothing
-- "proxy:/adventure.php?snarfblat=217"
-- collect 5 cult memo, use "cult memo"
-- use "decoded cult documents"
-- use spirit in volcano combat until ...
-- equip accessory "spaghetti cult robe"
-- "proxy:/volcanoisland.php?pwd=a412cd1e0a0d040806269162e564fcb1&action=tniat"  Nothing
-- "proxy:/adventure.php?snarfblat=221"
-- repeat until... boss fight, Angelhair Culottes
-- equip weapon Greek Pasta of Peril
-- "proxy:/volcanoisland.php?pwd=a412cd1e0a0d040806269162e564fcb1&action=tniat"  Nothing
-- "proxy:/volcanomaze.php?"  Nothing
		elseif classid() == 4 then -- sauceror
		elseif classid() == 5 then -- disco bandit
			text = "automate DB island!"
			local pwd = get_session_state("pwd") -- inserting pwd, boo!
			get_page("/account.php", { action = "autoattack", whichattack = "0", ajax = "1", pwd = pwd }) -- unset autoattack, bleh
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
							if not have("rave whistle") then
								pull_storage_items { "rave whistle" }
							end
							for name, value in pairs(rave_items) do
								if have(name) then
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
		elseif classid() == 6 then -- accordion thief
			get_page("/volcanoisland.php", { pwd = pwd, action = "npc" })
			if count("hacienda key") < 5 then
				text = "explore barracks"
				for i = 1, 100 do
					print("exploring barracks...", i)
					if buff("Beaten Up") then
						cast_skillid(1010) -- tongue of the walrus
						cast_skillid(3012) -- cocoon
					end
					if count("hacienda key") >= 5 then
						break
					end
					if not buff("The Sonata of Sneakiness") then
						cast_skillid(6015, 2) -- sonata of sneakiness
					end
					if not buff("Smooth Movements") then
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
					for x in table.values(want) do
						for y in table.values(x[2]) do
							for z in table.values(y[2]) do
								local name = tostring(x[1]) .. ":" .. tostring(y[1]) .. ":" .. tostring(z)
								if not visited[name] then
									choice_name = name
									choice_list = { x[1], y[1], z }
								end
							end
						end
					end
					print("volcano:tuba")
					local pt, url = get_page("/volcanoisland.php", { pwd = pwd, action = "tuba" })
					if not choice_name then
						stop "Explored all of nemesis AT barracks"
					end
					result, resulturl, advagain = handle_adventure_result(pt, url, 220, nil, {}, function (advtitle, choicenum)
						print("visiting", choice_name)
						visited[choice_name] = "yes"
						ascension["nemesis.at.visited"] = visited
						if advtitle == "The Island Barracks" then
							return "Continue"
						else
							if choice_list[1] then
								return table.remove(choice_list, 1)
							else
								-- TODO handle fights right
								return "Fight!"
							end
						end
					end)
					if not advagain then
						print("volcano:tuba:fight")
						pt, url = get_page("/fight.php")
						result, resulturl, advagain = handle_adventure_result(pt, url, 220, nil)
					end
					if not advagain then
						if buff("Beaten Up") then
							print("beaten up...")
							cast_skillid(1010) -- tongue
							cast_skillid(3012) -- cocoon
							if buff("Beaten Up") then
								break
							end
						else
							break
						end
					end
				end
				text = result
			else
				text = "TODO: have all hacienda keys"
			end
		end
-- 		dorefresh()
	end
	return text, url
end)

add_printer("/questlog.php", function ()
	if not setting_enabled("enable turnplaying automation") or ascensionstatus() ~= "Aftercore" then return end
	text = text:gsub("<b>Me and My Nemesis</b>", [[%0 <a href="]]..href { pwd = session.pwd }..[[" style="color:green">{ automate }</a>]])
end)
