__allow_global_writes = true

function get_automation_tasks(script, cached_stuff)
	local t = {}
	local task = t

	t.summon_clip_art = {
		nobuffing = true,
		action = function()
			inform "using clip art tome summons"

			if not have_item("shining halo") then
				script.ensure_mp(2)
				async_post_page("/campground.php", { preaction = "summoncliparts" })
				async_post_page("/campground.php", { pwd = get_pwd(), action = "bookshelf", preaction = "combinecliparts", clip1 = "01", clip2 = "06", clip3 = "06" })
			end
			if not have_item("Ur-Donut") then
				script.ensure_mp(2)
				async_post_page("/campground.php", { preaction = "summoncliparts" })
				async_post_page("/campground.php", { pwd = get_pwd(), action = "bookshelf", preaction = "combinecliparts", clip1 = "01", clip2 = "01", clip3 = "01" })
			end
			if not have_item("bucket of wine") then
				script.ensure_mp(2)
				async_post_page("/campground.php", { preaction = "summoncliparts" })
				async_post_page("/campground.php", { pwd = get_pwd(), action = "bookshelf", preaction = "combinecliparts", clip1 = "04", clip2 = "04", clip3 = "04" })
			end

			if not have_item("shining halo") or not have_item("Ur-Donut") or not have_item("bucket of wine") then
				print(have("shining halo"), have_item("Ur-Donut"), have_item("bucket of wine"))
				critical "Error getting clip art items"
			end

			eat_item("Ur-Donut")
			if level() >= 2 then
				did_action = true
			end
		end
	}

	-- TODO: split into 3 tasks
	t.get_starting_items = {
		message = "get starting items",
		nobuffing = true,
		action = function()
			if not (have_item("stolen accordion") and have_item("turtle totem") and have_item("saucepan")) then
				local pt, pturl, advagain
				while not (have_item("stolen accordion") and have_item("turtle totem") and have_item("saucepan")) do
					pt, pturl, advagain = script.buy_use_chewing_gum()
					if not advagain then
						critical "Failed to use chewing gum"
					end
				end
				return pt, pturl
			end

			if playerclass("Accordion Thief") and (AT_song_duration() or 0) < 10 then
				inform "pick up RnR"
				script.ensure_worthless_item()
				if not have_item("hermit permit") then
					buy_item("hermit permit", "m")
				end
				if not have_item("hot buttered roll") then
					async_post_page("/hermit.php", { action = "trade", whichitem = get_itemid("hot buttered roll"), quantity = 1 })
				end
				if not have_item("hot buttered roll") then
					critical "Failed to buy hot buttered roll."
				end
				if not have_item("casino pass") then
					buy_item("casino pass", "m")
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
				set_result(smith_items("heart of rock and roll", "stolen accordion"))
				if not have_item("Rock and Roll Legend") then
					critical "Couldn't smith RnR"
				end
				did_action = have_item("Rock and Roll Legend")
				return result, resulturl, did_action
			end

			if not playerclass("Accordion Thief") and (AT_song_duration() or 0) < 5 then
				inform "buy toy accordion"
				set_result(buy_item("toy accordion", "z"))
				did_action = have_item("toy accordion")
			end

			if not have_item("seal tooth") and challenge ~= "fist" and challenge ~= "zombie" then
				inform "pick up seal tooth"
				script.ensure_worthless_item()
				if not have_item("hermit permit") then
					buy_item("hermit permit", "m")
				end
				async_post_page("/hermit.php", { action = "trade", whichitem = get_itemid("seal tooth"), quantity = 1 })
				did_action = have_item("seal tooth")
				return result, resulturl, did_action
			end
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
			local pt, pturl, advagain = autoadventure { zoneid = 109 }
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
		elseif count("white pixel") < 30 then
			return {
				message = "make white pixels",
				nobuffing = true,
				action = function()
					local to_make = 30 - count("white pixel")
					shop_buyitem({ ["white pixel"] = to_make }, "mystic")
					did_action = (count("white pixel") >= 30)
				end
			}
		else
			return {
				message = "make digital key",
				nobuffing = true,
				action = function()
					shop_buyitem("digital key", "mystic")
					did_action = have_item("digital key")
				end
			}
		end
	end

	function t.do_8bit_realm()
		local action = nil
		local pixels = count("white pixel") + math.min(count("red pixel"), count("green pixel"), count("blue pixel"))
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
					fam = "Stocking Mimic",
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
		fam = "He-Boulder",
		minmp = 10,
		action = function()
			script.get_faxbot_fax("sleepy mariachi", "sleepy_mariachi")
			use_item("photocopied monster")
			local pt, url = get_page("/fight.php")
			local mariachi_macro = [[
abort pastround 20
abort hppercentbelow 50
scrollwhendone

cast Entangling Noodles

if match yellow eye
  cast point at your opponent
  goto m_done
endif

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
		script.ensure_buffs { "Pisces in the Skyces" }
		script.shrug_buff("Ode to Booze")
		script.maybe_ensure_buffs { "Mental A-cue-ity" }
		return {
			message = "sewerlevel to lvl 6",
			fam = "Frumious Bandersnatch",
			buffs = { "Springy Fusilli", "Spirit of Garlic" },
			minmp = 70,
			action = adventure {
				zoneid = 166,
				macro_function = function() return macro_noodlegeyser(3) end,
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

	function t.there_can_be_only_one_topping()
		if ascension_script_option("manual lvl 9 quest") then
			stop "STOPPED: Ascension script option set to do lvl 9 quest manually"
		end
		if quest_text("should seek him out, in the Highlands beyond the Orc Chasm") then
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
				if have_item("smut orc keepsake box") then
					return {
						message = "use keepsake box",
						fam = "Slimeling",
						nobuffing = true,
						minmp = 0,
						action = function()
							local c = count_item("smut orc keepsake box")
							use_item("smut orc keepsake box")()
							did_action = count_item("smut orc keepsake box") == c - 1
						end
					}
				elseif ascensionstatus("Softcore") then
					return {
						message = "pull keepsake box",
						fam = "Slimeling",
						nobuffing = true,
						minmp = 0,
						action = function()
							pull_in_softcore("smut orc keepsake box")
							did_action = have_item("smut orc keepsake box")
						end
					}
				else
					return {
						message = "get bridge parts (" .. pieces .. ")",
						fam = "Slimeling",
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
		elseif quest_text("now you should go talk to Black Angus") or quest_text("Go see Black Angus") then
			return {
				message = "visit highland lord",
				action = function()
					get_page("/place.php", { whichplace = "highlands", action = "highlands_dude" })
					refresh_quest()
					did_action = not (quest_text("now you should go talk to Black Angus") or quest_text("Go see Black Angus"))
				end
			}
		elseif quest_text("should go to Oil Peak and investigate the signal fire there") or quest_text("should keep killing oil monsters until the pressure on the peak drops") then
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
			script.ensure_buffs { "Ur-Kel's Aria of Annoyance" }
			local ml = estimate_bonus("Monster Level")
			if ml < 50 then
				script.maybe_ensure_buffs { "Pride of the Puffin" }
				ml = estimate_bonus("Monster Level")
			end
			if ml < 20 then
				stop "Not enough +ML for Oil Peak (want 20+ for automation)"
			elseif not ascensionstatus("Hardcore") and ml < 50 and not challenge then
				-- TODO: Trigger this if script options set to go fast
				stop "Not enough +ML for Oil Peak (want 50+ for SCNP automation)"
			end
			return {
				message = "do oil peak",
				fam = "Baby Bugged Bugbear",
				buffs = { "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "A Few Extra Pounds", "Ur-Kel's Aria of Annoyance" },
				minmp = 60,
				action = adventure {
					zoneid = 298,
					macro_function = macro_noodleserpent,
				}
			}
		elseif quest_text("should check out A-Boo Peak and see") or quest_text("should keep clearing the ghosts out of A-Boo Peak") then
			local hauntedness = get_aboo_peak_hauntedness()
			if hauntedness > 0 and hauntedness - count_item("A-Boo clue") * 30 <= 0 then
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
					if have_item("eXtreme mittens") and have_item("eXtreme scarf") and have_item("snowboarder pants") then
						gear = { hat = "eXtreme scarf", pants = "snowboarder pants", acc3 = "eXtreme mittens" }
					end
					gear.acc1 = first_wearable { "glowing red eye" }
					script.wear(gear)
					script.ensure_buffs { "Reptilian Fortitude", "Power Ballad of the Arrowsmith" }
					script.force_heal_up()
				end
				if predict_aboo_peak_banish() < 30 then
					stop "TODO: Buff up and finish A-Boo Peak clues (couldn't banish 30%)"
				end
				use_item("A-Boo clue")
-- 				-- TODO: handle other towel versions

-- 				-- TODO: buff max hp

-- 				if not have_buff("Spooky Flavor") and have_item("ectoplasmic paste") then
-- 					use_item("ectoplasmic paste")
-- 					-- +0/+2
-- 				end
-- 				if not have_buff("Spookypants") and have_item("spooky powder") then
-- 					use_item("spooky powder")
-- 					-- +0/+1
-- 				end
-- 				if not have_buff("Insulated Trousers") and have_item("cold powder") then
-- 					use_item("cold powder")
-- 					-- +1/+0
-- 				end
				-- TODO: heal up fully
				return {
					message = string.format("follow a-boo clue (%d%% haunted)", hauntedness),
					fam = "Exotic Parrot",
					buffs = { "Astral Shell", "Elemental Saucesphere", "Scarysauce", "A Few Extra Pounds", "Go Get 'Em, Tiger!" },
					minmp = 5,
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
				return {
					message = string.format("do a-boo peak (%d%% haunted)", hauntedness),
					fam = "Slimeling",
					buffs = { "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "Empathy" },
					minmp = 50,
					action = adventure {
						zoneid = 296,
						macro_function = macro_noodlecannon,
					}
				}
			end
		elseif quest_text("need to solve the mystery of Twin Peak") then
--			-- TODO: track steps!

-- 			-- TODO: boost item drops & noncombats, sniff either topiary
-- 			-- TODO: ensure 4+ stench resistance
-- 			-- TODO: one choice adv
-- 			-- TODO: ensure +50% item drops (excluding familiars)
-- 			-- TODO: one choice adv
-- 			-- TODO: ensure "jar of oil"
-- 			-- TODO: one choice adv
-- 			-- TODO: ensure combat init +40%
-- 			-- TODO: one choice adventure

			if session["__script.automate twin peak"] == "yes" then
				return {
					message = "solve twin peak mystery",
					fam = "Slimeling",
					buffs = { "Fat Leon's Phat Loot Lyric", "Astral Shell", "Elemental Saucesphere" },
					bonus_target = { "noncombat", "item" },
					minmp = 50,
					action = function()
						if get_resistance_level("Stench") < 4 and not have_buff("Red Door Syndrome") then
							script.ensure_buffs { "Red Door Syndrome" }
						end
						if get_resistance_level("Stench") < 4 then
							script.want_familiar "Exotic Parrot"
						end
						local force_advagain = false
						local function ncfunc(advtitle, choicenum, pagetext)
							if advtitle == "Welcome to the Great Overlook Lodge" then
								force_advagain = true
								return "", 1
							elseif advtitle == "Lost in the Great Overlook Lodge" then
								for _, x in ipairs { "Investigate Room 237", "Search the pantry", "Follow the faint sound of music", "Wait -- who's that?" } do
									if pagetext:contains(x) then
										if pagetext == cached_stuff.previous_twin_peak_noncombat_pagetext then
											stop "Failed to make progress in Twin Peak"
										end
										cached_stuff.previous_twin_peak_noncombat_pagetext = pagetext
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
			else
				return {
					message = "check twin peak requirements",
					buffs = { "Fat Leon's Phat Loot Lyric", "Astral Shell", "Elemental Saucesphere" },
					bonus_target = { "noncombat", "item" },
					action = function()
						if not have_item("jar of oil") then
							use_item("bubblin' crude", 12)
						end
						if get_resistance_level("Stench") < 4 and not have_buff("Red Door Syndrome") then
							script.ensure_buffs { "Red Door Syndrome" }
						end
						if get_resistance_level("Stench") < 4 then
							script.want_familiar "Exotic Parrot"
						end
						if get_resistance_level("Stench") >= 4 and estimate_bonus("Item Drops from Monsters") - __DONOTUSE_estimate_familiar_item_drop_bonus() + estimate_bonus("Food Drops from Monsters") >= 50 and have_item("jar of oil") and estimate_bonus("Combat Initiative") >= 40 then
							session["__script.automate twin peak"] = "yes"
							did_action = true
						else
							stop "TODO: solve twin peak mystery (or get 4+ stench resist, +50% items, jar of oil, and +40% init and run again)"
						end
					end
				}
			end
		end
	end

	t.do_daily_dungeon = {
		message = "do daily dungeon",
		buffs = { "Astral Shell", "Elemental Saucesphere", "Scarysauce" },
		equipment = { acc1 = first_wearable { "ring of Detect Boring Doors" } },
		minmp = 20,
		action = function()
			local advf = adventure {
				zone = "The Daily Dungeon",
				macro_function = macro_noodlecannon,
				noncombats = {
					["It's Almost Certainly a Trap"] = have_item("eleven-foot pole") and "Use your eleven-foot pole" or "Proceed forward cautiously",
					["The First Chest Isn't the Deepest."] = have_equipped_item("ring of Detect Boring Doors") and "Go through the boring door" or "Ignore the chest",
					["I Wanna Be a Door"] = have_item("Pick-O-Matic lockpicks") and "Use your lockpicks" or "Use a skeleton key",
					["Second Chest"] = have_equipped_item("ring of Detect Boring Doors") and "Go through the boring door" or "Ignore the chest",
					["The Final Reward"] = "Open it!",
				},
			}
			local pt, pturl, advagain = advf()
			if pt:contains("Daily Done, John.") then
				cached_stuff.done_daily_dungeon = true
				advagain = true
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

	return t
end

function have_gelatinous_cubeling_items()
	return have_item("eleven-foot pole") and have_item("ring of Detect Boring Doors") and have_item("Pick-O-Matic lockpicks")
end

function buy_shore_inc_item(item)
	autoadventure { zoneid = get_zoneid("The Shore, Inc. Travel Agency"), noncombatchoices = { ["Welcome to The Shore, Inc."] = "Check out the gift shop" } }
	return shop_buyitem(item, "shore")
end
