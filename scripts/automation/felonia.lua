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

local felonia_href = add_automation_script("automate-felonia", function ()
	if not autoattack_is_set() then
		stop "Set a macro on autoattack to use for scripting this quest."
	end

	-- TODO: expect autoattack set
	-- +++ TODO: merge with common automation
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
	-- --- TODO: merge with common automation

	script = get_automation_scripts()
	maybe_pull_item("annoying pitchfork")
	maybe_pull_item("frozen mushroom")
	maybe_pull_item("stinky mushroom")
	maybe_pull_item("flaming mushroom")
	maybe_pull_item("ring of conflict")
	maybe_pull_item("Space Trip safety headphones")
	local function run_turns()
		advagain = false
		if advs() == 0 then
			return "Out of adventures.", requestpath
		end
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
				cook_items("small leather glove", "spooky fairy gravy")
				advagain = have("spooky glove")
			else
				if have("spooky glove") and have("inexplicably glowing rock") then
					equip_item("spooky glove", "acc1")
					equip_item("ring of conflict", "acc2")
					equip_item("Space Trip safety headphones", "acc3")
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
			end
		else
			result, resulturl = get_page("/knoll.php", { place = "mayor" })
		end
		if advagain then
			return run_turns()
		else
			return result, resulturl
		end
	end
	return run_turns()
end)

add_printer("/questlog.php", function ()
	if not setting_enabled("enable turnplaying automation") or ascensionstatus() ~= "Aftercore" then return end
	text = text:gsub("<b>A Bugbear of a Problem</b>", [[%0 <a href="]]..felonia_href { pwd = session.pwd }..[[" style="color:green">{ automate }</a>]])
end)
