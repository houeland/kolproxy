__allow_global_writes = true

local previous_twin_peak_noncombat_pagetext = nil

function get_automation_tasks(script, cached_stuff)
	local t = {}
	local task = t

	t.summon_clip_art = {
		nobuffing = true,
		action = function ()
			inform "using clip art tome summons"

			if not have("shining halo") then
				script.ensure_mp(2)
				async_post_page("/campground.php", { preaction = "summoncliparts" })
				async_post_page("/campground.php", { pwd = get_pwd(), action = "bookshelf", preaction = "combinecliparts", clip1 = "01", clip2 = "06", clip3 = "06" })
			end
			if not have("Ur-Donut") then
				script.ensure_mp(2)
				async_post_page("/campground.php", { preaction = "summoncliparts" })
				async_post_page("/campground.php", { pwd = get_pwd(), action = "bookshelf", preaction = "combinecliparts", clip1 = "01", clip2 = "01", clip3 = "01" })
			end
			if not have("bucket of wine") then
				script.ensure_mp(2)
				async_post_page("/campground.php", { preaction = "summoncliparts" })
				async_post_page("/campground.php", { pwd = get_pwd(), action = "bookshelf", preaction = "combinecliparts", clip1 = "04", clip2 = "04", clip3 = "04" })
			end

			if not have("shining halo") or not have("Ur-Donut") or not have("bucket of wine") then
				print(have("shining halo"), have("Ur-Donut"), have("bucket of wine"))
				critical "Error getting clip art items"
			end

			eat_item("Ur-Donut")
			if level() >= 2 then
				did_action = true
			end
		end
	}

	t.get_starting_items = {
		nobuffing = true,
		action = function ()
			if not ((have("stolen accordion") or have("Rock and Roll Legend")) and have("turtle totem") and have("saucepan")) then
				local pt, pturl, advagain
				while not ((have("stolen accordion") or have("Rock and Roll Legend")) and have("turtle totem") and have("saucepan")) do
					pt, pturl, advagain = script.buy_use_chewing_gum()
					if not advagain then
						critical "Failed to use chewing gum"
					end
				end
				return pt, pturl
			end

			if not have("Rock and Roll Legend") and challenge ~= "boris" then
				inform "pick up RnR"
				script.ensure_worthless_item()
				if not have("hermit permit") then
					buy_item("hermit permit", "m")
				end
				if not have("hot buttered roll") then
					async_post_page("/hermit.php", { action = "trade", whichitem = get_itemid("hot buttered roll"), quantity = 1 })
				end
				if not have("hot buttered roll") then
					critical "Failed to buy hot buttered roll."
				end
				if not have("casino pass") then
					buy_item("casino pass", "m")
				end
				if not have("casino pass") then
					critical "Failed to buy casino pass."
				end
				if not have("big rock") then
					if not have("ten-leaf clover") and have("disassembled clover") then
						use_item("disassembled clover")
					end
					if not have("ten-leaf clover") then
						uncloset_item("ten-leaf clover")
					end
					if not have("ten-leaf clover") then
						script.trade_for_clover()
					end
					if not have("ten-leaf clover") then
						stop "No ten-leaf clover."
					end
					script.maybe_ensure_buffs { "Mental A-cue-ity" }
					async_get_page("/casino.php", { action = "slot", whichslot = 11 })
					if not have("big rock") then
						critical "Didn't get big rock."
					end
				end
				set_result(smith_items("hot buttered roll", "big rock"))
				set_result(smith_items("heart of rock and roll", "stolen accordion"))
				if not have("Rock and Roll Legend") then
					critical "Couldn't smith RnR"
				end
				did_action = have("Rock and Roll Legend")
				return result, resulturl, did_action
			end

			if not have("seal tooth") and challenge ~= "fist" then
				inform "pick up seal tooth"
				script.ensure_worthless_item()
				if not have("hermit permit") then
					buy_item("hermit permit", "m")
				end
				async_post_page("/hermit.php", { action = "trade", whichitem = get_itemid("seal tooth"), quantity = 1 })
				did_action = have("seal tooth")
				return result, resulturl, did_action
			end
		end
	}

	t.extend_tmm_and_mojo = {
		message = "extending tmm+mojo",
		nobuffing = true,
		action = function ()
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
			if not have("Frobozz Real-Estate Company Instant House (TM)") then
				did_action = true
			end
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
		if not have("continuum transfunctioner") then
			return {
				message = "pick up continuum transfunctioner",
				nobuffing = true,
				action = function()
					set_result(pick_up_continuum_transfunctioner())
					did_action = have("continuum transfunctioner")
				end
			}
		elseif count("white pixel") < 30 then
			return {
				message = "make white pixels",
				nobuffing = true,
				action = function()
					local to_make = 30 - count("white pixel")
					async_post_page("/shop.php", { whichshop = "mystic", pwd = get_pwd(), action = "buyitem", whichitem = get_itemid("white pixel"), quantity = to_make })
					did_action = (count("white pixel") >= 30)
				end
			}
		else
			return {
				message = "make digital key",
				nobuffing = true,
				action = function()
					async_post_page("/shop.php", { whichshop = "mystic", pwd = get_pwd(), action = "buyitem", whichitem = get_itemid("digital key"), quantity = to_make })
					did_action = have("digital key")
				end
			}
		end
	end

	function t.do_8bit_realm()
		local action = nil
		local pixels = count("white pixel") + math.min(count("red pixel"), count("green pixel"), count("blue pixel"))
		if pixels < 30 then
			if not have("continuum transfunctioner") then
				return {
					message = "pick up continuum transfunctioner",
					action = function()
						set_result(pick_up_continuum_transfunctioner())
						did_action = have("continuum transfunctioner")
					end
				}
			else
				return {
					hide_message = true,
					message = "do_8bit_realm",
					fam = "Stocking Mimic",
					olfact = "Blooper",
					equipment = { acc3 = "continuum transfunctioner" },
					action = function()
						-- TODO: use adventure()
						script.go("farm pixels for digital key: " .. pixels, 73, macro_8bit_realm, nil, { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Ghostly Shell", "Astral Shell", "Leash of Linguini", "Empathy" }, "Stocking Mimic", 15, { olfact = "Blooper", equipment = { acc3 = "continuum transfunctioner" } })
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
			if advagain and have("spangly sombrero") and have("spangly mariachi pants") then
				did_action = true
			end
		end
	}

	function t.do_sewerleveling()
		if advs() < 12 then
			stop "Fewer than 12 advs for sewerleveling"
		elseif not buff("Pisces in the Skyces") then
			stop "No gamestore +spelldmg% buff when sewer-leveling to reach level 6"
		else
			script.shrug_buff("Ode to Booze")
			script.maybe_ensure_buffs { "Mental A-cue-ity" }
			return {
				message = "sewerlevel to lvl 6",
				fam = "Frumious Bandersnatch",
				buffs = { "Springy Fusilli", "Spirit of Garlic", "Jaba&ntilde;ero Saucesphere", "Curiosity of Br'er Tarrypin" },
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
		if not did_action then
			result = add_colored_message_to_page(get_result(), "Tried to adventure at the Hobopolis sewer entrance", "darkorange")
		end
		return result, resulturl, did_action
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
			result = add_colored_message_to_page(get_result(), "Tried to adventure at the Hobopolis sewer entrance", "darkorange")
		end
		return result, resulturl, did_action
	end

-- TODO: fax & arrow smut orc instead of ascii art (day 3)
-- TODO: lvl 9 quest on day 4 & after the bridge is untinkered
	function t.there_can_be_only_one_topping()
		if quest_text("should seek him out, in the Highlands beyond the Orc Chasm") then
			local pt, pturl = get_page("/place.php", { whichplace = "orc_chasm" })
			local pieces = tonumber(pt:match("action=bridge([0-9]*)"))
			if not pieces then
				critical "Couldn't determine bridge status"
			end
			if not have_item("dictionary") then
				if have_item("abridged dictionary") then
					async_post_page("/forestvillage.php", { pwd = get_pwd(), action = "untinker", whichitem = get_itemid("abridged dictionary") })
				else
					stop "Missing bridge from pirates"
				end
			end
			pt = get_page("/place.php", { whichplace = "orc_chasm", action = "bridge" .. pieces })
			if pt:contains("have to check out that lumber camp down there") then
				return {
					message = "get bridge parts (" .. pieces .. ")",
					fam = "Slimeling",
					buffs = { "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "Empathy" },
					bonus_target = { "item" },
					minmp = 30,
					action = adventure {
						zoneid = 295,
						macro_function = macro_noodleserpent,
					}
				}
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
			if have_item("A-Boo clue") then
				if not buff("Super Structure") and have("Greatest American Pants") then
					script.wear { pants = "Greatest American Pants" }
					script.get_gap_buff("Super Structure")
				end
				if not have_buff("Well-Oiled") and have_item("Oil of Parrrlay") then
					use_item("Oil of Parrrlay")
				end
-- 				wear { weapon = "titanium assault umbrella" }
-- 				wear { weapon = "double-barreled sling" }
-- 				wear { weapon = "broken sword" }
-- 				wear { offhand = "battered hubcap" }
-- 				wear { weapon = "coffin lid" }
-- 				wear { shirt = "eXtreme Bi-Polar Fleece Vest" }
-- 				wear { acc2 = "enchanted handwarmer" }
-- 				wear { acc1 = "glowing red eye" }
-- 				wear { hat = "eXtreme scarf", pants = "snowboarder pants", acc3 = "eXtreme mittens" }
-- 				wear { hat = "antique helmet" }
-- 				wear { hat = "lihc face" }
-- 				-- TODO: handle other towel versions
-- 				wear { hat = "makeshift turban" }
-- 				wear { hat = "wool hat" }

-- 				-- TODO: buff max hp

-- 				if not buff("Spooky Flavor") and have("ectoplasmic paste") then
-- 					use_item("ectoplasmic paste")
-- 					-- +0/+2
-- 				end
-- 				if not buff("Spookypants") and have("spooky powder") then
-- 					use_item("spooky powder")
-- 					-- +0/+1
-- 				end
-- 				if not buff("Insulated Trousers") and have("cold powder") then
-- 					use_item("cold powder")
-- 					-- +1/+0
-- 				end
				-- TODO: heal up fully
				return {
					message = "follow a-boo clue",
					fam = "Exotic Parrot",
					buffs = { "Astral Shell", "Elemental Saucesphere", "Scarysauce", "A Few Extra Pounds", "Go Get 'Em, Tiger!" },
					minmp = 5,
					action = adventure {
						zoneid = 296,
						choice_function = function (advtitle, choicenum)
							if advtitle == "The Horror..." then
								return "", 1
							end
						end
					}
				}
			else
				return {
					message = "do a-boo peak",
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
					minmp = 50,
					action = function()
						if get_resistance_levels().stench < 4 and not have_buff("Red Door Syndrome") then
							script.ensure_buffs { "Red Door Syndrome" }
						end
						if get_resistance_levels().stench < 4 then
							switch_familiarid(72)
						end
						local force_advagain = false
						result, resulturl, advagain = autoadventure { zoneid = 297, macro = macro_noodlecannon(), noncombatchoices = nil, specialnoncombatfunction = function(advtitle, choicenum, pagetext)
							if advtitle == "Welcome to the Great Overlook Lodge" then
								force_advagain = true
								return "", 1
							elseif advtitle == "Lost in the Great Overlook Lodge" then
								for _, x in ipairs { "Investigate Room 237", "Search the pantry", "Follow the faint sound of music", "Wait -- who's that?" } do
									if pagetext:contains(x) then
										if pagetext == previous_twin_peak_noncombat_pagetext then
											stop "Failed to make progress in Twin Peak"
										end
										previous_twin_peak_noncombat_pagetext = pagetext
										return x
									end
								end
							else
								return "", 1
							end
						end, ignorewarnings = true }
						if force_advagain then
							-- TODO: Why is this necessary?
							advagain = true
						end
						return result, resulturl, advagain
					end
				}
			else
				return {
					message = "check twin peak requirements",
					action = function()
						if not have_item("jar of oil") then
							use_item("bubblin' crude", 12)
						end
						script.ensure_buffs { "Fat Leon's Phat Loot Lyric", "Astral Shell", "Elemental Saucesphere" }
						if get_resistance_levels().stench < 4 and not have_buff("Red Door Syndrome") then
							script.ensure_buffs { "Red Door Syndrome" }
						end
						if get_resistance_levels().stench < 4 then
							switch_familiarid(72)
						end
						if familiarid() ~= 72 then
							switch_familiarid(1)
						end
						if get_resistance_levels().stench >= 4 and (familiarid() == 1 or familiarid() == 72) and estimate_modifier_bonuses().item >= 50 and have_item("jar of oil") and estimate_modifier_bonuses().initiative >= 40 then
							session["__script.automate twin peak"] = "yes"
							did_action = true
						else
							stop "TODO: solve twin peak mystery"
						end
					end
				}
			end
		end
	end

	return t
end
