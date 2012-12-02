local script = nil

local function maybe_pull_item(name, amount)
	amount = amount or 1
	if count(name) < amount then
		async_post_page("/storage.php", { action = "pull", whichitem1 = get_itemid(name), howmany1 = amount - count(name), pwd = session.pwd, ajax = 1 })
		if amount > 1 and count(name) < amount then
			critical("Couldn't pull " .. tostring(amount) .. "x " .. tostring(name))
		end
	end
end

function setup_turnplaying_script(tbl)
	return add_automation_script(tbl.name, function ()
		if tbl.preparation then
			tbl.preparation()
		end

		if not tbl.macro and not autoattack_is_set() then
			stop "Set a macro on autoattack to use for scripting this quest."
		end

		-- +++ TODO: merge with common automation
		-- TODO: cache quest per pageload
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
		questlog_page = questlog_page_async()
		script = get_automation_scripts()

		function cast_autoattack_macro()
			local attid = status().flag_config.autoattack
			local macroid = attid:match("^99([0-9]+)$")
			if tonumber(macroid) then
				local pt, pturl = post_page("/fight.php", { action = "macro", macrotext = "", whichmacro = macroid })
				return handle_adventure_result(pt, pturl)
			else
				return result, resulturl, advagain
--/fight.php [("action","skill"),("whichskill","3022")]
			end
		end

		function inform(msg)
			local mpstr = string.format("%s / %s MP", mp(), maxmp())
			if challenge == "zombie" then
				mpstr = string.format("%s horde", horde_size())
			end
			local formatted = string.format("[%s] %s (level %s.%02d, %s turns remaining, %s full, %s drunk, %s spleen, %s meat, %s)", turnsthisrun(), tostring(msg), level(), level_progress() * 100, advs(), fullness(), drunkenness(), spleen(), meat(), mpstr)
			print(formatted)
		end

		-- --- TODO: merge with common automation

		advagain = true
		while advagain do
			advagain = false
			result, resulturl = nil, nil
			if advs() == 0 then
				stop "Out of adventures."
			end
			refresh_quest()
			inform(tbl.name)
			tbl.adventuring()
		end
		return result, resulturl
	end)
end

local felonia_href = setup_turnplaying_script {
	name = "automate-felonia",
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
		if quest_text("investigate the Gnolls' bugbear pens") then
			result, resulturl = get_page("/knoll.php", { place = "mayor" })
			refresh_quest()
			advagain = quest_text("find your way to the spooky gravy fairies' barrow")
		elseif quest_text("but first he needs you to") then
			result, resulturl = get_page("/knoll.php", { place = "mayor" })
			refresh_quest()
			advagain = quest_text("investigate the Spooky Gravy Barrow")
		elseif quest_text("investigate the Spooky Gravy Barrow") then
			script.set_familiar "Flaming Gravy Fairy"
			if not have("spooky glove") and have("small leather glove") and have("spooky fairy gravy") then
				result, result_url = cook_items("small leather glove", "spooky fairy gravy")()
				advagain = have("spooky glove")
			else
				if not have_equipped_item("ring of conflict") then
					equip_item("ring of conflict", "acc2")
				end
				if not have_equipped_item("Space Trip safety headphones") then
					equip_item("Space Trip safety headphones", "acc3")
				end
				if have("spooky glove") and have("inexplicably glowing rock") then
					equip_item("spooky glove", "acc1")
				end
				if not buff("The Sonata of Sneakiness") then
					cast_skillid(6015, 2) -- sonata of sneakiness
				end
				if not buff("Smooth Movements") then
					cast_skillid(5017, 2) -- smooth moves
				end
				result, resulturl, advagain = autoadventure {
					zoneid = 48,
					specialnoncombatfunction = function (advtitle, choicenum, pt)
						if advtitle == "Heart of Very, Very Dark Darkness" then
							if have_equipped("spooky glove") and have("inexplicably glowing rock") then
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
		else
			result, resulturl = get_page("/knoll.php", { place = "mayor" })
		end
	end,
}

add_printer("/questlog.php", function ()
	if not setting_enabled("enable turnplaying automation") or ascensionstatus() ~= "Aftercore" then return end
	text = text:gsub("<b>A Bugbear of a Problem</b>", [[%0 <a href="]]..felonia_href { pwd = session.pwd }..[[" style="color:green">{ automate }</a>]])
end)
