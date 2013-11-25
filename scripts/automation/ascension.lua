__allow_global_writes = true

-- TODO FIX LIST

-- TMM and butt-rock hair are moxie-specific, as are boss items picked up. get mainstat item from goblin king?
-- script IDing dod potions automatically

-- cast libram summons

-- handle organ grinding

show_spammy_automation_events = true

stop_on_potentially_unwanted_softcore_actions = false

lowskill_fist_run = nil
-- support no healing?
-- support losing init?

highskill_at_run = nil

can_change_familiar = nil

ignore_buffing_and_outfit = nil

local function check_for_highskill_run()
	if classid() == 6 and have_item("astral belt") and moonsign() == "Vole" and current_ascension_number() >= 100 and ascensionpathid() == 0 then
		--return true
	end
end

function softcore_stoppable_action(msg)
	if stop_on_potentially_unwanted_softcore_actions then
		stop("Stopping before: " .. tostring(msg))
	end
end

local debug_show_empty_messages = false

local cached_stuff = {}

local function write_log_line(msg)
	local f = io.open(string.format("logs/scripts/scripted-ascension-log-%s-%s.txt", playername(), ascensions_count() + 1), "a+")
	f:write(msg.."\n")
	f:close()
end

local finished = false

local function automate_hcnp_day(whichday)
	reset_error_trace_steps()
	finished = false

	if show_spammy_automation_events then
		print()
	end
	result = "??? No action found ???"
	resulturl = "/automate-ascension-hcnp-day" .. whichday
	did_action = false

	function hidden_inform(msg)
		add_error_trace_step(msg)
	end

	function inform(msg)
		result = "Tried to perform: " .. tostring(msg)
		add_error_trace_step(msg)
		local mpstr = string.format("%s / %s MP", mp(), maxmp())
		if challenge == "zombie" then
			mpstr = string.format("%s horde", horde_size())
		end
		local formatted = string.format("[%s] %s (level %s.%02d, %s turns remaining, %s full, %s drunk, %s spleen, %s meat, %s / %s HP, %s)", turnsthisrun(), tostring(msg), level(), level_progress() * 100, advs(), fullness(), drunkenness(), spleen(), meat(), hp(), maxhp(), mpstr)
		print(formatted)
		write_log_line(formatted)
	end

	local function can_yellow_ray()
		return not have_buff("Everything Looks Yellow")
	end

	local function can_photocopy()
		return not cached_stuff.have_faxed_today and have_item("Clan VIP Lounge key") and not ascensionpath("Avatar of Boris") and not ascensionpath("Avatar of Jarlsberg")
	end

	local function want_shore()
		return not unlocked_island() and not have_item("skeleton")
	end

	local function unlocked_knob()
		return level() >= 5 and not have_item("Cobb's Knob map")
	end

	-- TODO: do these properly
	local function started_war()
		return quest("Make War, Not... Oh, Wait")
	end

	local function completed_war()
		return not quest("Make War, Not... Oh, Wait")
	end

	local function completed_filthworms()
		return have_item("heart of the filthworm queen")
	end

	local function completed_sonofa_beach()
		return have_item("tequila grenade") or have_item("molotov cocktail cocktail")
	end

	local function completed_gremlins()
		return have_item("rusty chain necklace") or have_item("sawblade shield") or have_item("wrench bracelet")
	end

	local function completed_arena()
		return not have_item("rock band flyers")
	end

	challenge = nil
	if ascensionpath("Way of the Surprising Fist") then
		challenge = "fist"
		fist_level = 0
		for _, x in ipairs { "Flying Fire Fist", "Salamander Kata", "Drunken Baby Style", "Stinkpalm", "Worldpunch" } do
			if have_skill(x) then
				fist_level = fist_level + 1
			end
		end
		attack_action = fist_action
		cannon_action = fist_action
		if fist_level >= 3 then
			-- TODO: be reasonably drunk when using drunken baby to kill
			serpent_action = fist_action
		end
	elseif ascensionpathid() == 7 then
		challenge = "trendy"
		serpent_action = geyser_action
		function make_yellowray_macro(name)
			return [[
]] .. COMMON_MACROSTUFF_START(20, 50) .. [[

if monstername ]] .. name .. [[

  use unbearable light
  goto m_done
endif

]] .. COMMON_MACROSTUFF_FLYERS .. [[

while !times 3
]] .. cannon_action() .. [[
endwhile

mark m_done

]]
		end
	elseif ascensionpath("Avatar of Boris") then
		-- TODO: pull third wine bottle
		challenge = "boris"
		if ascensionstatus() == "Hardcore" then
			macro_softcore_boris = macro_hardcore_boris
		end
		macro_softcore = macro_softcore_boris
		macro_autoattack = macro_softcore_boris
		macro_stasis = macro_softcore_boris
		macro_8bit_realm = macro_softcore_boris
		macro_noodlecannon = macro_softcore_boris
		macro_ppnoodlecannon = macro_softcore_boris
		macro_noodleserpent = macro_softcore_boris
		macro_barrr = macro_softcore_boris
		macro_spookyraven = macro_softcore_boris
		function macro_noodlegeyser() return macro_softcore_boris end
		make_gremlin_macro = macro_softcore_boris_gremlin
		function noodles_action()
			return [[

if hascombatitem Rain-Doh blue balls
  use Rain-Doh blue balls
  use Rain-Doh indigo cup
endif
if !hascombatitem Rain-Doh blue balls
  if hasskill Broadside
    cast Broadside
  endif
endif

]]
		end
		elemental_damage_action = boris_action
		if ascensionstatus() == "Hardcore" or fullness() >= 10 then
			function elemental_damage_action()
				return [[

cast Heroic Belch

]]
			end
		end
		cannon_action = boris_action
		serpent_action = boris_cleave_action
		geyser_action = boris_cleave_action
		function make_cannonsniff_macro(name)
			if name == "dairy goat" then
				return macro_softcore_boris()
			elseif name == "dirty old lihc" then
				return macro_softcore_boris()
			elseif name == "zombie waltzers" then
				return macro_softcore_boris()
			elseif name == "Hellion" then
				return macro_softcore_boris()
			elseif name == "Astronomer" and ascensionstatus() == "Hardcore" then
				return macro_softcore_boris()
			elseif name == "gaudy pirate" then
				if not have_item("gaudy key") and not have_item("snakehead charrrm") and not have_item("Talisman o' Nam") and ascensionstatus() ~= "Hardcore" then
					if have_item("Rain-Doh black box") then
						return macro_softcore_boris([[

if monstername gaudy pirate
  use Rain-Doh black box
endif

]])
					end
					stop "TODO: fight and copy gaudy pirate to make talisman"
				else
					return macro_softcore_boris()
				end
			elseif name == "morbid skull" then
				return macro_softcore_boris()
			else
				critical("Trying to sniff " .. name .. " in Boris")
			end
		end
	elseif ascensionpath("Zombie Slayer") then
		challenge = "zombie"
		if ascensionstatus() == "Hardcore" then
			macro_softcore_boris = macro_hardcore_boris
		end
		boris_action = function()
			return [[

if hasskill Kodiak Moment
  cast Kodiak Moment
endif
if hasskill Throw Shield
  cast Throw Shield
  attack
endif
if hasskill Ravenous Pounce
  cast Ravenous Pounce
endif
if hasskill Distracting Minion
  cast Distracting Minion
endif
if (!hasskill Ravenous Pounce) && (!hasskill Distracting Minion) && (hasskill Zombie Maestro)
  cast Zombie Maestro
endif
if (!hasskill Kodiak Moment) && (!hasskill Throw Shield) && (!hasskill Zombie Maestro) && (!hasskill Ravenous Pounce) && (!hasskill Distracting Minion)
  attack
endif

]]
		end
		cannon_action = boris_action
		serpent_action = boris_action
		geyser_action = boris_action
		boris_cleave_action = boris_action
		make_gremlin_macro = macro_softcore_boris_gremlin
		elemental_damage_action = boris_action
		macro_softcore_zombie = macro_softcore_boris
		macro_softcore = macro_softcore_zombie
		macro_autoattack = macro_softcore_zombie
		macro_stasis = macro_softcore_zombie
		macro_8bit_realm = macro_softcore_zombie
		macro_noodlecannon = macro_softcore_zombie
		macro_ppnoodlecannon = macro_softcore_zombie
		macro_noodleserpent = macro_softcore_zombie
		macro_barrr = macro_softcore_zombie
		macro_spookyraven = macro_softcore_zombie
		function macro_noodlegeyser() return macro_softcore_zombie end
		function make_cannonsniff_macro(name)
			return macro_softcore_zombie()
		end
	elseif ascensionpath("Avatar of Jarlsberg") then
		-- TODO: pull third wine bottle
		challenge = "jarlsberg"
		if ascensionstatus() == "Hardcore" then
			macro_softcore_boris = macro_hardcore_boris
		end
		macro_softcore = macro_softcore_boris
		macro_autoattack = macro_softcore_boris
		macro_stasis = macro_softcore_boris
		macro_8bit_realm = macro_softcore_boris
		macro_noodlecannon = macro_softcore_boris
		macro_ppnoodlecannon = macro_softcore_boris
		macro_noodleserpent = macro_softcore_boris
		macro_barrr = macro_softcore_boris
		macro_spookyraven = macro_softcore_boris
		function macro_noodlegeyser() return macro_softcore_boris end
		make_gremlin_macro = macro_softcore_boris_gremlin

		boris_action = function()
			local killspell = ""
			local maybe_jiggle = ""
			local cfm = getCurrentFightMonster()
			local monster_element = ""
			local physresist = 0
			local cfmhp = 10
			local cfmatt = 10
			if cfm and cfm.Stats and cfm.Stats.Element then
				monster_element = cfm.Stats.Element
			end
			if cfm and cfm.Stats and cfm.Stats.Phys then
				physresist = tonumber(cfm.Stats.Phys)
			end
			if cfm and cfm.Stats and cfm.Stats.HP then
				cfmhp = tonumber(cfm.Stats.HP)
			end
			if cfm and cfm.Stats and cfm.Stats.Atk then
				cfmatt = tonumber(cfm.Stats.Atk)
			end
			if (mp() >= 20 and have_skill("Slice")) and cfmhp >= 90 and physresist == 0 and (cfmatt > buffedmoxie() + 30) then
				killspell = [[

if hasskill Slice
  cast Slice
endif

]]
			elseif (level() >= 7 or mp() >= 25) and monster_element ~= "hot" and monster_element ~= "Hot" then
				killspell = [[

if hasskill Boil
  cast Boil
endif

]]
			elseif level() >= 9 or (mp() >= 40 and have_skill("Slice")) then
				killspell = [[

if hasskill Slice
  cast Slice
endif

]]
			elseif monster_element ~= "stench" and monster_element ~= "Stench" then
				killspell = [[

if hasskill Curdle
  cast Curdle
endif

]]
			else
				killspell = [[

if hasskill Boil
  cast Boil
endif

]]
			end
			if have_equipped_item("Staff of the Healthy Breakfast") then
				maybe_jiggle = [[

jiggle

]]
			end
			return [[

]] .. maybe_jiggle .. [[

if hasskill Throw Shield
  cast Throw Shield
endif
if (hasskill Blend) && (!monstername oil tycoon)
  cast Blend
endif

]] .. killspell .. [[

]]
		end

		function noodles_action()
			return [[

if (hascombatitem Rain-Doh blue balls) && (!monstername oil tycoon)
  use Rain-Doh blue balls
  use Rain-Doh indigo cup
endif
if (!hascombatitem Rain-Doh blue balls) && (!monstername oil tycoon)
  if hasskill Blend
    cast Blend
  endif
endif

]]
		end

		elemental_damage_action = boris_action
		cannon_action = boris_action
		serpent_action = boris_cleave_action
		geyser_action = boris_cleave_action
		function make_cannonsniff_macro(name)
			if name == "dairy goat" then
				return macro_softcore_boris()
			elseif name == "dirty old lihc" then
				return macro_softcore_boris()
			elseif name == "zombie waltzers" then
				return macro_softcore_boris()
			elseif name == "Hellion" then
				return macro_softcore_boris()
			elseif name == "Astronomer" and ascensionstatus() == "Hardcore" then
				return macro_softcore_boris()
			elseif name == "gaudy pirate" then
				if not have_item("gaudy key") and not have_item("snakehead charrrm") and not have_item("Talisman o' Nam") and ascensionstatus() ~= "Hardcore" then
					if have_item("Rain-Doh black box") then
						return macro_softcore_boris([[

if monstername gaudy pirate
  use Rain-Doh black box
endif

]])
					end
					stop "TODO: fight and copy gaudy pirate to make talisman"
				else
					return macro_softcore_boris()
				end
			elseif name == "morbid skull" then
				return macro_softcore_boris()
			else
				critical("Trying to sniff " .. name .. " in Boris")
			end
		end
	elseif ascensionpathid() == 0 then
		highskill_at_run = check_for_highskill_run()
		if not have_skill("Stringozzi Serpent") and have_skill("Cannelloni Cannon") then
			serpent_action = cannon_action
		end
	end
	if not have_skill("Saucy Salve") then
		conditional_salve_action = function() return [[



]]
		end
	end

	if ascensionpath("Avatar of Boris") or ascensionpath("Avatar of Jarlsberg") then
		can_change_familiar = false
	else
		can_change_familiar = true
	end

	if not cached_stuff.gotten_guild_challenge then
		async_get_page("/guild.php", { place = "challenge" })
		cached_stuff.gotten_guild_challenge = true
	end

	local script = get_automation_scripts(cached_stuff)
	local tasks = get_automation_tasks(script, cached_stuff)

	local council_text = nil
	local council_text_async = async_get_page("/council.php")

	local questlog_page = nil
	local questlog_page_async = async_get_page("/questlog.php", { which = 1 })
	function refresh_quest()
		questlog_page = get_page("/questlog.php", { which = 1 })
	end

	function quest(name)
		return questlog_page:contains([[<b>]] .. name .. [[</b>]])
	end
	function quest_text(name)
		return questlog_page:contains(name)
	end

	local function countif(x)
		if have(x) then
			return 1
		else
			return 0
		end
	end

	local function get_first_we_have(tbl, n)
		if n == nil then
			n = 1
		end
		local ret = {}
		for x in table.values(tbl) do
			local ctr = 1
			while count(x) >= ctr and n >= 0 do
				table.insert(ret, x)
				n = n - 1
				ctr = ctr + 1
			end
		end
		return unpack(ret)
	end

	local function ensure_yellow_ray()
		if not can_yellow_ray() then
			return false
		end
		if script.have_familiar("He-Boulder") then
			return true
		end
		if not have_item("unbearable light") and not cached_stuff.tried_to_summon_unbearable_light then
			inform "summoning unbearable light (no he-boulder)"
			script.ensure_mp(5)
			async_post_page("/campground.php", { preaction = "summoncliparts" })
			async_post_page("/campground.php", { pwd = get_pwd(), action = "bookshelf", preaction = "combinecliparts", clip1 = "06", clip2 = "06", clip3 = "06" })
			cached_stuff.tried_to_summon_unbearable_light = true
		end
		return have_item("unbearable light")
	end

	local function ensure_clover()
		if not have_item("ten-leaf clover") and have_item("disassembled clover") then
			use_item("disassembled clover")
		end
		return have_item("ten-leaf clover")
	end

	local tasks_list = {}

	local function add_task(t)
		if t.f then
		elseif t.action then
		elseif t.task then
		else
			error("Error adding task! (" .. tostring(t.message) .. ")")
		end
		table.insert(tasks_list, t)
	end

	local function ensure_empty_config_table(t)
		local n = next(t)
		if n then
			error("Config table not empty, contains key: " .. tostring(n))
		end
	end

	function adventure(t)
		return function()
			local pt, pturl, advagain = autoadventure { zoneid = get_zoneid(t.zone or t.zoneid), macro = t.macro_function and t.macro_function(), noncombatchoices = t.noncombats, specialnoncombatfunction = t.choice_function, ignorewarnings = true }
			t.zone = nil
			t.zoneid = nil
			t.macro_function = nil
			t.noncombats = nil
			t.choice_function = nil
			ensure_empty_config_table(t)
			return pt, pturl, advagain
		end
	end

	council_text = council_text_async()
	questlog_page = questlog_page_async()

	local DD_keys = countif("Boris's key") + countif("Jarlsberg's key") + countif("Sneaky Pete's key") + count("fat loot token")
	if ascensionstatus() ~= "Hardcore" or cached_stuff.completed_daily_dungeon then
		DD_keys = 100
	end

	kgs_available = cached_stuff.learned_lab_password and have_item("Cobb's Knob lab key")
	mmj_available = cached_stuff.mox_guild_is_open and (classid() == 3 or classid() == 4 or (classid() == 6 and level() >= 9))

	script.bonus_target {}
	script.set_runawayfrom(nil)

	if level() < 13 then
		if mainstat_type("Muscle") and (have_intrinsic("Gaze of the Trickster God") or have_intrinsic("Gaze of the Lightning God")) then
			stop "Non-volcanic gaze active! Set it manually and run again."
		elseif mainstat_type("Mysticality") and (have_intrinsic("Gaze of the Trickster God") or have_intrinsic("Gaze of the Volcano God")) then
			stop "Non-lightning gaze active! Set it manually and run again."
		elseif mainstat_type("Moxie") and (have_intrinsic("Gaze of the Volcano God") or have_intrinsic("Gaze of the Lightning God")) then
			stop "Non-trickster gaze active! Set it manually and run again."
		end
	end

	if not cached_stuff.visited_hermit and challenge == "zombie" then
		async_get_page("/hermit.php")
		cached_stuff.visited_hermit = true
	end

	add_task {
		when = have_item("ten-leaf clover"),
		task = {
			message = "hide ten-leaf clover",
			nobuffing = true,
			action = function()
				set_result(use_item("ten-leaf clover"))
				did_action = not have_item("ten-leaf clover")
			end
		}
	}

	add_task {
		when = have_buff("Just the Best Anapests"),
		task = {
			message = "shrugging anapests",
			nobuffing = true,
			action = function()
				async_get_page("/charsheet.php", { pwd = get_pwd(), ajax = 1, action = "unbuff", whichbuff = 1003 })
				did_action = not have_buff("Just the Best Anapests")
			end
		}
	}

	add_task {
		when = have_item("letter from King Ralph XI"),
		task = {
			message = "using letter from king",
			nobuffing = true,
			action = function()
				set_result(use_item("letter from King Ralph XI"))
				did_action = not have_item("letter from King Ralph XI")
			end
		}
	}

	add_task {
		when = not have_item("Clan VIP Lounge key") and not cached_stuff.gotten_vip_lounge_key,
		task = {
			message = "pull VIP key",
			nobuffing = true,
			action = function()
				freepull_item("Clan VIP Lounge key")
				async_get_page("/clan_viplounge.php", { action = "klaw" })
				async_get_page("/clan_viplounge.php", { action = "klaw" })
				async_get_page("/clan_viplounge.php", { action = "klaw" })
				cached_stuff.gotten_vip_lounge_key = true
				did_action = true
			end
		}
	}

	add_task {
		when = not have_item("gnomish housemaid's kgnee") and not cached_stuff.gotten_kgnee,
		task = {
			message = "get kgnee",
			nobuffing = true,
			action = function()
				cached_stuff.gotten_kgnee = true
				script.want_familiar "Reagnimated Gnome"
				async_get_page("/arena.php")
				async_get_page("/choice.php", { forceoption = 0 })
				async_post_page("/choice.php", { pwd = get_pwd(), whichchoice = 597, option = 4 })
				did_action = true
			end
		}
	}

	add_task {
		when = (challenge == "boris") and not have_item("Boris's Helm") and not have_item("Boris's Helm (askew)") and not cached_stuff.gotten_boris_helm,
		task = {
			message = "pull Boris's Helm",
			nobuffing = true,
			action = function()
				freepull_item("Boris's Helm")
				freepull_item("Boris's Helm (askew)")
				cached_stuff.gotten_boris_helm = true
				did_action = true
			end
		}
	}

	add_task {
		when = (challenge == "jarlsberg") and not have_item("Jarlsberg's pan") and not have_item("Jarlsberg's pan (Cosmic portal mode)") and not cached_stuff.gotten_jarlsberg_pan,
		task = {
			message = "pull Jarlsberg's pan",
			nobuffing = true,
			action = function()
				freepull_item("Jarlsberg's pan")
				freepull_item("Jarlsberg's pan (Cosmic portal mode)")
				cached_stuff.gotten_jarlsberg_pan = true
				did_action = true
			end
		}
	}

	add_task {
		when = not cached_stuff.gotten_drink_me_potion,
		task = {
			message = "picking up drink me potion",
			nobuffing = true,
			action = function()
				async_get_page("/clan_viplounge.php", { action = "lookingglass" })
				cached_stuff.gotten_drink_me_potion = true
				did_action = true
			end
		}
	}

	add_task {
		when = not cached_stuff.done_campground,
		task = {
			message = "doing campground stuff",
			nobuffing = true,
			action = function()
				async_get_page("/campground.php")
				if setting_enabled("automate daily visits/harvest garden") then
					-- TODO: remove, should have been done anyway?
					async_get_page("/campground.php", { action = "garden", pwd = get_pwd() })
				end

				async_post_page("/campground.php", { action = "telescopelow" })

		-- 		async_post_page("/campground.php", { smashstone = "Yep.", pwd = get_pwd(), confirm = "on" })
				did_action = true
				cached_stuff.done_campground = true
			end
		}
	}

	add_task {
		when = not cached_stuff.campground_psychoses,
		task = {
			message = "checking campground psychoses",
			nobuffing = true,
			action = function()
				set_result(get_page("/campground.php"))
				if get_result():contains("The Crackpot Mystic's Psychoses") then
					cached_stuff.campground_psychoses = "mystic"
				else
					cached_stuff.campground_psychoses = "not mystic"
				end
				did_action = true
			end
		}
	}

	add_task {
		when = council_text:contains("visit the Toot Oriole"),
		task = {
			message = "visit the toot oriole",
			nobuffing = true,
			action = function()
				async_get_page("/tutorial.php", { action = "toot" })
				did_action = have_item("letter from King Ralph XI")
			end
		}
	}

	add_task {
		when = have_item("Newbiesport&trade; tent") and not cached_stuff.tried_using_newbiesport_tent,
		task = {
			message = "using newbiesport tent",
			nobuffing = true,
			action = function()
				set_result(use_item("Newbiesport&trade; tent"))
				cached_stuff.tried_using_newbiesport_tent = true
				did_action = not have_item("Newbiesport&trade; tent")
			end
		}
	}

	add_task {
		when = meat() >= 1500 and moonsign_area() == "Degrassi Knoll" and not have_item("detuned radio"),
		task = {
			message = "buying detuned radio",
			nobuffing = true,
			action = function()
				set_result(buy_item("detuned radio", "4"))
				did_action = have_item("detuned radio")
			end
		}
	}

	add_task {
		when = have_item("batskin belt") and have_item("dragonbone belt buckle"),
		task = {
			message = "paste badass belt",
			nobuffing = true,
			action = function()
				set_result(meatpaste_items("batskin belt", "dragonbone belt buckle"))
				did_action = have_item("badass belt")
			end
		}
	}

	local function count_spare_brains()
		if have_item("good brain") or have_item("decent brain") or have_item("crappy brain") then
			local want_brains = estimate_max_fullness() - fullness()
			local have_brains = count_item("hunter brain") + count_item("boss brain") + count_item("good brain") + count_item("decent brain") + count_item("crappy brain")
			return have_brains - want_brains
		end
	end

	add_task {
		when = challenge == "zombie" and horde_size() < 100 and have_skill("Lure Minions") and (count_spare_brains() or 0) > 0,
		task = {
			message = "lure zombies",
			hide_message = true,
			nobuffing = true,
			action = function()
				local curhorde = horde_size()
				local options = {
					{ name = "crappy brain", option = 1 },
					{ name = "decent brain", option = 2 },
					{ name = "good brain", option = 3 },
				}

				for _, x in ipairs(options) do
					if have_item(x.name) then
						cast_skillid(12002, 1)
						async_get_page("/choice.php", { forceoption = 0 })
						async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 599, option = x.option, quantity = math.min(10, count_spare_brains(), count_item(x.name)) })
						async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 599, option = 5 })
						break
					end
				end

				did_action = horde_size() > curhorde
			end
		}
	}

	add_task {
		when = challenge == "zombie" and have_skill("Summon Horde") and ((horde_size() < 20 and meat() >= 6000) or (horde_size() < 100 and meat() >= 10000)),
		task = {
			message = "summon horde",
			nobuffing = true,
			action = function()
				local curhorde = horde_size()
				cast_skillid(12026, 1)
				async_get_page("/choice.php", { forceoption = 0 })
				async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 601, option = 1 })
				async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 601, option = 2 })
				did_action = horde_size() > curhorde
			end
		}
	}

	-- TODO: Handle when buffing
	add_task {
		when = challenge == "zombie" and not have_buff("Chow Downed") and have_skill("Zombie Chow") and horde_size() >= 20,
		task = {
			message = "cast zombie chow",
			nobuffing = true,
			action = function()
				cast_skillid(12022, 1)
				did_action = have_buff("Chow Downed")
			end
		}
	}

	add_task {
		when = challenge == "zombie" and not have_buff("Scavengers Scavenging") and have_skill("Scavenge") and horde_size() >= 20,
		task = {
			message = "cast scavenge",
			nobuffing = true,
			action = function()
				cast_skillid(12024, 1)
				did_action = have_buff("Scavengers Scavenging")
			end
		}
	}

	local function do_day_2_mining()
		inform "mine free 5 times"
		local pt = get_page("/mining.php", { mine = 1, intro = 1 })
		if pt:contains("takes one Adventure") then
			inform "done with free mining"
			return nil
		end
		local which_to_mine = {
			[51] = true,
			[43] = true,
			[35] = true,
			[27] = true,
			[19] = true,
		}
		for x, y in pt:gmatch("<a href='mining.php%?mine=1&which=([0-9]+)&pwd=([0-9a-f]+)'>") do
			if y == get_pwd() then
				print("can mine", x)
				if which_to_mine[tonumber(x)] then
					inform("do mine " .. x)
					print("do mine", x)
					result, resulturl = get_page("/mining.php", { mine = 1, which = x, pwd = get_pwd() })
					did_action = true
					return did_action
				end
			end
		end
	end

	trailed = nil
	if have_buff("On the Trail") then
		trailed = retrieve_trailed_monster()
	end

	if have_buff("Beaten Up") then
		stop "Beaten up..."
	end

	arrowed_possible = nil
	do
		local remaining = tonumber(day["obtuse angel romantic arrow monsters remaining"])
		if remaining and remaining > 0 then
			local start = tonumber(day["obtuse angel romantic arrow next monster start"])
			if start then
				if turnsthisrun() >= start then
					arrowed_possible = day["obtuse angel romantic arrow target"]
				end
			end
		end
	end
	
	if drunkenness() > estimate_max_safe_drunkenness() then
		stop "Overdrunk"
	end

	if have_buff("Temporary Amnesia") then
		use_hottub()
		if have_buff("Temporary Amnesia") then
			stop "Temporary amnesia..."
		end
	end

	local function have_frat_war_outfit()
		return have_item("beer helmet") and have_item("distressed denim pants") and have_item("bejeweled pledge pin")
	end

	local function have_miners_outfit()
		return have_item("miner's helmet") and have_item("7-Foot Dwarven mattock") and have_item("miner's pants")
	end

	add_task {
		when = have_item("Frobozz Real-Estate Company Instant House (TM)"),
		task = tasks.place_instant_house,
	}

	add_task {
		when = have_item("steel margarita"),
		task = {
			message = "drinking steel margarita",
			nobuffing = true,
			action = function()
				clear_cached_skills()
				drink_item("steel margarita")
				if not have_item("steel margarita") then
					did_action = true
				end
			end
		}
	}

	add_task {
		when = have_item("steel lasagna") and estimate_max_fullness() - fullness() >= 5,
		task = {
			message = "eating steel lasagna",
			nobuffing = true,
			action = function()
				clear_cached_skills()
				eat_item("steel lasagna")
				if not have_item("steel lasagna") then
					did_action = true
				end
			end
		}
	}

	add_task {
		when = have_item("steel-scented air freshener") and estimate_max_spleen() - spleen() >= 5,
		task = {
			message = "using steel-scented air freshener",
			nobuffing = true,
			action = function()
				clear_cached_skills()
				use_item("steel-scented air freshener")
				if not have_item("steel-scented air freshener") then
					did_action = true
				end
			end
		}
	}

	add_task {
		when = estimate_max_spleen() - spleen() == 7 and have_item("astral energy drink") and level() >= 11 and have_item("mojo filter"),
		task = {
			message = "use mojo filter",
			nobuffing = true,
			action = function()
				print("free spleen before", estimate_max_spleen() - spleen())
				set_result(use_item("mojo filter"))
				print("free spleen after", estimate_max_spleen() - spleen())
				get_result()
				print("free spleen after get_result", estimate_max_spleen() - spleen())
				did_action = estimate_max_spleen() - spleen() >= 8
			end
		}
	}

	add_task {
		when = estimate_max_spleen() - spleen() >= 8 and have_item("astral energy drink") and level() >= 11,
		task = {
			message = "use astral energy drink",
			nobuffing = true,
			action = function()
				local a = advs()
				set_result(use_item("astral energy drink"))
				did_action = advs() > a
			end
		}
	}

	add_task {
		when = challenge and not ascensionstatus("Hardcore") and estimate_max_spleen() - spleen() == 7 and have_item("astral energy drink") and level() >= 11 and not have_item("mojo filter") and not cached_stuff["ignore pull: mojo filter"],
		task = {
			message = "pull mojo filter",
			action = function()
				cached_stuff["ignore pull: mojo filter"] = "yes"
				pull_in_softcore("mojo filter")
				did_action = have_item("mojo filter")
			end
		}
	}

	add_task {
		when = challenge == "boris" and daysthisrun() == 1 and estimate_max_spleen() - spleen() >= 8 and have_item("astral energy drink") and level() >= 9,
		task = {
			message = "use astral energy drink",
			nobuffing = true,
			action = function()
				local a = advs()
				set_result(use_item("astral energy drink"))
				did_action = advs() > a
			end
		}
	}

	add_task {
		when = challenge == "boris" and daysthisrun() == 1 and estimate_max_safe_drunkenness() - drunkenness() >= 2 and have_item("Crimbojito") and level() >= 2,
		task = {
			message = "drink Crimbojito",
			nobuffing = true,
			action = function()
				local a = advs()
				set_result(drink_item("Crimbojito"))
				did_action = advs() > a
			end
		}
	}

	add_task {
		when = estimate_max_spleen() - spleen() >= 4 and have_item("glimmering roc feather") and level() >= 4,
		task = {
			message = "use glimmering roc feather",
			nobuffing = true,
			action = function()
				local a = advs()
				set_result(use_item("glimmering roc feather"))
				did_action = advs() > a
			end
		}
	}

	add_task {
		when = estimate_max_spleen() - spleen() >= 4 and have_item("not-a-pipe") and level() >= 4,
		task = {
			message = "use not-a-pipe",
			nobuffing = true,
			action = function()
				local a = advs()
				set_result(use_item("not-a-pipe"))
				did_action = advs() > a
			end
		}
	}

	add_task {
		when = estimate_max_spleen() - spleen() >= 4 and have_item("groose grease"),
		task = {
			message = "use groose grease",
			nobuffing = true,
			action = function()
				local a = advs()
				set_result(use_item("groose grease"))
				did_action = advs() > a
			end
		}
	}

	add_task {
		when = estimate_max_spleen() - spleen() >= 4 and have_item("agua de vida") and level() >= 4,
		task = {
			message = "use agua de vida",
			nobuffing = true,
			action = function()
				local a = advs()
				set_result(use_item("agua de vida"))
				did_action = advs() > a
			end
		}
	}

	add_task {
		when = estimate_max_spleen() - spleen() >= 4 and have_item("Game Grid token") and level() >= 4,
		task = {
			message = "use coffee pixie stick",
			nobuffing = true,
			action = script.coffee_pixie_stick
		}
	}

	add_task {
		prereq = have_item("Teachings of the Fist"),
		message = "use fist scroll",
		action = function()
			clear_cached_skills()
			use_item("Teachings of the Fist")
			if have_item("Teachings of the Fist") then
				critical "Failed to use teachings of the fist"
			end
			did_action = true
			return result, resulturl, did_action
		end
	}

	add_task {
		when = have_item("Knob Goblin encryption key") and have_item("Cobb's Knob map"),
		task = {
			message = "decrypt knob map",
			nobuffing = true,
			action = function()
				set_result(use_item("Cobb's Knob map"))
				refresh_quest()
				if not quest_text("haven't figured out how to decrypt it yet") then
					did_action = true
				end
			end
		}
	}

	add_task {
		when = challenge == "boris" and cached_stuff.trained_boris_skills_level ~= level(),
		task = {
			message = "train boris skill",
			nobuffing = true,
			action = function()
				local borispt = get_page("/da.php", { place = "gate1" })
				local boris_skills = {
					{ "Demand Sandwich", 3 },
					{ "Legendary Girth", 3 },
					{ "Song of the Glorious Lunch", 3 },
					{ "Cleave", 1 },
					{ "Big Boned", 3 },
					{ "Legendary Appetite", 3 },
					{ "Intimidating Bellow", 2 },
					{ "Legendary Bravado", 2 },
					{ "Song of Accompaniment", 2 },
					{ "Big Lungs", 2 },
					{ "Song of Solitude", 2 },
					{ "Good Singing Voice", 2 },
					{ "Song of Fortune", 2 },
					{ "Louder Bellows", 2 },
					{ "Song of Battle", 2 },
					{ "Banishing Shout", 2 },
					{ "Heroic Belch", 3 },
					{ "Hungry Eyes", 3 },
					{ "More to Love", 3 },
					{ "Barrel Chested", 3 },
					{ "Gourmand", 3 },
					{ "Ferocity", 1 },
					{ "Broadside", 1 },
					{ "Sick Pythons", 1 },
					{ "Pep Talk", 1 },
					{ "Throw Trusty", 1 },
					{ "Legendary Luck", 1 },
					{ "Song of Cockiness", 1 },
					{ "Legendary Impatience", 1 },
					{ "Bifurcating Blow", 1 },
				}
				local available_boris_points = tonumber(borispt:match("You can learn ([0-9-]+) more skill"))
				if not available_boris_points or available_boris_points <= 0 then
					cached_stuff.trained_boris_skills_level = level()
					did_action = true
				else
					local learned_boris_skills = 0
					for x in table.values(boris_skills) do
						if have_skill(x[1]) then
							learned_boris_skills = learned_boris_skills + 1
						end
					end
					local base_boris_points = learned_boris_skills + available_boris_points - level()
					print("  base boris points: ", base_boris_points)
					local boris_learn_order = boris_skills
					if base_boris_points >= 14 then
						boris_learn_order = {
							{ "Cleave", 1 },
							{ "Ferocity", 1 },
							{ "Broadside", 1 },
							{ "Sick Pythons", 1 },
							{ "Pep Talk", 1 },
							{ "Intimidating Bellow", 2 },
							{ "Legendary Bravado", 2 },
							{ "Song of Accompaniment", 2 },
							{ "Big Lungs", 2 },
							{ "Demand Sandwich", 3 },
							{ "Legendary Girth", 3 },
							{ "Song of the Glorious Lunch", 3 },
							{ "Big Boned", 3 },
							{ "Legendary Appetite", 3 },
							{ "Heroic Belch", 3 },
							{ "Hungry Eyes", 3 },
							{ "More to Love", 3 },
							{ "Barrel Chested", 3 },
							{ "Gourmand", 3 },
							{ "Song of Solitude", 2 },
							{ "Good Singing Voice", 2 },
							{ "Song of Fortune", 2 },
							{ "Louder Bellows", 2 },
							{ "Song of Battle", 2 },
							{ "Banishing Shout", 2 },
							{ "Throw Trusty", 1 },
							{ "Legendary Luck", 1 },
							{ "Song of Cockiness", 1 },
							{ "Legendary Impatience", 1 },
							{ "Bifurcating Blow", 1 },
						}
					elseif base_boris_points >= 7 then
						boris_learn_order = {
							{ "Demand Sandwich", 3 },
							{ "Legendary Girth", 3 },
							{ "Song of the Glorious Lunch", 3 },
							{ "Intimidating Bellow", 2 },
							{ "Legendary Bravado", 2 },
							{ "Song of Accompaniment", 2 },
							{ "Big Lungs", 2 },
							{ "Song of Solitude", 2 },
							{ "Big Boned", 3 },
							{ "Legendary Appetite", 3 },
							{ "Heroic Belch", 3 },
							{ "Hungry Eyes", 3 },
							{ "More to Love", 3 },
							{ "Barrel Chested", 3 },
							{ "Gourmand", 3 },
							{ "Good Singing Voice", 2 },
							{ "Song of Fortune", 2 },
							{ "Louder Bellows", 2 },
							{ "Song of Battle", 2 },
							{ "Banishing Shout", 2 },
							{ "Cleave", 1 },
							{ "Ferocity", 1 },
							{ "Broadside", 1 },
							{ "Sick Pythons", 1 },
							{ "Pep Talk", 1 },
							{ "Throw Trusty", 1 },
							{ "Legendary Luck", 1 },
							{ "Song of Cockiness", 1 },
							{ "Legendary Impatience", 1 },
							{ "Bifurcating Blow", 1 },
						}
					end
					for x in table.values(boris_learn_order) do
						if not have_skill(x[1]) then
							softcore_stoppable_action("Training boris skill: " .. tostring(x[1]))
							print("  training " .. x[1])
							post_page("/da.php", { action = "borisskill", whichtree = x[2] })
							if have_skill(x[1]) then
								did_action = true
								break
							else
								critical("Failed to train Boris skill: " .. x[1])
							end
						end
					end
				end
			end
		}
	}

	add_task {
		when = challenge == "jarlsberg" and cached_stuff.trained_jarlsberg_skills_level ~= level(),
		task = {
			message = "train jarlsberg skill",
			nobuffing = true,
			action = function()
				local function get_available_points()
					local jarlspt = get_page("/da.php", { place = "gate2" })
					return tonumber(jarlspt:match("You have ([0-9]*) skill point")) or 0
				end
				local points = get_available_points()
				if points <= 0 then
					cached_stuff.trained_jarlsberg_skills_level = level()
					did_action = true
				else
					if ascension_script_option("train skills manually") then
						stop "STOPPED: Ascension script option set to train skills manually"
					end
					local skill_list = {
						"Bake",
						"Conjure Potato",
						"Hippotatomous",
						"Boil",
						"Conjure Vegetables",
						"Chop",
						"Slice",
						"Conjure Meat Product",
						"Conjure Eggs",
						"Conjure Dough",
						"Conjure Cheese",
						"Fry",
						"Lunch Like a King",
						"Food Coma",
						"The Most Important Meal",
						"Never Late for Dinner",
						"Coffeesphere",
						"Egg Man",
						"Working Lunch",
						"Oilsphere",
						"Conjure Fruit",
						"Best Served Cold",
						"Freeze",
						"Nightcap",
						"Conjure Cream",
						"Blend",
						"Cream Puff",
						"Chocolatesphere",
						"Grill",
						"Gristlesphere",
						"Early Riser",
						"Radish Horse",
					}
					for _, x in ipairs(skill_list) do
						async_get_page("/jarlskills.php", { action = "getskill", getskid = datafile("skills")[x].skillid })
					end
					if get_available_points() < points then
						did_action = true
					else
						critical "Tried to learn Jarlsberg skills"
					end
				end
			end
		}
	}

	add_task {
		when = challenge == "boris" and ascensionstatus() ~= "Hardcore" and meat() >= 3000 and buffturns("Go Get 'Em, Tiger!") < 10,
		task = {
			message = "use ben-gal",
			nobuffing = true,
			action = function()
				script.ensure_buff_turns("Go Get 'Em, Tiger!", 20)
				did_action = buffturns("Go Get 'Em, Tiger!") >= 10
			end
		}
	}

	add_task {
		when = challenge == "boris" and have_skill("Pep Talk") and ((level() >= 3 and ascensionstatus() ~= "Hardcore") or level() >= 7) and level() < 13 and not have_intrinsic("Overconfident"),
		task = {
			message = "use pep talk",
			nobuffing = true,
			action = function()
				set_result(script.cast_buff("Pep Talk"))
				did_action = have_intrinsic("Overconfident")
			end
		}
	}

	add_task {
		when = have_item("Boris's Helm") and not have_item("Boris's Helm (askew)") and level() >= 3 and level() < 13,
		task = {
			message = "twist Boris's Helm",
			nobuffing = true,
			action = function()
				if have_equipped_item("Boris's Helm") then
					unequip_slot("hat")
				end
				set_result(use_item("Boris's Helm"))
				did_action = have_item("Boris's Helm (askew)")
			end
		}
	}

	add_task {
		when = have_item("Boris's Helm (askew)") and not have_item("Boris's Helm") and level() >= 13,
		task = {
			message = "twist Boris's Helm back",
			nobuffing = true,
			action = function()
				if have_equipped_item("Boris's Helm (askew)") then
					unequip_slot("hat")
				end
				set_result(use_item("Boris's Helm (askew)"))
				did_action = have_item("Boris's Helm")
			end
		}
	}

	add_task {
		when = challenge == "boris" and level() >= 13 and have_intrinsic("Overconfident"),
		task = {
			message = "remove pep talk",
			nobuffing = true,
			action = function()
				set_result(script.cast_buff("Pep Talk"))
				did_action = not have_intrinsic("Overconfident")
			end
		}
	}

	function ascension_automation_pull_item(name)
		softcore_stoppable_action("pulling " .. tostring(name))
		if ascension_script_option("ignore automatic pulls") then
			return
		end
		print("  pulling " .. tostring(name))
		set_result(pull_storage_items { name })
	end

	function pull_in_softcore(item)
		if not have_item(item) and not ascensionstatus("Hardcore") then
			ascension_automation_pull_item(item)
			if ascension_script_option("ignore automatic pulls") then
				return
			end
			if not have(item) then
				critical("Failed to pull " .. tostring(item))
			end
		end
	end

	function pull_in_scboris(item)
		if challenge == "boris" then
			pull_in_softcore(item)
		end
	end

	add_task {
		when = not have_item("digital key") and count("white pixel") + math.min(count("red pixel"), count("green pixel"), count("blue pixel")) >= 30,
		task = tasks.make_digital_key,
	}

	add_task {
		when = have_item("Loathing Legion necktie") and have_item("abridged dictionary") and moonsign_area() ~= "Degrassi Knoll",
		task = {
			message = "untinker dictionary",
			nobuffing = true,
			action = function()
				if not have_inventory("Loathing Legion necktie") then
					for x in table.values { "acc1", "acc2", "acc3" } do
						if equipment()[x] == get_itemid("Loathing Legion necktie") then
							unequip_slot(x)
						end
					end
				end
				async_get_page("/inv_use.php", { whichitem = get_itemid("Loathing Legion necktie"), switch = 1, fold = "Loathing Legion universal screwdriver", pwd = get_pwd() })
				async_get_page("/inv_use.php", { whichitem = get_itemid("Loathing Legion universal screwdriver"), action = "screw", dowhichitem = get_itemid("abridged dictionary"), pwd = get_pwd() })
				did_action = have_item("bridge")
			end
		}
	}

	add_task {
		when = have_item("Loathing Legion necktie") and have_item("clockwork maid") and not have_item("frilly skirt") and moonsign_area() ~= "Degrassi Knoll",
		task = {
			message = "untinker clockwork maid",
			nobuffing = true,
			action = function()
				if not have_inventory("Loathing Legion necktie") then
					for x in table.values { "acc1", "acc2", "acc3" } do
						if equipment()[x] == get_itemid("Loathing Legion necktie") then
							unequip_slot(x)
						end
					end
				end
				async_get_page("/inv_use.php", { whichitem = get_itemid("Loathing Legion necktie"), switch = 1, fold = "Loathing Legion universal screwdriver", pwd = get_pwd() })
				async_get_page("/inv_use.php", { whichitem = get_itemid("Loathing Legion universal screwdriver"), action = "screw", dowhichitem = get_itemid("clockwork maid"), pwd = get_pwd() })
				async_get_page("/inv_use.php", { whichitem = get_itemid("Loathing Legion universal screwdriver"), action = "screw", dowhichitem = get_itemid("Meat maid body"), pwd = get_pwd() })
				did_action = have_item("frilly skirt")
			end
		}
	}

	add_task {
		when = have_item("Loathing Legion necktie") and have_item("heavy metal thunderrr guitarrr"),
		task = {
			message = "untinker heavy metal thunderrr guitarrr",
			nobuffing = true,
			action = function()
				if not have_inventory("Loathing Legion necktie") then
					for x in table.values { "acc1", "acc2", "acc3" } do
						if equipment()[x] == get_itemid("Loathing Legion necktie") then
							unequip_slot(x)
						end
					end
				end
				async_get_page("/inv_use.php", { whichitem = get_itemid("Loathing Legion necktie"), switch = 1, fold = "Loathing Legion universal screwdriver", pwd = get_pwd() })
				async_get_page("/inv_use.php", { whichitem = get_itemid("Loathing Legion universal screwdriver"), action = "screw", dowhichitem = get_itemid("heavy metal thunderrr guitarrr"), pwd = get_pwd() })
				did_action = have_item("acoustic guitarrr")
			end
		}
	}

	add_task {
		when = have_item("Loathing Legion universal screwdriver"),
		task = {
			message = "turn legion screwdriver into necktie",
			nobuffing = true,
			action = function()
				get_page("/inv_use.php", { whichitem = get_itemid("Loathing Legion universal screwdriver"), switch = 1, fold = "Loathing Legion necktie", pwd = get_pwd() })
				did_action = not have_item("Loathing Legion universal screwdriver") and have_item("Loathing Legion necktie")
			end
		}
	}

	add_task {
		when = have_item("Loathing Legion moondial"),
		task = {
			message = "turn legion moondial into necktie",
			nobuffing = true,
			action = function()
				if not have_inventory("Loathing Legion moondial") then
					script.wear {}
				end
				get_page("/inv_use.php", { whichitem = get_itemid("Loathing Legion moondial"), switch = 1, fold = "Loathing Legion necktie", pwd = get_pwd() })
				did_action = have_item("Loathing Legion necktie")
			end
		}
	}

	local function want_softcore_item(item, pullname, anytime)
		add_task {
			when = not ascensionstatus("Hardcore") and not ascension_script_option("ignore automatic pulls") and not have_item(item) and not cached_stuff["ignore pull: " .. tostring(item)],
			task = {
				message = "pull " .. item,
				nobuffing = true,
				action = function()
					if have(pullname or item) then
						critical("Already have " .. tostring(pullname) .. " but not " .. tostring(item))
					end
					cached_stuff["ignore pull: " .. tostring(item)] = "yes"
					if turnsthisrun() > 50 and not anytime then
						stop("Trying to pull " .. item .. " late in the run [run again to ignore]")
					end
					ascension_automation_pull_item(pullname or item)
					if have(pullname or item) then
						did_action = true
					else
						stop("Tried to pull " .. tostring(pullname or item) .. " [run again to ignore]")
-- 						did_action = true -- try just continuing on for off-hands automation
					end
				end
			}
		}
	end
	local function want_softcore_item_oneof(itemnames)
		local descitem = itemnames[1] or "???"
		local gotone = false
		for _, x in ipairs(itemnames) do
			if have_item(x) then
				gotone = true
			end
		end
		add_task {
			when = not ascensionstatus("Hardcore") and not ascension_script_option("ignore automatic pulls") and not gotone and not cached_stuff["ignore pull: " .. tostring(descitem)],
			task = {
				message = "pull " .. descitem,
				nobuffing = true,
				action = function()
					cached_stuff["ignore pull: " .. tostring(descitem)] = "yes"
					if turnsthisrun() > 50 then
						stop("Trying to pull " .. descitem .. " late in the run [run again to ignore]")
					end
					for _, x in ipairs(itemnames) do
						ascension_automation_pull_item(x)
						if have_item(x) then
							did_action = true
							return
						end
					end
					stop("Tried to pull " .. descitem .. " [run again to ignore]")
				end
			}
		}
	end
	want_scboris_item = want_softcore_item

	want_softcore_item("Rain-Doh indigo cup", "can of Rain-Doh")
	want_softcore_item("Juju Mojo Mask")
	want_softcore_item_oneof { "Loathing Legion necktie", "Loathing Legion abacus", "Loathing Legion can opener", "Loathing Legion chainsaw", "Loathing Legion corkscrew", "Loathing Legion defibrillator", "Loathing Legion double prism", "Loathing Legion electric knife", "Loathing Legion hammer", "Loathing Legion helicopter", "Loathing Legion jackhammer", "Loathing Legion kitchen sink", "Loathing Legion knife", "Loathing Legion many-purpose hook", "Loathing Legion moondial", "Loathing Legion pizza stone", "Loathing Legion rollerblades", "Loathing Legion tape measure", "Loathing Legion tattoo needle", "Loathing Legion universal screwdriver" }
	want_softcore_item("plastic vampire fangs")
	want_softcore_item_oneof { "stinky cheese diaper", "stinky cheese wheel", "stinky cheese eye", "Staff of Queso Escusado", "stinky cheese sword" }
	want_softcore_item("Greatest American Pants")
	want_softcore_item("Camp Scout backpack")
	want_softcore_item_oneof { "Jekyllin hide belt", "Mr. Accessory Jr.", "astral mask" }
	want_softcore_item_oneof { "Boris's Helm (askew)", "Boris's Helm", "Spooky Putty mitre" }
	if can_wear_weapons() and not have_item("Jarlsberg's pan (Cosmic portal mode)") and not have_item("Jarlsberg's pan") then
		want_softcore_item("Operation Patriot Shield")
	end
	if ascensionpath("Avatar of Jarlsberg") then
		want_softcore_item("ring of conflict")
	end

	add_task {
		when = ascensionstatus() ~= "Hardcore" and
			moonsign_area() == "Gnomish Gnomad Camp" and
			not unlocked_beach(),
		task = {
			message = "unlock beach (early with bus pass for gnomad camp)",
			nobuffing = true,
			action = function()
				if meat() >= 5000 then
					buy_item("Desert Bus pass", "m")
					did_action = have_item("Desert Bus pass")
				elseif have_item("facsimile dictionary") then
					sell_item("facsimile dictionary")
					did_action = meat() >= 5000
				else
					pull_in_softcore("facsimile dictionary")
					did_action = have_item("facsimile dictionary")
				end
			end
		}
	}

	add_task {
		when = ascensionstatus() ~= "Hardcore" and moonsign_area() == "Gnomish Gnomad Camp" and not have_skill("Torso Awaregness") and meat() >= 10000,
		task = {
			message = "learn Torso Awaregness",
			nobuffing = true,
			action = function()
				post_page("/gnomes.php", { action = "trainskill", whichskill = 12 })
				did_action = have_skill("Torso Awaregness")
			end
		}
	}

	add_task {
		when = ascensionstatus() ~= "Hardcore" and moonsign_area() == "Gnomish Gnomad Camp" and not have_skill("Powers of Observatiogn") and meat() >= 10000,
		task = {
			message = "learn Powers of Observatiogn",
			nobuffing = true,
			action = function()
				post_page("/gnomes.php", { action = "trainskill", whichskill = 10 })
				did_action = have_skill("Powers of Observatiogn")
			end
		}
	}

	add_task {
		when = challenge == "boris" and moonsign_area() == "Gnomish Gnomad Camp" and not have_item("Clancy's crumhorn") and clancy_instrumentid() ~= 2 and meat() >= 5000,
		task = {
			message = "buy crumhorn",
			nobuffing = true,
			action = function()
				buy_item("Clancy's crumhorn", "p")
				did_action = have_item("Clancy's crumhorn")
			end
		}
	}

	add_task {
		when = not unlocked_island() and count_item("skeleton") >= 7,
		task = {
			message = "make skiff",
			nobuffing = true,
			action = function()
				use_item("skeleton", 7)
				did_action = unlocked_island()
			end
		}
	}

	-- TODO: make into separate tasks
	if quest("The Final Ultimate Epic Final Conflict") and quest_text("You've come to an odd junction in the cave leading to the Sorceress' Lair") then
		if not have_item("stone tablet (Really Evil Rhythm)") and have_item("skeleton key") and quest_text("solve a really convoluted and contrived puzzle involving a cloud of gas") then
			inform "do skeleton key"
			script.maybe_ensure_buffs { "A Few Extra Pounds" }
			while true do
				if hp() <= 60 and hp() < maxhp() then
					script.heal_up()
				end
				local before_hp = hp()
				async_post_page("/lair2.php", { prepreaction = "skel" })
				if have_item("stone tablet (Really Evil Rhythm)") or hp() >= before_hp then
					break
				end
			end
			if have_item("stone tablet (Really Evil Rhythm)") then
				did_action = true
			end
		elseif countif("Boris's key") + countif("Jarlsberg's key") + countif("Sneaky Pete's key") < 3 and not have_item("makeshift SCUBA gear") then
			-- TODO: if not enough fat loot tokens, and no wand, hmm(?)
			inform "trading for legend keys"
			for _, x in ipairs { "Boris's key", "Jarlsberg's key", "Sneaky Pete's key" } do
				if not have_item(x) then
					shop_buyitem(x, "damachine")
				end
			end
			if countif("Boris's key") + countif("Jarlsberg's key") + countif("Sneaky Pete's key") >= 3 then
				did_action = true
			end
		else
			inform "TODO: finish lair"
			if challenge == "fist" then
				script.ensure_buffs { "Earthen Fist" }
			end
			result, resulturl = get_page("/lair2.php", { action = "statues" })
			local missing_stuff = automate_lair_statues(result)
			if missing_stuff then
				result, resulturl = get_page("/lair2.php")
				result = add_message_to_page(get_result(), "TODO: finish lair<br><br>" .. table.concat(missing_stuff, ", "), nil, "darkorange")
				did_action = false
				finished = true
			else
				did_action = true
			end
		end
		return result, resulturl, did_action
	end

	add_task {
		when = challenge == "boris" and
			daysthisrun() == 1 and
			ascensionstatus() ~= "Hardcore" and
			count_item("Moon Pie") >= 4 and
			have_item("Wrecked Generator") and
			count_item("milk of magnesium") >= 2 and
			fullness() == 0 and
			not script.get_turns_until_sr() and
			level() >= 5,
		task = {
			message = "eat moon pies and fortune cookie",
			nobuffing = true,
			action = function()
				if not have_item("fortune cookie") then
					buy_item("fortune cookie", "m")
				end
				if not have_item("fortune cookie") then
					critical "Failed to buy fortune cookie"
				end
				script.ensure_buff_turns("Song of the Glorious Lunch", 11)
				if not have_buff("Got Milk") then
					use_item("milk of magnesium")
				end
				set_result(eat_item("fortune cookie")())
				set_result(eat_item("Moon Pie")())
				set_result(eat_item("Moon Pie")())
				did_action = script.get_turns_until_sr() and fullness() == 11
			end
		}
	}

	add_task {
		when = challenge == "boris" and
			daysthisrun() == 1 and
			ascensionstatus() ~= "Hardcore" and
			count_item("Moon Pie") >= 2 and
			have_item("Wrecked Generator") and
			count_item("milk of magnesium") >= 1
			and fullness() == 11 and
			not script.get_turns_until_sr() and
			level() >= 5 and
			count_item("tasty tart") >= 2,
		task = {
			message = "eat tasty tarts and fortune cookie",
			nobuffing = true,
			action = function()
				if not have_item("fortune cookie") then
					buy_item("fortune cookie", "m")
				end
				if not have_item("fortune cookie") then
					critical "Failed to buy fortune cookie"
				end
				script.ensure_buff_turns("Song of the Glorious Lunch", 3)
				set_result(eat_item("fortune cookie")())
				set_result(eat_item("tasty tart")())
				set_result(eat_item("tasty tart")())
				did_action = script.get_turns_until_sr() and fullness() == 14
			end
		}
	}

	add_task {
		when = challenge == "boris" and
			daysthisrun() == 1 and
			ascensionstatus() ~= "Hardcore" and
			count_item("Moon Pie") >= 2 and
			have_item("Wrecked Generator") and
			count_item("milk of magnesium") >= 1 and
			fullness() == 19 and
			level() >= 7 and
			count_item("tasty tart") >= 1 and
			have_skill("Stomach of Steel") and
			estimate_max_fullness() - fullness() == 11,
		task = {
			message = "eat moon pies after stomach",
			nobuffing = true,
			action = function()
				script.ensure_buff_turns("Song of the Glorious Lunch", 10)
				if not have_buff("Got Milk") then
					use_item("milk of magnesium")
				end
				set_result(eat_item("Moon Pie")())
				set_result(eat_item("Moon Pie")())
				did_action = fullness() == 29
			end
		}
	}

	-- TODO: make task
	if have_buff("Teleportitis") then
		if have_item("plus sign") then
			script.want_familiar "Pair of Stomping Boots"
			stop "TODO: find oracle"
		else
			stop "TODO: Wear off teleportitis"
		end
	end

	add_task {
		when = challenge == "zombie" and
			ascensionstatus() == "Hardcore" and
			have_skill("Neurogourmet") and
			(have_item("hunter brain") or have_item("boss brain")) and
			fullness() < estimate_max_fullness() and
			(have_skill("Stomach of Steel") or fullness() + 5 <= estimate_max_fullness()),
		task = {
			message = "eat epic brain",
			action = function()
				local a = advs()
				eat_item("hunter brain")
				eat_item("boss brain")
				did_action = (advs() > a)
			end,
		}
	}

	add_task {
		when = challenge == "zombie" and
			ascensionstatus() == "Hardcore" and
			have_skill("Neurogourmet") and
			have_skill("Stomach of Steel") and
			have_item("good brain") and
			fullness() + 5 <= estimate_max_fullness(),
		task = {
			message = "eat good brain",
			action = function()
				local a = advs()
				eat_item("good brain")
				did_action = (advs() > a)
			end,
		}
	}

	-- start of turn-spending things

	add_task {
		when = level() >= 6 and
			(level() < 13 or quest("Make War, Not... Oh, Wait") or quest("The Rain on the Plains is Mainly Garbage") or quest_text("Quest for the Holy MacGuffin")) and
			advs() <= 20 and
			fullness() == estimate_max_fullness() and
			drunkenness() == estimate_max_safe_drunkenness(),
		task = {
			message = "end of day",
			nobuffing = true,
			action = function()
				if not have_item("time halo") then
					script.ensure_mp(2)
					summon_clipart("time halo")
				end
				script.wear { acc1 = first_wearable { "time halo" }, acc2 = first_wearable { "dead guy's watch" }, acc3 = first_wearable { "gold wedding ring" } }

				if ascension_script_option("overdrink with nightcap") then
					if can_drink_normal_booze() then
						script.maybe_ensure_buffs { "Ode to Booze" }
						if have_buff("Ode to Booze") then
							script.ensure_buff_turns("Ode to Booze", 10)
						end
						if not have_item("bucket of wine") then
							script.ensure_mp(2)
							summon_clipart("bucket of wine")
						end
						if buffturns("Ode to Booze") >= 10 and have_item("bucket of wine") then
							set_result(drink_item("bucket of wine"))
							result = add_message_to_page(get_result(), "<p>Overdrunk, finished day. (Do PvP?)</p>", "Ascension script:")
							finished = true
							return
						end
					end
				end
				result, resulturl = get_page("/inventory.php", { which = 1 })
				result = add_message_to_page(get_result(), "<p>End of day.</p><p>(PvP?,) cast ode and overdrink, then done.</p>", "Ascension script:")
				finished = true
			end
		}
	}

	local want_advs = 0
	if highskill_at_run or challenge then
		want_advs = 5
	else
		want_advs = 10
	end

	add_task {
		when = advs() < want_advs,
		task = {
			message = "low on adventures",
			nobuffing = true,
			action = function()
				local final_eating = (estimate_max_fullness() - fullness()) <= 3 and (estimate_max_safe_drunkenness() - drunkenness()) <= 3
				result, resulturl, ate = script.eat_food(final_eating)
				if ate then
					did_action = true
				else
					stop("Fewer than " .. tostring(want_advs) .. " adventures left")
				end
			end
		}
	}

	do
		local pt, pturl, did_sr = script.check_sr()
		if pt and pturl then
			return pt, pturl, did_sr
		end
	end
	if not turns_to_next_sr then
		turns_to_next_sr = 1000000
	end

	local use_new_faxing = ascensionpath("BIG!") and script.have_familiar("Obtuse Angel")

	add_task {
		when = use_new_faxing and not cached_stuff.handled_icy_peak and can_photocopy(),
		task = function()
			local mc = get_page("/mclargehuge.php")
			if mc:contains("cloudypeak.gif") and not have_item("ninja rope") and not have_item("ninja crampons") and not have_item("ninja carabiner") then
				if script.get_photocopied_monster() ~= "ninja snowman assassin" then
					return {
						message = "get assassin from faxbot",
						action = function()
							script.get_faxbot_fax("ninja snowman assassin")
							did_action = true
						end
					}
				else
					return {
						message = "fight and arrow assassin",
						action = function()
							script.heal_up()
							script.ensure_mp(30)
							script.want_familiar "Obtuse Angel"
							set_result(use_item("photocopied monster"))
							if get_result():contains("You don't think you can handle another one of these things today") then
								cached_stuff.have_faxed_today = true
								did_action = true
								return
							end
							local pt, url = get_page("/fight.php")
							result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_romanticarrow)
							if resulturl:contains("fight.php") then
								cached_stuff.have_faxed_today = true
							end
							if advagain then
								did_action = true
								cached_stuff.handled_icy_peak = true
							end
						end
					}
				end
			else
				return {
					message = "icy peak is already handled",
					action = function()
						cached_stuff.handled_icy_peak = true
						did_action = true
					end
				}
			end
		end,
	}

	add_task {
		when = use_new_faxing and not cached_stuff.handled_smut_orcs and can_photocopy() and false,
		task = function()
			local oc = get_page("/place.php", { whichplace = "orc_chasm" })
			if oc:contains("nobridge.gif") and not have_item("smut orc keepsake box") then
				if script.get_photocopied_monster() ~= "smut orc pervert" then
					return {
						message = "get pervert from faxbot",
						action = function()
							script.get_faxbot_fax("smut orc pervert")
							did_action = true
						end
					}
				else
					return {
						message = "fight and arrow pervert",
						action = function()
							script.heal_up()
							script.ensure_mp(30)
							script.want_familiar "Obtuse Angel"
							set_result(use_item("photocopied monster"))
							if get_result():contains("You don't think you can handle another one of these things today") then
								cached_stuff.have_faxed_today = true
								did_action = true
								return
							end
							local pt, url = get_page("/fight.php")
							result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_romanticarrow)
							if resulturl:contains("fight.php") then
								cached_stuff.have_faxed_today = true
							end
							if advagain then
								did_action = true
								cached_stuff.handled_smut_orcs = true
							end
						end
					}
				end
			else
				return {
					message = "smut orcs are already handled",
					action = function()
						cached_stuff.handled_smut_orcs = true
						did_action = true
					end
				}
			end
		end,
	}

	add_task {
		when = use_new_faxing and not cached_stuff.handled_lfms and can_photocopy(),
		task = function()
			if not completed_sonofa_beach() and not have_item("barrel of gunpowder") then
				if script.get_photocopied_monster() ~= "lobsterfrogman" then
					return {
						message = "get lfm from faxbot",
						action = function()
							script.get_faxbot_fax("lobsterfrogman")
							did_action = true
						end
					}
				else
					return {
						message = "fight and arrow lfm",
						action = function()
							script.heal_up()
							script.ensure_mp(30)
							script.want_familiar "Obtuse Angel"
							set_result(use_item("photocopied monster"))
							if get_result():contains("You don't think you can handle another one of these things today") then
								cached_stuff.have_faxed_today = true
								did_action = true
								return
							end
							local pt, url = get_page("/fight.php")
							result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_romanticarrow)
							if resulturl:contains("fight.php") then
								cached_stuff.have_faxed_today = true
							end
							if advagain then
								did_action = true
								cached_stuff.handled_lfms = true
							end
						end
					}
				end
			else
				return {
					message = "lfms are already handled",
					action = function()
						cached_stuff.handled_lfms = true
						did_action = true
					end
				}
			end
		end,
	}

	add_task {
		when = challenge == "zombie" and
			level() < 6 and
			get_daily_counter("zombie.bear arm Bear Hugs used") < 10 and
			have_item("right bear arm") and have_item("left bear arm") and
			have_skill("Hunter's Sprint"),
		task = tasks.do_bearhug_sewerleveling,
	}

	add_task {
		when = challenge == "boris" and quest("The Minstrel Cycle") and quest_text("Clancy would like you to take him to the Typical Tavern"),
		task = {
			message = "clancy barroom brawl",
			bonus_target = { "item" },
			action = adventure {
				zoneid = 233,
				macro_function = macro_softcore_boris,
			},
		}
	}

	add_task {
		when = challenge == "boris" and quest("The Minstrel Cycle") and quest_text("Clancy would like you to take him to the Knob Shaft") and have_item("Cobb's Knob lab key"),
		task = {
			message = "clancy knob shaft",
			action = adventure {
				zoneid = 101,
				macro_function = macro_softcore_boris,
			},
		}
	}

	add_task {
		when = challenge == "boris" and
			quest("The Minstrel Cycle") and
			quest_text("Clancy would like you to take him to the Knob Shaft") and
			(not have_item("Cobb's Knob lab key") or quest("The Goblin Who Wouldn't Be King")),
		task = {
			message = "kill goblin king",
			action = function()
				if ascensionstatus() == "Hardcore" then
					stop "TODO: Kill goblin king in HCBoris"
				end
				pull_in_scboris("Knob Goblin harem veil")
				pull_in_scboris("Knob Goblin harem pants")
				script.wear { hat = "Knob Goblin harem veil", pants = "Knob Goblin harem pants" }
				if have_buff("Knob Goblin Perfume") then
					inform "fight king in harem girl outfit"
					script.ensure_mp(20)
					script.want_familiar "Frumious Bandersnatch"
					set_mcd(7) -- TODO: moxie-specific
					local pt, url = get_page("/cobbsknob.php", { action = "throneroom" })
					result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_softcore_boris)
					did_action = advagain
				elseif have_item("Knob Goblin perfume") then
					use_item("Knob Goblin perfume")
					if have_buff("Knob Goblin Perfume") then
						did_action = true
					end
				else
					result, resulturl, advagain = autoadventure { zoneid = 259 }
					if have_buff("Knob Goblin Perfume") then
						did_action = true
					end
				end
			end,
		}
	}

	-- TODO: generalize
	add_task {
		when = challenge == "boris" and
			quest("The Goblin Who Wouldn't Be King") and
			have_item("Knob Goblin harem veil") and have_item("Knob Goblin harem pants"),
		task = {
			message = "kill goblin king",
			action = function()
				script.wear { hat = "Knob Goblin harem veil", pants = "Knob Goblin harem pants" }
				if have_buff("Knob Goblin Perfume") then
					inform "fight king in harem girl outfit"
					script.ensure_mp(20)
					script.want_familiar "Frumious Bandersnatch"
					set_mcd(7) -- TODO: moxie-specific
					local pt, url = get_page("/cobbsknob.php", { action = "throneroom" })
					result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_softcore_boris)
					did_action = advagain
				elseif have_item("Knob Goblin perfume") then
					use_item("Knob Goblin perfume")
					if have_buff("Knob Goblin Perfume") then
						did_action = true
					end
				else
					result, resulturl, advagain = autoadventure { zoneid = 259 }
					if have_buff("Knob Goblin Perfume") then
						did_action = true
					end
				end
			end,
		}
	}

	add_task {
		when = challenge == "boris" and quest("The Minstrel Cycle") and quest_text("Clancy would like you to find the grave of The Luter"),
		task = {
			message = "clancy fight luter",
			action = function()
				local pt, url = get_page("/place.php", { whichplace = "plains", action = "lutersgrave" })
				result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_softcore_boris)
				did_action = have_item("Clancy's lute")
			end
		}
	}

	add_task {
		when = challenge == "boris" and level() >= 7 and not have_item("Clancy's lute") and clancy_instrumentid() ~= 3,
		task = {
			message = "get clancy quest",
			nobuffing = true,
			action = function()
				if clancy_wantsattention() then
					result, resulturl = get_page("/main.php", { action = "clancy" })
					result, resulturl = handle_adventure_result(result, resulturl, "?", nil, {
						["Your Minstrel Vamps"] = "Let Us Forthrightly Go Forthwith",
						["Your Minstrel Clamps"] = "Go Down to the Old Mine",
						["Your Minstrel Stamps"] = "Let's Go Save the Lute!",
					})
					did_action = not clancy_wantsattention()
				else
					stop "TODO: do clancy quests to get lute"
				end
			end
		}
	}

	add_task {
		prereq = quest_text("this is Azazel in Hell") and challenge == "boris" and daysthisrun() == 1 and (have("Clancy's lute") or clancy_instrumentid() == 3) and estimate_max_fullness() - fullness() >= 5,
		f = script.do_azazel,
	}

	add_task {
		when = challenge == "boris" and
			daysthisrun() == 1 and
			estimate_max_safe_drunkenness() - drunkenness() >= 2 and
			have_item("bottle of rum") and
			(have_item("peppermint sprout") or have_item("peppermint twist")) and
			level() >= 2 and
			meat() >= 2000 and
			not have_item("Crimbojito"),
		task = {
			message = "mix Crimbojito",
			nobuffing = true,
			action = function()
				if not have_item("peppermint twist") then
					use_item("peppermint sprout")
				end
				set_result(mix_items("bottle of rum", "peppermint twist"))
				did_action = have_item("Crimbojito")
			end
		}
	}

	add_task {
		prereq = want_shore() and
			challenge == "boris" and
			not unlocked_island() and
			turns_to_next_sr >= 5 and
			(have("Clancy's lute") or clancy_instrumentid() == 3),
		f = script.get_dinghy,
	}

	add_task {
		prereq = challenge == "boris" and
			not have_item("The Big Book of Pirate Insults") and not have_item("pirate fledges") and unlocked_island() and
			not quest_text("successfully joined Cap'm Caronch's crew") and not ascension["zone.pirates.insults"] and
			basemysticality() >= 25 and basemoxie() >= 25,
		f = function()
			use_dancecard()
			script.get_big_book_of_pirate_insults()
		end
	}

	add_task {
		when = tonumber(ascension["dance card turn"]) == turnsthisrun(),
		task = tasks.rotting_matilda,
	}

	local want_starting_items = classid() < 10 and (not AT_song_duration() or not have_item("turtle totem") or not have_item("saucepan") or (not have_item("seal tooth") and challenge ~= "fist" and challenge ~= "zombie"))

	add_task {
		when = want_starting_items and meat() >= 200,
		task = tasks.get_starting_items,
	}

	add_task {
		when = have_item("strange leaflet") and not cached_stuff.used_strange_leaflet,
		task = {
			message = "using strange leaflet",
			nobuffing = true,
			action = function()
				result, resulturl = get_page("/leaflet.php", { justgothere = "yes" })
				if get_result():contains("You are standing in an open field west of a white house.") then
					result, resulturl = do_leaflet()
					result, resulturl = get_page("/leaflet.php", { justgothere = "yes" })
				elseif get_result():contains("The two giant shot glasses have been knocked over") then
				else
					critical "Unexpected strange leaflet status"
				end
				cached_stuff.used_strange_leaflet = true
				did_action = get_result():contains("The two giant shot glasses have been knocked over")
			end
		}
	}

	add_task {
		when = not have_item("digital key") and trailed == "Blooper" and ascensionstatus() == "Hardcore",
		task = tasks.do_8bit_realm,
	}

	if highskill_at_run then
		local day1spleenfam = "Rogue Program"
		local day1spleenfam_macro_function = macro_stasis
		local day1spleenfam_buffs = { "The Moxious Madrigal", "The Magical Mojomuscular Melody" }
		local day1spleenfam_minmp = 5
		if have_item("spangly mariachi pants") and spleen() < 12 then
			day1spleenfam = "Bloovian Groose"
			day1spleenfam_macro_function = macro_autoattack
			day1spleenfam_buffs = { "The Moxious Madrigal", "Power Ballad of the Arrowsmith" }
			day1spleenfam_minmp = 10
		end
		if spleen() >= 12 and mp() >= 35 then
			day1spleenfam = "Mini-Hipster"
			day1spleenfam_macro_function = macro_stasis
			day1spleenfam_buffs = { "The Moxious Madrigal", "The Magical Mojomuscular Melody" }
			day1spleenfam_minmp = 30
		end
		if fullness() <= 1 and (ascension["familiar.organ grinder.bit types"] or {}).boss then
			day1spleenfam = "Knob Goblin Organ Grinder"
			day1spleenfam_macro_function = macro_autoattack
			day1spleenfam_buffs = { "The Moxious Madrigal", "Power Ballad of the Arrowsmith" }
			day1spleenfam_minmp = 10
		end

		local function count_mixed_swill()
			return count("blended frozen swill") + count("fruity girl swill") + count("tropical swill")
		end

		if not have_item("spangly mariachi pants") and familiarid() ~= 152 then
			async_get_page("/familiar.php", { pwd = get_pwd(), action = "unequip", famid = 152 })
		end

		add_task {
			when = not have_item("shining halo"),
			task = {
				message = "summon shining halo",
				action = function()
					script.ensure_mp(2)
					async_post_page("/campground.php", { preaction = "summoncliparts" })
					async_post_page("/campground.php", { pwd = get_pwd(), action = "bookshelf", preaction = "combinecliparts", clip1 = "01", clip2 = "06", clip3 = "06" })
					did_action = have_item("shining halo")
				end
			}
		}

		add_task {
			when = not have_item("studded leather boxer shorts"),
			task = {
				message = "buying studded leather boxer shorts",
				action = function()
					buy_item("studded leather boxer shorts", "z")
					did_action = have_item("studded leather boxer shorts")
				end
			}
		}

		-- consumption

		add_task {
			-- TODO: do it only on day 1, revamp day 2+ eating?
			when = not ascension["fortune cookie numbers"] and fullness() <= 2,
			task = {
				message = "eat fortune cookie",
				action = function()
					if not have_item("fortune cookie") then
						buy_item("fortune cookie", "m")
					end
					set_result(eat_item("fortune cookie")())
					did_action = ascension["fortune cookie numbers"]
				end
			}
		}

		add_task {
			when = have_item("badass pie") and level() >= 4 and level() < 6 and fullness() <= 1,
			task = {
				message = "eat badass pie",
				action = function()
					eat_item("badass pie")
					did_action = fullness() >= 2
				end
			}
		}

		local function drink_swill()
			if drunkenness() + 4 > estimate_max_safe_drunkenness() then
				critical "Too drunk to safely drink mixed swill"
			end
			script.ensure_buffs { "Ode to Booze" }
			script.ensure_buff_turns("Ode to Booze", 4)
			if have_item("blended frozen swill") then
				set_result(drink_item("blended frozen swill"))
			elseif have_item("fruity girl swill") then
				set_result(drink_item("fruity girl swill"))
			elseif have_item("tropical swill") then
				set_result(drink_item("tropical swill"))
			end
		end

		add_task {
			when = (daysthisrun() == 1) and drunkenness() <= 4 and count_mixed_swill() >= 2,
			task = {
				message = "drink swill day 1",
				action = function()
					drink_swill()
					if drunkenness() <= 4 then
						drink_swill()
					end
					did_action = drunkenness() >= 5
				end
			}
		}

		add_task {
			when = (daysthisrun() == 1) and drunkenness() <= 10 and count_mixed_swill() >= 1 and count("distilled fortified wine") >= 2,
			task = {
				message = "drink rest for day 1",
				action = function()
					drink_swill()
					for i = 1, 10 do
						if drunkenness() < estimate_max_safe_drunkenness() then
							script.ensure_buffs { "Ode to Booze" }
							set_result(drink_item("distilled fortified wine"))
						end
					end
					did_action = drunkenness() == estimate_max_safe_drunkenness()
				end
			}
		}

		add_task {
			when = (daysthisrun() == 1) and drunkenness() <= 12 and have_item("Typical Tavern swill"),
			task = {
				message = "mix swill booze",
				action = function()
					for i = 1, 5 do
						script.ensure_mp(10)
						cast_skillid(5014, 1) -- advanced cocktailcrafting
					end
					local c = count_mixed_swill()
					if have_item("magical ice cubes") then
						set_result(mix_items("Typical Tavern swill", "magical ice cubes"))
					elseif have_item("little paper umbrella") then
						set_result(mix_items("Typical Tavern swill", "little paper umbrella"))
					elseif have_item("coconut shell") then
						set_result(mix_items("Typical Tavern swill", "coconut shell"))
					end
					if count_mixed_swill() > c then
						did_action = true
					end
				end
			}
		}

		add_task {
			when = (daysthisrun() == 1) and fullness() <= estimate_max_fullness() - 6 and (have("Hell ramen") or have_item("Hell broth") or have_item("hellion cube")),
			task = {
				message = "eat hell ramen day 1",
				action = function()
					if have_item("Hell ramen") then
						local a = advs()
						set_result(eat_item("Hell ramen"))
						did_action = (advs() > a)
					else
						result, resulturl, did_action = script.make_reagent_pasta()
					end
				end
			}
		}

		-- adventuring

		add_task {
			when = not cached_stuff.mox_guild_is_open,
			task = function()
				async_get_page("/guild.php", { place = "challenge" })
				local guildpt = get_page("/guild.php")
				if guildpt:match("scg") then
					cached_stuff.mox_guild_is_open = true
					return {
						message = "already opened guild store",
						action = function() did_action = true end,
					}
				else
-- 					if not quest("Suffering For His Art") then
-- 						async_get_page("/town_wrong.php", { place = "artist" })
-- 						async_post_page("/town_wrong.php", { place = "artist", getquest = 1 })
-- 					end
					script.maybe_ensure_buffs { "Cat-Alyzed" }
					return {
						message = "do mox guild quest",
						fam = day1spleenfam,
						buffs = day1spleenfam_buffs,
						minmp = day1spleenfam_minmp,
						action = adventure {
							zoneid = 112,
							macro_function = day1spleenfam_macro_function,
							noncombats = {
								["Now's Your Pants!  I Mean... Your Chance!"] = "Yoink!",
								["Aww, Craps"] = "Walk away",
								["Dumpster Diving"] = "Punch the hobo",
								["The Entertainer"] = "Introduce them to avant-garde",
								["Under the Knife"] = "Umm, no thanks.  Seriously.",
								["Please, Hammer"] = "&quot;Sure, I'll help.&quot;",
							}
						}
					}
				end
			end
		}

		add_task {
			when = cached_stuff.mox_guild_is_open and not cached_stuff.used_all_still_charges and not have_item("tonic water"),
			task = {
				message = "distill tonic water",
				action = function()
					result, resulturl = post_page("/guild.php", { place = "still" })
					local lights = tonumber(get_result():match("black readout with ([0-9]*) bright green lights on it"))
					if lights and (daysthisrun() == 1 or lights > 6) then
						if not have_item("soda water") then
							buy_item("soda water", "m", 1)
						end
						if not have_item("soda water") then
							critical "Failed to buy soda water"
						end
						async_post_page("/guild.php", { action = "stillfruit", whichitem = get_itemid("soda water"), quantity = 1 })
					end
					if not have_item("tonic water") then
						cached_stuff.used_all_still_charges = true
					end
					did_action = true
				end
			}
		}

		add_task {
			when = quest("Ooh, I Think I Smell a Bat."),
			task = {
				message = "do bat quest",
				nobuffing = true,
				action = function()
					script.maybe_ensure_buffs { "Spirit of Garlic" }
					return script.do_boss_bat(macro_noodlecannon, 20)
				end,
			}
		}

		add_task {
			when = not have_item("Knob Goblin encryption key") and
				not unlocked_knob(),
			task = {
				message = "get encryption key",
				fam = day1spleenfam,
				buffs = day1spleenfam_buffs,
				minmp = day1spleenfam_minmp,
				action = adventure {
					zoneid = 114,
					macro_function = day1spleenfam_macro_function,
					noncombats = {
						["Up In Their Grill"] = "Grab the sausage, so to speak.  I mean... literally.",
						["Knob Goblin BBQ"] = "Kick the chef",
						["Ennui is Wasted on the Young"] = "&quot;Since you're bored, you're boring.  I'm outta here.&quot;",
						["Malice in Chains"] = "Plot a cunning escape",
						["When Rocks Attack"] = "&quot;Sorry, gotta run.&quot;",
					}
				},
				after_action = function()
					if have_item("Knob Goblin encryption key") then
						did_action = true
					end
				end
			}
		}

		add_task {
			when = quest("Ooh, I Think I Smell a Rat"),
			task = {
				message = "do rat cellar",
				action = function()
					return script.do_tavern({ "Scarecrow with Boss Bat britches", "Rogue Program" }, 20, macro_noodlecannon)
				end
			}
		}

		add_task {
			when = quest("Trial By Friar"),
			task = {
				message = "do friars quest",
				action = script.do_friars,
			}
		}

		add_task {
			when = quest_text("this is Azazel in Hell") and (daysthisrun() == 1 or (daysthisrun() <= 2 and ascensionstatus() == "Hardcore")),
			task = {
				message = "do azazel quest",
				action = script.do_azazel,
			}
		}

		-- TODO: automate
		add_task {
			when = DD_keys < 1 and level() >= 6,
			task = {
				message = "get DD key",
				action = function()
					stop "TODO: get DD key day 1"
				end
			}
		}

		add_task {
			when = quest("Looking for a Larva in All the Wrong Places"),
			task = {
				message = "find larva",
				fam = day1spleenfam,
				buffs = day1spleenfam_buffs,
				minmp = day1spleenfam_minmp,
				action = adventure {
					zoneid = 15,
					macro_function = day1spleenfam_macro_function,
					noncombats = {
						["Arboreal Respite"] = "Explore the stream",
						["Consciousness of a Stream"] = "March to the marsh",
					}
				}
			}
		}

		add_task {
			when = not cached_stuff.unlocked_manor and not have_item("Spookyraven library key"),
			task = function()
				local townright = get_page("/town_right.php")
				if townright:contains("The Haunted Pantry") then
					return {
						message = "unlock manor",
						fam = day1spleenfam,
						buffs = day1spleenfam_buffs,
						minmp = day1spleenfam_minmp,
						action = adventure {
							zoneid = 113,
							macro_function = day1spleenfam_macro_function,
							noncombats = {
								["Oh No, Hobo"] = "Give him a beating",
								["Trespasser"] = "Tackle him",
								["The Singing Tree"] = "&quot;No singing, thanks.&quot;",
								["The Baker's Dilemma"] = "&quot;Sorry, I'm busy right now.&quot;",
							}
						},
						after_action = function()
							if get_result():contains("The Manor in Which You're Accustomed") then
								did_action = true
							end
						end
					}
				else
					cached_stuff.unlocked_manor = true
					return {
						message = "already unlocked manor",
						action = function() did_action = true end,
					}
				end
			end
		}

		add_task {
			prereq = not have_item("Spookyraven library key"),
			f = script.get_library_key,
		}

		add_task {
			when = not cached_stuff.unlocked_upstairs and not have_item("Spookyraven ballroom key"),
			task = function()
				local manor = get_page("/manor.php")
				if not manor:match("Stairs Up") then
					return {
						message = "unlock upstairs",
						fam = "Scarecrow with Boss Bat britches",
						buffs = { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic", "A Few Extra Pounds", "The Moxious Madrigal" },
						bonus_target = { "noncombat" },
						minmp = 30,
						action = adventure {
							zoneid = 104,
							macro_function = macro_noodlecannon,
							choice_function = function(advtitle, choicenum)
								if advtitle == "Take a Look, it's in a Book!" then
									return "", 99
								elseif advtitle == "Melvil Dewey Would Be Ashamed" then
									return "Gaffle the purple-bound book"
								end
							end
						},
					}
				else
					cached_stuff.unlocked_upstairs = true
					return {
						message = "already unlocked upstairs",
						action = function() did_action = true end,
					}
				end
			end
		}
	end

	if challenge == "fist" and have_item("Game Grid token") and not have_item("finger cuffs") and not (have("spangly sombrero") and have_item("spangly mariachi pants")) then
		return script.finger_cuffs()
	end

	if ascensionstatus() ~= "Aftercore" then -- TODO: redo
		script.use_and_sell_items()
		if did_action then
			return result, resulturl, did_action
		end
	end

	need_total_reagent_pastas = 4 * 2
	have_reagent_pastas = 2 + count("hellion cube") + count("goat cheese") + count("Hell ramen") + count("Hell broth") + count("fettucini Inconnu") + count("fancy schmancy cheese sauce")
	if ascensionstatus() ~= "Hardcore" then
		have_reagent_pastas = 100
	elseif fullness() > 9 then
		have_reagent_pastas = have_reagent_pastas + 2
	elseif fullness() > 3 then
		have_reagent_pastas = have_reagent_pastas + 1
	end

	do
		if trailed ~= "dairy goat" then
			local pt, pturl, ate = script.eat_food()
			if not ate and get_result():contains("You need a more advanced cooking appliance") and meat() >= 2500 then
				if not have_item("Dramatic&trade; range") then
					inform "  buying dramatic range"
					set_result(buy_item("Dramatic&trade; range", "m"))
					if not have_item("Dramatic&trade; range") then
						critical "Couldn't buy dramatic range (for advanced cooking)"
					end
				end
				inform "  using dramatic range"
				set_result(use_item("Dramatic&trade; range"))
				did_action = not have_item("Dramatic&trade; range")
			end
			if pt and pturl and ate then
				return pt, pturl, ate
			end
		end
	end
-- 	print("reagent pasta have", have_reagent_pastas, "need", need_total_reagent_pastas)

	do
		local pt, pturl, drank = script.drink_booze()
		if pt then
			return pt, pturl, drank
		end
	end

	local do_powerleveling_sub = nil
	use_dancecard = nil
	if mainstat_type("Muscle") then
		do_powerleveling_sub = script.do_muscle_powerleveling
		use_dancecard = function() end
	elseif mainstat_type("Mysticality") then
		do_powerleveling_sub = script.do_mysticality_powerleveling
		use_dancecard = function() end
	elseif mainstat_type("Moxie") then
		do_powerleveling_sub = script.do_moxie_powerleveling
		use_dancecard = script.do_moxie_use_dancecard
	end

	function do_powerleveling()
		if have_item("plastic vampire fangs") and not day["vamped out.isabella"] and not cached_stuff.tried_vamping_out then
			cached_stuff.tried_vamping_out = true
			script.wear { acc1 = "plastic vampire fangs" }
			inform("vamping out: " .. mainstat_type())
			vamp_out(mainstat_type())
			did_action = true
		else
			return do_powerleveling_sub()
		end
	end

	if challenge == "fist" and not have_item("spangly sombrero") and familiarid() ~= 82 then
		async_get_page("/familiar.php", { pwd = get_pwd(), action = "unequip", famid = 82 })
	end
	if challenge == "fist" and not have_item("spangly mariachi pants") and familiarid() ~= 152 then
		async_get_page("/familiar.php", { pwd = get_pwd(), action = "unequip", famid = 152 })
	end

	if challenge ~= "zombie" then
		if have_buff("Hardly Poisoned at All") or have_buff("A Little Bit Poisoned") or have_buff("Somewhat Poisoned") or have_buff("Really Quite Poisoned") or have_buff("Majorly Poisoned") then
			async_get_page("/galaktik.php", { action = "buyitem", buying = 1, pwd = get_pwd(), whichitem = get_itemid("anti-anti-antidote"), howmany = 1, ajax = 1 })
			use_item("anti-anti-antidote")
			if have_buff("Hardly Poisoned at All") or have_buff("A Little Bit Poisoned") or have_buff("Somewhat Poisoned") or have_buff("Really Quite Poisoned") or have_buff("Majorly Poisoned") then
				critical "Failed to remove poison"
			else
				did_action = true
			end
			return result, resulturl, did_action
		end
	end

	add_task {
		when = not have_item("shining halo") and level() == 1 and not get_ascension_automation_settings().should_wear_weapons,
		task = tasks.summon_clip_art,
	}

	add_task {
		when = AT_song_duration() and level() < 5 and (buffturns("The Moxious Madrigal") < 10 or buffturns("The Magical Mojomuscular Melody") < 10) and have_skill("The Moxious Madrigal") and have_skill("The Magical Mojomuscular Melody"),
		task = tasks.extend_tmm_and_mojo,
	}

	local function have_guard_outfit()
		return have_item("Knob Goblin elite helm") and have_item("Knob Goblin elite polearm") and have_item("Knob Goblin elite pants")
	end

	local function can_disguise_as_guard()
		return have_guard_outfit() and can_equip_item("Knob Goblin elite helm") and can_equip_item("Knob Goblin elite polearm") and can_equip_item("Knob Goblin elite pants")
	end

	local function have_harem_outfit()
		return have_item("Knob Goblin harem veil") and have_item("Knob Goblin harem pants")
	end

	add_task {
		prereq = use_new_faxing and
			not have_item("Knob Goblin encryption key") and
			not unlocked_knob(),
		f = script.unlock_cobbs_knob,
	}

	add_task {
		when = use_new_faxing and quest("The Goblin Who Wouldn't Be King"),
		task = function()
			if have_item("Knob Goblin elite helm") and have_item("Knob Goblin elite polearm") and have_item("Knob Goblin elite pants") then
				return {
					message = "kill goblin king",
					action = function()
						return script.knob_goblin_king_with_cake(macro_noodlecannon)
					end
				}
			else
				return {
					message = "get KGE outfit",
					fam = "Slimeling",
					buffs = { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "Empathy" },
					maybe_buffs = { "Mental A-cue-ity" },
					minmp = 25,
					action = adventure {
						zoneid = 257,
						macro_function = macro_ppnoodlecannon,
						noncombats = {
							["Welcome to the Footlocker"] = "Loot the locker",
						}
					}
				}
			end
		end,
	}

	add_task {
		when = not cached_stuff.learned_lab_password and
			have_item("Cobb's Knob lab key") and
			can_wear_weapons() and
			(can_disguise_as_guard() or (not quest("The Goblin Who Wouldn't Be King") and not challenge)),
		task = function()
			local pt = get_page("/cobbsknob.php", { action = "dispensary" })
			if pt:contains("FARQUAR") then
				cached_stuff.learned_lab_password = true
				return {
					message = "already learned knob lab password",
					nobuffing = true,
					action = function() did_action = true end,
				}
			else
				return {
					message = "learn knob lab password",
					action = adventure { zoneid = 257 },
					equipment = { hat = "Knob Goblin elite helm", weapon = "Knob Goblin elite polearm", pants = "Knob Goblin elite pants" },
				}
			end
		end
	}

	add_task {
		when = mainstat_type("Muscle") and
			ascensionstatus("Hardcore") and
			meat() < 2000 and
			unlocked_knob(),
		task = {
			message = "farm treasury meat",
			familiar = "He-Boulder",
			action = adventure {
				zone = "Cobb's Knob Treasury",
				macro_function = macro_autoattack,
			}
		}
	}

	-- TODO: do if we're in hardcore, can fax and have a rack-fam
	add_task {
		when = challenge == "fist" and not (have("spangly sombrero") and have_item("spangly mariachi pants")) and level() < 6 and count("finger cuffs") >= 5,
		task = tasks.yellow_ray_sleepy_mariachi,
	}

	add_task { -- TODO: rogue program token counter won't work in haiku dungeon
		prereq = (challenge == "fist") and fist_level == 0,
		message = "get haiku dungeon fist scroll",
		buffs = { "Polka of Plenty" },
		fam = "Rogue Program",
		minmp = 10,
		action = adventure {
			zoneid = 138,
			macro_function = macro_stasis,
			noncombats = {
				["Gravy Fairy Ring"] = "Gaffle some mushrooms", -- TODO: if we don't already have spooky
			},
		},
	}

	add_task {
		prereq = not cached_stuff.have_moxie_guild_access and (classid() == 5 or classid() == 6) and not have_item("tonic water") and meat() >= 100,
		f = script.unlock_guild_and_get_tonic_water,
	}

	add_task {
		prereq = (classid() == 3 or classid() == 4) and session["__script.opened myst guild store"] ~= "yes",
		f = script.open_myst_guildstore,
	}

	do
		local larvafam = "Mini-Hipster"
		local larvamacro = macro_stasis
		if challenge == "fist" then
			larvafam = "Knob Goblin Organ Grinder"
			larvamacro = macro_fist
		end
		add_task {
			prereq = quest("Looking for a Larva in All the Wrong Places"),
			message = "find larva",
			buffs = { "Smooth Movements" },
			fam = larvafam,
			runawayfrom = { "bar", "spooky mummy", "spooky vampire", "triffid", "warwelf", "wolfman" },
			minmp = 10,
			action = adventure {
				zoneid = 15,
				macro_function = larvamacro,
				noncombats = {
					["Arboreal Respite"] = "Explore the stream",
					["Consciousness of a Stream"] = "March to the marsh",
				},
			},
		}
	end

	add_task {
		prereq = (challenge == "fist") and level() < 6 and not have_item("tree-holed coin"), -- TODO: make a better check than level to see that we haven't completed temple unlock
		message = "get tree-holed coin",
		buffs = { "Smooth Movements" },
		fam = "Mini-Hipster",
		minmp = 15,
		action = adventure {
			zoneid = 15,
			macro_function = macro_stasis,
			noncombats = {
				["Arboreal Respite"] = "Explore the stream",
				["Consciousness of a Stream"] = "Squeeze into the cave",
			},
		},
	}

	add_task {
		prereq = quest("Ooh, I Think I Smell a Rat") and challenge ~= "fist",
		f = script.do_tavern,
	}

	add_task {
		prereq = have_item("pretentious palette") and have_item("pretentious paintbrush") and have_item("pail of pretentious paint"),
		message = "turn in rat whiskers",
		action = function()
			async_get_page("/town_wrong.php", { place = "artist" })
			async_post_page("/town_wrong.php", { action = "whisker" })
			if not have_item("pail") or have_item("pail of pretentious paint") then
				critical "Error finishing artist quest"
			end
			did_action = true
		end
	}

	add_task {
		prereq = (challenge == "fist") and fist_level == 1,
		message = "get barroom brawl fist scroll",
		buffs = { "Polka of Plenty" },
		fam = "Rogue Program",
		minmp = 10,
		action = adventure {
			zoneid = 233,
			macro_function = macro_stasis,
		},
	}

	add_task {
		prereq = challenge == "fist" and whichday == 1 and fullness() <= 1 and drunkenness() == 0 and level() < 6,
		message = "consuming day 1 fist, first time",
		action = function()
			local f = fullness()
			if not have_item("fortune cookie") then
				buy_item("fortune cookie", "m")
			end
			if count("pumpkin beer") < 3 then
				if not have_item("fermenting powder") and have_item("pumpkin") then
					buy_item("fermenting powder", "m")
				end
				mix_items("pumpkin", "fermenting powder")
			end
			if not have_item("tobiko-infused sake") then
				script.ensure_mp(5)
				cast_skillid(8202) -- summon alice's army cards
				async_post_page("/gamestore.php", { action = "buysnack", whichsnack = get_itemid("tobiko-infused sake") })
			end
			script.ensure_buffs { "Ode to Booze" }
			if not have_item("fortune cookie") or count("pumpkin beer") < 3 or not have_item("tobiko-infused sake") or buffturns("Ode to Booze") < 5 then
				stop "Failed to get items to consume on day 1 fist"
			end
			eat_item("fortune cookie")
			drink_item("tobiko-infused sake")
			drink_item("pumpkin beer")
			drink_item("pumpkin beer")
			if fullness() == f + 1 and drunkenness() == 5 then
				did_action = true
			end
		end,
	}

	add_task {
		prereq = challenge == "fist" and whichday == 1 and fullness() <= 3 and drunkenness() == 5 and level() < 7 and have_item("distilled fortified wine"),
		message = "consuming day 1 fist, second time",
		action = function()
			if count("pumpkin beer") < 1 or count("distilled fortified wine") < 3 then
				stop "Didn't have items to consume on day 1 fist"
			end
			script.ensure_buffs { "Ode to Booze" }
			drink_item("pumpkin beer")
			drink_item("distilled fortified wine")
			drink_item("distilled fortified wine")
			drink_item("distilled fortified wine")
			if fullness() <= 3 and drunkenness() == 9 then
				did_action = true
			end
		end,
	}

	add_task {
		prereq = challenge == "fist" and whichday == 1 and fullness() <= 3 and level() < 8 and (count("Hell ramen") + count("Hell broth") + count("hellion cube") >= 2) and (advs() < 10 or meat() >= 1000),
		message = "eating reagent pasta",
		action = function()
			local kitchen = get_page("/campground.php", { action = "inspectkitchen" })
			if kitchen:contains("E-Z Cook") and not kitchen:contains("Dramatic") then
				if not have_item("Dramatic&trade; range") and meat() < 1000 then
					stop "Not enough meat for dramatic range"
				end
				if count("hellion cube") < 2 then
					stop "Not enough hellion cubes"
				end
				if not have_item("Dramatic&trade; range") then
					buy_item("Dramatic&trade; range", "m")
				end
				inform "using dramatic range"
				use_item("Dramatic&trade; range")
				local kitchen = get_page("/campground.php", { action = "inspectkitchen" })
				if kitchen:contains("E-Z Cook") and not kitchen:contains("Dramatic") then
					critical "Failed to install dramatic range"
				end
			end
			if count("Hell ramen") >= 2 then
				inform "eating hell ramen"
				eat_item("Hell ramen")
				eat_item("Hell ramen")
				if fullness() == 15 then
					did_action = true
				end
			else
				inform "making reagent pasta"
				script.make_reagent_pasta()
			end
		end,
	}

	-- TODO: redo eating/drinking in fist, and in no-path
	add_task {
		prereq = challenge == "fist" and whichday >= 2 and level() >= 7 and (advs() < 50 or not quest("Am I My Trapper's Keeper?")) and fullness() <= 9 and (whichday == 2 or have_reagent_pastas >= 8),
		f = function()
			if whichday == 2 and fullness() <= 3 then
				if count("Hell ramen") >= 2 then
					inform "eating hell ramen in fist"
					eat_item("Hell ramen")
					eat_item("Hell ramen")
					if fullness() >= 12 then
						did_action = true
					end
				else
					inform "making reagent pasta"
					script.make_reagent_pasta()
				end
			elseif whichday >= 3 and fullness() <= 3 and (have("glass of goat's milk") or have_item("milk of magnesium") or have_buff("Got Milk")) then
				if not have_item("milk of magnesium") and not have_buff("Got Milk") then
					inform "making milk"
					if count("scrumptious reagent") < 1 then
						script.ensure_mp(10)
						cast_skillid(4006, 1) -- advanced saucecrafting
					end
					cook_items("glass of goat's milk", "scrumptious reagent")
					if have_item("milk of magnesium") then
						did_action = true
					end
				elseif count("Hell ramen") + count("fettucini Inconnu") >= 2 then
					if not have_buff("Got Milk") then
						inform "using milk"
						use_item("milk of magnesium")
						if not have_buff("Got Milk") then
							critical "Failed to use milk of magnesium"
						end
					end
					inform "eating reagent pasta in fist with milk"
					eat_item("Hell ramen")
					eat_item("Hell ramen")
					eat_item("fettucini Inconnu")
					eat_item("fettucini Inconnu")
					if fullness() >= 12 then
						did_action = true
					end
				else
					inform "making reagent pasta"
					script.make_reagent_pasta()
				end
			else
				stop "Trying to eat day 2+ in fist"
			end
		end,
	}

	add_task {
		prereq = (challenge == "fist") and fist_level == 2,
		message = "get entryway fist scroll",
		buffs = { "Polka of Plenty" },
		fam = "Mini-Hipster",
		minmp = 10,
		action = adventure {
			zoneid = 30,
			macro_function = macro_stasis,
		},
	}

	add_task {
		prereq = (challenge == "trendy") and spleen() < 12 and level() < 6,
		message = "get spleen in trendy day 1",
		fam = "Pair of Stomping Boots",
		minmp = 5,
		action = function()
			if familiarid() ~= 150 then
				critical "Failed to use stomping boots in trendy"
			end
			if have_item("oily paste") then
				local a = advs()
				set_result(use_item("oily paste"))
				did_action = advs() > a
			else
				local f = adventure {
					zoneid = 240,
					macro_function = function()
						return [[
]] .. COMMON_MACROSTUFF_START(20, 50) .. [[
pickpocket
]] .. COMMON_MACROSTUFF_FLYERS .. [[

if hasskill release the boots
  cast release the boots
endif

while !times 10
  attack
endwhile

]]
					end
				}
				return f()
			end
		end
	}

	add_task {
		when = quest("Ooh, I Think I Smell a Bat.") and challenge ~= "fist",
		task = {
			message = "do bat quest",
			nobuffing = true,
			action = function()
				script.maybe_ensure_buffs { "Spirit of Garlic" }
				return script.do_boss_bat(macro_noodlecannon, 20)
			end,
		}
	}

	add_task {
		when = not cached_stuff.got_hermit_clovers,
		task = {
			message = "get clovers from hermit",
			nobuffing = true,
			action = function()
				if not script.trade_for_clover() then
					cached_stuff.got_hermit_clovers = true
				end
				did_action = true
			end
		}
	}

	add_task {
		prereq = level() >= 6 and quest("The Goblin Who Wouldn't Be King") and quest_text("haven't figured out how to decrypt it yet"),
		f = script.unlock_cobbs_knob,
	}

	add_task {
		prereq = not have_item("Knob Goblin encryption key") and
			not unlocked_knob(),
		f = script.unlock_cobbs_knob,
	}

	add_task {
		prereq = quest("The Goblin Who Wouldn't Be King") and
			can_disguise_as_guard(),
		f = function()
			script.knob_goblin_king_with_cake(macro_noodlecannon)
		end,
	}

	add_task {
		prereq = quest("The Goblin Who Wouldn't Be King") and
			have_harem_outfit(),
		f = function()
			script.wear { hat = "Knob Goblin harem veil", pants = "Knob Goblin harem pants" }
			if have_buff("Knob Goblin Perfume") then
				inform "fight king in harem girl outfit"
				script.ensure_mp(20)
				script.want_familiar "Frumious Bandersnatch"
				set_mcd(7) -- TODO: moxie-specific
				local pt, url = get_page("/cobbsknob.php", { action = "throneroom" })
				result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_noodleserpent)
				did_action = advagain
			elseif have_item("Knob Goblin perfume") then
				use_item("Knob Goblin perfume")
				if have_buff("Knob Goblin Perfume") then
					did_action = true
				end
			else
				result, resulturl, advagain = autoadventure { zoneid = 259 }
				if have_buff("Knob Goblin Perfume") then
					did_action = true
				end
			end
		end,
	}

	add_task {
		prereq = quest("The Goblin Who Wouldn't Be King") and
			not have_guard_outfit() and
			can_wear_weapons() and
			can_photocopy(),
		f = function()
			if script.get_photocopied_monster() ~= "Knob Goblin Elite Guard Captain" then
				inform "get KGE captain from faxbot"
				script.get_faxbot_fax("Knob Goblin Elite Guard Captain", "kge")
			else
				inform "fight KGE captain"
				script.heal_up()
				script.ensure_mp(30)
				use_item("photocopied monster")
				local pt, url = get_page("/fight.php")
				result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_noodlecannon)
				cached_stuff.have_faxed_today = true
				if advagain then
					did_action = true
				end
			end
		end,
	}

	add_task {
		when = quest("The Goblin Who Wouldn't Be King") and
			not have_guard_outfit() and
			can_wear_weapons(),
		task = {
			message = "get KGE outfit",
			fam = "Slimeling",
			buffs = { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "Empathy" },
			maybe_buffs = { "Mental A-cue-ity" },
			minmp = 25,
			action = adventure {
				zoneid = 257,
				macro_function = macro_ppnoodlecannon,
				noncombats = {
					["Welcome to the Footlocker"] = "Loot the locker",
				}
			}
		},
	}

	add_task {
		prereq = quest("The Goblin Who Wouldn't Be King") and
			challenge == "fist" and
			not have_harem_outfit() and
			can_yellow_ray(),
		f = function()
			script.go("yellow raying harem girl", 259, make_yellowray_macro("harem girl"), {}, {}, "He-Boulder", 15)
		end,
	}

	add_task {
		prereq = function() return quest("The Goblin Who Wouldn't Be King") and
			challenge == "jarlsberg" and
			not have_harem_outfit() and
			ensure_yellow_ray() end,
		f = function()
			script.go("yellow raying harem girl", 259, make_yellowray_macro("harem girl"), {}, {}, "He-Boulder", 15)
		end,
	}

	-- TODO: find a better way to check this? redo it
	add_task {
		prereq = not have_item("Knob Goblin seltzer") and
			not have_item("Knob Goblin pet-buffing spray") and
			can_disguise_as_guard(),
		f = function()
			if not have_item("Knob Goblin pet-buffing spray") then
				inform "buying pet-buffing spray"
				if meat() < 250 then
					stop "Can't afford pet-buffing spray"
				end
				buy_item("Knob Goblin pet-buffing spray", "k", 1)
				if have_item("Knob Goblin pet-buffing spray") then
					inform "bought pet-buffing spray"
					did_action = true
					return
				end
			end
			if not have_item("Knob Goblin seltzer") then
				inform "buying seltzer"
				if meat() < 80 then
					stop "Can't afford seltzer"
				end
				result, resulturl = buy_item("Knob Goblin seltzer", "k", 1)()
				if have_item("Knob Goblin seltzer") then
					inform "bought seltzer"
					did_action = true
				elseif get_result():contains("You don't belong in this store.") then
					script.go("get dispensary password", 257, nil, {}, {}, "Slimeling", 0, { equipment = { hat = "Knob Goblin elite helm", weapon = "Knob Goblin elite polearm", pants = "Knob Goblin elite pants" } })
					if get_result():match("FARQUAR") then
						did_action = true
					end
					if did_action then
						script.wear {}
					end
				end
			end
		end,
	}

	add_task {
		prereq = challenge == "fist"
			and level() >= 5
			and not quest("The Goblin Who Wouldn't Be King")
			and have_item("Knob Goblin harem veil") and have_item("Knob Goblin harem pants")
			and session["__script.gotten treasury meat"] ~= "yes",
		f = function()
			inform "getting treasury meat"
			script.wear { hat = "Knob Goblin harem veil", pants = "Knob Goblin harem pants" }
			local pt, pturl, advagain = autoadventure { zoneid = 260 }
			session["__script.gotten treasury meat"] = "yes"
			if not pt:contains("Finally, the Payoff") and not("Just Tryin' to Get Paid") then
				critical "Failed to get harem treasury meat"
			end
			did_action = true
		end,
	}

	add_task {
		when = level() < 6 and (challenge ~= "fist" or fist_level >= 3) and challenge ~= "boris" and challenge ~= "zombie" and challenge ~= "jarlsberg" and not ascensionpath("Class Act II: A Class For Pigs") and ascensionstatus() == "Hardcore",
		task = tasks.do_sewerleveling,
	}

	add_task {
		prereq = quest("Trial By Friar"),
		f = script.do_friars,
	}

	add_task {
		prereq = quest_text("this is Azazel in Hell") and not ascension_script_option("skip azazel quest"),
		f = script.do_azazel,
	}

	do
		local three_drunk = get_first_we_have { "sangria", "tequila with training wheels", "margarita", "strawberry daiquiri", "Mad Train wine", "ice-cold fotie" }
		local one_drunk1, one_drunk2 = get_first_we_have({ "gin-soaked blotter paper", "ice-cold Sir Schlitz", "ice-cold Willer" }, 1)
		add_task {
			prereq = challenge == "fist" and whichday == 1 and have_skill("Liver of Steel") and drunkenness() == 14 and three_drunk and one_drunk1 and one_drunk2,
			message = "drinking booze day 1 fist",
			action = function()
				script.ensure_buffs { "Ode to Booze" }
				drink_item(three_drunk)
				drink_item(one_drunk1)
				drink_item(one_drunk2)
				did_action = (drunkenness() == 19)
			end
		}
	end

	add_task {
		prereq = challenge == "fist" and
			quest("Suffering For His Art") and
			have("pail of pretentious paint") and
			have("pretentious paintbrush"),
		f = script.unlock_manor,
	}

	add_task {
		when = challenge == "boris" and
			not cached_stuff.unlocked_manor and
			not have_item("Spookyraven library key"),
		task = function()
			local townright = get_page("/town_right.php")
			if townright:contains("The Haunted Pantry") then
				return {
					message = "unlock manor",
					fam = "Rogue Program",
					buffs = { "The Moxious Madrigal", "The Magical Mojomuscular Melody" },
					minmp = 5,
					action = adventure {
						zoneid = 113,
						macro_function = macro_stasis,
						noncombats = {
							["Oh No, Hobo"] = "Give him a beating",
							["Trespasser"] = "Tackle him",
							["The Singing Tree"] = "&quot;No singing, thanks.&quot;",
							["The Baker's Dilemma"] = "&quot;Sorry, I'm busy right now.&quot;",
						}
					},
					after_action = function()
						if get_result():contains("The Manor in Which You're Accustomed") then
							did_action = true
						end
					end
				}
			else
				cached_stuff.unlocked_manor = true
				return {
					message = "already unlocked manor",
					action = function() did_action = true end,
				}
			end
		end
	}

	add_task {
		prereq = challenge == "fist" and not have_buff("Assaulted with Pepper") and have_item("pail") and have_item("&quot;DRINK ME&quot; potion"),
		message = "getting assulted with pepper",
		action = function()
			script.wear { hat = "pail" }
			use_item("&quot;DRINK ME&quot; potion")
			result, resulturl = get_page("/rabbithole.php", { action = "teaparty" })
			result, resulturl = handle_adventure_result(result, resulturl, "?", nil, { ["The Mad Tea Party"] = "Try to get a seat" })
			if have_buff("Assaulted with Pepper") then
				did_action = true
			end
		end,
	}

	if challenge == "fist" and have_buff("Everything Looks Yellow") and not (have("Knob Goblin harem veil") and have_item("Knob Goblin harem pants")) and quest("The Goblin Who Wouldn't Be King") then
		add_task {
			prereq = not have_item("Spookyraven library key"),
			f = script.get_library_key,
		}

		add_task {
			prereq = (challenge == "fist") and fist_level == 3,
			message = "get conservatory fist scroll",
			fam = "Mini-Hipster",
			minmp = 10,
			action = adventure {
				zoneid = 103,
				macro_function = macro_stasis,
			},
		}

		add_task {
			prereq = (challenge == "fist") and fist_level == 4,
			message = "get slums fist scroll",
			fam = "Mini-Hipster",
			minmp = 10,
			action = adventure {
				zoneid = 248,
				macro_function = macro_fist,
			},
		}
	end

	add_task {
		prereq = (challenge == "trendy") and spleen() < 12 and advs() < 20,
		message = "get spleen in trendy",
		fam = "Pair of Stomping Boots",
		minmp = 5,
		action = function()
			if familiarid() ~= 150 then
				critical "Failed to use stomping boots in trendy"
			end
			if have_item("goblin paste") then
				local a = advs()
				set_result(use_item("goblin paste"))
				did_action = advs() > a
			else
				local f = adventure {
					zoneid = 260,
					macro_function = function()
						return [[
]] .. COMMON_MACROSTUFF_START(20, 50) .. [[
pickpocket
]] .. COMMON_MACROSTUFF_FLYERS .. [[

if hasskill release the boots
  cast release the boots
endif

while !times 10
  attack
endwhile

]]
					end
				}
				return f()
			end
		end
	}

	add_task {
		when = not cached_stuff.did_forest_runaways,
		task = {
			message = "doing spooky forest runaways",
			nobuffing = true,
			action = function()
				if not script.spooky_forest_runaways() then
					cached_stuff.did_forest_runaways = true
				end
				did_action = true
			end
		}
	}

	add_task {
		when = not have_item("sugar shield") and not cached_stuff.summoned_sugar_shield,
		task = {
			message = "summon sugar shield",
			nobuffing = true,
			action = function()
				script.ensure_mp(2)
				cast_skill("Summon Sugar Sheets")
				async_get_page("/sugarsheets.php", { pwd = get_pwd(), action = "fold", whichitem = get_itemid("sugar shield") })
				cached_stuff.summoned_sugar_shield = true
				did_action = true
			end
		}
	}

	local function drink_1_drunk_booze_loop()
		if have_item("pumpkin") then
			if not have_item("fermenting powder") then
				buy_item("fermenting powder", "m")
			end
			mix_items("pumpkin", "fermenting powder")
			if not have_item("pumpkin beer") then
				critical "Failed to mix pumpkin beer"
			end
		end
		for i = 1, 20 do
			script.ensure_buffs { "Ode to Booze" }
			if drunkenness() < estimate_max_safe_drunkenness() then
				if have_item("astral pilsner") and level() >= 11 then
					drink_item("astral pilsner")
				elseif have_item("thermos full of Knob coffee") then
					drink_item("thermos full of Knob coffee")
				elseif have_item("pumpkin beer") then
					drink_item("pumpkin beer")
				elseif have_item("distilled fortified wine") then
					drink_item("distilled fortified wine")
				end
			end
		end
	end

	add_task {
		prereq = challenge == "fist" and drunkenness() < 3 and (have("pumpkin") or have_item("pumpkin beer")),
		f = function()
			inform "drinking early-day booze in fist"
			drink_1_drunk_booze_loop()
			if drunkenness() >= 3 then
				did_action = true
			end
		end,
	}

	add_task {
		prereq = challenge == "fist" and drunkenness() < estimate_max_safe_drunkenness() and have_item("astral pilsner") and level() >= 11,
		f = function()
			inform "drinking astral pilsners"
			local d = drunkenness()
			drink_1_drunk_booze_loop()
			if drunkenness() > d then
				did_action = true
			end
		end,
	}

	add_task {
		prereq = challenge == "fist" and drunkenness() < 10 and level() >= 12,
		f = function()
			script.wear { hat = "filthy knitted dread sack", pants = "filthy corduroys" }
			stop "TODO: Drink up to at least 10 drunk in fist"
		end,
	}

	add_task {
		when = not have_item("digital key") and
			ascensionstatus() == "Hardcore" and
			not script.have_familiar("Angry Jung Man") and
			have_skill("Transcendent Olfaction") and
			not trailed and
			can_photocopy(),
		task = function()
			return {
				message = "find blooper",
				action = function()
					if script.get_photocopied_monster() ~= "Blooper" then
						print("photocopied:", script.get_photocopied_monster())
						inform "get blooper from faxbot"
						script.get_faxbot_fax("Blooper", "blooper")
					else
						if not have_item("continuum transfunctioner") then
							inform "pick up continuum transfunctioner (for faxed blooper)"
							set_result(pick_up_continuum_transfunctioner())
						end
						inform "fight and sniff blooper"
						script.heal_up()
						script.ensure_buffs { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric" }
						script.want_familiar "Frumious Bandersnatch"
						script.wear { acc3 = "continuum transfunctioner" }
						script.ensure_mp(60)
						set_result(use_item("photocopied monster"))
						cached_stuff.have_faxed_today = true
						local pt, url = get_page("/fight.php")
						if url:contains("/fight.php") then
							result, resulturl, advagain = handle_adventure_result(pt, url, "?", make_cannonsniff_macro("Blooper"))
							if advagain then
								did_action = true
							end
						end
					end
				end
			}
		end
	}

	add_task {
		when = not have_item("digital key") and
			ascensionstatus() == "Hardcore" and
			not script.have_familiar("Angry Jung Man") and
			have_item("Staff of the Standalone Cheese") and
			can_equip_item("Staff of the Standalone Cheese") and
			(cached_stuff.doing_8bit or advs() >= 40),
		task = function()
			cached_stuff.doing_8bit = true
			local banished = retrieve_standalone_cheese_banished_monsters()
			--print("DEBUG banished:", table_to_json(banished))
			if not banished[4] then
				return {
                                        message = "fight and banish non-bloopers",
                                        equipment = { weapon = "Staff of the Standalone Cheese", acc3 = "continuum transfunctioner" },
					action = adventure {
						zoneid = 73,
						macro_function = function()
							return [[

if monstername Blooper
]] .. boris_action() .. [[
  goto done
endif

if (monstername Bullet Bill) || (monstername Keese) || (monstername Octorok) || (monstername Zol)
  jiggle
  goto done
endif

]] .. boris_action() .. [[

mark done
]]
							end,
					},
                                }
			elseif have_item("Staff of the Cream of the Cream") and can_equip_item("Staff of the Cream of the Cream") and retrieve_cream_olfacted_monster() ~= "Blooper" then
				return {
                                        message = "sniff blooper",
                                        equipment = { weapon = "Staff of the Cream of the Cream", acc3 = "continuum transfunctioner" },
					action = adventure {
						zoneid = 73,
						macro_function = function()
							return [[

if monstername Blooper
  jiggle
endif

]] .. boris_action() .. [[

]]
							end,
					},
                                }
			else
				return {
                                        message = "fight in 8-bit realm",
                                        equipment = { acc3 = "continuum transfunctioner" },
					action = adventure {
						zoneid = 73,
						macro_function = macro_8bit_realm,
					},
                                }
			end
		end,
	}

	add_task {
		when = not have_item("digital key") and cached_stuff.campground_psychoses == "mystic" and count("white pixel") + math.min(count("red pixel"), count("green pixel"), count("blue pixel")) < 30,
		task = {
			message = "get digital key (mystic's jar)",
			fam = "Slimeling",
			buffs = { "Glittering Eyelashes", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy", "A Few Extra Pounds", "Reptilian Fortitude", "Astral Shell", "Ghostly Shell" },
			minmp = 20,
			olfact = "morbid skull",
			action = adventure {
				zoneid = 302,
				macro_function = function() return make_cannonsniff_macro("morbid skull") end,
				noncombats = {
					["Snakes."] = "No.  No no no.",
				}
			},
		}
	}

	add_task {
		when = have_buff("Consumed by Fear"),
		task = {
			message = "remove consumed by fear buff",
			nobuffing = true,
			action = function()
				get_page("/place.php", { whichplace = "junggate_3", action = "mystic_face" })
				did_action = not have_buff("Consumed by Fear")
			end
		}
	}

	add_task {
		when = not have_item("digital key") and
			(have_item("psychoanalytic jar") or have_item("jar of psychoses (The Crackpot Mystic)")) and
			advs() >= 40 and
			not trailed,
		task = {
			message = "use mystic jar",
			nobuffing = true,
			action = function()
				post_page("/shop.php", { whichshop = "mystic", action = "jung", whichperson = "mystic" })
				if not have_item("jar of psychoses (The Crackpot Mystic)") then
					critical "Failed to pick up crackpot mystic jar"
				end
				cached_stuff.campground_psychoses = nil
				use_item("jar of psychoses (The Crackpot Mystic)")
				did_action = not have_item("jar of psychoses (The Crackpot Mystic)")
			end
		}
	}

	add_task {
		when = quest("Am I My Trapper's Keeper?") and (not trailed or trailed == "dairy goat") and highskill_at_run,
		task = {
			message = "get milk early in highskill AT",
			nobuffing = true,
			action = function()
				ignore_buffing_and_outfit = false
				script.do_trapper_quest()
			end
		}
	}

	add_task {
		when = highskill_at_run and
			not have_item("barrel of gunpowder") and
			level() >= 8 and level() < 12 and
			script.have_familiar("Obtuse Angel") and
			can_photocopy(),
		task = {
			message = "fax and arrow lobsterfrogman",
			action = function()
				if script.get_photocopied_monster() ~= "lobsterfrogman" then
					inform "get LFM from faxbot"
					script.get_faxbot_fax("lobsterfrogman", "lobsterfrogman")
				else
					script.heal_up()
					script.want_familiar "Obtuse Angel"
					stop "TODO: summon quake, fax and arrow lobsterfrogman"
				end
			end
		}
	}

	add_task {
		prereq = not have_item("Spookyraven library key"),
		f = script.get_library_key,
		message = "get library key",
		hide_message = true,
	}

	add_task {
		prereq = (challenge == "fist") and fist_level == 3,
		message = "get conservatory fist scroll",
		fam = "Mini-Hipster",
		minmp = 10,
		action = adventure {
			zoneid = 103,
			macro_function = macro_stasis,
		},
	}

	add_task {
		prereq = (challenge == "fist") and
			fist_level == 4,
		message = "get slums fist scroll",
		fam = "Mini-Hipster",
		minmp = 10,
		action = adventure {
			zoneid = 248,
			macro_function = macro_fist,
		},
	}

	add_task {
		prereq = quest("Ooh, I Think I Smell a Rat") and
			challenge == "fist",
		f = script.do_tavern,
	}

	add_task {
		prereq = quest("Ooh, I Think I Smell a Bat.") and
			challenge == "fist",
		f = script.do_boss_bat,
	}

	add_task {
		prereq = not unlocked_beach() and
			moonsign_area() == "Degrassi Knoll",
		f = script.make_meatcar,
	}

	add_task {
		when = not unlocked_beach() and
			moonsign_area() ~= "Degrassi Knoll" and
			meat() >= 6000,
		task = {
			message = "unlock beach (with bus pass)",
			nobuffing = true,
			action = function()
				buy_item("Desert Bus pass", "m")
				did_action = have_item("Desert Bus pass")
			end
		}
	}

	-- TODO: unless in fist and bonerdagon is up
	-- TODO: don't need no-trail for all of crypt, just niche
	add_task {
		prereq = quest("Cyrptic Emanations") and (not trailed or trailed == "dirty old lihc"),
		f = script.do_crypt,
	}

	add_task {
		when = DD_keys < 3 and (have_gelatinous_cubeling_items() or not script.have_familiar("Gelatinous Cubeling")) and not cached_stuff.done_daily_dungeon,
		task = tasks.do_daily_dungeon,
	}

	add_task {
		prereq = not have_item("Spookyraven ballroom key") and ((challenge ~= "boris" and challenge ~= "zombie" and challenge ~= "jarlsberg") or level() >= 7),
		f = script.get_ballroom_key,
		message = "ballroom key",
	}

	add_task {
		prereq =
			have("Spookyraven ballroom key") and
			level() < 11 and
			ascension["zone.manor.quartet song"] ~= "Sono Un Amante Non Un Combattente",
		f = function()
			script.bonus_target { "noncombat" }
			if mainstat_type("Moxie") then
				script.go("set song (moxie)", 109, macro_noodlecannon, {
					["Curtains"] = "Watch the dancers",
					["Strung-Up Quartet"] = "&quot;Play 'Sono Un Amanten Non Un Combattente'&quot;",
				}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic" }, "Slimeling", 25)
			else
				script.go("set song (non-moxie)", 109, macro_noodlecannon, {
					["Curtains"] = "Pay no attention to the stuff in front of the curtain",
					["Strung-Up Quartet"] = "&quot;Play 'Sono Un Amanten Non Un Combattente'&quot;",
				}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic" }, "Llama Lama", 25)
			end
		end,
		message = "ballroom song",
	}

	local function have_hippy_outfit()
		return have_item("filthy knitted dread sack") and have_item("filthy corduroys")
	end

	-- TODO: shore as early as possible.
	if challenge == "fist" then
		add_task {
			prereq = want_shore() and
				not unlocked_island() and
				turns_to_next_sr >= 5 and
				not have_frat_war_outfit(),
			f = script.get_dinghy,
			message = "get dinghy",
		}

		add_task {
			prereq = not have_hippy_outfit() and
				can_yellow_ray(),
			f = function()
				-- TODO: want +combat%
				script.go("yellow raying hippy", 26, make_yellowray_macro("hippy"), {}, {}, "He-Boulder", 15)
			end,
		}
	end

	add_task { prereq = challenge == "fist" and (whichday == 2) and ((not highskill_at_run and advs() < 110) or (advs() < 20 and level() >= 8)), f = function()
		if drunkenness() < estimate_max_safe_drunkenness() then
			if have_hippy_outfit() and drunkenness() < estimate_max_safe_drunkenness() then
				local kitchen = get_page("/campground.php", { action = "inspectkitchen" })
				if kitchen:contains("My First Shaker") and not kitchen:contains("Du Coq cocktailcrafting") then
					if not have_item("Queue Du Coq cocktailcrafting kit") and meat() < 1000 then
						stop "Not enough meat for cocktailcrafting kit"
					end
					if not have_item("Queue Du Coq cocktailcrafting kit") then
						buy_item("Queue Du Coq cocktailcrafting kit", "m")
					end
					inform "using cocktailcrafting kit"
					use_item("Queue Du Coq cocktailcrafting kit")
					local kitchen = get_page("/campground.php", { action = "inspectkitchen" })
					if kitchen:contains("My First Shaker") and not kitchen:contains("Du Coq cocktailcrafting") then
						critical "Failed to install cocktailcrafting kit"
					end
				end
				script.wear { hat = "filthy knitted dread sack", pants = "filthy corduroys" }
				stop "TODO: mix and drink SHCs to max drunk"
			else
				inform "drinking at end of day 2"
				local pt, pturl, drank = script.drink_booze()
				if pt then
					return pt, pturl, drank
				end
			end
		end
	end }

	add_task {
		prereq = function() return not have_hippy_outfit() and
			unlocked_island() and
			ensure_yellow_ray() and
			not have_frat_war_outfit() end,
		f = function()
			-- TODO: Should do this before level 9 to avoid noncombats!
			script.bonus_target { "combat" }
			script.go("yellow raying hippy", 26, make_yellowray_macro("hippy"), {}, { "Musk of the Moose", "Carlweather's Cantata of Confrontation" }, "He-Boulder", 15, { choice_function = function(advtitle, choicenum)
				if advtitle == "Peace Wants Love" then
					if not have_item("filthy corduroys") then
						return "Agree to take his clothes"
					else
						return "Say &quot;No thanks.&quot;"
					end
				elseif advtitle == "An Inconvenient Truth" then
					if not have_item("filthy knitted dread sack") then
						return "Check out the clothing"
					else
						return "Avert your eyes"
					end
				end
			end })
		end,
	}

	add_task {
		prereq = not have_hippy_outfit() and
			can_yellow_ray() and
			unlocked_island() and
			challenge ~= "boris" and
			challenge ~= "zombie" and
			challenge ~= "jarlsberg" and
			level() >= 9,
		f = function()
			script.bonus_target { "noncombat" }
			script.go("yellow raying hippy", 26, macro_noodlecannon, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Bacon Grease" }, "He-Boulder", 15, { choice_function = function(advtitle, choicenum)
				if advtitle == "Peace Wants Love" then
					if not have_item("filthy corduroys") then
						return "Agree to take his clothes"
					else
						return "Say &quot;No thanks.&quot;"
					end
				elseif advtitle == "An Inconvenient Truth" then
					if not have_item("filthy knitted dread sack") then
						return "Check out the clothing"
					else
						return "Avert your eyes"
					end
				end
			end })
		end,
	}

	add_task {
		prereq = have_buff("Ultrahydrated") and quest("A Pyramid Scheme") and not quest_text("found the little pyramid") and not have_item("Staff of Ed"),
		f = script.do_oasis_and_desert,
		message = "ultrahydrated",
	}

	add_task {
		prereq = (trailed == "zombie waltzers" and level() < 13 and (level() + level_progress() < 12.25) and (not highskill_at_run or level() < 12)),
		f = function()
			use_dancecard()
			do_powerleveling()
		end,
		message = "tailed zombie waltzers",
	}

	add_task {
		prereq = have_reagent_pastas < need_total_reagent_pastas and trailed == "dairy goat",
		f = function()
			-- TODO: burrito blessing if available. messed up when it's taken too long! don't craft food/equipment until this is done
			script.go("get goat cheese for pasta", 271, make_cannonsniff_macro("dairy goat"), nil, { "Heavy Petting", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy" }, "Slimeling even in fist", 30, { olfact = "dairy goat" })
		end,
	}

	add_task {
		prereq = quest("Am I My Trapper's Keeper?") and (not trailed or trailed == "dairy goat") and challenge ~= "boris",
		f = function()
			ignore_buffing_and_outfit = false
			script.do_trapper_quest()
		end,
		message = "trapper quest",
	}

	add_task {
		prereq = want_shore() and
			not unlocked_island() and
			turns_to_next_sr >= 5 and
			meat() >= 1000 and
			unlocked_beach(),
		f = script.get_dinghy,
		message = "get dinghy",
	}

	add_task {
		prereq = not have_item("The Big Book of Pirate Insults") and
			not have_item("pirate fledges") and
			unlocked_island() and
			not quest_text("successfully joined Cap'm Caronch's crew") and
			not ascension["zone.pirates.insults"] and
			basemysticality() >= 25 and
			basemoxie() >= 25,
		f = function()
			use_dancecard()
			script.get_big_book_of_pirate_insults()
		end,
		message = "get book of pirate insults",
	}

	add_task {
		prereq = not quest_text("you've been given crappy scutwork") and
			not have_item("pirate fledges") and
			unlocked_island() and
			basemysticality() >= 25 and
			basemoxie() >= 25,
		f = function()
			script.wear { hat = "eyepatch", pants = "swashbuckling pants", acc3 = "stuffed shoulder parrot" }
			local covept = get_page("/cove.php")
			if covept:match("The F'c'le") then
				critical "F'c'le unlocked, but quest is not at the right point?"
			else
				use_dancecard()
				-- barrr
				local tbl = ascension["zone.pirates.insults"] or {}
				local insults = table.maxn(tbl)
				if insults < 7 or quest_text("A salty old pirate named Cap'm Caronch has offered to let you join his crew if you find some treasure for him") then
					script.do_barrr(insults)
				elseif have_item("Cap'm Caronch's nasty booty") then
					inform "get blueprints"
					script.wear { hat = "eyepatch", pants = "swashbuckling pants", acc3 = "stuffed shoulder parrot" }
					result, resulturl, advagain = autoadventure { zoneid = 157 }
					if have_item("Orcish Frat House blueprints") then
						did_action = advagain
					end
				elseif have_item("Orcish Frat House blueprints") and quest_text("and asked you to steal his dentures back") then
					inform "use blueprints"
					if not have_item("frilly skirt") then
						buy_item("frilly skirt", "4")
					end
					if not have_item("frilly skirt") and moonsign_area() ~= "Degrassi Knoll" and not ascensionstatus("Hardcore") then
						if challenge == "boris" then
							if have_item("clockwork maid") then
								stop "Already have clockwork maid!"
							end
							ascension_automation_pull_item("clockwork maid")
							if have_item("clockwork maid") then
								did_action = true
								return
							end
						end
						pull_in_softcore("frilly skirt")
					end
					if have_item("frilly skirt") and count("hot wing") >= 3 then
						script.wear { pants = "frilly skirt" }
						use_item("Orcish Frat House blueprints")
						async_get_page("/choice.php")
						result, resulturl = post_page("/choice.php", { pwd = get_pwd(), whichchoice = 188, option = 3 })
						if have_item("Cap'm Caronch's dentures") then
							did_action = true
						end
					end
				elseif have_item("Cap'm Caronch's dentures") then
					inform "return blueprints"
					script.wear { hat = "eyepatch", pants = "swashbuckling pants", acc3 = "stuffed shoulder parrot" }
					result, resulturl, advagain = autoadventure { zoneid = 157 }
					if not have_item("Cap'm Caronch's dentures") then
						did_action = advagain
					end
				elseif quest_text("wants you to defeat Old Don Rickets") then
					script.beat_ibp()
				else
					critical "Unexpected quest status while trying to find pirate fledges. Didn't find the map?"
				end
			end
		end,
	}

	add_task {
		when = quest("Am I My Trapper's Keeper?") and challenge == "boris",
		task = {
			message = "trapper quest in boris",
			nobuffing = true,
			action = function()
				async_get_page("/place.php", { whichplace = "mclargehuge", action = "trappercabin" })
				refresh_quest()
				if not quest("Am I My Trapper's Keeper?") then
					did_action = true
					return
				end
				if quest_text("gather up some cheese and ore") and count_item("goat cheese") >= 3 then
					if daysthisrun() >= 2 and not ascensionstatus("Hardcore") then
						local want_ore = questlog_page:match("bring him back 3 chunks of ([a-z]+ ore)")
						if want_ore and get_itemid(want_ore) then
							local got = count(want_ore)
							if got < 3 then
								if want_ore == "chrome ore" and not have_item("acoustic guitarrr") and not have_item("heavy metal thunderrr guitarrr") then
									pull_in_softcore("heavy metal thunderrr guitarrr")
									did_action = have_item("heavy metal thunderrr guitarrr")
									return
								else
									pull_in_softcore(want_ore)
									did_action = count(want_ore) > got
									return
								end
							end
						end
					end
					ignore_buffing_and_outfit = false
					if (daysthisrun() == 1 or ascensionstatus() == "Hardcore") and have_skill("Banishing Shout") then
						script.bonus_target { "item", "extraitem" }
						script.go("farming mountain men", 270, macro_softcore_boris, {
							["A Flat Miner"] = "Hijack the Meat vein",
							["100% Legal"] = "Ask for ore",
							["See You Next Fall"] = "Give 'im the stick",
							["More Locker Than Morlock"] = "Get to the choppa' (which is outside)",
						}, {}, "He-Boulder", 15)
					else
						script.bonus_target { "item" }
						script.ensure_buffs {}
						script.wear {}
						stop "TODO: Want trapper ore. End the day(?) or fight mountain men."
					end
				else
					ignore_buffing_and_outfit = false
					script.do_trapper_quest()
				end
			end
		}
	}

	add_task {
		when = challenge == "boris" and
			not have_hippy_outfit() and
			unlocked_island() and
			level() >= 9,
		task = {
			message = "get hippy outfit",
			bonus_target = { "noncombat" },
			action = function()
				script.go("get hippy outfit", 26, macro_autoattack, {}, {}, "He-Boulder", 15, { choice_function = function(advtitle, choicenum)
					if advtitle == "Peace Wants Love" then
						if not have_item("filthy corduroys") then
							return "Agree to take his clothes"
						else
							return "Say &quot;No thanks.&quot;"
						end
					elseif advtitle == "An Inconvenient Truth" then
						if not have_item("filthy knitted dread sack") then
							return "Check out the clothing"
						else
							return "Avert your eyes"
						end
					end
				end })
			end
		}
	}

	add_task {
		when = (challenge == "boris" or challenge == "zombie") and
			not cached_stuff.unlocked_hidden_temple and
			((have("Greatest American Pants") and get_daily_counter("item.fly away.free runaways") < 9) or daysthisrun() >= 2),
		task = {
			message = "unlock hidden temple",
			nobuffing = true,
			action = function()
				local woodspt = get_page("/woods.php")
				if woodspt:contains("The Hidden Temple") then
					cached_stuff.unlocked_hidden_temple = true
					did_action = true
				else
					ignore_buffing_and_outfit = false
					script.unlock_hidden_temple()
				end
			end
		}
	}

	add_task {
		prereq = mainstat_type("Muscle") and not have_item("Spookyraven gallery key") and level() < 13,
		f = script.do_muscle_powerleveling,
	}

	add_task {
		prereq = quest("Ooh, I Think I Smell a Bat.") and challenge == "fist",
		f = script.do_boss_bat,
	}

	add_task {
		when = level() < 7 and not cached_stuff.unlocked_hidden_temple,
		task = {
			message = "unlock hidden temple",
			nobuffing = true,
			action = function()
				local woodspt = get_page("/woods.php")
				if woodspt:contains("The Hidden Temple") then
					cached_stuff.unlocked_hidden_temple = true
					did_action = true
				else
					ignore_buffing_and_outfit = false
					script.unlock_hidden_temple()
				end
			end
		}
	}

	add_task {
		when = quest("There Can Be Only One Topping") and (level() >= 11 and not quest_text("Your first step is to find the Black Market")),
		task = tasks.there_can_be_only_one_topping,
	}

	add_task {
		when = not cached_stuff.unlocked_upstairs and not have_item("Spookyraven ballroom key"),
		task = function()
			local manor = get_page("/manor.php")
			if not manor:match("Stairs Up") then
				return {
					message = "unlock upstairs",
					fam = "Rogue Program",
					buffs = { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic", "A Few Extra Pounds", "The Moxious Madrigal" },
					bonus_target = { "noncombat" },
					minmp = 30,
					action = adventure {
						zoneid = 104,
						macro_function = macro_noodlecannon,
						choice_function = function(advtitle, choicenum)
							if advtitle == "Take a Look, it's in a Book!" then
								return "", 99
							elseif advtitle == "Melvil Dewey Would Be Ashamed" then
								return "Gaffle the purple-bound book"
							end
						end
					},
				}
			else
				cached_stuff.unlocked_upstairs = true
				return {
					message = "already unlocked upstairs",
					action = function() did_action = true end,
				}
			end
		end
	}


	add_task {
		when = DD_keys < 3 and not cached_stuff.done_daily_dungeon,
		task = tasks.do_daily_dungeon,
	}

	add_task {
		prereq = level() < 10,
		f = function()
			use_dancecard()
			do_powerleveling()
		end,
		message = "level to 10",
	}

	add_task {
		prereq = quest("The Rain on the Plains is Mainly Garbage") or (level() >= 10 and not have_item("steam-powered model rocketship") and ascensionstatus() == "Hardcore"),
		f = function()
			if have_item("BitterSweetTarts") and not have_buff("Full of Wist") then
				use_item("BitterSweetTarts")
			end
			use_dancecard()
			local plainspt = get_page("/plains.php")
			if plainspt:match("A Giant Pile of Coffee Grounds") then
				inform "do beanstalk"
				if have_item("enchanted bean") then
					use_item("enchanted bean")
					plainspt = get_page("/plains.php")
					if not plainspt:match("A Giant Pile of Coffee Grounds") then
						did_action = true
					end
				else
					script.go("get enchanted bean", 33, macro_autoattack, nil, { "Leash of Linguini" }, "Slimeling", 5)
				end
				return result, resulturl, did_action
			end
			script.bonus_target { "noncombat" }

			if not have_item("S.O.C.K.") then
				script.maybe_ensure_buffs { "Ur-Kel's Aria of Annoyance", "Silent Running" }
				script.go("do airship", 81, macro_noodlecannon, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Ur-Kel's Aria of Annoyance", "Spirit of Garlic", "Leash of Linguini", "Empathy" }, "Slimeling even in fist", 35, { choice_function = function(advtitle, choicenum)
					if advtitle == "Random Lack of an Encounter" then
						if not have_item("model airship") then
							return "Gallivant down to the head"
						else
							return "Investigate the crew quarters"
						end
					elseif advtitle == "Hammering the Armory" then
						return "Blow this popsicle stand"
					elseif advtitle == "F-F-Fantastic!" then
						return "Give him the spirits"
					end
				end })
				if have_item("S.O.C.K.") then
					did_action = true
				end
			elseif quest("The Rain on the Plains is Mainly Garbage") then
				script.maybe_ensure_buffs { "Silent Running" }
				script.do_castle()
			elseif not have_item("steam-powered model rocketship") and ascensionstatus() == "Hardcore" then
				script.maybe_ensure_buffs { "Silent Running" }
				script.unlock_hits()
			end
		end,
		message = "get steam-powered model rocketship",
	}

	local function have_wand_or_parts()
		if have_item("Wand of Nagamar") then
			return true
		else
			local wa = have_item("WA") or (have_item("ruby W") and have_item("metallic A"))
			local nd = have_item("ND") or (have_item("lowercase N") and have_item("heavy D"))
			return wa and nd
		end
	end

	add_task {
		when = function() return not ascensionstatus("Aftercore") and
			level() >= 10 and
			requires_wand_of_nagamar() and
			not have_wand_or_parts() and
			ensure_clover() end,
		task = {
			message = "clovering for wand",
			nobuffing = true,
			action = function()
				result, resulturl = autoadventure { zoneid = 322 }
				did_action = have_wand_or_parts()
			end
		}
	}

	add_task {
		when = not have_item("Wand of Nagamar") and
			requires_wand_of_nagamar() and
			have_wand_or_parts(),
		task = {
			message = "pasting wand",
			nobuffing = true,
			action = function()
				meatpaste_items("ruby W", "metallic A")
				meatpaste_items("lowercase N", "heavy D")
				meatpaste_items("WA", "ND")
				did_action = have_item("Wand of Nagamar")
			end
		}
	}

	add_task {
		prereq = level() < 11,
		f = function()
			use_dancecard()
			do_powerleveling()
		end,
		message = "level to 11",
	}

	add_task { prereq = challenge == "fist" and (whichday == 3) and not highskill_at_run and advs() < 100, f = function()
		if drunkenness() < estimate_max_safe_drunkenness() then
			if challenge == "fist" then
				script.wear { hat = "filthy knitted dread sack", pants = "filthy corduroys" }
				stop "TODO: mix and drink SHCs to max drunk"
			else
				inform "drinking at end of day 3"
				local pt, pturl, drank = script.drink_booze()
				if pt then
					return pt, pturl, drank
				end
			end
		end
	end }

	add_task {
		when = ascensionstatus() ~= "Hardcore" and quest("Make War, Not... Oh, Wait") and not have_frat_war_outfit(),
		task = {
			message = "pull frat war outfit",
			action = function()
				if daysthisrun() >= 3 then
					pull_in_softcore("beer helmet")
					pull_in_softcore("distressed denim pants")
					pull_in_softcore("bejeweled pledge pin")
					did_action = have_frat_war_outfit()
				else
					if not have_item("pumpkin") and not have_item("pumpkin bomb") then
						script.bonus_target { "combat" }
						pull_in_scboris("unbearable light")
						local macro = make_yellowray_macro("War")
						if not script.have_familiar("He-Boulder") then
							macro = "use unbearable light"
						end
						script.go("yellow raying frat house", 134, macro, {
							["Catching Some Zetas"] = "Wake up the pledge and throw down",
							["Fratacombs"] = "Wander this way",
							["One Less Room Than In That Movie"] = "Officers' Lounge",
						}, {}, "He-Boulder", 20, { equipment = { hat = "filthy knitted dread sack", pants = "filthy corduroys" } })
						did_action = have_frat_war_outfit() or (did_action and have_item("unbearable light"))
					else
						stop "TODO: Get frat war outfit [not automated when it's day 2]"
					end
				end
			end
		}
	}

	add_task {
		prereq = function() return quest("Make War, Not... Oh, Wait") and
			not have_frat_war_outfit() and
			ensure_yellow_ray() end,
		f = function()
			script.go("yellow raying frat house", 134, make_yellowray_macro("War"), {
				["Catching Some Zetas"] = "Wake up the pledge and throw down",
				["Fratacombs"] = "Wander this way",
				["One Less Room Than In That Movie"] = "Officers' Lounge",
			}, {}, "He-Boulder", 20, { equipment = { hat = "filthy knitted dread sack", pants = "filthy corduroys" } })
		end,
	}

	add_task {
		prereq = quest("Make War, Not... Oh, Wait") and not have_frat_war_outfit() and challenge == "boris",
		f = function()
			stop "TODO: Get frat war outfit in boris"
		end,
	}

	-- TODO: started late if the offstats are weak
	add_task {
		prereq = quest_text("see if you can't stir up some trouble") and
			basemoxie() >= 70 and basemysticality() >= 70 and
			have_frat_war_outfit() and
			not have_buff("Musk of the Moose"),
		f = function()
			-- TODO: get what's needed from hippy store first
			use_dancecard()
			script.bonus_target { "noncombat" }
			script.go("start war", 131, macro_noodlecannon, {
				["Bait and Switch"] = "Wake the cadet up and fight him",
				["Blockin' Out the Scenery"] = "The Lookout Tower",
				["The Thin Tie-Dyed Line"] = "The Rations Yurt",
			}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling", 30, { equipment = { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" } })
			if get_result():match("Begun, this frat war has.") then
				did_action = true
			end
		end,
	}

	add_task {
		prereq = quest_text("Your first step is to find the Black Market"),
		f = script.find_black_market,
	}

	add_task {
		prereq = quest_text("now to hit the Travel Agency and get yourself on a slow boat"),
		f = script.get_macguffin_diary,
	}

	add_task {
		prereq = quest_text("now the Council wants you to finish it") and have_item("PADL Phone"),
		f = function()
			if have_item("BitterSweetTarts") and not have_buff("Full of Wist") then
				use_item("BitterSweetTarts")
			end
			script.do_battlefield()
		end
	}

	add_task {
		prereq = quest_text("now the Council wants you to finish it") and not have_item("rock band flyers"),
		f = script.get_flyers,
	}

	add_task {
		prereq = (challenge == "fist" or challenge == "boris") and basemysticality() < 60,
		f = script.do_mysticality_powerleveling,
	}

	add_task {
		prereq = quest("Never Odd Or Even") and basemysticality() >= 60,
		f = script.do_never_odd_or_even_quest,
	}

	add_task {
		prereq = (challenge == "fist") and basemysticality() < 65 and level() >= 11,
		f = script.do_mysticality_powerleveling,
	}

	add_task {
		when = quest("A Pyramid Scheme") and
			not quest_text("found the little pyramid") and
			not have_item("Staff of Ed") and
			can_wear_weapons() and
			not have_item("UV-resistant compass") and
			turns_to_next_sr >= 3,
		task = tasks.get_uv_compass,
	}

	add_task {
		prereq = quest("A Pyramid Scheme") and
			not quest_text("found the little pyramid") and
			not have_item("Staff of Ed") and
			(not can_wear_weapons() or have_item("UV-resistant compass")),
		f = script.do_oasis_and_desert,
	}

	add_task {
		when = quest("A Pyramid Scheme") and quest_text("found the little pyramid") and have_item("Staff of Ed"),
		task = {
			message = "unlock pyramid",
			nobuffing = true,
			action = function()
				get_page("/place.php", { whichplace = "desertbeach", action = "db_pyramid1" })
				refresh_quest()
				if not quest_text("found the little pyramid") then
					did_action = true
				end
			end
		}
	}

	add_task {
		prereq = (level() + level_progress() < 11.75) or (challenge == "boris" and level() < 12),
		f = function()
			use_dancecard()
			do_powerleveling()
		end,
		message = "level to 12",
	}

	add_task {
		prereq = (challenge == "fist" or challenge == "boris") and basemysticality() < 70 and level() >= 12,
		f = script.do_mysticality_powerleveling,
	}

	add_task {
		prereq = challenge and basemoxie() < 70 and level() >= 12,
		f = script.do_moxie_powerleveling,
	}

	add_task {
		prereq = quest("In a Manor of Spooking"),
		f = script.do_manor_of_spooking,
	}

	add_task {
		prereq = quest("Gotta Worship Them All") and turns_to_next_sr >= 3,
		f = script.do_gotta_worship_them_all,
	}

	add_task {
		prereq = have_item("ancient amulet") and have_item("Eye of Ed") and have_item("Staff of Fats"),
		f = function()
			inform "paste staff of ed"
			meatpaste_items("Eye of Ed", "ancient amulet")
			meatpaste_items("headpiece of the Staff of Ed", "Staff of Fats")
			if have_item("Staff of Ed") then
				async_get_page("/beach.php", { action = "woodencity" })
				did_action = true
			end
		end,
	}

	add_task {
		prereq =
			count("star chart") < 3 and
			(challenge ~= "fist" or count("star chart") < 2) and
			(challenge ~= "boris" or count("star chart") < 2) and
			not have_item("Richard's star key") and
			(not trailed or trailed == "Astronomer") and
			have("steam-powered model rocketship") and ascensionstatus() == "Hardcore",
		f = function()
			if have_item("BitterSweetTarts") and not have_buff("Full of Wist") then
				use_item("BitterSweetTarts")
			end
			script.go("do hits astronomers", 83, make_cannonsniff_macro("Astronomer"), nil, { "Spirit of Peppermint", "Fat Leon's Phat Loot Lyric", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Slimeling", 60, { olfact = "Astronomer" })
		end,
	}

	add_task {
		prereq = quest("A Pyramid Scheme") and quest_text("found the hidden buried pyramid") and turns_to_next_sr >= 7,
		f = script.do_pyramid,
	}

	add_task {
		prereq = quest("Make War, Not... Oh, Wait") and basemoxie() >= 70 and basemysticality() >= 70,
		f = function()
			if not completed_filthworms() then
				if have_item("Polka Pop") and not have_buff("Polka Face") then
					use_item("Polka Pop")
				end
				-- TODO: increase priority with stench buffs up
				script.do_filthworms()
			elseif not completed_sonofa_beach() then
				script.do_sonofa()
			elseif not completed_gremlins() then
				script.do_junkyard()
			elseif not completed_arena() then
				inform "turn in rock band flyers"
				script.wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
				result, resulturl = get_page("/bigisland.php", { place = "concert" })
				if not have_item("rock band flyers") then
					did_action = true
				end
			end
		end,
	}

	add_task {
		prereq =
			not have_item("Richard's star key") and
			trailed ~= "Astronomer" and ascensionstatus() == "Hardcore",
		f = script.make_star_key,
	}

-- 	add_task {
-- 		prereq = not (
-- 			have("pine wand") or
-- 			have("ebony wand") or
-- 			have("hexagonal wand") or
-- 			have("aluminum wand") or
-- 			have("marble wand")
-- 		) and meat() >= 5000 and challenge ~= "fist",
-- 		f = script.get_dod_wand,
-- 	}

	add_task {
		when = quest("A Quest, LOL") and have_item("64735 scroll"),
		task = {
			message = "using 64735 scroll",
			nobuffing = true,
			action = function()
				set_result(use_item("64735 scroll"))
				did_action = have_item("facsimile dictionary")
			end
		}
	}

	add_task { prereq = true, f = function()
		if ((advs() < 50 and turnsthisrun() + advs() < 650) or (advs() < 10)) and fullness() >= 12 and drunkenness() >= estimate_max_safe_drunkenness() and not highskill_at_run then
			stop "TODO: end of day 4. (pvp,) overdrink"
		elseif level() < 13 then
			if ascensionstatus() ~= "Hardcore" then
				stop "Level to 13."
			end
			inform "level to 13"
			if count("disassembled clover") >= 3 then -- TODO: uncloset and trade them as well
				use_item("disassembled clover")
			end
			use_dancecard()
			do_powerleveling()
		elseif not have_item("huge mirror shard") then
			local lairpt = get_page("/lair1.php", { action = "gates" })
			local dapt = get_page("/da.php")
			if dapt:contains("The Enormous Greater-Than Sign") and not lairpt:contains("Gate that is Not a Gate") and lairpt:contains("arcane inscription in front of the gates") and ascensionstatus() == "Hardcore" then
				if have_item("plus sign") and meat() < 1000 then
					stop "Need 1k meat for oracle"
				end
				script.go("do > sign", 226, macro_noodlecannon, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic" }, "Slimeling", 25, { choice_function = function(advtitle, choicenum)
					if advtitle == "Typographical Clutter" then
						if not have_item("plus sign") then
							return "The big apostrophe"
						else
							return "The upper-case Q"
						end
					end
				end, finalcheck = function()
						if meat() < 1000 then
							stop "Need 1k meat for oracle"
						end
					end
				})
			else
				inform "do lair entrance"
				set_result(get_page("/lair1.php", { action = "gates" }))
				if get_result():contains([[value="mirror"]]) then
					inform "break mirror"
					set_equipment {}
					result, resulturl = get_page("/lair1.php", { action = "mirror" })
					script.wear {}
					did_action = result:contains("huge mirror shard")
					return
				end
				local dod_tbl = get_dod_potion_status()
				local dod_reverse = {}
				for a, b in pairs(dod_tbl) do
					dod_reverse[b] = a
				end
				local got_items = true
				for a, b in pairs(lair_gateitems) do
					if get_result():contains(a) then
						local needitem = b.item or dod_reverse[b.potion]
						local got = false
						if needitem and moonsign_area() == "Gnomish Gnomad Camp" and not have(needitem) then
							buy_item(needitem, "n")
						end
						if needitem and have(needitem) then
							got = true
						else
							got_items = false
						end
						print("Need", b.effect, needitem, got)
					end
				end
				if got_items then
					print("woo got them!")
				end
				result = add_message_to_page(get_result(), "TODO: do lair gates, then run script again", nil, "darkorange")
				finished = true
			end
		else
			-- TODO: Make it so we can do one level at a time, not all 3 at once?
			local pt, pturl = get_page("/lair3.php")
			if pt:contains("lair4.php") then
				local itemsneeded = session["zone.lair.itemsneeded"] or {}
				local function check_levels(lvls)
					local allok = true
					for _, level in ipairs(lvls) do
						local thisok = false
						local item = itemsneeded[level + 1]
						if item then
							if have(item) then
								print("have lair", level, item)
								thisok = true
							else
								print("missing lair", level, item)
							end
						end
						if not thisok then
							allok = false
						end
					end
					return allok
				end
				local function make_tower_macro(level)
					return [[

use ]] .. itemsneeded[level + 1] .. [[

]]
				end
				local pt, pturl = get_page("/lair4.php")
				if pt:contains("lair5.php") then
					local pt, pturl = get_page("/lair5.php")
					if pt:contains("lair6.php") then
						result, resulturl = get_page("/lair6.php")
						if result:contains("place=0") then
							inform "pass door riddle"
							result, resulturl = get_page("/lair6.php", { place = 0 })
							automate_lair6_place(0, result)
							pt, pturl = get_page("/lair6.php")
							did_action = pt:contains("place=1")
						elseif result:contains("place=1") then
							inform "avoid electrical attack"
							if can_wear_weapons() then
								script.wear { weapon = "huge mirror shard" }
							end
							result, resulturl = get_page("/lair6.php", { place = 1 })
							script.wear {}
							did_action = result:contains("place=2")
						elseif result:contains("place=2") and have_skill("Ambidextrous Funkslinging") and count_item("gauze garter") >= 8 then
							inform "defeat shadow"
							script.wear {}
							script.heal_up()
							script.want_familiar "Frumious Bandersnatch"
							set_mcd(0)
							local pt, url = get_page("/lair6.php", { place = 2 })
							result, resulturl, advagain = handle_adventure_result(pt, url, "?", [[
]] .. COMMON_MACROSTUFF_START(20, 5) .. [[

if hasskill Saucy Salve
  cast Saucy Salve
endif

use gauze garter, gauze garter
use gauze garter, gauze garter
use gauze garter, gauze garter
use gauze garter, gauze garter

]])
							did_action = get_result():contains("<!--WINWINWIN-->")
						elseif result:contains("place=3") or result:contains("place=4") then
							inform "pass NS familiars"
							script.ensure_buffs { "Leash of Linguini", "Empathy", "Billiards Belligerence" }
							script.maybe_ensure_buffs_in_fist { "Leash of Linguini", "Empathy", "Billiards Belligerence" }
							script.heal_up()
							result, resulturl = get_page("/lair6.php", { place = 3 })
							automate_lair6_place(3, result)
							script.heal_up()
							result, resulturl = get_page("/lair6.php", { place = 4 })
							automate_lair6_place(4, result)
							pt, pturl = get_page("/lair6.php")
							did_action = pt:contains("place=5")
						else
							inform "TODO: finish lair (6)"
							script.wear {}
							script.heal_up()
							result, resulturl = get_page("/lair6.php")
							result = add_message_to_page(get_result(), "TODO: Finish top of tower", nil, "darkorange")
							finished = true
						end
					else
						if check_levels { 4, 5, 6 } then
							async_post_page("/lair5.php", { action = "level1" })
							local pt, url = get_page("/fight.php")
							result, resulturl, advagain = handle_adventure_result(pt, url, "?", make_tower_macro(4))
							async_post_page("/lair5.php", { action = "level2" })
							local pt, url = get_page("/fight.php")
							result, resulturl, advagain = handle_adventure_result(pt, url, "?", make_tower_macro(5))
							async_post_page("/lair5.php", { action = "level3" })
							local pt, url = get_page("/fight.php")
							result, resulturl, advagain = handle_adventure_result(pt, url, "?", make_tower_macro(6))
							local pt, pturl = get_page("/lair5.php")
							if pt:contains("lair6.php") then
								did_action = true
							end
						else
							inform "TODO: finish lair (5)"
							result, resulturl = get_page("/lair5.php")
							result = add_message_to_page(get_result(), "TODO: Finish upper part of tower", nil, "darkorange")
							finished = true
						end
					end
				else
					if check_levels { 1, 2, 3 } then
						async_post_page("/lair4.php", { action = "level1" })
						local pt, url = get_page("/fight.php")
						result, resulturl, advagain = handle_adventure_result(pt, url, "?", make_tower_macro(1))
						async_post_page("/lair4.php", { action = "level2" })
						local pt, url = get_page("/fight.php")
						result, resulturl, advagain = handle_adventure_result(pt, url, "?", make_tower_macro(2))
						async_post_page("/lair4.php", { action = "level3" })
						local pt, url = get_page("/fight.php")
						result, resulturl, advagain = handle_adventure_result(pt, url, "?", make_tower_macro(3))
						local pt, pturl = get_page("/lair4.php")
						if pt:contains("lair5.php") then
							did_action = true
						end
					else
						inform "TODO: finish lair (4)"
						result, resulturl = get_page("/lair4.php")
						result = add_message_to_page(get_result(), "TODO: Finish lower part of tower", nil, "darkorange")
						finished = true
					end
				end
			elseif pturl:contains("/lair3.php") then
				inform "finish lair (3)"
				script.heal_up()
				script.ensure_mp(100)
				local pt, url = post_page("/lair3.php", { action = "hedge" })
				result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_noodleserpent)
				if have_item("hedge maze puzzle") and not locked() then
					solve_hedge_maze_puzzle()
					advagain = true
				end
				did_action = advagain
			else
				inform "TODO: finish lair (2)"
				if challenge == "fist" then
					script.ensure_buffs { "Earthen Fist" }
				end
				result, resulturl = get_page("/lair2.php")
				result = add_message_to_page(get_result(), "TODO: do lair (2)", nil, "darkorange")
				finished = true
			end
		end
	end }

	function run_task(x)
		ignore_buffing_and_outfit = false
		if x.f then
			if x.message then
				hidden_inform(x.message)
			end
			if have_item("detuned radio") or (moonsign_area() == "Little Canadia") or (moonsign_area() == "Gnomish Gnomad Camp" and unlocked_beach()) then
				if mcd() < 10 and level() < 13 then
					if moonsign_area() == "Little Canadia" then
						set_mcd(11)
					else
						set_mcd(10)
					end
				elseif mcd() ~= 0 and level() >= 13 then
					set_mcd(0)
				end
			end
			x.f()
		else
			x.prereq = nil
			if not x.hide_message and not debug_show_empty_messages then
				if x.message then
					inform(x.message)
				elseif debug_show_empty_messages then
					inform "{ no task message }"
				end
			end
			x.message = nil
			x.hide_message = nil

			if x.mcd then
				set_mcd(x.mcd)
			elseif have_item("detuned radio") or (moonsign_area() == "Little Canadia") or (moonsign_area() == "Gnomish Gnomad Camp" and unlocked_beach()) then
				if mcd() < 10 and level() < 13 then
					if moonsign_area() == "Little Canadia" then
						set_mcd(11)
					else
						set_mcd(10)
					end
				elseif mcd() ~= 0 and level() >= 13 then
					set_mcd(0)
				end
			end
			x.mcd = nil

			if x.nobuffing then
				ignore_buffing_and_outfit = true
				x.nobuffing = nil
			end

			if x.bonus_target then
				script.bonus_target(x.bonus_target)
				x.bonus_target = nil
			end

			if x.runawayfrom then
				script.set_runawayfrom(x.runawayfrom)
				x.runawayfrom = nil
			end

			if x.buffs then
				script.ensure_buffs(x.buffs)
				x.buffs = nil
			elseif not ignore_buffing_and_outfit then
				script.ensure_buffs {}
			end

			if x.maybe_buffs then
				script.maybe_ensure_buffs(x.maybe_buffs)
				x.maybe_buffs = nil
			end

			script.heal_up()

			local towear = x.equipment or (not ignore_buffing_and_outfit and {})
			x.equipment = nil

			x.minmp = x.minmp or 0
			if x.olfact then
				if not trailed then
					x.minmp = x.minmp + 40
				elseif trailed ~= x.olfact then
					stop("Trailing " .. trailed .. " when trying to olfact " .. x.olfact)
				end
				x.olfact = nil
			end

			if arrowed_possible and x.minmp < 60 then
				x.minmp = 60
			end

			x.familiar = x.familiar or x.fam
			if x.familiar then
				-- TODO: unequip fam?
				local famt = script.want_familiar(x.familiar)
				local fammpregen, famequip = famt.mpregen, famt.familiarequip
				if fammpregen then
					if challenge == "fist" then
						script.burn_mp(x.minmp + 40)
					else
						script.burn_mp(x.minmp + 20)
					end
				end
				if famequip and towear and not towear.familiarequip and have(famequip) then
					towear.familiarequip = famequip
				end
				x.familiar = nil
				x.fam = nil
			end

			if towear then
				script.wear(towear)
			end

			if x.minmp then
				script.ensure_mp(x.minmp)
				x.minmp = nil
			end

			if x.finalcheck then
				x.finalcheck()
				x.finalcheck = nil
			end

			local pt, pturl, advagain = x.action()
			if pt then
				result, resulturl = pt, pturl
			end
			x.action = nil

			if x.after_action then
				x.after_action()
			end
			x.after_action = nil

			if advagain then
				did_action = true
			end

			ensure_empty_config_table(x)
		end
	end

	for _, x in ipairs(tasks_list) do
		--print("DEBUG taskcheck", pretty_tostring { message = x.message, task = x.task, prereq = x.prereq, when = x.when, when_function = type(x.when) == "function" and x.when() })
		if x.task ~= nil then
			local triggered = false
			if type(x.when) == "function" then
				triggered = x.when()
			else
				triggered = x.when
			end
			if triggered then
				if type(x.task) == "function" then
					run_task(x.task())
				else
					run_task(x.task)
				end
				break
			end
		elseif x.prereq ~= nil then
			local triggered = false
			if type(x.prereq) == "function" then
				triggered = x.prereq()
			else
				triggered = x.prereq
			end
			if triggered then
				run_task(x)
				break
			end
		end
	end

	if not did_action and get_result():contains("You need a more advanced cooking appliance") then
		if have_item("Dramatic&trade; range") then
			inform "  using dramatic range"
			set_result(use_item("Dramatic&trade; range"))
			did_action = not have_item("Dramatic&trade; range")
		else
			inform "  buying dramatic range"
			set_result(buy_item("Dramatic&trade; range", "m"))
			did_action = have_item("Dramatic&trade; range")
		end
	end

	if not did_action and get_result():contains("Your cocktail set is not advanced enough") then
		if have_item("Queue Du Coq cocktailcrafting kit") then
			print "  using cocktailcrafting kit"
			set_result(use_item("Queue Du Coq cocktailcrafting kit"))
			did_action = not have_item("Queue Du Coq cocktailcrafting kit")
		else
			print "  buying cocktailcrafting kit"
			set_result(buy_item("Queue Du Coq cocktailcrafting kit", "m"))
			did_action = have_item("Queue Du Coq cocktailcrafting kit")
		end
	end

	if not did_action then
		if get_result():contains("You acquire an item: <b>Cobb's Knob lab key</b>") and get_result():contains("you see a glint of metal sticking out from the edge of one of the ubiquitous piles of garbage") then
			did_action = true
		end
		if get_result():contains("surging oil finally drops in pressure enough for you to get up to the signal fire") then
			did_action = true
		end
		if get_result():contains("finally see a clear path to the signal fire and make your way to it") then
			did_action = true
		end
	end

	if have_buff("Beaten Up") then
		if get_result():contains("That's all the horror you can take.  You flee the scene.") then
			if have_buff("Beaten Up") then
				cast_skillid(1010)
			end
			if have_buff("Beaten Up") then
				cast_skillid(1007)
			end
			if have_buff("Beaten Up") then
				use_item("tiny house")
			end
			if have_buff("Beaten Up") then
				use_hottub()
			end
			did_action = not have_buff("Beaten Up")
		else
			did_action = false
		end
	end

	if not did_action and not finished then
		result = add_message_to_page(get_result(), "Automation stopped while trying to do: <tt>" .. table.concat(get_error_trace_steps(), " &rarr; ") .. "</tt>", "Automation stopped:", "darkorange")
	end

	return result, resulturl, did_action
end

function disable_autoattack()
	async_get_page("/account.php", { action = "autoattack", value = 0, ajax = 1, pwd = session.pwd })
end

local function do_loop(whichday)
	if show_spammy_automation_events then
		enable_function_debug_output()
	end
	print("Running automation script, day", whichday)
-- 	if autoattack_is_set() then
-- 		disable_autoattack()
-- 	end
	if autoattack_is_set() then
		stop "Disable your autoattack. The ascension script will handle (most) combats automatically."
	end
	local loop = true
	while loop do
		loop = false
		local result, resulturl, did_action = automate_hcnp_day(whichday)
		if did_action then
			loop = true
		else
			text, url = [[<script>top.charpane.location = "charpane.php"</script>]] .. tostring(get_result()), resulturl
		end
	end
	print("finished...", url)
	return text, url
end

ascension_automation_script_href = add_automation_script("automate-ascension", function()
	return do_loop(tonumber(params.whichday))
end)

local ascension_script_options_tbl = {
	["stop on imported beer"] = { yes = "stop", no = "drink as fallback booze" },
	["skip azazel quest"] = { yes = "skip quest", no = "get steel organ" },
	["manual lvl 9 quest"] = { yes = "stop and do manually", no = "automate" },
	["manual castle quest"] = { yes = "stop and do manually", no = "automate" },
	["eat manually"] = { yes = "eat manually", no = "automate consumption" },
	["ignore automatic pulls"] = { yes = "only pull softcore items manually", no = "automate some pulls", when = function() return not ascensionstatus("Hardcore") end },
	["train skills manually"] = { yes = "train manually", no = "automate training", when = function() return ascensionpath("Avatar of Jarlsberg") end },
	["100% familiar run"] = { yes = "don't change familiar", no = "automate familiar choice" },
	["overdrink with nightcap"] = { yes = "overdrink automatically", no = "don't automate" },
}

function ascension_script_option(name)
	if not ascension_script_options_tbl[name] then
		critical("Unsupported script option: " .. tostring(name))
	end
	local opts = ascension["__script.ascension script options"] or {}
	return opts[name] == "yes"
end

ascension_automation_setup_href = add_automation_script("setup-ascension-automation", function()
	if params.confirm == "yes" then
		local opts = {}
		for x, _ in pairs(ascension_script_options_tbl) do
			opts[x] = params[x]
		end
		ascension["__script.ascension script enabled"] = true
		ascension["__script.ascension script options"] = opts
		return get_page("/main.php")
	end

	local ok_paths = { [0] = true, ["Way of the Surprising Fist"] = true, ["Avatar of Boris"] = true, [10] = true, ["Avatar of Jarlsberg"] = true, ["BIG!"] = true }
	local path_support_text = ""
	local pathdesc = string.format([[%s %s]], ascensionstatus(), ascensionpathname())
	if ascensionpathid() == 0 then
		pathdesc = ascensionstatus()
	end
	local path_is_ok = true
	if (not ok_paths[ascensionpathid()] and not ok_paths[ascensionpathname()]) or (ascensionpathid() == 0 and ascensionstatus() ~= "Hardcore") then
		path_is_ok = false
	end
	if not path_is_ok then
		path_support_text = string.format([[<p style="color: darkorange">You are currently in %s. This is not a well supported path for the ascension script.</p>]], pathdesc)
	else
		path_support_text = string.format([[<p>You are currently in %s.</p>]], pathdesc)
	end
	local setting_buttons = {}
	for x, y in pairs(ascension_script_options_tbl) do
		if not y.when or y.when() then
			table.insert(setting_buttons, string.format([[%s: <input type="radio" name="%s" value="no" checked>%s]], x, x, y.no))
			table.insert(setting_buttons, string.format([[| %s<input type="radio" name="%s" value="yes"><br>]], y.yes, x))
		end
	end
	text = [[
<html>
<body>
<p>Are you sure you want to enable ascension automation for this run?</p>
]] .. path_support_text .. [[
<form action="/kolproxy-automation-script" method="get">
<input type="hidden" name="pwd" value="]]..session.pwd..[[">
<input type="hidden" name="confirm" value="yes">
<input type="hidden" name="automation-script" value="setup-ascension-automation">
]] .. table.concat(setting_buttons, "\n") .. [[
<input type="submit">
</form>
</body>
</html>]]
	return text, requestpath
end)

add_printer("/main.php", function()
	if not setting_enabled("enable turnplaying automation") then return end
	if not setting_enabled("enable turnplaying automation in-run") then return end
	if tonumber(status().freedralph) == 1 then
		text = text:gsub([[title="Bottom Edge".-</table>]], [[%0<table><tr><td><center><a href="]]..custom_aftercore_automation_href { pwd = session.pwd }..[[" style="color: green">{ Setup/run scripts }</a></center></td></tr></table>]])
		return
	end

	if ascension["__script.ascension script enabled"] == true then
		local links = {
			{ titleday = " day 1", whichday = 1 },
			{ titleday = " day 2", whichday = 2 },
			{ titleday = " day 3", whichday = 3 },
			{ titleday = " day 4+", whichday = 4 },
		}
		if not ascensionpath("Way of the Surprising Fist") then
			links = {
				{ titleday = "", whichday = 1000 },
			}
		end

		local rows = {}
		for _, x in ipairs(links) do
			local alink = [[<a href="]]..ascension_automation_script_href { pwd = session.pwd, whichday = x.whichday }..[[" style="color: green">{ Automate ascension]]..x.titleday..[[ }</a>]]
			if x.whichday == daysthisrun() then
				alink = [[&rarr; ]] .. alink .. [[ &larr;]]
			end
			table.insert(rows, [[<tr><td><center>]] .. alink .. [[</center></td></tr>]])
		end
		text = text:gsub([[title="Bottom Edge".-</table>]], [[%0<table>]] .. table.concat(rows) .. [[</table>]])
	else
		local rows = {}
		local alink = [[<a href="]]..ascension_automation_setup_href { pwd = session.pwd }..[[" style="color: green">{ Setup ascension automation }</a>]]
		table.insert(rows, [[<tr><td><center>]] .. alink .. [[</center></td></tr>]])
		text = text:gsub([[title="Bottom Edge".-</table>]], [[%0<table>]] .. table.concat(rows) .. [[</table>]])
	end
end)
