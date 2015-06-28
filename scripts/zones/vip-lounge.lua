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
	if text:contains([[title="A Pool Table"]]) then
		local uses_left = 3 - get_daily_counter("zone.vip lounge.pool table")
		if uses_left <= 0 then
			table.insert(messages, string.format([[<span style="color: gray">{ A Pool Table (no uses left today) }</span>]]))
		else
			table.insert(messages, string.format([[<span style="color: green">{ A Pool Table (%s left today) }</span>]], make_plural(uses_left, "use", "uses")))
		end
	end
	local hot_tub_text = text:match([[title="(A Relaxing Hot Tub.-)"]])
	if hot_tub_text then
		if hot_tub_text:contains("no uses left") then
			table.insert(messages, string.format([[<span style="color: gray">{ %s }</span>]], hot_tub_text))
		else
			table.insert(messages, string.format([[<span style="color: green">{ %s }</span>]], hot_tub_text))
		end
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
	if text:contains("A Speakeasy") and session["clan vip speakeasy available"] == nil then
		local pt = get_page("/clan_viplounge.php", { action = "speakeasy" })
		session["clan vip speakeasy available"] = not pt:contains("had your limit for today")
	end
end)

add_processor("/clan_viplounge.php", function()
	if params.preaction then
		session["clan vip shower available"] = nil
		session["clan vip swimming pool available"] = nil
		session["clan vip speakeasy available"] = nil
	end
end)

add_processor("/clan_viplounge.php", function()
	if params.preaction == "eathotdog" and tonumber(params.whichdog) and tonumber(params.whichdog) ~= -92 and not text:contains("too full to eat that") then
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
		reset_daily_counter("zone.vip lounge.deluxe mr klaw", 3)
	end
end)

add_processor("use item: photocopied monster", function()
	day["item.photocopied monster.used today"] = true
end)

add_printer("/clan_viplounge.php", function()
	text = text:gsub([[title="A Relaxing Hot Tub %(no uses left today%)"]], [[%0 style="opacity: 0.3"]])
	text = text:gsub([[title="A Crimbo Tree %(with no present under it.%)"]], [[%0 style="opacity: 0.3"]])
	text = text:gsub([[alt="Too Old to use"]], [[%0 style="opacity: 0.3"]])
	if session["clan vip shower available"] == false then
		text = text:gsub([[title="April Shower"]], [[%0 style="opacity: 0.3"]])
	end
	if session["clan vip swimming pool available"] == false then
		text = text:gsub([[title="An Olympic%-Sized Swimming Pool"]], [[%0 style="opacity: 0.3"]])
	end
	if session["clan vip speakeasy available"] == false then
		text = text:gsub([[title="A Speakeasy"]], [[%0 style="opacity: 0.3"]])
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
	if not can_use_vip_fax_machine() then
		text = text:gsub([[title="A Fax Machine"]], [[%0 style="opacity: 0.3"]])
	end
end)

add_automator("/clan_viplounge.php", function()
	if params.preaction == "receivefax" then
		if text:contains("You acquire") then
			if have_item("photocopied monster") then
				local itempt = get_page("/desc_item.php", { whichitem = "835898159" })
				local copied = itempt:match([[blurry likeness of [a-zA-Z]* (.-) on it.]])
				text = text:gsub([[You acquire an item: <b>photocopied monster</b>]], [[%0 <span style="color: green">{ ]] .. copied .. [[ }</span>]])
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
				async_get_page("/submitnewchat.php", { graf = "/msg faustbot " .. cmd, pwd = params.pwd })
				return string.format("Getting %s from faustbot.", describe_faxbot_option(x))
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
	local faxbot_monsters_datafile = datafile("faxbot monsters")
	text = text:gsub([[<input class=button type=submit value="Receive a Fax">.-</form>]], function(x)
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
		return x .. [[<hr><form action="]] .. faxbot_href {} .. [[" method="post"><input type=hidden name=pwd value="]]..session.pwd..[["><span style="color: green;">{ Choose monster: }</span> <select name="faxcommand"><option value="">-- nothing --</option>]] .. table.concat(optgroups) .. [[</select> <input class="button" type="submit" value="Get fax"></form>]]
	end)
end)

add_warning {
	message = "The hot tub will remove the Thrice-Cursed, Twice-Cursed, and Once-Cursed buffs.",
	path = "/clan_viplounge.php",
	type = "extra",
	check = function()
		if params.action ~= "hottub" then return end
		return have_apartment_building_cursed_buff()
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

function can_use_vip_fax_machine()
	return not day["item.photocopied monster.used today"] and have_item("Clan VIP Lounge key") and not ascensionpath("Avatar of Boris") and not ascensionpath("Avatar of Jarlsberg") and not ascensionpath("Avatar of Sneaky Pete")
end

local hot_dog_href = add_automation_script("eat-hot-dog-and-restock", function()
	if params.show_normal_page then
		session["show normal vip hot dog page"] = true
		return get_page("/clan_viplounge.php", { action = "hotdogstand" })
	end
	local whichdog = tonumber(params.whichdog)
	local ingredient_cost = tonumber(params.ingredient_cost)
	if not whichdog or not ingredient_cost then
		error("Invalid parameters.")
	end
	result, resulturl = post_page("/clan_viplounge.php", { preaction = "eathotdog", whichdog = whichdog })
	if result:contains("hourglass.gif") and not result:contains("aren't in the mood for any more fancy dogs") then
		local pt, pturl = get_page("/clan_viplounge.php", { preaction = "hotdogsupply", hagnks = 1, whichdog = whichdog, quantity = ingredient_cost })
		if not pt:contains("put some hot dog making supplies") then
			error "Failed to restock ingredients"
		end
	end
	return result, resulturl
end)

add_printer("/clan_viplounge.php", function()
	if not text:contains("hot dog man smiles as you approach") or day["zone.vip lounge.fancy hot dog eaten"] or session["show normal vip hot dog page"] then return end
	local changed = false
	text = text:gsub([[<tr>.-</tr>]], function(tr)
		if tr:contains("value=eathotdog") then
			--print(tr)
			local name = nil
			local ingredient_name = nil
			local ingredient_cost = nil
			local ingredient_hagnks = nil
			local whichdog = nil
			for td in tr:gmatch([[<td.-</td>]]) do
				if td:contains("<span onclick") and td:contains("descitem(") then
					name = td:match("<b>(.-)</b>")
				elseif td:contains("<img style") and td:contains("descitem(") then
					ingredient_name = td:match([[title="(.-)"]])
				elseif td:contains("<b>x ") then
					ingredient_cost = tonumber(td:match("<b>x ([0-9]-)</b>"))
				elseif td:contains("preaction=hotdogsupply&hagnks=1") then
					ingredient_hagnks = tonumber(td:match("rel='([0-9]-)'"))
					whichdog = tonumber(td:match("whichdog=([0-9-]+)"))
				end
			end
			--print(name, ingredient_name, ingredient_cost, ingredient_hagnks, whichdog)
			if name and ingredient_name and ingredient_cost and (ingredient_hagnks or 0) >= ingredient_cost and (whichdog or 0) < 0 then
				changed = true
				local href = hot_dog_href { pwd = session.pwd, whichdog = whichdog, ingredient_cost = ingredient_cost }
				return tr:gsub([[<input class=button type=submit value=Eat>]], string.format([[<a href="%s" style="color: green">{ Eat and restock }</a>]], href))
			end
		end
	end)
	if changed then
		local normal_page_href = hot_dog_href { pwd = session.pwd, show_normal_page = 1 }
		text = text:gsub([[</head>]], [[
<style>
#hotdogtable td:first-of-type { text-align: right }
</style>
</head>
]]):gsub([[<table><tr><form action=clan_viplounge.php method=post>]], [[<table id="hotdogtable"><tr><form action=clan_viplounge.php method=post>]]):gsub([[Hot Dog Leaderboards</a>]], [[%0<br><a href="]]..normal_page_href..[[" style="color: green">{ Hide "eat and restock" links }</a>]])
	end
end)

add_automator("/clan_viplounge.php", function()
	if params.preaction == "speakeasydrink" and params.drink and text:contains("<table><tr><td>Huh?</td></tr></table>") then
		-- WORKAROUND: Kolproxy is changing this POST request into GET when clicking through warnings.
		-- WORKAROUND: Reload the page here to get around this bug, since this particular page requires POST parameters.
		text, url = post_page(path, params)
	end
end)
