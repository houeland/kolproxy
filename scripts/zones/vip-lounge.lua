-- TODO: fade out items that can't be used anymore

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
	text = text:gsub([[<input class=button type=submit value="Play Aggressively">]], [[%0<br><span style="color: green">{ Weapon Damage +50%%, +5 to Familiar Weight }</span>]])
	text = text:gsub([[<input class=button type=submit value="Play Strategically">]], [[%0<br><span style="color: green">{ +50%% Spell Damage, Regenerate 10 MP per Adventure }</span>]])
	text = text:gsub([[<input class=button type=submit value="Play Stylishly">]], [[%0<br><span style="color: green">{ +50%% Combat Initiative, +10%% Item Drops from Monsters }</span>]])
end)

add_printer("/clan_viplounge.php", function()
	text = text:gsub([[<input class=button type=submit value="Swim Laps">]], [[%0<br><span style="color: green">{ +30%% Combat Initiative, +25 Stench Damage, +20 to Monster Level }</span>]])
	text = text:gsub([[<input class=button type=submit value="Do Submarine Sprints">]], [[%0<br><span style="color: green">{ Decreased chance of random PvP Attacks, Monsters will be less attracted to you }</span>]])
end)

add_printer("/clan_viplounge.php", function()
	local messages = {}
	function add_message(c, maxcounter, msg)
		local color = (c < maxcounter) and "green" or "gray"
		table.insert(messages, string.format([[<span style="color: %s">{ %s used: %d / %d times today. }</span>]], color, msg, c, maxcounter))
	end
	add_message(get_daily_counter("zone.vip lounge.pool table"), 3, "A Pool Table")
	local hot_tub_text = text:match([[title="(A Relaxing Hot Tub.-)"]])
	if hot_tub_text:contains("no uses left") then
		table.insert(messages, string.format([[<span style="color: gray">{ %s }</span>]], hot_tub_text))
	else
		table.insert(messages, string.format([[<span style="color: green">{ %s }</span>]], hot_tub_text))
	end
	text = text:gsub([[<p><Center><A href="clan_hall.php">Back to Clan Hall]], [[<p><center>]] .. table.concat(messages, "<br>") .. [[</center></p>%0]])
end)

add_automator("/clan_viplounge.php", function()
	if text:contains("April Shower") and session["clan vip shower available"] == nil then
		local pt = get_page("/clan_viplounge.php", { action = "shower" })
		session["clan vip shower available"] = not pt:contains("already had a shower today")
	end
	if text:contains("An Olympic-Sized Swimming Pool") and session["clan vip swimming pool available"] == nil then
		local pt = get_page("/clan_viplounge.php", { action = "swimmingpool" })
		session["clan vip swimming pool available"] = not pt:contains("already worked out in the pool today")
	end
end)

add_processor("/clan_viplounge.php", function()
	if params.preaction then
		session["clan vip shower available"] = nil
		session["clan vip swimming pool available"] = nil
	end
end)

add_processor("/clan_viplounge.php", function()
	if params.preaction == "eathotdog" and tonumber(params.whichdog) and tonumber(params.whichdog) ~= -92 then
		day["zone.vip lounge.fancy hot dog eaten"] = true
	end
end)

add_processor("/clan_viplounge.php", function()
	if text:contains("check yourself out in the looking glass") then
		day["zone.vip lounge.checked looking glass"] = true
	end
end)

add_processor("/clan_viplounge.php", function()
	if text:contains("carefully guide the claw over a prize and press the button") then
		increase_daily_counter("zone.vip lounge.deluxe mr klaw")
	end
	if text:contains("probably shouldn't play with this machine any more today") then
		increase_daily_counter("zone.vip lounge.deluxe mr klaw", 3)
	end
end)

add_processor("use item: photocopied monster", function()
	day["item.photocopied monster.used today"] = true
end)

add_printer("/clan_viplounge.php", function()
	text = text:gsub([[title="A Relaxing Hot Tub %(no uses left today%)"]], [[%0 style="opacity: 0.3"]])
	text = text:gsub([[title="A Crimbo Tree %(with no present under it.%)"]], [[%0 style="opacity: 0.3"]])
	if session["clan vip shower available"] == false then
		text = text:gsub([[title="April Shower"]], [[%0 style="opacity: 0.3"]])
	end
	if session["clan vip swimming pool available"] == false then
		text = text:gsub([[title="An Olympic%-Sized Swimming Pool"]], [[%0 style="opacity: 0.3"]])
	end
	if get_daily_counter("zone.vip lounge.deluxe mr klaw") >= 3 then
		text = text:gsub([[title="Deluxe Mr. Klaw &quot;Skill&quot; Crane Game"]], [[%0 style="opacity: 0.3"]])
	end
	if get_daily_counter("zone.vip lounge.pool table") >= 3 then
		text = text:gsub([[title="A Pool Table"]], [[%0 style="opacity: 0.3"]])
	end
	if day["zone.vip lounge.fancy hot dog eaten"] then
		text = text:gsub([[title="A Hot Dog Stand"]], [[%0 style="opacity: 0.3"]])
	end
	if day["zone.vip lounge.checked looking glass"] then
		text = text:gsub([[title="A Looking Glass"]], [[%0 style="opacity: 0.3"]])
	end
	if day["item.photocopied monster.used today"] then
		text = text:gsub([[title="A Fax Machine"]], [[%0 style="opacity: 0.3"]])
	end
end)

add_automator("/clan_viplounge.php", function()
	if params.preaction == "receivefax" then
		if text:contains("You acquire") then
			if have_item("photocopied monster") then
				local itempt = get_page("/desc_item.php", { whichitem = "835898159" })
				local copied = itempt:match([[blurry likeness of [a-zA-Z]* (.-) on it.]])
				text = text:gsub([[You acquire an item: <b>photocopied monster</b>]], [[%0 <span style="color:green">{ ]] .. copied .. [[ }</span>]])
			end
		end
	end
end)

local function describe_faxbot_option(x)
	if x.name:lower() == x.description:lower() then
		return x.name
	else
		return x.description
	end
end

local faxbot_href = add_automation_script("get-faxbot-monster", function()
	local pt, pturl = get_page("/clan_viplounge.php", { action = "faxmachine" })
	local function get_contents(cmd)
		local faxbot_monsters_datafile = datafile("faxbot monsters")
		for _, c in ipairs(faxbot_monsters_datafile.order) do
			local x = faxbot_monsters_datafile.categories[c][cmd]
			if x then
				async_get_page("/submitnewchat.php", { graf = "/msg FaxBot " .. cmd, pwd = params.pwd })
				return string.format("Getting %s from FaxBot.", describe_faxbot_option(x))
			end
		end
		-- TODO: Use darkorange frame? Never actually happens without authenticated but still invalid requests anyway.
		return "You didn't select a known monster."
	end
	return pt:gsub("<body>", function(x)
		return x .. make_kol_html_frame(get_contents(params.faxcommand), "Retrieve Fax:")
	end), pturl
end)

add_printer("/clan_viplounge.php", function()
	if not setting_enabled("run automation scripts") then return end
	local faxbot_monsters_datafile = datafile("faxbot monsters")
	text = text:gsub([[<input class=button type=submit value="Receive a Fax"></form>]], function(x)
		local optgroups = {}
		for _, c in ipairs(faxbot_monsters_datafile.order) do
			local optorder = {}
			for x, y in pairs(faxbot_monsters_datafile.categories[c]) do
				table.insert(optorder, { command = x, displayname = describe_faxbot_option(y) })
			end

			table.sort(optorder, function(a, b)
				return a.displayname:lower() < b.displayname:lower()
			end)

			local opts = {}
			for _, x in ipairs(optorder) do
				table.insert(opts, string.format([[<option value="%s">%s</option>]], x.command, x.displayname))
			end
			table.insert(optgroups, string.format([[<optgroup label="%s">%s</optgroup>]], c, table.concat(opts)))
		end
		return x .. [[<hr><form action="]] .. faxbot_href {} .. [[" method="post"><input type=hidden name=pwd value="]]..session.pwd..[["><span style="color: green;">{ Choose monster: }</span> <select name="faxcommand"><option value="">-- nothing --</option>]] .. table.concat(optgroups) .. [[</select> <input class="button" type="submit" value="Get from FaxBot"></form>]]
	end)
end)

add_warning {
	message = "The hot tub will remove the Thrice-Cursed, Twice-Cursed, and Once-Cursed buffs.",
	path = "/clan_viplounge.php",
	type = "extra",
	check = function()
		if params.action ~= "hottub" then return end
		return have_buff("Thrice-Cursed") or have_buff("Twice-Cursed") or have_buff("Once-Cursed")
	end,
}

function use_hottub()
	return async_get_page("/clan_viplounge.php", { action = "hottub" })
end

function get_remaining_hottub_uses()
	local vippt = get_page("/clan_viplounge.php")
	local uses = vippt:match([[title="A Relaxing Hot Tub %(([0-9]+) uses left today%)"]])
	return tonumber(uses) or 0
end
