add_processor("/clan_viplounge.php", function()
	if text:match("You skillfully defeat .- and take control of the table.") or text:contains("You play a game of pool against yourself.") or text:contains("Try as you might, you are unable to defeat") then
		increase_daily_counter("zone.vip lounge.pool table")
	end
end)

add_printer("/clan_viplounge.php", function()
	text = text:gsub(">Hot<", ">Hot { restore 1000 MP }<")
	text = text:gsub(">Warm<", ">Warm { +5%% muscle gains }<")
	text = text:gsub(">Lukewarm<", ">Lukewarm { +5%% mysticality gains }<")
	text = text:gsub(">Cool<", ">Cool { +5%% moxie gains }<")
	text = text:gsub(">Cold<", ">Cold { get 3-4 shards of double-ice }<")
end)

add_printer("/clan_viplounge.php", function()
	messages = {}
	function add_message(counter, maxcounter, msg)
		local c = get_daily_counter(counter)
		if c < maxcounter then
			table.insert(messages, msg .. [[: used ]] .. c .. [[ / ]] .. maxcounter .. [[ times today.]])
		else
			table.insert(messages, [[<span style="color: gray">]] .. msg .. [[ used: ]] .. c .. [[ / ]] .. maxcounter .. [[ times today.</span>]])
		end
	end
	add_message("zone.vip lounge.pool table", 3, "A Pool Table")
-- 	add_message("zone.vip lounge.hot tub", 5, "A Relaxing Hot Tub")
	text = text:gsub([[<p><Center><A href="clan_hall.php">Back to Clan Hall]], [[<p><center>]] .. table.concat(messages, "<br>") .. [[</center></p>%0]])
end)

-- add_automator("/clan_viplounge.php", function()
-- 	if params.action == "faxmachine" then
-- 		logpt = get_page("/clan_log.php")
-- 		monsterdesc = logpt:match("</a> faxed in ([^<]-)<")
-- 		if monsterdesc then
-- 			text = text:gsub("What do you want to do%?", [[%0<br><p><span style="color: green">{ Probably contains ]] .. monsterdesc .. [[. }</span></p>]])
-- 		end
-- 	end
-- end)

add_automator("/clan_viplounge.php", function()
	if params.preaction == "receivefax" then
		if text:contains("You acquire") then
			if have("photocopied monster") then
				local itempt = get_page("/desc_item.php", { whichitem = "835898159" })
				local copied = itempt:match([[blurry likeness of [a-zA-Z]* (.-) on it.]])
				text = text:gsub([[You acquire an item: <b>photocopied monster</b>]], [[%0 <span style="color:green">{ ]] .. copied .. [[ }</span>]])
			end
		end
	end
end)


local faxbot_href = add_automation_script("get-faxbot-monster", function ()
	local pt, pturl = get_page("/clan_viplounge.php", { action = "faxmachine" })
	local function get_contents(cmd)
		local category_contents, category_order = faxbot_monsterlist()
		for _, xs in pairs(category_contents) do
			for _, x in ipairs(xs) do
				if x.command == cmd then
					get_page("/submitnewchat.php", { graf = "/msg FaxBot " .. x.command, pwd = params.pwd })
					return ("Getting " .. x.name .. " from FaxBot.")
				end
			end
		end
		return "You didn't select a known monster."
	end
	return pt:gsub("<body>", function(x)
		return x .. make_kol_html_frame(get_contents(params.faxcommand), "Retrieve Fax:")
	end), pturl
end)

add_printer("/clan_viplounge.php", function()
	if not setting_enabled("run automation scripts") then return end
	text = text:gsub([[<input class=button type=submit value="Receive a Fax"></form>]], function(x)
		local category_contents, category_order = faxbot_monsterlist()
		local optstext = ""
		for _, c in pairs(category_order) do
			local opts = {}
			for _, x in ipairs(category_contents[c]) do
				table.insert(opts, string.format([[<option value="%s">%s</option>]], x.command, x.name))
			end
			optstext = optstext .. string.format([[<optgroup label="%s">%s</optgroup>]], c, table.concat(opts))
		end
		return x .. [[<hr><form action="]] .. faxbot_href {} .. [[" method="post"><input type=hidden name=pwd value="]]..session.pwd..[["><span style="color: green;">Choose monster:</span> <select name="faxcommand"><option value="">-- nothing --</option>]] .. optstext .. [[</select> <input class="button" type="submit" value="Get from FaxBot"></form>]]
	end)
end)
