-- TODO: Really Deep Breath support

sea_automation_kill_macro = function()
	local use_lasso = ""
	if have_equipped_item("sea cowboy hat") and have_equipped_item("sea chaps") then
		print("training lasso")
		use_lasso = [[

use sea lasso

]]
	end
	return [[
scrollwhendone

abort pastround 20
abort hppercentbelow 5

if (monstername Mer-Kin drifter) && (hascombatitem pulled yellow taffy) && (!haseffect Everything Looks Yellow)
	use pulled yellow taffy
endif

if hasskill Noodles of Fire
  cast Noodles of Fire
endif

]] .. noodles_action() .. [[

]] .. use_lasso .. [[

while !times 5

]] .. serpent_action() .. [[

endwhile
]]
end

sea_automation_tame_seahorse_macro = function()
	return [[
scrollwhendone

abort pastround 20
abort hppercentbelow 20

if hasskill Noodles of Fire
  cast Noodles of Fire
endif

]] .. noodles_action() .. [[

if monstername wild seahorse
  use sea cowbell
  use sea cowbell
  use sea cowbell
  use sea lasso
endif

if monstername Mer-kin rustler
  use crystal skull
endif

if monstername sea cowboy
  use divine champagne popper
endif

if monstername sea cow
  use pulled indigo taffy
endif

if monstername tumbleweed
  attack
  attack
endif

abort Unexpected fight in corral

]]
end

local function expertly_trained()
	return ascension["zones.sea.lasso expertly trained"]
end

local visited_old_man = false
local found_castle = false
local found_big_brother = false
local found_grandpa = false
local found_currents = false
local tamed_seahorse = false

local used_items = false

local function use_plusitem_items()
	if not used_items then
		use_item("moveable feast")
		use_item("The Legendary Beat")
		use_item("fishy pipe")
		used_items = true
	end
end

function automate_sea_find_castle()
	if have_item("wriggling flytrap pellet") then
		set_result(use_item("wriggling flytrap pellet"))
		advagain = not have_item("wriggling flytrap pellet")
		return
	end
	script.bonus_target { "item" }
	script.wear {
		hat = first_wearable { "Mer-kin scholar mask", "Mer-kin gladiator mask", "aerated diving helmet" },
		shirt = first_wearable { "sea salt scrubs" },
	}
	set_result(get_page("/monkeycastle.php"))
	if get_result():contains("Sea Monkee Castle") then
		set_result(async_get_page("/monkeycastle.php", { who = 1 }))
		found_castle = true
		advagain = true
		return
	end
	use_plusitem_items()
	script.ensure_buffs { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Ghostly Shell", "Astral Shell", "Leash of Linguini", "Empathy", "Donho's Bubbly Ballad" }
	script.heal_up()
	script.ensure_mp(100)
	result, resulturl, advagain = autoadventure {
		zoneid = 190,
		macro = automation_macro,
	}
end

local function get_exploration_outfit()
	local towear = {
		hat = first_wearable { "Mer-kin sneakmask" },
		container = first_wearable { "old SCUBA tank" },
		shirt = first_wearable { "sea salt scrubs" },
	}
	if not expertly_trained() then
		towear.hat = "sea cowboy hat"
		towear.pants = "sea chaps"
	end
	if not have_item("old SCUBA tank") then
		towear.hat = first_wearable { "Mer-kin scholar mask", "Mer-kin gladiator mask", "aerated diving helmet" }
	end
	return towear
end

function automate_sea_find_big_brother()
	script.bonus_target { "noncombat" }
	script.wear(get_exploration_outfit())
	set_result(get_page("/monkeycastle.php"))
	if get_result():contains("who=2") or not get_result():contains("littlebrother") then
		set_result(async_get_page("/monkeycastle.php", { who = 1 }))
		set_result(async_get_page("/monkeycastle.php", { who = 2 }))
		set_result(async_get_page("/monkeycastle.php", { who = 1 }))
		found_big_brother = true
		advagain = true
		return
	end
	script.ensure_buffs { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Ghostly Shell", "Astral Shell", "Leash of Linguini", "Empathy", "Smooth Movements", "The Sonata of Sneakiness" }
	script.heal_up()
	script.ensure_mp(100)
	result, resulturl, advagain = autoadventure {
		zoneid = 191,
		macro = automation_macro,
		noncombatchoices = {
			["Down at the Hatch"] = "Open the bulkhead",
		},
	}
end

function automate_sea_find_grandpa()
	script.bonus_target { "noncombat" }
	script.wear(get_exploration_outfit())
	set_result(get_page("/monkeycastle.php"))
	if get_result():contains("who=3") or not get_result():contains("brothers") then
		set_result(async_get_page("/monkeycastle.php", { who = 1 }))
		set_result(async_get_page("/monkeycastle.php", { who = 3 }))
		set_result(async_get_page("/monkeycastle.php", { action = "grandpastory", topic = "grandma" }))
		set_result(async_get_page("/monkeycastle.php", { who = 1 }))
		found_grandpa = true
		advagain = true
		return
	end
	script.ensure_buffs { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Ghostly Shell", "Astral Shell", "Leash of Linguini", "Empathy", "Smooth Movements", "The Sonata of Sneakiness" }
	script.heal_up()
	script.ensure_mp(100)
	local zoneid = nil
	if mainstat_type("Muscle") then
		zoneid = 196
	elseif mainstat_type("Mysticality") then
		zoneid = 195
	elseif mainstat_type("Moxie") then
		zoneid = 197
	end
	result, resulturl, advagain = autoadventure {
		zoneid = zoneid,
		macro = automation_macro,
		noncombatchoices = {
			["Not a Micro Fish"] = "Watch in horror",
			["A Vent Horizon"] = "Leave",
			["There is Sauce at the Bottom of the Ocean"] = "Leave",
			["You've Hit Bottom"] = "See what he wants to show you.",
			["Barback"] = "Leave it beaode",
			["Ode to the Sea"] = "Let Grandpa Learn You Something",
			["Boxing the Juke"] = "Listen to the Music",
		},
	}
end

function automate_sea_find_currents()
	set_result(get_page("/seafloor.php"))
	if get_result():contains("currents") then
		found_currents = true
		advagain = true
		return
	end

	if have_item("Mer-kin trailmap") then
		set_result(use_item("Mer-kin trailmap"))
		set_result(async_get_page("/monkeycastle.php", { action = "grandpastory", topic = "currents" }))
		advagain = not have_item("Mer-kin trailmap")
		return
	end

	if have_item("Mer-kin stashbox") then
		set_result(use_item("Mer-kin stashbox"))
		advagain = not have_item("Mer-kin stashbox")
		return
	end

	if have_item("Mer-kin lockkey") then
		script.bonus_target { "noncombat" }
		script.wear(get_exploration_outfit())
		script.ensure_buffs { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Ghostly Shell", "Astral Shell", "Leash of Linguini", "Empathy", "Smooth Movements", "The Sonata of Sneakiness" }
		script.heal_up()
		script.ensure_mp(100)
		result, resulturl, advagain = autoadventure {
			zoneid = 198,
			macro = automation_macro,
			specialnoncombatfunction = function(advtitle, choicenum, pt)
				if advtitle == "Into the Outpost" then
					local m = ascension["zones.sea.outpost lockkey monster"]
					if m == "Mer-kin raider" then
						return "Infiltrate the skull-bedecked tent"
					elseif m == "Mer-kin healer" then
						return "Insinuate yourself into the glyphed tent"
					elseif m == "Mer-kin burglar" then
						return "Sneak into the camouflaged tent"
					end
				elseif advtitle and advtitle:contains(" Intent") then
					local option = (session["zones.sea.outpost camp last choice option"] or 0) + 1
					session["zones.sea.outpost camp last choice option"] = option
					print("DEBUG: Exploring outpost, going to option", option, "at", advtitle)
					return "", option
				end
			end
		}
	else
		script.bonus_target { "item" }
		script.wear {
			hat = first_wearable { "Mer-kin scholar mask", "Mer-kin gladiator mask", "aerated diving helmet" },
			shirt = first_wearable { "sea salt scrubs" },
		}
		use_plusitem_items()
		script.ensure_buffs { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Ghostly Shell", "Astral Shell", "Leash of Linguini", "Empathy", "Donho's Bubbly Ballad" }
		script.heal_up()
		script.ensure_mp(100)
		result, resulturl, advagain = autoadventure {
			zoneid = 198,
			macro = automation_macro,
		}
	end
end

function automate_sea_tame_seahorse()
	set_result(get_page("/seafloor.php", { action = "currents" }))
	if not get_result():contains("far, far too strong for you to swim against") then
		result = get_result()
		tamed_seahorse = true
		advagain = false
		return
	end
	maybe_pull_item("sea lasso", 1)
	maybe_pull_item("sea cowbell", 3)
	maybe_pull_item("crystal skull", 1)
	maybe_pull_item("divine champagne popper", 1)
	maybe_pull_item("pulled indigo taffy", 1)

	if not expertly_trained() then
		script.bonus_target { "item" }
		script.wear(get_exploration_outfit())
		script.ensure_buffs { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "Ghostly Shell", "Astral Shell", "Leash of Linguini", "Empathy", "Donho's Bubbly Ballad" }
		script.heal_up()
		script.ensure_mp(100)
		result, resulturl, advagain = autoadventure {
			zoneid = 198,
			macro = automation_macro,
			noncombatchoices = {
				["Into the Outpost"] = "Leave the camp",
			},
		}
		return
	end

	script.bonus_target { "easy combat" }
	script.wear {
		hat = first_wearable { "Mer-kin scholar mask", "Mer-kin gladiator mask", "aerated diving helmet" },
		shirt = first_wearable { "sea salt scrubs" },
	}
	script.ensure_buffs { "Ghostly Shell", "Astral Shell" }
	script.heal_up()
	script.ensure_mp(100)
	result, resulturl, advagain = autoadventure {
		zoneid = 199,
		macro = sea_automation_tame_seahorse_macro,
	}
end

local violence_href = setup_turnplaying_script {
	name = "automate-sea-tame-seahorse",
	description = "Automate sea (tame seahorse, run this first)",
	when = function() return not accomplishment_text("tamed the mighty seahorse") end,
	macro = sea_automation_kill_macro,
	preparation = function()
		maybe_pull_item("sea salt scrubs")
		maybe_pull_item("ring of conflict", 1)
		maybe_pull_item("Mer-kin sneakmask", 1)
		maybe_pull_item("Space Trip safety headphones")
		maybe_pull_item("Fuzzy Slippers of Hatred")
		maybe_pull_item("silent beret")
		maybe_pull_item("Mer-kin scholar mask")
		maybe_pull_item("Mer-kin scholar tailpiece")
		maybe_pull_item("Mer-kin gladiator mask")
		maybe_pull_item("Mer-kin gladiator tailpiece")
		maybe_pull_item("aerated diving helmet")
		if not expertly_trained() then
			maybe_pull_item("sea cowboy hat", 1)
			maybe_pull_item("sea chaps", 1)
			maybe_pull_item("sea lasso", 1)
			maybe_pull_item("sea cowbell", 3)
			maybe_pull_item("crystal skull", 1)
			maybe_pull_item("divine champagne popper", 1)
			maybe_pull_item("pulled indigo taffy", 1)
		end
	end,
	autoinform = false,
	adventuring = function()
		result = "??? Didn't do anything ???"
		advagain = false
		script.want_familiar "Grouper Groupie"
		hidden_inform "getting seahorse"
		if not expertly_trained() then
			maybe_pull_item("sea lasso", 1)
		end
		if not visited_old_man then
			inform "visiting old man"
			set_result(async_get_page("/oldman.php"))
			set_result(async_get_place("sea_oldman", "oldman_oldman"))
			visited_old_man = true
			advagain = true
		elseif not found_castle then
			inform "finding castle"
			automate_sea_find_castle()
		elseif not found_big_brother then
			inform "finding big brother"
			automate_sea_find_big_brother()
		elseif not found_grandpa then
			inform "finding grandpa"
			automate_sea_find_grandpa()
		elseif not found_currents then
			inform "finding currents"
			automate_sea_find_currents()
		elseif not tamed_seahorse then
			inform "taming seahorse"
			automate_sea_tame_seahorse()
		else
			stop "Already tamed seahorse."
		end
		set_result(result)
		result = get_result()
		if result:match("and [a-z]* toss it over") then
			print("  lasso training: " .. result:match("and ([a-z]* toss it) over"))
			if result:contains("and expertly toss it over") then
				print("  expertly trained!")
				ascension["zones.sea.lasso expertly trained"] = true
			end
		end
		__set_turnplaying_result(result, resulturl, advagain)
	end,
}

-- pull 10 Mer-kin wordquiz & 10 Mer-kin cheatsheet
-- outfit scholar, adv at 208
-- use killscroll and healscroll and cast deep dark and use knucklebone and record everything and use dreadscroll
