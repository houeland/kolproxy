sea_automation_gladiator_macro = [[
if monstername the
  cast Volcanometeor Showeruption
  goto done
endif
cast Stringozzi Serpent
cast Stringozzi Serpent
mark done
]]

local violence_href = setup_turnplaying_script {
	name = "automate-sea-violence",
	description = "Automate sea (gladiator colosseum / violence boss)",
	when = function() return ascension["zones.sea.deepcity reached"] and not ascension["zones.sea.deepcity temple finished"] end,
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
			stop "TODO: Kill temple boss."
		end
		__set_turnplaying_result(result, resulturl, advagain)
	end,
}
