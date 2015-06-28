__allow_global_writes = true

function get_automation_tasks(script, cached_stuff)
	local t = {}
	local task = t
	local tasks = t

	t.summon_tomes = {
		message = "summon tomes",
		nobuffing = true,
		action = function()
			cached_stuff.summoned_tomes = true
			local want_smith_weapons = {
				["Seal Clubber"] = "Meat Tenderizer is Murder",
				["Turtle Tamer"] = "Work is a Four Letter Sword",
				["Pastamancer"] = "Hand that Rocks the Ladle",
				["Sauceror"] = "Saucepanic",
				["Disco Bandit"] = "Frankly Mr. Shank",
				["Accordion Thief"] = "Shakespeare's Sister's Accordion",
			}
			if moonsign_area("Degrassi Knoll") then
				local want_items = {}
				if want_smith_weapons[maybe_playerclassname()] and not have_item("Thor's Pliers") then table.insert(want_items, want_smith_weapons[maybe_playerclassname()]) end
				table.insert(want_items, "A Light that Never Goes Out")
				table.insert(want_items, "Hairpiece On Fire")
				table.insert(want_items, "Vicar's Tutu")
				for _, x in ipairs(want_items) do
					if not have_item(x) then
						if not have_item("lump of Brituminous coal") then
							script.ensure_mp(2)
							get_page("/campground.php", { preaction = "summonsmithsness", quantity = 1 })
						end
						if have_item("lump of Brituminous coal") then
							if x == "Work is a Four Letter Sword" and not have_item("sword hilt") then
								store_buy_item("sword hilt", "s")()
							elseif x == "A Light that Never Goes Out" and not have_item("third-hand lantern") then
								store_buy_item("third-hand lantern", "m")()
							elseif x == "Hairpiece On Fire" and not have_item("maiden wig") then
								store_buy_item("maiden wig", "4")()
							elseif x == "Vicar's Tutu" and not have_item("frilly skirt") then
								store_buy_item("frilly skirt", "4")()
							else
								unequip_slot("weapon")()
							end
							craft_item(x)()
						end
					end
					if not have_item(x) then
						break
					end
				end

				local have_all = true
				for idx, x in ipairs(want_items) do
					if idx >= 3 then
						break
					elseif not have_item(x) then
						have_all = false
					end
				end
--				if have_all and level() <= 6 and script_use_unified_kill_macro() then
--					pull_in_softcore("Hand in Glove")
--				end
			end

			if not have_item("shining halo") and level() == 1 and not get_ascension_automation_settings().should_wear_weapons then
				script.ensure_mp(2)
				summon_clipart("shining halo")
			end

			if not have_item("Ur-Donut") and level() == 1 then
				script.ensure_mp(2)
				summon_clipart("Ur-Donut")
				eat_item("Ur-Donut")
			end
			did_action = true
		end
	}

	t.get_starting_items = {
		message = "get starting items",
		nobuffing = true,
		action = function()
			if not (have_item("stolen accordion") and have_item("turtle totem") and have_item("saucepan")) then
				inform "buy and use chewing gum"
				while not (have_item("stolen accordion") and have_item("turtle totem") and have_item("saucepan")) do
					result, resulturl, advagain = script.buy_use_chewing_gum()
					if not advagain then
						critical "Failed to use chewing gum"
					end
				end
				return result, resulturl
			end

			if not playerclass("Accordion Thief") and AT_song_duration() < 5 then
				inform "buy toy accordion"
				set_result(store_buy_item("toy accordion", "z"))
				did_action = have_item("toy accordion")
			end
		end
	}

	t.get_seal_tooth = {
		message = "get seal tooth",
		nobuffing = true,
		action = function()
			inform "pick up seal tooth"
			script.ensure_worthless_item()
			if not have_item("hermit permit") then
				store_buy_item("hermit permit", "m")
			end
			set_result(post_page("/hermit.php", { action = "trade", whichitem = get_itemid("seal tooth"), quantity = 1 }))
			did_action = have_item("seal tooth")
		end
	}

	t.extend_tmm_and_mojo = {
		message = "extending tmm+mojo",
		nobuffing = true,
		action = function()
			script.ensure_buffs { "The Moxious Madrigal", "The Magical Mojomuscular Melody" }
			script.ensure_buff_turns("The Moxious Madrigal", 10)
			script.ensure_buff_turns("The Magical Mojomuscular Melody", 10)
			did_action = true
		end,
	}

	t.place_instant_house = {
		message = "place instant house",
		nobuffing = true,
		action = function()
			get_page("/inv_use.php", { pwd = get_pwd(), whichitem = get_itemid("Frobozz Real-Estate Company Instant House (TM)"), ajax = 1, confirm = "true" })
			did_action = not have_item("Frobozz Real-Estate Company Instant House (TM)")
		end
	}

	t.rotting_matilda = {
		message = "rotting matilda",
		nobuffing = true,
		action = function()
			local pt, pturl, advagain = autoadventure { zoneid = get_zoneid("The Haunted Ballroom") }
			if not pt:contains("Rotting Matilda") then
				set_result(pt, pturl)
				critical "Didn't find rotting matilda on dance card turn"
			end
			return pt, pturl, advagain
		end
	}

	-- TODO: merge
	function t.make_digital_key()
		if not have_item("continuum transfunctioner") then
			return {
				message = "pick up continuum transfunctioner (to make digital key)",
				nobuffing = true,
				action = function()
					set_result(pick_up_continuum_transfunctioner())
					did_action = have_item("continuum transfunctioner")
				end
			}
		elseif count_item("white pixel") < 30 then
			return {
				message = "make white pixels",
				nobuffing = true,
				action = function()
					local to_make = 30 - count_item("white pixel")
					shop_buy_item({ ["white pixel"] = to_make }, "mystic")
					did_action = (count_item("white pixel") >= 30)
				end
			}
		else
			return {
				message = "make digital key",
				nobuffing = true,
				action = function()
					shop_buy_item("digital key", "mystic")
					did_action = have_item("digital key")
				end
			}
		end
	end

	function t.do_8bit_realm()
		local action = nil
		local pixels = count_item("white pixel") + math.min(count_item("red pixel"), count_item("green pixel"), count_item("blue pixel"))
		if pixels < 30 then
			if not have_item("continuum transfunctioner") then
				return {
					message = "pick up continuum transfunctioner (to do 8-bit realm)",
					action = function()
						set_result(pick_up_continuum_transfunctioner())
						did_action = have_item("continuum transfunctioner")
					end
				}
			else
				return {
					hide_message = true,
					message = "do_8bit_realm",
					familiar = "Stocking Mimic",
					olfact = "Blooper",
					equipment = { acc1 = "continuum transfunctioner" },
					action = function()
						-- TODO: use adventure()
						script.go("farm pixels for digital key: " .. pixels, 73, macro_8bit_realm, nil, { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Ghostly Shell", "Astral Shell", "Leash of Linguini", "Empathy" }, "Stocking Mimic", 15, { olfact = "Blooper", equipment = { acc1 = "continuum transfunctioner" } })
					end
				}
			end
		else
			return task.make_digital_key()
		end
	end

	t.yellow_ray_sleepy_mariachi = {
		message = "yellow ray sleepy mariachi",
		familiar = "He-Boulder",
		minmp = 10,
		action = function()
			script.get_faxbot_fax("sleepy mariachi")
			use_item("photocopied monster")
			local pt, url = get_page("/fight.php")
			local mariachi_macro = [[
abort pastround 20
abort hppercentbelow 50
scrollwhendone

use finger cuffs

while !times 10
  if match yellow eye
    cast point at your opponent
    goto m_done
  endif
  if match tear the finger cuffs
    use finger cuffs
	goto m_whiledone
  endif
  cast Sing
  mark m_whiledone
endwhile

mark m_done

]]
			result, resulturl, advagain = handle_adventure_result(pt, url, "?", mariachi_macro)
			if advagain and have_item("spangly sombrero") and have_item("spangly mariachi pants") then
				did_action = true
			end
		end
	}

	function t.do_sewerleveling()
		if advs() < 12 then
			stop "Fewer than 12 advs for sewerleveling"
		end
		if have_buff("Ode to Booze") then
			script.shrug_buff("Ode to Booze")
		end
		return {
			message = "sewerlevel to lvl 6",
			familiar = "Frumious Bandersnatch",
			buffs = { "Springy Fusilli", "Spirit of Garlic", "Pisces in the Skyces" },
			maybe_buffs = { "Mental A-cue-ity" },
			minmp = 70,
			action = adventure {
				zoneid = 166,
				macro_function = macro_noodlegeyser(3),
				noncombats = {
					["Disgustin' Junction"] = "Swim back toward the entrance",
					["The Former or the Ladder"] = "Play in the water",
					["Somewhat Higher and Mostly Dry"] = "Dive back into the water",
				}
			}
		}
	end

	function t.do_bearhug_sewerleveling()
		if advs() < 12 then
			stop "Fewer than 12 advs for sewerleveling"
		else
			return {
				message = "sewerlevel with bear hug",
				equipment = { weapon = "right bear arm", offhand = "left bear arm" },
				action = adventure {
					zoneid = 166,
					macro_function = function() return "cast Bear Hug" end,
					noncombats = {
						["Disgustin' Junction"] = "Swim back toward the entrance",
						["The Former or the Ladder"] = "Play in the water",
						["Somewhat Higher and Mostly Dry"] = "Dive back into the water",
					}
				}
			}
		end
		if not did_action then
			result = add_message_to_page(get_result(), "Tried to adventure at the Hobopolis sewer entrance", nil, "darkorange")
		end
		return result, resulturl, did_action
	end

	function t.do_orc_chasm()
		local pt, pturl = get_place("orc_chasm")
		local pieces = tonumber(pt:match("action=bridge([0-9]*)"))
		if not pieces and ascensionpath("Actually Ed the Undying") then
			result, resulturl = get_place("orc_chasm", "bridge_done")
			result, resulturl, did_action = handle_adventure_result(result, resulturl, "?", macro_kill_monster)
			return
		end
		if not pieces then
			critical "Couldn't determine bridge status"
		end
		if not have_item("dictionary") then
			if have_item("abridged dictionary") then
				do_degrassi_untinker_quest()
				async_post_page("/place.php", { whichplace = "forestvillage", action = "fv_untinker", pwd = get_pwd(), preaction = "untinker", whichitem = get_itemid("abridged dictionary") })
			end
			if not have_item("dictionary") then
				stop "Missing bridge from pirates"
			end
		end
		pt = get_page("/place.php", { whichplace = "orc_chasm", action = "bridge" .. pieces })
		if pt:contains("have to check out that lumber camp down there") then
			-- TODO: bees hate you
			if have_item("snow boards") then
				return maketask_use_item("snow boards")
			elseif have_item("smut orc keepsake box") then
				return maketask_use_item("smut orc keepsake box")
			elseif count_item("snow berries") >= 2 then
				return {
					message = "buy snow boards",
					nobuffing = true,
					action = function()
						shop_buy_item("snow boards", "snowgarden")
						did_action = have_item("snow boards")
					end
				}
			elseif ascensionstatus("Softcore") and not skipped_pull("smut orc keepsake box") then
				return {
					message = "pull keepsake box",
					nobuffing = true,
					action = function()
						pull_in_softcore("smut orc keepsake box", true)
						did_action = have_item("smut orc keepsake box") or ascension_script_option("automate whenever possible")
					end
				}
			else
				return {
					message = "get bridge parts (" .. pieces .. ")",
					familiar = "Slimeling",
					buffs = { "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "Empathy" },
					bonus_target = { "item" },
					minmp = 35,
					action = adventure {
						zoneid = 295,
						macro_function = macro_noodleserpent,
					}
				}
			end
		else
			return {
				message = "check bridge",
				nobuffing = true,
				action = function()
					pt = get_place("orc_chasm")
					pieces = tonumber(pt:match("action=bridge([0-9]*)"))
					if not pieces then
						did_action = true
						return
					end
					pt, pturl = get_page("/place.php", { whichplace = "orc_chasm", action = "bridge" .. pieces })
					if pt:contains("have to check out that lumber camp down there") then
						did_action = true
					end
					return pt, pturl
				end
			}
		end
	end

	function t.do_oil_peak()
		-- TODO: buff ML to +50 or +100 via:
			-- bugbear familiar or purse rat + familiar levels
			-- ur-kel's
			-- lap dog
			-- hipposkin poncho or goth kid t-shirt
			-- buoybottoms
			-- spiky turtle helmet or crown of thrones w/ el vibrato megadrone
			-- astral belt, C.A.R.N.I.V.O.R.E. button, grumpy old man charrrm bracelet, ring of aggravate monster
			-- Boris: Song of Cockiness, Overconfident
		if have_skill("Gristlesphere") then
			script.ensure_buffs { "Gristlesphere" }
		end
		return {
			message = "do oil peak",
			familiar = "Baby Bugged Bugbear",
			buffs = { "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "A Few Extra Pounds", "Ur-Kel's Aria of Annoyance" },
			bonus_target = { "monster level" },
			minmp = 60,
			action = function()
				if estimate_bonus("Monster Level") < 50 then
					script.maybe_ensure_buffs { "Pride of the Puffin" }
				end
				if estimate_bonus("Monster Level") < 50 then
					script.maximize("Monster Level")
				end
				if estimate_bonus("Monster Level") < 20 then
					stop "Not enough +ML for Oil Peak (want 20+ for automation)"
				elseif not ascensionstatus("Hardcore") and estimate_bonus("Monster Level") < 50 and ascensionpathid() == 0 then
					-- TODO: Trigger this if script options set to go fast
					stop "Not enough +ML for Oil Peak (want 50+ for SCNP automation)"
				end
				return (adventure {
					zoneid = 298,
					macro_function = macro_noodleserpent,
				})()
			end
		}
	end

	function t.do_aboo_peak()
		local hauntedness = get_aboo_peak_hauntedness()
		if hauntedness > 0 and hauntedness - count_item("A-Boo clue") * 30 <= 0 then
			if ascensionpath("Avatar of Sneaky Pete") and ascensionstatus("Hardcore") and basemuscle() < 70 then
				return
			end
			script.ensure_buffs { "Go Get 'Em, Tiger!", "Astral Shell", "Elemental Saucesphere", "Scarysauce" }
			if predict_aboo_peak_banish() < 30 then
				if not have_buff("Super Structure") and have_item("Greatest American Pants") then
					script.wear { pants = "Greatest American Pants" }
					script.get_gap_buff("Super Structure")
				end
				if not have_buff("Well-Oiled") and have_item("Oil of Parrrlay") then
					use_item("Oil of Parrrlay")
				end
				if predict_aboo_peak_banish(maxhp()) >= 30 then
					script.force_heal_up()
				end
			end
			if predict_aboo_peak_banish() < 30 then
				script.maybe_ensure_buffs { "Red Door Syndrome" }
			end
			if predict_aboo_peak_banish() < 30 then
				local gear = {}
				if not have_buff("Super Structure") and have_item("eXtreme mittens") and have_item("eXtreme scarf") and have_item("snowboarder pants") then
					gear = { hat = "eXtreme scarf", pants = "snowboarder pants", acc3 = "eXtreme mittens" }
				end
				gear.hat = first_wearable { "lihc face" }
				gear.weapon = first_wearable { "titanium assault umbrella" }
				gear.acc1 = first_wearable { "sphygmomanometer", "plastic vampire fangs", "bejeweled pledge pin" }
				gear.acc2 = first_wearable { "glowing red eye" }
				if count_item("glowing red eye") >= 2 then
					gear.acc3 = first_wearable { "glowing red eye" }
				end
				script.wear(gear)
				script.ensure_buffs { "Reptilian Fortitude", "Power Ballad of the Arrowsmith" }
				if predict_aboo_peak_banish(maxhp()) >= 30 then
					script.force_heal_up()
				end
			end
			if predict_aboo_peak_banish() < 30 then
				script.maybe_ensure_buffs { "Oiled-Up", "Standard Issue Bravery", "Starry-Eyed", "Puddingskin", "Protection from Bad Stuff", "Truly Gritty" }
				if predict_aboo_peak_banish(maxhp()) >= 30 then
					script.force_heal_up()
				end
			end
			if predict_aboo_peak_banish() < 30 and have_skill("Check Mirror") and not have_intrinsic("Slicked-Back Do") then
				cast_check_mirror_for_intrinsic("Slicked-Back Do")
				if predict_aboo_peak_banish(maxhp()) >= 30 then
					script.force_heal_up()
				end
			end
			if predict_aboo_peak_banish() < 30 then
				script.maximize("HP & cold/spooky resistance")
				if predict_aboo_peak_banish(maxhp()) >= 30 then
					script.force_heal_up()
				end
			end
			if predict_aboo_peak_banish() < 30 then
				stop "TODO: Buff up and finish A-Boo Peak clues (couldn't banish 30%)"
			end
			use_item("A-Boo clue")
-- 			-- TODO: handle other towel versions

-- 			-- TODO: buff max hp

-- 			if not have_buff("Spooky Flavor") and have_item("ectoplasmic paste") then
-- 				use_item("ectoplasmic paste")
-- 				-- +0/+2
-- 			end
-- 			if not have_buff("Spookypants") and have_item("spooky powder") then
-- 				use_item("spooky powder")
-- 				-- +0/+1
-- 			end
-- 			if not have_buff("Insulated Trousers") and have_item("cold powder") then
-- 				use_item("cold powder")
-- 				-- +1/+0
-- 			end
			-- TODO: heal up fully
			return {
				message = string.format("follow a-boo clue (%d%% haunted)", hauntedness),
				minmp = 5,
				nobuffing = true,
				action = adventure {
					zoneid = 296,
					choice_function = function(advtitle, choicenum)
						if advtitle == "The Horror..." then
							return "", 1
						end
					end
				}
			}
		else
			-- TODO: use a clover?
			script.prepare_physically_resistant()
			return {
				message = string.format("do a-boo peak (%d%% haunted)", hauntedness),
				familiar = "Slimeling",
				buffs = { "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "Empathy" },
				bonus_target = { "item", "extraitem" },
				minmp = 50,
				action = adventure {
					zoneid = 296,
					macro_function = macro_noodlecannon,
				}
			}
		end
	end

	function t.do_twin_peak()
-- 		-- TODO: boost item drops & noncombats, sniff either topiary
		return {
			message = "solve twin peak mystery",
			familiar = "Slimeling",
			buffs = { "Fat Leon's Phat Loot Lyric", "Astral Shell", "Elemental Saucesphere" },
			bonus_target = { "noncombat", "item" },
			minmp = 50,
			action = function()
				if not cached_stuff.previous_twin_peak_noncombat_option then
					if get_resistance_level("Stench") < 4 then
						script.want_familiar "Exotic Parrot"
					end
					if get_resistance_level("Stench") < 4 and not have_buff("Red Door Syndrome") then
						script.ensure_buffs { "Red Door Syndrome" }
					end
					if get_resistance_level("Stench") < 4 then
						script.maximize("Stench Resistance")
					end
					if get_resistance_level("Stench") < 4 then
						stop "Need 4+ stench resistance"
					end
				elseif cached_stuff.previous_twin_peak_noncombat_option == "Investigate Room 237" then
					if estimate_twin_peak_effective_plusitem() < 50 then
						script.bonus_target { "item", "extraitem", "noncombat" }
						script.ensure_buffs {}
						script.wear {}
					end
					if estimate_twin_peak_effective_plusitem() < 50 then
						script.maybe_ensure_buffs { "Brother Flying Burrito's Blessing" }
					end
					if estimate_twin_peak_effective_plusitem() < 50 then
						script.maximize("Item Drops from Monsters")
					end
					if estimate_twin_peak_effective_plusitem() < 50 then
						stop "Need 50%+ item drops from monsters"
					end
				elseif cached_stuff.previous_twin_peak_noncombat_option == "Search the pantry" then
					if not have_item("jar of oil") then
						use_item("bubblin' crude", 12)
					end
					if not have_item("jar of oil") then
						--stop "Need jar of oil"
						local crude = count_item("bubblin' crude")
						run_task(t.do_oil_peak())
						did_action = (count_item("bubblin' crude") > crude)
						return
					end
				elseif cached_stuff.previous_twin_peak_noncombat_option == "Follow the faint sound of music" or cached_stuff.previous_twin_peak_noncombat_option == "Wait -- who's that?" then
					if estimate_bonus("Combat Initiative") < 40 then
						script.bonus_target { "initiative", "noncombat", "item" }
						script.maybe_ensure_buffs { "Springy Fusilli" }
					end
					if estimate_bonus("Combat Initiative") < 40 then
						script.maybe_ensure_buffs { "Sugar Rush" }
					end
					if estimate_bonus("Combat Initiative") < 40 then
						stop "Need 40%+ combat initiative"
					end
				end

				local force_advagain = false
				local else_defaulted_count = 0
				local function ncfunc(advtitle, choicenum, pagetext)
					if advtitle == "Welcome to the Great Overlook Lodge" then
						force_advagain = true
						return "", 1
					elseif advtitle == "Lost in the Great Overlook Lodge" then
						for _, x in ipairs { "Investigate Room 237", "Search the pantry", "Follow the faint sound of music", "Wait -- who's that?" } do
							if pagetext:contains(x) then
								if x == cached_stuff.previous_twin_peak_noncombat_option then
									stop "Failed to make progress in Twin Peak"
								end
								cached_stuff.previous_twin_peak_noncombat_option = x
								print("AUTOMATION: picking choice", x)
								return x
							end
						end
					else
						if else_defaulted_count >= 10 then
							print(pagetext)
							print(advtitle, choicenum)
							print("AUTOMATION: assume it's OK and move on, twin peak is buggy")
							set_result(pagetext)
							force_advagain = true
							--stop "Failed to make default-progress in Twin Peak"
						else
							else_defaulted_count = else_defaulted_count + 1
							print("AUTOMATION: defaulting to choice 1")
							return "", 1
						end
					end
				end

				if have_item("rusty hedge trimmers") then
					set_result(use_item("rusty hedge trimmers"))
					result, resulturl = get_page("/choice.php")
					result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", nil, nil, ncfunc)
					if not have_item("rusty hedge trimmers") then
						advagain = true
					end
				else
					result, resulturl, advagain = autoadventure { zoneid = 297, macro = macro_noodlecannon(), noncombatchoices = nil, specialnoncombatfunction = ncfunc, ignorewarnings = true }
				end
				if force_advagain then
					-- TODO: Why is this necessary? No adventure again at great overlook? Do a test for page result instead?
					advagain = true
				end
				return result, resulturl, advagain
			end
		}
	end

	local function want_lvl_9_quest()
		return level() >= 11 and not quest_text("Black Market")
	end

	t.manual_lvl_9_quest = {
		when = quest("There Can Be Only One Topping") and
			ascension_script_option("manual lvl 9 quest"),
		task = {
			message = "do lvl 9 quest manually",
			nobuffing = true,
			action = function()
				stop "STOPPED: Ascension script option set to do lvl 9 quest manually"
			end,
		}
	}

	t.find_way_across_bridge = {
		when = quest("There Can Be Only One Topping") and
			(quest_text("Find a way across") or quest_text("Finish building a bridge across")),
		task = t.do_orc_chasm,
	}

	t.visit_highland_lord = {
		when = quest("There Can Be Only One Topping") and
			want_lvl_9_quest() and
			(quest_text("Speak to the Highland Lord") or quest_text("Go see the Highland Lord")),
		task = {
			message = "visit highland lord",
			action = function()
				get_place("highlands", "highlands_dude")
				refresh_quest()
				did_action = not (quest_text("Speak to the Highland Lord") or quest_text("Go see the Highland Lord"))
			end
		}
	}

	t.light_oil_peak = {
		when = quest("There Can Be Only One Topping") and
			want_lvl_9_quest() and
			quest_text("* Oil Peak"),
		task = t.do_oil_peak,
	}

	t.light_aboo_peak = {
		when = quest("There Can Be Only One Topping") and
			want_lvl_9_quest() and
			quest_text("* A-boo Peak"),
		task = t.do_aboo_peak,
	}

	t.light_twin_peak = {
		when = quest("There Can Be Only One Topping") and
			want_lvl_9_quest() and
			quest_text("* Twin Peak"),
		task = t.do_twin_peak,
	}

	t.tasklist_there_can_be_only_one_topping = {
		t.manual_lvl_9_quest,
		t.find_way_across_bridge,
		t.visit_highland_lord,
		t.light_oil_peak,
		t.light_aboo_peak,
		t.light_twin_peak,
	}

	t.do_daily_dungeon = {
		message = "do daily dungeon",
		buffs = { "Astral Shell", "Elemental Saucesphere", "Scarysauce" },
		equipment = { acc1 = first_wearable { "ring of Detect Boring Doors" } },
		minmp = 20,
		action = function()
			local door_action = "Sneak past it"
			if have_item("Pick-O-Matic lockpicks") then
				door_action = "Use your lockpicks"
			elseif have_item("skeleton key") then
				door_action = "Use a skeleton key"
			end
			if hp() <= maxhp() / 2 then
				script.force_heal_up()
			end
			local advf = adventure {
				zone = "The Daily Dungeon",
				macro_function = macro_noodlecannon,
				noncombats = {
					["It's Almost Certainly a Trap"] = have_item("eleven-foot pole") and "Use your eleven-foot pole" or "Proceed forward cautiously",
					["The First Chest Isn't the Deepest."] = have_equipped_item("ring of Detect Boring Doors") and "Go through the boring door" or "Ignore the chest",
					["I Wanna Be a Door"] = door_action,
					["Second Chest"] = have_equipped_item("ring of Detect Boring Doors") and "Go through the boring door" or "Ignore the chest",
					["The Final Reward"] = "Open it!",
				},
			}
			local pt, pturl, advagain = advf()
			if pt:contains("Daily Done, John.") then
				cached_stuff.done_daily_dungeon = true
				advagain = true
			end
			if have_buff("Beaten Up") and pt:contains("sneak past the door without it noticing you") and have_skill("Shake It Off") then
				script.force_heal_up()
			end
			return pt, pturl, advagain
		end
	}

	function t.get_uv_compass()
		if not have_item("Shore Inc. Ship Trip Scrip") then
			return {
				message = "shore for scrip to buy compass",
				action = script.take_shore_trip,
			}
		else
			return {
				message = "buy UV-resistant compass",
				action = function()
					buy_shore_inc_item("UV-resistant compass")
					did_action = have_item("UV-resistant compass")
				end
			}
		end
	end

	function t.get_tower_item_farming_task(item)
		local towerfarming = {}
		local function shore_item_crate(cratename)
			return {
				f = function()
					if have_item(cratename) then
						return {
							message = "use " .. cratename,
							action = function()
								use_item(cratename)
								did_action = have_item(item)
							end
						}
					elseif have_item("Shore Inc. Ship Trip Scrip") then
						return {
							message = "buy " .. cratename,
							action = function()
								buy_shore_inc_item(cratename)
								did_action = have_item(cratename)
							end
						}
					else
						return {
							message = "shore for " .. cratename,
							action = function()
								local scrip = count_item("Shore Inc. Ship Trip Scrip")
								result, resulturl = script.take_shore_trip()
								did_action = count_item("Shore Inc. Ship Trip Scrip") > scrip
							end
						}
					end
				end
			}
		end
		local function clover_adv(zone)
			if not have_item("ten-leaf clover") and have_item("disassembled clover") then
				use_item("disassembled clover")
			end
			if have_item("ten-leaf clover") then
				return {
					message = "clovering " .. zone,
					action = adventure { zone = zone }
				}
			end
		end
		local function NG_farming()
			return {
				f = function()
					if have_item("lowercase N") and have_item("original G") then
						return {
							message = "crafting NG",
							action = function()
								craft_item("NG")
								did_action = have_item("NG")
							end
						}
					elseif count_item("ten-leaf clover") + count_item("disassembled clover") >= 2 then
						return clover_adv("The Castle in the Clouds in the Sky (Basement)")
					end
				end
			}
		end
		local function clover_zone(z) -- TODO: do as .need_clover = true instead?
			return {
				f = function()
					if count_item("ten-leaf clover") + count_item("disassembled clover") >= 2 then
						return clover_adv(z)
					end
				end
			}
		end

		towerfarming["stick of dynamite"] = shore_item_crate("dude ranch souvenir crate")
		towerfarming["tropical orchid"] = shore_item_crate("tropical island souvenir crate")
		towerfarming["barbed-wire fence"] = shore_item_crate("ski resort souvenir crate")
		towerfarming["frigid ninja stars"] = { zone = "Lair of the Ninja Snowmen" }
		towerfarming["meat vortex"] = { zone = "The Valley of Rof L'm Fao" }
		towerfarming["spider web"] = { zone = "The Sleazy Back Alley", want_combat = true } -- TODO: noncombat choices
		towerfarming["fancy bath salts"] = { zone = "The Haunted Bathroom", want_combat = true } -- TODO: noncombat choices
		towerfarming["razor-sharp can lid"] = { zone = "The Haunted Pantry", want_combat = true } -- TODO: noncombat choices
		towerfarming["NG"] = NG_farming()
		towerfarming["leftovers of indeterminate origin"] = clover_zone("The Haunted Kitchen")
		if estimate_bonus("Item Drops from Monsters") >= 200 then
			towerfarming["sonar-in-a-biscuit"] = { zone = "The Batrat and Ratbat Burrow" }
			towerfarming["disease"] = { zone = "Cobb's Knob Harem" } -- TODO: YR/banish?
			if not have_item("black picnic basket") then
				towerfarming["black pepper"] = { zone = "The Black Forest", want_combat = true } -- TODO: noncombat choices
			end
		end
		if have_item("sonar-in-a-biscuit") then
			towerfarming["baseball"] = clover_zone("Guano Junction")
		end

		local farmdata = towerfarming[item]
		if farmdata then
			if farmdata.f then
				return farmdata.f()
			else
				local bonus_target = { "item", "extraitem" }
				if farmdata.want_combat then
					bonus_target = { "combat", "item", "extraitem" }
				end
				return {
					message = "farm " .. item,
					familiar = "Slimeling",
					buffs = { "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "Empathy" },
					bonus_target = bonus_target,
					minmp = 50,
					action = adventure {
						zone = farmdata.zone,
						macro_function = macro_noodleserpent,
					}
				}
			end
		end
	end

	function t.lady_spookyraven_dance()
		if not have_item("Lady Spookyraven's powder puff") then
			return {
				message = "get Lady Spookyraven's powder puff",
				minmp = 35,
				bonus_target = { "noncombat" },
				action = adventure {
					zone = "The Haunted Bathroom",
					noncombats = { ["Never Gonna Make You Up"] = "Open it" },
					macro_function = macro_noodlecannon,
				}
			}
		elseif not have_item("Lady Spookyraven's finest gown") or (not have_item("Lord Spookyraven's spectacles")) or (not have_item("disposable instant camera")) then
			if not have_item("Lord Spookyraven's spectacles") then
				ornate_option = "Look behind the nightstand"
			elseif not have_item("disposable instant camera") then
				ornate_option = "Look under the nightstand"
			else
				ornate_option = "Open the top drawer"
			end
			return {
				message = "get Lady Spookyraven's finest gown",
				minmp = 35,
				bonus_target = { "noncombat" },
				action = adventure {
					zone = "The Haunted Bedroom",
					noncombats = {
						["One Mahogany Nightstand"] = "Check the top drawer",
						["One Ornate Nightstand"] = ornate_option,
						--["One Rustic Nightstand"] = "Investigate the jewelry",
						["One Rustic Nightstand"] = "Check the top drawer",
						["One Elegant Nightstand"] = "Open the single drawer",
						["One Simple Nightstand"] = "Check the bottom drawer",
					},
					macro_function = macro_noodlecannon,
				}
			}
		elseif not have_item("Lady Spookyraven's dancing shoes") then
			return {
				message = "get Lady Spookyraven's dancing shoes",
				minmp = 35,
				bonus_target = { "noncombat" },
				action = adventure {
					zone = "The Haunted Gallery",
					noncombats = { ["Out in the Garden"] = "None of the above" },
					choice_function = function(advtitle, choicenum, pagetext)
						if advtitle == "Out in the Garden" then
							return "None of the above"
						elseif pagetext:contains("Louvre It or Leave It") then
							return navigate_to_louvre_reward("Lady Spookyraven's dancing shoes", advtitle, choicenum, pagetext)
						end
					end,
					macro_function = macro_noodlecannon,
				}
			}
		else
			stop "TODO: lady spookyraven dance"
		end
	end

	t.get_billiards_room_key = {
		when = script_want_library_key() and
			not have_item("Spookyraven billiards room key"),
		task = {
			message = "get billiards room key",
			familiar = "Exotic Parrot",
			buffs = { "Astral Shell", "Elemental Saucesphere" },
			maybe_buffs = { "Protection from Bad Stuff" },
			minmp = 15,
			action = adventure {
				zone = "The Haunted Kitchen",
				macro_function = macro_noodlecannon,
			}
		},
	}

	t.get_library_key = {
		when = script_want_library_key() and
			not have_item("Spookyraven library key") and
			have_item("Spookyraven billiards room key") and
			drunkenness() <= 12 and drunkenness() >= 4,
		task = {
			message = "get library key",
			familiar = "Slimeling",
			minmp = 25,
			maybe_buffs = { "Chalky Hand" },
			bonus_target = { "noncombat" },
			equipment = { weapon = first_wearable { "pool cue" } },
			action = adventure {
				zone = "The Haunted Billiards Room",
				noncombats = { ["Welcome To Our ool Table"] = "Hustle the ghost" },
				macro_function = macro_noodlecannon,
			}
		},
	}

	t.find_lady_spookyravens_necklace = {
		when = quest_text("find Lady Spookyraven's necklace") and
			have_item("Spookyraven library key"),
		task = {
			message = "find Lady Spookyraven's necklace",
			minmp = 35,
			action = adventure {
				zone = "The Haunted Library",
				noncombats = {
					["Take a Look, it's in a Book!"] = "Reading is for losers.  I'm outta here.",
					["Melvil Dewey Would Be Ashamed"] = "Leave without taking anything",
				},
				macro_function = macro_noodlecannon,
			}
		}
	}

	t.take_necklace_to_lady_spookyraven = {
		when = quest_text("Take the necklace to Lady Spookyraven"),
		task = {
			message = "Take the necklace to Lady Spookyraven",
			nobuffing = true,
			action = function()
				get_place("manor1", "manor1_ladys")
				refresh_quest()
				did_action = not quest_text("Take the necklace to Lady Spookyraven")
			end,
		}
	}

	t.see_lady_spookyraven = {
		when = quest("Lady Spookyraven's Dance") and (quest_text("Go see Lady Spookyraven") or quest_text("Go back to")),
		task = {
			message = "Go see Lady Spookyraven",
			nobuffing = true,
			action = function()
				get_place("manor2", "manor2_ladys")
				refresh_quest()
				did_action = not quest_text("Go see Lady Spookyraven") and not quest_text("Go back to")
			end,
		}
	}

	t.check_hidden_temple = {
		when = not cached_stuff.unlocked_hidden_temple and cached_stuff.currently_checked.checked_hidden_temple_unlock == nil,
		task = {
			message = "check hidden temple",
			nobuffing = true,
			action = function()
				local woodspt = get_page("/woods.php")
				cached_stuff.currently_checked.checked_hidden_temple_unlock = woodspt:contains("The Hidden Temple")
				cached_stuff.unlocked_hidden_temple = cached_stuff.currently_checked.checked_hidden_temple_unlock
				did_action = true
			end
		}
	}

	t.use_spooky_temple_map = {
		when = have_item("Spooky Temple map") and have_item("Spooky-Gro fertilizer") and have_item("spooky sapling"),
		task = {
			message = "use spooky temple map",
			nobuffing = true,
			action = function()
				cached_stuff.currently_checked.checked_hidden_temple_unlock = nil
				set_result(use_item("Spooky Temple map"))
				local newwoodspt = get_page("/woods.php")
				did_action = newwoodspt:contains("The Hidden Temple")
			end
		}
	}

	t.unlock_hidden_temple = {
		when = not cached_stuff.unlocked_hidden_temple,
		task = {
			message = "unlock hidden temple",
			bonus_target = { "noncombat" },
			action = function()
				if script_want_2_day_SCHR() then
					if zone_awaiting_florist_decision("The Spooky Forest") then
						plant_florist_plants { 1, 10, 9 }
					end
				end
				if have_item("Spooky Temple map") and have_item("Spooky-Gro fertilizer") and have_item("spooky sapling") then
					inform "use spooky temple map"
					set_result(use_item("Spooky Temple map"))
					local newwoodspt = get_page("/woods.php")
					did_action = newwoodspt:contains("The Hidden Temple")
				else
					if meat() < 100 then
						stop "Not enough meat for spooky sapling."
					end
					script.go("get parts to unlock hidden temple", "The Spooky Forest", macro_kill_monster, {}, {}, "auto", 10, { choice_function = spooky_forest_choice_function })
				end
			end
		}
	}

	t.unlock_pyramid = {
		when = quest_text("the Quest for the Holy MacGuffin") and have_item("Staff of Ed") and not quest("A Pyramid Scheme"),
		task = {
			message = "Use Staff of Ed",
			nobuffing = true,
			action = function()
				get_place("desertbeach", "db_pyramid1")
				refresh_quest()
				did_action = quest("A Pyramid Scheme")
			end,
		}
	}

	t.a_pyramid_scheme = {
		when = quest("A Pyramid Scheme"),
		task = function()
			if quest_text("Make your way into the depths") then
				return {
					message = "unlock middle chamber",
					bonus_target = { "noncombat", "extranoncombat" },
					buffs = { "Spirit of Garlic" },
					minmp = 45,
					action = adventure {
						zone = "The Upper Chamber",
						macro_function = macro_noodleserpent,
					},
					after_action = function()
						if get_result():contains(">Down Dooby-Doo Down Down<") then
							did_action = true
						end
					end,
				}
			elseif quest_text("Explore the Middle Chamber") or quest_text("Keep exploring the Middle Chamber") then
				return {
					message = "explore middle chamber",
					bonus_target = { "item", "noncombat" },
					familiar = "Slimeling",
					buffs = { "Spirit of Garlic" },
					minmp = 45,
					action = adventure {
						zone = "The Middle Chamber",
						macro_function = macro_noodleserpent,
					},
					after_action = function()
						if get_result():contains(">Further Down Dooby-Doo Down Down<") or get_result():contains(">Under Control<") then
							did_action = true
						end
					end,
				}
			elseif quest_text("Solve the mystery of the Lower Chambers") then
				local pyramidpt = get_place("pyramid")
				if pyramidpt:contains("action=pyramid_state1a") then
					if script.semirare_within_N_turns(7) then return end
					local minmp = 100
					if maxmp() >= 200 then
						minmp = 150
					end
					return {
						message = "fight ed",
						buffs = { "Spirit of Garlic", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds" },
						maybe_buffs = { "Mental A-cue-ity" },
						minmp = minmp,
						familiar = "Frumious Bandersnatch",
						bonus_target = { "easy combat" },
						action = function()
							result, resulturl = get_place("pyramid", "pyramid_state1a")
							result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(5), { ["Ed the Undrowning"] = "If you say so..." })
							while get_result():contains([[<!--WINWINWIN-->]]) and get_result():contains([[fight.php]]) do
								result, resulturl = get_page("/fight.php")
								result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(5))
							end
							did_action = have_item("Holy MacGuffin")
						end
					}
				end
				local function pyramidstate(assumed_position)
					local turns_required = 0
					local first_action = nil
					local function turn_to(where)
						while assumed_position ~= where do
							first_action = first_action or "turn"
							turns_required = turns_required + 1
							assumed_position = (assumed_position % 5) + 1
						end
					end
					local function head_down()
						first_action = first_action or "head down"
					end
					if not have_item("ancient bomb") then
						if not have_item("ancient bronze token") then
							turn_to(4)
							head_down()
						end
						turn_to(3)
						head_down()
					end
					turn_to(1)
					head_down()
					return turns_required, first_action
				end
				local current_position = tonumber(pyramidpt:match("action=pyramid_state([1-5])"))
				local turns_required, first_action = pyramidstate(current_position)
				if count_item("tomb ratchet") + count_item("crumbling wooden wheel") < turns_required then
					local need = turns_required - count_item("tomb ratchet") - count_item("crumbling wooden wheel")
					return {
						message = "get " .. need .. " crumbling wooden wheels",
						bonus_target = { "noncombat", "extranoncombat" },
						buffs = { "Spirit of Garlic" },
						minmp = 45,
						action = adventure {
							zone = "The Upper Chamber",
							macro_function = macro_noodleserpent,
						},
					}
				else
					return {
						message = "using pyramid control room",
						nobuffing = true,
						action = function()
							get_place("pyramid", "pyramid_control")
							if first_action == "turn" then
								if have_item("crumbling wooden wheel") then
									post_page("/choice.php", { pwd = session.pwd, whichchoice = 929, option = 1 }) -- use wheel
								else
									post_page("/choice.php", { pwd = session.pwd, whichchoice = 929, option = 2 }) -- use ratchet
								end
							elseif first_action == "head down" then
								post_page("/choice.php", { pwd = session.pwd, whichchoice = 929, option = 5 }) -- head down
							end
							local new_pyramidpt = get_place("pyramid")
							if new_pyramidpt:contains("action=pyramid_state1a") then
								did_action = true
							else
								local new_assumed_position = tonumber(new_pyramidpt:match("action=pyramid_state([1-5])"))
								local new_turns_required, new_first_action = pyramidstate(new_assumed_position)
								did_action = new_turns_required ~= turns_required or new_first_action ~= first_action
							end
						end,
					}
				end
			else
				critical "Unknown state while doing pyramid"
			end
		end,
	}

	t.tasklist_pyramid_quest = { t.unlock_pyramid, t.a_pyramid_scheme }

	local function want_skill(skills)
		for _, x in ipairs(skills) do
			if not have_skill(x) then
				return x
			end
		end
	end

	local function heavyrains_make_train_skill_task(item, skills)
		local skill = want_skill(skills)
		return {
			when = not ascension_script_option("train skills manually") and have_item(item) and skill,
			task = {
				message = "train skill " .. tostring(skill),
				nobuffing = true,
				action = function()
					did_action = heavyrains_train_skill(item, skill)
				end,
			}
		}
	end

	if script_want_2_day_SCHR() then
		t.tasklist_heavyrains_train_skills = {
			heavyrains_make_train_skill_task("thunder thigh", { "Thunder Clap", "Thunderheart", "Thunderstrike", "Thunder Thighs" }),
			heavyrains_make_train_skill_task("aquaconda brain", { "Rain Man", "Rain Delay" }),
			heavyrains_make_train_skill_task("lightning milk", { "Ball Lightning", "Lightning Strike", "Riding the Lightning" }),
		}
	else
		t.tasklist_heavyrains_train_skills = {
			heavyrains_make_train_skill_task("thunder thigh", { "Thunderheart", "Thunderstrike", "Thunder Clap", "Thunder Thighs" }),
			heavyrains_make_train_skill_task("aquaconda brain", { "Rain Man", "Rain Delay", "Rain Dance" }),
			heavyrains_make_train_skill_task("lightning milk", { "Sheet Lightning", "Lightning Strike", "Riding the Lightning" }),
		}
	end

	tasks.ns_lair_investigate_contest = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and (quest_text("investigate the weird contest") or quest_text("not yet entered")),
		task = {
			message = "sign up for NS lair contest",
			nobuffing = true,
			action = function()
				result, resulturl = get_place("nstower", "ns_01_contestbooth")
				local options = parse_choice_options(result)
				if options["Enter the Fastest Adventurer contest"] then
					--...maximize init...
				elseif options["Enter the Smoothest Adventurer contest"] then
					--...maximize moxie...
				elseif options["Enter the Stinkiest Adventurer contest"] then
					--...maximixe stinky...
				end
				print("DEBUG ns contest", tostring(options))
				did_action = false
			end,
		}
	}

	tasks.ns_lair_defeat_other_entrants = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and quest_text("Defeat the other entrants"),
		task = {
			message = "defeat other NS lair contestants",
			action = function()
				result, resulturl = get_place("nstower")
				for i = 1, 3 do
					if result:contains("ns_01_crowd" .. i) then
						result, resulturl = get_page("/place.php", { whichplace = "nstower", action = "ns_01_crowd" .. i })
						result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_kill_monster)
						if result:contains([[>You win the fight!<!--WINWINWIN--><]]) then
							did_action = true
						end
						return
					end
				end
			end,
		}
	}

	tasks.ns_lair_finish_contest = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and quest_text("talk to the contest official"),
		task = {
			message = "finish NS lair contest",
			nobuffing = true,
			action = function()
				result, resulturl = get_place("nstower", "ns_01_contestbooth")
				result, resulturl, advagain = handle_adventure_result(result, resulturl, "?")
				refresh_quest()
				did_action = quest_text("Attend your coronation in the courtyard")
			end,
		}
	}

	tasks.ns_lair_attend_coronation = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and quest_text("Attend your coronation in the courtyard"),
		task = {
			message = "attend NS lair coronation",
			nobuffing = true,
			action = function()
				result, resulturl = get_place("nstower", "ns_02_coronation")
				result, resulturl, advagain = handle_adventure_result(result, resulturl, "?")
				refresh_quest()
				did_action = not quest_text("Attend your coronation in the courtyard")
			end,
		}
	}

	tasks.ns_lair_navigate_hedge_maze = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and quest_text("Make your way through the treacherous hedge maze"),
		task = {
			message = "navigate NS hedge maze",
			action = function()
				result, resulturl = get_place("nstower", "ns_03_hedgemaze")
				result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_kill_monster, nil, function(advtitle, choicenum, pagetext)
					print("DEBUG advtitle choicenum", advtitle, choicenum)
					return "", 1
				end)
				refresh_quest()
				did_action = not quest_text("Make your way through the treacherous hedge maze")
			end,
		}
	}

	tasks.ns_lair_door = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and quest_text("Get through the door at the base"),
		task = {
			message = "pass NS lair door",
			nobuffing = true,
			action = function()
				result, resulturl = get_place("nstower_door")
				local buy_keys = {
					ns_lock1 = "Boris's key",
					ns_lock2 = "Jarlsberg's key",
					ns_lock3 = "Sneaky Pete's key",
				}
				for _, lock in ipairs { "ns_lock1", "ns_lock2", "ns_lock3", "ns_lock4", "ns_lock5", "ns_lock6" } do
					if result:contains(lock) then
						local function try_lock()
							result, resulturl = get_place("nstower_door", lock)
							local pt = get_place("nstower_door")
							return not pt:contains(lock)
						end
						did_action = try_lock()
						if not did_action and buy_keys[lock] then
							buy_item(buy_keys[lock])
							did_action = try_lock()
						end
						return
					end
				end
				result, resulturl = get_place("nstower_door", "ns_doorknob")
				refresh_quest()
				did_action = not quest_text("Get through the door at the base")
			end,
		}
	}

	local tower_page = nil
	local function at_tower_level(idx)
		if not tower_page then
			tower_page = get_place("nstower")
		end
		return tower_page:contains("Tower Level " .. idx)
	end

	tasks.ns_lair_wall_of_skin = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and quest_text("Ascend the <") and at_tower_level(1),
		task = {
			message = "pass wall of skin",
			action = function()
				script.want_familiar("Warbear Drone")
				script.wear {
					offhand = first_wearable { "hot plate" },
					familiarequip = first_wearable { "ant hoe", "ant pick", "ant pitchfork", "ant rake", "ant sickle" },
					acc1 = first_wearable { "hippy protest button" },
					acc2 = first_wearable { "bottle opener belt buckle" },
				}
				script.maybe_ensure_buffs { "Spiky Shell", "Jalape&ntilde;o Saucesphere", "Scarysauce", "Psalm of Pointiness" }
				script.ensure_mp(80)
				script.heal_up()
				result, resulturl = get_place("nstower")
				stop("TODO: kill wall of skin", result)
			end,
		}
	}

	tasks.ns_lair_wall_of_meat = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and (quest_text("Ascend the <") or quest_text("Defeat the wall of meat")) and at_tower_level(2),
		task = {
			message = "pass wall of meat",
			action = function()
				script.want_familiar("leprechaun")
				script.wear {}
				script.ensure_buffs { "Polka of Plenty", "Disco Leer" }
				script.ensure_mp(120)
				script.heal_up()
				result, resulturl = get_place("nstower", "ns_06_monster2")
				result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", macro_kill_monster)
				did_action = advagain
			end,
		}
	}

	tasks.ns_lair_wall_of_bones = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and
			(quest_text("Ascend the <") or quest_text("Defeat the wall of bones")) and
			at_tower_level(3) and
			have_item("electric boning knife"),
		task = {
			message = "pass wall of bones",
			action = function()
				result, resulturl = get_place("nstower", "ns_07_monster3")
				result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", [[use electric boning knife]])
				did_action = advagain
			end,
		}
	}

	tasks.ns_lair_get_boning_knife = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and
			(quest_text("Ascend the <") or quest_text("Defeat the wall of bones")) and
			at_tower_level(3) and
			not have_item("electric boning knife"),
		task = {
			message = "get electric boning knife",
			bonus_target = { "noncombat", "item" },
			action = adventure {
				zone = "The Castle in the Clouds in the Sky (Ground Floor)",
				macro_function = macro_kill_monster,
				noncombats = {
					["There's No Ability Like Possibility"] = "Go out the Way You Came In",
					["Putting Off Is Off-Putting"] = "Get out of this Junk",
					["Huzzah!"] = "Seek the Egress Anon",
					["Home on the Free Range"] = "Investigate the noisy drawer",
				}
			}
		}
	}

	tasks.ns_lair_tower_mirror = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and quest_text("Continue climbing") and at_tower_level(4),
		task = {
			message = "look in tower mirror",
			action = function()
				result, resulturl = get_place("nstower", "ns_08_monster4")
				result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", nil, {
					["The Mirror in the Tower has the View that is True"] = "Gaze into the mirror...",
				})
				did_action = have_intrinsic("Confidence!")
			end,
		}
	}

	tasks.ns_lair_defeat_shadow = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and
			(quest_text("Continue your ascent") or quest_text("Defeat your shadow")) and
			at_tower_level(5),
		task = {
			message = "defeat your shadow",
			action = function()
				script.bonus_target { "easy combat" }
				set_mcd(0)
				script.want_familiar("Frumious Bandersnatch")
				script.ensure_buffs { "Go Get 'Em, Tiger!" }
				script.wear { hat = first_wearable { "double-ice cap" } }
				local use_garter = "use gauze garter"
				if have_skill("Ambidextrous Funkslinging") and count_item("gauze garter") >= 8 then
					script.heal_up()
					use_garter = "use gauze garter, gauze garter"
				elseif count_item("gauze garter") >= 8 and (have_item("Rain-Doh indigo cup") or have_item("double-ice cap")) then
					if maxhp() < 300 then
						script.wear { hat = first_wearable { "double-ice cap" }, acc1 = first_wearable { "bejeweled pledge pin" }, acc2 = first_wearable { "plastic vampire fangs" }, acc1 = first_wearable { "sphygmomanometer" } }
					end
					if maxhp() < 300 then
						script.maybe_ensure_buffs { "Standard Issue Bravery", "Starry-Eyed", "Puddingskin" }
					end
					script.force_heal_up()
					if hp() < 300 and not have_equipped_item("double-ice cap") then
						stop "Kill your shadow"
					end
				else
					stop "Kill your shadow"
				end
				result, resulturl = get_place("nstower", "ns_09_monster5")
				result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", [[
]] .. COMMON_MACROSTUFF_START(20, 5) .. [[


]] .. use_garter .. [[


if hasskill Saucy Salve
	cast Saucy Salve
endif


]] .. use_garter .. [[


if hascombatitem Rain-Doh indigo cup
	use Rain-Doh indigo cup
endif


]] .. use_garter .. [[


]] .. use_garter .. [[


]] .. use_garter .. [[


]])
				if not locked() then
					refresh_quest()
					did_action = not (quest_text("Continue your ascent") and at_tower_level(5))
				end
			end,
		}
	}

	tasks.ns_lair_confront_ns = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and quest_text("Confront the ") and quest_text("Naughty Sorceress"),
		task = {
			message = "confront the naughty sorceress",
			action = function()
				script.bonus_target { "easy combat" }
				set_mcd(0)
				script.want_familiar("Frumious Bandersnatch")
				script.ensure_buffs { "Go Get 'Em, Tiger!" }
				result, resulturl = get_place("nstower")
				if ascensionpath("Actually Ed the Undying") then
					result, resulturl = get_place("nstower", "ns_10_sorcfight")
					result, resulturl, did_action = handle_adventure_result(result, resulturl, "?", macro_kill_monster)
					return
				end
				stop("TODO: kill NS", result)
				did_action = false
			end,
		}
	}

	tasks.ns_lair_free_king = {
		when = quest("The Ultimate Final Epic Conflict of the Ages") and quest_text("Free King Ralph from his prism"),
		task = {
			message = "free king ralph",
			action = function()
				set_result(get_place("nstower"))
				result = add_message_to_page(get_result(), "<p>Finished, free the king!</p>", "Ascension script:")
				result_status.finished()
			end,
		}
	}

	tasks.tasklist_ns_lair = {
		tasks.ns_lair_investigate_contest,
		tasks.ns_lair_defeat_other_entrants,
		tasks.ns_lair_finish_contest,
		tasks.ns_lair_attend_coronation,
		tasks.ns_lair_navigate_hedge_maze,
		tasks.ns_lair_door,
		tasks.ns_lair_wall_of_skin,
		tasks.ns_lair_wall_of_meat,
		tasks.ns_lair_wall_of_bones,
		tasks.ns_lair_get_boning_knife,
		tasks.ns_lair_tower_mirror,
		tasks.ns_lair_defeat_shadow,
		tasks.ns_lair_confront_ns,
		tasks.ns_lair_free_king,
	}

	local ka_skills = {
		"Extra Spleen",
		"Another Extra Spleen",
		"Yet Another Extra Spleen",
		"Replacement Liver",
		"Replacement Stomach",
		"Still Another Extra Spleen",
		"Just One More Extra Spleen",
		"Okay Seriously, This is the Last Spleen",
		"Upgraded Legs",
		"More Legs",
		"Elemental Wards",
		"More Elemental Wards",
	}

	local function want_ka_skill()
		if ascension_script_option("train skills manually") then return end
		for _, skill in ipairs(ka_skills) do
			if not have_skill(skill) then
				return skill
			end
		end
	end

	local function cache_wrapper(f)
		cached_stuff.cache_wrapper = cached_stuff.cache_wrapper or {}
		local key = debug.callsitedesc()
		if cached_stuff.cache_wrapper[key] == nil then
			cached_stuff.cache_wrapper[key] = f()
		end
		return cached_stuff.cache_wrapper[key]
	end

	local function parse_ed_skills_page(pt)
		local skills = {}
		for tr in pt:gmatch("<tr.-</tr>") do
			local name = tr:match([[<td class="skp"><b>(.-)</b></td>]])
			local pwd = tr:match([[name="pwd" value="(.-)"]])
			local skillid = tonumber(tr:match([[name="skillid" value="(.-)"]]))
			local option = tonumber(tr:match([[name="option" value="(.-)"]]))
			local whichchoice = tonumber(tr:match([[name="whichchoice" value="(.-)"]]))
			if name then
				skills[name] = { pwd = pwd, skillid = skillid, option = option, whichchoice = whichchoice }
			end
		end
		return skills
	end

	local ed_skills = {
		"Fist of the Mummy",
		"Prayer of Seshat",
		"Wisdom of Thoth",
		"Power of Heka",
		"Hide of Sobek",
		"Blessing of Serqet",
		"Shelter of Shed",
		"Bounty of Renenutet",
		"Howl of the Jackal",
		"Roar of the Lion",
		"Storm of the Scarab",
		"Purr of the Feline",
		"Lash of the Cobra",
		"Wrath of Ra",
		"Curse of the Marshmallow",
		"Curse of Indecision",
		"Curse of Yuck",
		"Curse of Heredity",
		"Curse of Fortune",
		"Curse of Vacation",
		"Curse of Stench",
	}

	local function get_ed_skill(whichplace, action, want_skills)
		local pt = get_page("/place.php", { whichplace = whichplace, action = action })
		local skilldata = parse_ed_skills_page(pt)
		local learned = nil
		for _, skill in ipairs(want_skills) do
			if not have_skill(skill) then
				print("INFO: getting skill: " .. skill)
				if not skilldata[skill] then
					result = pt
					critical("Could not get skill: " .. skill)
				end
				set_result(post_page("/choice.php", skilldata[skill]))
				learned = skill
				break
			end
		end
		if locked() == "choice" then
			local pt, pturl = get_page("/choice.php")
			handle_adventure_result(pt, pturl, "?", nil, { ["Underworld Body Shop"] = "Back to the Underworld" })
		end
		return learned
	end

	tasks.ed_memorize_page = {
		when = can_memorize_page() and not ascension_script_option("train skills manually"),
		task = {
			message = "memorize page",
			nobuffing = true,
			action = function()
				did_action = get_ed_skill("edbase", "edbase_book", ed_skills)
			end
		}
	}

	tasks.ed_release_servant = {
		when = can_release_servant,
		task = {
			message = "release servant",
			nobuffing = true,
			action = function()
				result, resulturl = get_place("edbase", "edbase_door")
				for _, sid in ipairs { 6, 1, 2, 3 } do
					result, resulturl = post_page("/choice.php", { whichchoice = 1053, option = 3, pwd = session.pwd, sid = sid })
					if not can_release_servant() and not result:contains("That servant already works for you") then
						did_action = true
						return
					end
				end
				stop("TODO: release servant", result)
			end
		}
	}

	local function go_to_underworld()
		local zone = "A Maze of Sewer Tunnels"
		if cache_wrapper(have_conspiracy_island) then
			zone = "The Secret Government Laboratory"
		elseif cache_wrapper(have_dinseylandfill) then
			zone = "Pirates of the Garbage Barges"
		end
		return (adventure {
			zone = zone,
			macro_function = [[
cast Mild Curse
repeat
]],
			noncombats = { ["Like a Bat Into Hell"] = "Enter Underworld" },
		})()
	end

	local function return_from_underworld()
		used_undying()
		local pt, pturl = get_place("edunder", "edunder_leave")
		result, resulturl, did_action = handle_adventure_result(pt, pturl, "?", macro_kill_monster, { ["Like a Bat out of Hell"] = "Return to the fight!" })
	end

	local function want_beef_haunch()
		if ascension_script_option("eat manually") then return end
		return not have_item("mummified beef haunch") and spleen() + 5 <= estimate_max_spleen()
	end

	tasks.ed_buy_beef_haunch = {
		when = want_beef_haunch() and count_item("Ka coin") >= 20,
		task = {
			message = "buy mummified beef haunch",
			minmp = 10,
			equipment = { acc1 = first_wearable { "Personal Ventilation Unit" } },
			action = function()
				go_to_underworld()
				buy_item("mummified beef haunch")()
				buy_item("talisman of Renenutet")()
				buy_item("talisman of Renenutet")()
				buy_item("talisman of Renenutet")()
				if count_item("linen bandages") < 5 then
					buy_item("linen bandages")()
				end
				if count_item("talisman of Horus") < 3 and count_item("Ka coin") >= 25 then
					buy_item("talisman of Horus")()
				end
				if count_item("linen bandages") < 25 and count_item("Ka coin") >= 50 then
					buy_item("linen bandages")()
					buy_item("linen bandages")()
					buy_item("linen bandages")()
					buy_item("linen bandages")()
					buy_item("linen bandages")()
				end
				if not have_item("mummified beef haunch") then
					critical "Failed to buy mummified beef haunch"
				end
				return_from_underworld()
			end
		},
	}

	tasks.ed_buy_skill = {
		when = want_ka_skill() and count_item("Ka coin") >= 30,
		task = {
			message = "buy body augmentation",
			minmp = 10,
			equipment = { acc1 = first_wearable { "Personal Ventilation Unit" } },
			action = function()
				go_to_underworld()
				learned = get_ed_skill("edunder", "edunder_bodyshop", ka_skills)
				if not learned then
					critical "Failed to buy body augmentation!"
				end
				return_from_underworld()
				clear_cached_skills()
				reset_pageload_cache()
				did_action = have_skill(learned)
				print("DEBUG learned", learned, have_skill(learned))
			end
		},
	}

	local function want_ka()
		if want_ka_skill() and count_item("Ka coin") < 30 then
			return true
		elseif want_beef_haunch() and count_item("Ka coin") < 20 and advs() < 30 then
			return true
		end
	end

	tasks.ed_farm_ka_at_government_lab = {
		when = want_ka() and have_skill("Fist of the Mummy") and cache_wrapper(have_conspiracy_island),
		task = function()
			if zone_awaiting_florist_decision("The Secret Government Laboratory") then
				plant_florist_plants { 20, 11, 15 }
			end
			return {
				message = "farm ka at government lab",
				minmp = 10,
				equipment = { acc1 = first_wearable { "Personal Ventilation Unit" } },
				action = adventure {
					zone = "The Secret Government Laboratory",
					macro_function = macro_kill_monster,
				}
			}
		end,
	}

	tasks.ed_farm_ka_at_government_lab = {
		when = want_ka() and
			have_skill("Fist of the Mummy") and
			not cache_wrapper(have_conspiracy_island) and
			cache_wrapper(have_dinseylandfill),
		task = function()
			if zone_awaiting_florist_decision("Pirates of the Garbage Barges") then
				plant_florist_plants { 20, 11, 15 }
			end
			return {
				message = "farm ka at garbage barges",
				minmp = 10,
				action = adventure {
					zone = "Pirates of the Garbage Barges",
					macro_function = macro_kill_monster,
				}
			}
		end,
	}

	tasks.ed_use_map_page = {
		when = quest_text("Search for the MacGuffin in the Warehouse") and
			not have_item("Holy MacGuffin") and
			have_item("warehouse map page") and
			have_item("warehouse inventory page"),
		task = maketask_use_item("warehouse map page"),
	}

	tasks.ed_search_warehouse = {
		when = quest_text("Search for the MacGuffin in the Warehouse") and
			not have_item("Holy MacGuffin"),
		task = {
			message = "search for macguffin",
			minmp = 35,
			action = adventure {
				zone = "The Secret Council Warehouse",
				macro_function = macro_kill_monster,
			}
		},
	}

	tasks.tasklist_actually_ed_the_undying = {
		tasks.ed_memorize_page,
		tasks.ed_release_servant,
		tasks.ed_buy_beef_haunch,
		tasks.ed_buy_skill,
		tasks.ed_farm_ka_at_government_lab,
		tasks.ed_use_map_page,
		tasks.ed_search_warehouse,
	}

	return t
end

function maketask_use_item(item)
	return {
		message = "use item: " .. tostring(item),
		nobuffing = true,
		action = function()
			local c = count_item(item)
			use_item(item)()
			did_action = count_item(item) == c - 1
		end
	}
end

function heavyrains_train_skill(item, skill)
	result, resulturl = use_item(item)()
	result, resulturl = get_page("/choice.php", { forceoption = 0 })
	result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", nil, {
		["The Thunder Rolls..."] = skill,
		["The Rain Falls Down With Your Help..."] = skill,
		["And The Lightning Strikes..."] = skill,
	})
	get_page("/main.php")
	return have_skill(skill)
end
