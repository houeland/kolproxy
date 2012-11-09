__allow_global_writes = true

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
					async_get_page("/mystic.php")
					async_post_page("/mystic.php", { action = "crackyes1" })
					async_post_page("/mystic.php", { action = "crackyes2" })
					result, resulturl = post_page("/mystic.php", { action = "crackyes3" })
					did_action = have("continuum transfunctioner")
				end
			}
		elseif count("white pixel") < 30 then
			return {
				message = "make white pixels",
				nobuffing = true,
				action = function()
					local to_make = 30 - count("white pixel")
					async_post_page("/mystic.php", { action = "makepixel", pwd = get_pwd(), makewhich = get_itemid("white pixel"), quantity = to_make })
					did_action = (count("white pixel") >= 30)
				end
			}
		else
			return {
				message = "make digital key",
				nobuffing = true,
				action = function()
					async_post_page("/mystic.php", { action = "makepixel", pwd = get_pwd(), makewhich = get_itemid("digital key"), quantity = 1 })
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
						async_get_page("/mystic.php")
						async_post_page("/mystic.php", { action = "crackyes1" })
						async_post_page("/mystic.php", { action = "crackyes2" })
						result, resulturl = post_page("/mystic.php", { action = "crackyes3" })
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

	return t
end
