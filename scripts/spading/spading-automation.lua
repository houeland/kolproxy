local minelayout_href = add_automation_script("automate-spading-mine-layouts", function()
	equip_item("miner's helmet")
	equip_item("7-Foot Dwarven mattock")
	equip_item("miner's pants")
	equip_item("hippy medical kit", 1)
	local eq = equipment()
	if not ascensionstatus("Aftercore") then
		text, url = "Not in aftercore.", requestpath
	elseif eq.hat ~= get_itemid("miner's helmet") or eq.weapon ~= get_itemid("7-Foot Dwarven mattock") or eq.pants ~= get_itemid("miner's pants") then
		text, url = "Couldn't equip mining outfit.", requestpath
	elseif eq.acc1 ~= get_itemid("hippy medical kit") and eq.acc2 ~= get_itemid("hippy medical kit") and eq.acc3 ~= get_itemid("hippy medical kit") then
		text, url = "Couldn't equip hippy medical kit (need HP-regen).", requestpath
	elseif advs() < 36 then
		text, url = "Not enough turns (need 36+).", requestpath
	else
		local layout_results = {}
		local times = math.floor(advs() / 36)
		while times > 0 do
			times = times - 1
--~ 				times = 0
			local pt, pturl = get_page("/mining.php", { intro = "1", mine = "1" })
			if pt:match("Find New Cavern") then
				post_page("/mining.php", { mine = "1", reset = "1", pwd = params.pwd })
			end
			ascension["mining.results.1"] = nil
			local mine_order = {
				49, 50, 51, 52, 53, 54,
				41, 42, 43, 44, 45, 46,
				33, 34, 35, 36, 37, 38,
				25, 26, 27, 28, 29, 30,
				17, 18, 19, 20, 21, 22,
				 9, 10, 11, 12, 13, 14,
			}
			for _, x in ipairs(mine_order) do
				local pt, pturl = get_page("/mining.php", { mine = "1", which = tostring(x), pwd = params.pwd })
				if not pt:match("You start digging. You hit the rock with all your might.") then
					print("Error while spading mining: Mining request failed:\n" .. pt)
					error("Error while spading mining: Mining request failed.")
				end
			end
			local pt, pturl = get_page("/mining.php", { intro = "1", mine = "1" })
			if pt:match("<a href='mining.php?mine=1&which=") then
				print("Error while spading mining: Itznotyerzitz Mine wasn't cleared.")
				error("Error while spading mining: Itznotyerzitz Mine wasn't cleared.")
			else
				local line = "mining.results.1 (kolproxy, " .. charpane.charName:match([[^"(.+)"$]]) .. ", " .. os.date() .. "): "..tostring(ascension["mining.results.1"]).."\n"
				table.insert(layout_results, line)
				f = io.open("spading-log.txt", "a+")
				f:write(line)
				f:close()
				print(line)
			end
		end
		text, url = table.concat(layout_results, "<br>"), requestpath
	end
	return text, url
end)

add_printer("/main.php", function()
	if ascensionstatus("Aftercore") then
		local links = {
			{ title = "Mine layout spading", url = minelayout_href { pwd = session.pwd } },
		}
		local rows = {}
		for _, x in ipairs(links) do
			table.insert(rows, [[<tr><td><a href="]]..x.url..[[">]]..x.title..[[</a></td></tr>]])
		end
		text = text:gsub([[title="Bottom Edge"></td></tr>.</table>]], [[%0<table>]] .. table.concat(rows) .. [[</table>]])
	end
end)
