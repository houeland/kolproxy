-- Tracks flyer progress
--

add_processor("/fight.php", function()
	if text:contains("You slap a flyer up on your opponent") then
		local flyertext = text:match([[documents.gif" width=30 height=30 alt=.-You slap a flyer up on your opponent]])
		local whichflyer = flyertext:match([[title="(.-)"]])
		if whichflyer then
			local monster = getCurrentFightMonster()
			if monster and monster.Stats then
				local atk = tonumber(monster.Stats.Atk)
				if atk then
					if whichflyer == "rock band flyers" then
						increase_ascension_counter("zone.island.frat arena flyerML", atk)
					elseif whichflyer == "jam band flyers" then
						increase_ascension_counter("zone.island.hippy arena flyerML", atk)
					end
				end
			end
		end
	end
end)

add_printer("/fight.php", function()
	if text:contains("You slap a flyer up on your opponent") then
		text = text:gsub([[documents.gif" width=30 height=30 alt=.-</td></tr>]], function(flyertext)
			local completion = "?"
			local whichband = "?"
			if flyertext:contains([[title="rock band flyers"]]) then
				completion = round_down((ascension["zone.island.frat arena flyerML"] or 0) / 100, 1)
				whichband = "rock band"
			elseif flyertext:contains([[title="jam band flyers"]]) then
				completion = round_down((ascension["zone.island.hippy arena flyerML"] or 0) / 100, 1)
				whichband = "jam band"
			end
			return flyertext:gsub([[(You slap a flyer up on your opponent.-)(<)]], [[%1 <span style="color: green">{&nbsp;Advertised ~]] .. completion .. [[%% for ]]..whichband..[[.&nbsp;}</span>%2]])
		end)
	end
end)

add_printer("/bigisland.php", function()
	if have_item("rock band flyers") or have_item("jam band flyers") then
		local msgs = {}
		if have_item("rock band flyers") then
			table.insert(msgs, "{&nbsp;~" .. (ascension["zone.island.frat arena flyerML"] or 0) .. " ML slapped for frat boys.&nbsp;}")
		end
		if have_item("jam band flyers") then
			table.insert(msgs, "{&nbsp;~" .. (ascension["zone.island.hippy arena flyerML"] or 0) .. " ML slapped for hippies.&nbsp;}")
		end
		text = text:gsub([[<p><Center>]], [[<p style="color: green;text-align:center;">]] .. table.concat(msgs, "<br>\n") .. [[</p>%0]])
	end
end)

add_printer("/inventory.php", function()
	local fratMLCompleted = ascension["zone.island.frat arena flyerML"] or 0
	local hippyMLCompleted = ascension["zone.island.hippy arena flyerML"] or 0
	
	text = text:gsub([[rock band flyers]], [[%0&nbsp;]]..[[<span style="color: green;" >{&nbsp;]]..fratMLCompleted..[[ ML slapped&nbsp;}</span>]])
	text = text:gsub([[jam band flyers]], [[%0&nbsp;]]..[[<span style="color: green;" >{&nbsp;]]..hippyMLCompleted..[[ ML slapped&nbsp;}</span>]])
end)
