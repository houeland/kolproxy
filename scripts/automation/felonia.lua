local dk_mayor_last = nil

local felonia_href = setup_turnplaying_script {
	name = "automate-felonia",
	description = "Defeat Felonia (Degrassi Knoll quest)",
	when = function() return moonsign_area() == "Degrassi Knoll" and not quest_completed("A Bugbear of a Problem") end,
	macro = nil,
	preparation = function()
		maybe_pull_item("annoying pitchfork")
		maybe_pull_item("frozen mushroom")
		maybe_pull_item("stinky mushroom")
		maybe_pull_item("flaming mushroom")
		maybe_pull_item("ring of conflict")
		maybe_pull_item("Space Trip safety headphones")
	end,
	adventuring = function()
		advagain = false
		result, resulturl = get_place("knoll_friendly", "dk_mayor")
		refresh_quest()
		if result ~= dk_mayor_last then
			dk_mayor_last = result
			advagain = true
		elseif quest_text("investigate the Spooky Gravy Burrow") then
			script.want_familiar "Flaming Gravy Fairy"
			if not have_item("spooky glove") and have_item("small leather glove") and have_item("spooky fairy gravy") then
				result, result_url = cook_items("small leather glove", "spooky fairy gravy")()
				advagain = have_item("spooky glove")
			else
				if not have_equipped_item("ring of conflict") then
					equip_item("ring of conflict", "acc2")
				end
				if not have_equipped_item("Space Trip safety headphones") then
					equip_item("Space Trip safety headphones", "acc3")
				end
				if have_item("spooky glove") and have_item("inexplicably glowing rock") then
					equip_item("spooky glove", "acc1")
				end
				if not have_buff("The Sonata of Sneakiness") then
					cast_skillid(6015, 2) -- sonata of sneakiness
				end
				if not have_buff("Smooth Movements") then
					cast_skillid(5017, 2) -- smooth moves
				end
				result, resulturl, advagain = autoadventure {
					zoneid = 48,
					specialnoncombatfunction = function(advtitle, choicenum, pt)
						if advtitle == "Heart of Very, Very Dark Darkness" then
							if have_equipped_item("spooky glove") and have_item("inexplicably glowing rock") then
								return "Enter the cave"
							else
								return "Don't enter the cave"
							end
						elseif advtitle == "How Depressing" then
							return "Put your hand in the depression"
						elseif advtitle == "On the Verge of a Dirge" then
							-- TODO: workaround, results show first and mess up the title recognition
							return "Enter the chamber"
						end
					end
				}
				if result:contains("Felonia, Queen of the Spooky Gravy Fairies") then
					result, resulturl, advagain = cast_autoattack_macro()
				end
			end
		end
		__set_turnplaying_result(result, resulturl, advagain)
	end,
}
