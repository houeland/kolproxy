__allow_global_writes = true

function get_automation_tasks(script, cached_stuff)
	local t = {}
	local task = t

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
			if moonsign_area("Degrassi Knoll") and want_smith_weapons[playerclassname()] then
				local want_items = { want_smith_weapons[playerclassname()], "A Light that Never Goes Out", "Hairpiece On Fire" }
				if ascensionstatus("Hardcore") then table.insert(want_items, "Vicar's Tutu") end
				for _, x in ipairs(want_items) do
					if not have_item(x) then
						if not have_item("lump of Brituminous coal") then
							script.ensure_mp(2)
							cast_skill("Summon Smithsness")()
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

			if playerclass("Accordion Thief") and AT_song_duration() < 10 then
				inform "pick up RnR"
				script.ensure_worthless_item()
				if not have_item("hermit permit") then
					store_buy_item("hermit permit", "m")
				end
				if not have_item("hot buttered roll") then
					async_post_page("/hermit.php", { action = "trade", whichitem = get_itemid("hot buttered roll"), quantity = 1 })
				end
				if not have_item("hot buttered roll") then
					critical "Failed to buy hot buttered roll."
				end
				if not have_item("casino pass") then
					store_buy_item("casino pass", "m")
				end
				if not have_item("casino pass") then
					critical "Failed to buy casino pass."
				end
				if not have_item("big rock") then
					if not have_item("ten-leaf clover") then
						uncloset_item("ten-leaf clover")
					end
					if not have_item("ten-leaf clover") and not have_item("disassembled clover") then
						script.trade_for_clover()
					end
					if not have_item("ten-leaf clover") and have_item("disassembled clover") then
						use_item("disassembled clover")
					end
					if not have_item("ten-leaf clover") then
						stop "No ten-leaf clover."
					end
					script.maybe_ensure_buffs { "Mental A-cue-ity" }
					async_get_page("/casino.php", { action = "slot", whichslot = 11 })
					if not have_item("big rock") then
						critical "Didn't get big rock."
					end
				end
				set_result(smith_items("hot buttered roll", "big rock"))
				script.unequip_if_worn("stolen accordion")
				set_result(smith_items("heart of rock and roll", "stolen accordion"))
				if not have_item("Rock and Roll Legend") then
					critical "Couldn't smith RnR"
				end
				did_action = have_item("Rock and Roll Legend")
				return result, resulturl, did_action
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
		local pt, pturl = get_page("/place.php", { whichplace = "orc_chasm" })
		local pieces = tonumber(pt:match("action=bridge([0-9]*)"))
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
			elseif ascensionstatus("Softcore") then
				return {
					message = "pull keepsake box",
					nobuffing = true,
					action = function()
						pull_in_softcore("smut orc keepsake box")
						did_action = have_item("smut orc keepsake box")
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
					pt = get_page("/place.php", { whichplace = "orc_chasm" })
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
				local ml = estimate_bonus("Monster Level")
				if ml < 50 then
					script.maybe_ensure_buffs { "Pride of the Puffin" }
					ml = estimate_bonus("Monster Level")
				end
				if ml < 20 then
					stop "Not enough +ML for Oil Peak (want 20+ for automation)"
				elseif not ascensionstatus("Hardcore") and ml < 50 and ascensionpathid() == 0 then
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
			if not have_buff("Super Structure") and have_item("Greatest American Pants") then
				script.wear { pants = "Greatest American Pants" }
				script.get_gap_buff("Super Structure")
			end
			if not have_buff("Well-Oiled") and have_item("Oil of Parrrlay") then
				use_item("Oil of Parrrlay")
			end
			script.ensure_buffs { "Go Get 'Em, Tiger!", "Red Door Syndrome", "Astral Shell", "Elemental Saucesphere", "Scarysauce" }
			script.force_heal_up()
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
				script.force_heal_up()
			end
			if predict_aboo_peak_banish() < 30 then
				script.maybe_ensure_buffs { "Oiled-Up", "Standard Issue Bravery", "Starry-Eyed", "Puddingskin", "Protection from Bad Stuff", "Truly Gritty" }
				script.force_heal_up()
			end
			if predict_aboo_peak_banish() < 30 and have_skill("Check Mirror") and not have_intrinsic("Slicked-Back Do") then
				cast_check_mirror_for_intrinsic("Slicked-Back Do")
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
					if get_resistance_level("Stench") < 4 and not have_buff("Red Door Syndrome") then
						script.ensure_buffs { "Red Door Syndrome" }
					end
					if get_resistance_level("Stench") < 4 then
						script.want_familiar "Exotic Parrot"
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
						stop "Need 50%+ item drops from monsters"
					end
				elseif cached_stuff.previous_twin_peak_noncombat_option == "Search the pantry" then
					if not have_item("jar of oil") then
						use_item("bubblin' crude", 12)
					end
					if not have_item("jar of oil") then
						stop "Need jar of oil"
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
								return x
							end
						end
					else
						return "", 1
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

	function t.there_can_be_only_one_topping()
		if ascension_script_option("manual lvl 9 quest") then
			stop "STOPPED: Ascension script option set to do lvl 9 quest manually"
		end
		if quest_text("Find a way across") or quest_text("Finish building a bridge across") then
			return t.do_orc_chasm()
		elseif quest_text("Speak to the Highland Lord") or quest_text("Go see the Highland Lord") then
			return {
				message = "visit highland lord",
				action = function()
					get_page("/place.php", { whichplace = "highlands", action = "highlands_dude" })
					refresh_quest()
					did_action = not (quest_text("Speak to the Highland Lord") or quest_text("Go see the Highland Lord"))
				end
			}
		elseif quest_text("* Oil Peak") then
			return t.do_oil_peak()
		elseif quest_text("* A-boo Peak") then
			return t.do_aboo_peak()
		elseif quest_text("* Twin Peak") then
			return t.do_twin_peak()
		else
			stop "TODO: handle only one topping quest"
		end
	end

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
		when = not have_item("Spookyraven billiards room key"),
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
		when = not have_item("Spookyraven library key") and
			have_item("Spookyraven billiards room key") and
			drunkenness() <= 11 and drunkenness() >= 7,
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
				get_page("/place.php", { whichplace = "manor1", action = "manor1_ladys" })
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
				get_page("/place.php", { whichplace = "manor2", action = "manor2_ladys" })
				refresh_quest()
				did_action = not quest_text("Go see Lady Spookyraven") and not quest_text("Go back to")
			end,
		}
	}

	t.unlock_pyramid = {
		when = quest_text("the Quest for the Holy MacGuffin") and have_item("Staff of Ed") and not quest("A Pyramid Scheme"),
		task = {
			message = "Use Staff of Ed",
			nobuffing = true,
			action = function()
				get_page("/place.php", { whichplace = "desertbeach", action = "db_pyramid1" })
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
				local pyramidpt = get_page("/place.php", { whichplace = "pyramid" })
				if pyramidpt:contains("action=pyramid_state1a") then
					if turns_to_next_sr < 7 then return end
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
						action = function()
							result, resulturl = get_page("/place.php", { whichplace = "pyramid", action = "pyramid_state1a" })
							result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(5))
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
							get_page("/place.php", { whichplace = "pyramid", action = "pyramid_control" })
							if first_action == "turn" then
								if have_item("crumbling wooden wheel") then
									post_page("/choice.php", { pwd = session.pwd, whichchoice = 929, option = 1 }) -- use wheel
								else
									post_page("/choice.php", { pwd = session.pwd, whichchoice = 929, option = 2 }) -- use ratchet
								end
							elseif first_action == "head down" then
								post_page("/choice.php", { pwd = session.pwd, whichchoice = 929, option = 5 }) -- head down
							end
							local new_pyramidpt = get_page("/place.php", { whichplace = "pyramid" })
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
