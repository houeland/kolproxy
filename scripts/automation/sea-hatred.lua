sea_automation_scroll_macro = function()
	return [[
scrollwhendone

abort pastround 20
abort hppercentbelow 5

if hasskill Noodles of Fire
  cast Noodles of Fire
endif

]] .. noodles_action() .. [[

use Mer-kin healscroll
use Mer-kin killscroll

while !times 5

]] .. serpent_action() .. [[

endwhile
]]
end

local learned_vocabulary = false
local library_turns = 0
local last_noncombat_option = 0

local hatred_href = setup_turnplaying_script {
	name = "automate-sea-hatred",
	description = "Automate sea (scholar library / hatred boss, needs seahorse)",
	when = function() return accomplishment_text("tamed the mighty seahorse") and not ascension["zones.sea.deepcity temple finished"] end,
	macro = sea_automation_kill_macro,
	preparation = function()
		maybe_pull_item("sea salt scrubs", 1)
		maybe_pull_item("Mer-kin scholar mask", 1)
		maybe_pull_item("Mer-kin scholar tailpiece", 1)
		maybe_pull_item("Mer-kin prayerbeads", 3)
	end,
	autoinform = false,
	adventuring = function()
		advagain = false
		script.want_familiar "Grouper Groupie"
		hidden_inform "doing scholar/hatred path"
		if ascension["zones.sea.read darkscroll prophecy"] then
			inform "killing temple boss"
			stop "TODO: Wear 3 prayerbeads, pull a lot of healing items, kill temple boss."
		elseif not learned_vocabulary then
			inform "training Mer-kin vocabulary"
			maybe_pull_item("Mer-kin wordquiz", 1)
			maybe_pull_item("Mer-kin cheatsheet", 1)
			result, resulturl = use_item("Mer-kin wordquiz")()
			if result:contains("learned everything you're going to learn") then
				learned_vocabulary = true
				advagain = true
			elseif result:contains("vocabulary mastery is now at") then
				advagain = true
			end
		else
			local words = ascension["zones.sea.dreadscroll words"] or {}
			local macro = sea_automation_kill_macro
			local should_adventure = false
			if not words["Mer-kin healscroll"] or not words["Mer-kin killscroll"] and library_turns < 10 then
				inform "learning healscroll/killscroll words"
				macro = sea_automation_scroll_macro
				maybe_pull_item("Mer-kin healscroll", 1)
				maybe_pull_item("Mer-kin killscroll", 1)
			elseif not words["Noncombat creature"] or not words["Noncombat phrase"] or not words["Noncombat scrawl"] and last_noncombat_option < 3 then
				inform "learning secret words"
			elseif not have_item("Mer-kin dreadscroll") and library_turns < 10 then
				inform "finding dreadscroll"
			else
				stop "TODO: Use knucklebone, cast deep dark visions. Use dreadscroll, guess sushi one."
			end
			if not words["Noncombat creature"] or not words["Noncombat phrase"] or not words["Noncombat scrawl"] and last_noncombat_option < 3 then
				script.bonus_target { "noncombat" }
				script.ensure_buffs { "Smooth Movements", "The Sonata of Sneakiness", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds", "Reptilian Fortitude", "Spirit of Garlic" }
			else
				script.ensure_buffs { "Astral Shell", "Ghostly Shell", "A Few Extra Pounds", "Reptilian Fortitude", "Spirit of Garlic" }
			end
			script.wear {
				hat = "Mer-kin scholar mask",
				container = first_wearable { "sea shawl" },
				shirt = first_wearable { "sea salt scrubs" },
				offhand = first_wearable { "Rain-Doh green lantern" },
				pants = "Mer-kin scholar tailpiece",
			}
			script.heal_up()
			script.ensure_mp(100)
			result, resulturl, advagain = autoadventure {
				zoneid = 208,
				macro = macro,
				specialnoncombatfunction = function(advtitle, choicenum, pagetext)
					if advtitle == "Playing the Catalog Card" and last_noncombat_option < 3 then
						last_noncombat_option = last_noncombat_option + 1
						return "", last_noncombat_option
					end
				end
			}
			library_turns = library_turns + 1
		end
		__set_turnplaying_result(result, resulturl, advagain)
	end,
}
