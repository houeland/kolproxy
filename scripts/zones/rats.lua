add_automator("/choice.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if tonumber(params.whichchoice) == 509 then -- TODO: don't check by number?
		if text:match("You close the valve.") then
			text, url = get_page("/tavern.php", { place = "barkeep" })
		end
	end
end)

add_automator("/tavern.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if text:contains("should probably talk to the bartender") then
		async_get_page("/tavern.php", { place = "barkeep" })
		text, url = get_page("/cellar.php")
	end
end)

add_printer("/cellar.php", function()
	text = text:gsub([[<img.->]], function(imgtag)
		local x, y = imgtag:match("%(([0-9]*),([0-9]*)%)")
		if not x or not y then return imgtag end
		local areas = {
			["1,1"] = { region = 1, color = "green" },
			["1,2"] = { region = 1, color = "green" },
			["1,3"] = { region = 1, color = "green" },
			["1,4"] = { region = 2, color = "blue" },
			["1,5"] = { region = 2, color = "blue" },
			["2,4"] = { region = 2, color = "blue" },
			["2,5"] = { region = 2, color = "blue" },
			["3,5"] = { region = 3, color = "orange" },
			["4,5"] = { region = 3, color = "orange" },
			["5,5"] = { region = 3, color = "orange" },
		}
		local tiledata = areas[x .. "," .. y]

		if tiledata then
			return [[<div style="position: relative;"><div style="position: absolute; left: 0px; top: 0px; width: 100px; height: 100px; opacity: 0.3; background-color: ]]..tiledata.color..[[" title="Region ]]..tiledata.region..[["></div>]] .. imgtag .. [[</div>]]
		else
			return imgtag
		end
	end):gsub([[</body>]], [[<center><span style="color: green">{ The three colored regions each have one special adventure. <a target="_blank" href="http://kol.coldfront.net/thekolwiki/index.php/Tavern_Cellar#About_square_distribution">Explanation on wiki</a>. }</span></center>%0]])
end)
