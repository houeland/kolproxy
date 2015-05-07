sea_automation_gladiator_macro = [[
if monstername the
  cast Volcanometeor Showeruption
  goto done
endif
cast Stringozzi Serpent
cast Stringozzi Serpent
mark done
]]

sea_automation_violence_boss_macro = [[
scrollwhendone

abort pastround 20
abort hppercentbelow 10

use crayon shavings, crayon shavings
use crayon shavings, crayon shavings
use crayon shavings, crayon shavings
use crayon shavings, crayon shavings
use crayon shavings, crayon shavings
attack
repeat
]]

local violence_href = setup_turnplaying_script {
	name = "automate-sea-violence",
	description = "Automate sea (gladiator colosseum / violence boss, needs seahorse)",
	when = function() return accomplishment_text("tamed the mighty seahorse") and not ascension["zones.sea.deepcity temple finished"] end,
	macro = sea_automation_gladiator_macro,
	preparation = function()
		maybe_pull_item("sea salt scrubs", 1)
		maybe_pull_item("sea shawl")
		maybe_pull_item("can of Rain-Doh")
		maybe_pull_item("Snow Suit")
		maybe_pull_item("Space Trip safety headphones")
		maybe_pull_item("Mer-kin gladiator mask", 1)
		maybe_pull_item("Mer-kin gladiator tailpiece", 1)
		maybe_pull_item("crayon shavings", 10)
		maybe_pull_item("Rain-Doh green lantern", 1)
	end,
	autoinform = false,
	adventuring = function()
		advagain = false
		script.want_familiar "Magic Dragonfish"
		hidden_inform "doing gladiator/violence path"
		if not ascension["zones.sea.defeated gladiators"] then
			script.wear {
				hat = "Mer-kin gladiator mask",
				container = first_wearable { "sea shawl" },
				shirt = "sea salt scrubs",
				offhand = "Rain-Doh green lantern",
			}
			script.ensure_buffs { "Frigidalmatian", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds", "Reptilian Fortitude", "Pisces in the Skyces", "Spirit of Garlic" }
			script.wear {
				hat = "Mer-kin gladiator mask",
				container = first_wearable { "sea shawl" },
				shirt = "sea salt scrubs",
				offhand = "Rain-Doh green lantern",
				pants = "Mer-kin gladiator tailpiece",
			}
			inform "defeat gladiators"
			script.ensure_mp(100)
			script.force_heal_up()
			script.ensure_mp(100)
			maybe_pull_item("volcanic ash")
			result, resulturl, advagain = autoadventure {
				zoneid = 210,
				macro = sea_automation_gladiator_macro,
			}
			if result:contains("Colosseum is empty") or result:contains("branding its pattern into both your mask and your forehead") then
				ascension["zones.sea.defeated gladiators"] = true
			end
		else
			script.bonus_target { "easy combat" }
			script.ensure_buffs { "Astral Shell", "Ghostly Shell", "A Few Extra Pounds", "Reptilian Fortitude" }
			script.wear {
				hat = "Mer-kin gladiator mask",
				container = first_wearable { "sea shawl" },
				shirt = "sea salt scrubs",
				weapon = first_wearable { "Brimstone Bludgeon" },
				offhand = first_wearable { "Brimstone Bunker" },
				pants = "Mer-kin gladiator tailpiece",
			}
			local damage_sources = have_buff("Frigidalmatian") or have_buff("Jalape&ntilde;o Saucesphere") or have_buff("Scarysauce")
			switch_familiarid(0)
			if have_equipped_item("Brimstone Bludgeon") and have_equipped_item("Brimstone Bunker") and count_item("crayon shavings") >= 10 and not damage_sources and familiarid() == 0 and have_skill("Ambidextrous Funkslinging") then
				script.force_heal_up()
				async_get_page("/sea_merkin.php", { action = "temple" })
				async_get_page("/choice.php", { forceoption = 0 })
				async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 706, option = 1 })
				async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 707, option = 1 })
				result, resulturl = get_page("/choice.php", { pwd = get_pwd(), whichchoice = 708, option = 1 })
                                result, resulturl, advagain = handle_adventure_result(result, resulturl, "?", sea_automation_violence_boss_macro)
				-- async_get_page("/choice.php")
				-- async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 709, option = 1 })
			else
				stop "Kill temple boss manually."
			end
		end
		__set_turnplaying_result(result, resulturl, advagain)
	end,
}
