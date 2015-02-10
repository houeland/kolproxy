if register_setting then
register_setting {
	name = "enable dangerous chat commands",
	description = "Enable /sell and /stock chat commands",
	group = "chat",
	default_level = "detailed",
}
end

local function command_ok(ok_text)
	return make_kol_html_frame(ok_text)
end

local function usage_error(warning_text)
	return make_kol_html_frame(warning_text, nil, "darkorange")
end

local function command_failed(error_text)
	return make_kol_html_frame(error_text, nil, "red")
end

-- TODO: simplify functions

add_chat_redirect("/hottub", "Relaxing in the hot tub.", "/clan_viplounge.php", { action = "hottub" })

add_chat_redirect("/telescope", "Looking into the telescope.", "/campground.php", { action = "telescopelow" })
add_chat_alias("/scope", "/telescope")
add_chat_alias("/lairchecklist", "/telescope")

add_chat_command("/kolproxy_example_test_chat_command", "Testing things.", function()
	return command_ok("Hello, world.")
end)

--add_chat_command("/arrowme", "Kmailing time's arrow to kbay.", function()
--	if not ascensionstatus("Aftercore") then
--		return usage_error("Not in aftercore.")
--	elseif not have_item("time's arrow") then
--		return usage_error("No time's arrows to send.")
--	else
--		post_page("/sendmessage.php", { action = "send", pwd = session.pwd, towho = "kbay", whichitem1 = get_itemid("time's arrow"), howmany1 = 1 })
--		return command_ok("Sent.")
--	end
--end)

add_chat_command("/skeleton", "Using skeleton.", function(param)
	local skeletons = {
		warrior = 1,
		cleric = 2,
		wizard = 3,
		rogue = 4,
		buddy = 5,
	}
	if skeletons[param] then
		local pt, pturl = use_item("skeleton")()
		get_page("/choice.php", { forceoption = 0 })
		text, url = get_page("/choice.php", { pwd = session.pwd, whichchoice = 603, option = skeletons[param] })
		if url:contains("main.php") then
			text, url = pt, pturl
		end
		return text
	elseif param == "all" then
		if count_item("skeleton") < 5 then
			return usage_error("Not enough skeletons.")
		end
		for i = 1, 5 do
			use_item("skeleton")
			async_get_page("/choice.php", { forceoption = 0 })
			async_get_page("/choice.php", { pwd = session.pwd, whichchoice = 603, option = i })
		end
		return command_ok("Done.")
	else
		print("DEBUG: /skeleton param was [[" .. tostring(param) .."]]")
		return usage_error([[Unknown skeleton. Use /skeleton x, where "x" is one of "warrior", "cleric", "wizard", "rogue", "buddy", or "all" to use all 5.]])
	end
end)

add_chat_command("/pyec", "Using PYEC.", function()
	if not ascensionstatus("Aftercore") then
		return usage_error("Not in aftercore.")
	end
	if have_item("Platinum Yendorian Express Card") then
		local pt = use_item("Platinum Yendorian Express Card")()
		return pt
	end
	local clanstash = get_page("/clan_stash.php")
	local pyec_line = clanstash:match([[<option value=1687 descid=298008237>Platinum Yendorian Express Card.-</option>]])
	if not pyec_line then
		return usage_error("No PYEC in clan stash.")
	end
	if not clanstash:contains("You are exempt from your Clan's Karma requirements.") then
		return usage_error("Not Karma exempt.")
	end
	take_stash_item("Platinum Yendorian Express Card")
	if not have_item("Platinum Yendorian Express Card") then
		return command_failed("Error taking PYEC from clan stash!")
	else
		local _, pt = pcall(function() return use_item("Platinum Yendorian Express Card")() end)
		add_stash_item("Platinum Yendorian Express Card")
		local newclanstash = get_page("/clan_stash.php")
		if newclanstash:match([[<option value=1687 descid=298008237>Platinum Yendorian Express Card.-</option>]]) ~= pyec_line then
			return command_failed("Error returning PYEC to clan stash!")
		else
			return pt
		end
	end
end)

add_chat_trigger("/stop", function()
	block_lua_scripting()
	return [[<span style="color: green">{ Page loading halted! }</span><br>]]
end)

add_raw_chat_script_redirect("/mcd", "Setting MCD.", function(mcdparam)
	local amount = tonumber(mcdparam)
	if amount and amount >= 0 then
		return set_mcd(amount)()
	else
		return usage_error("Example usage: /mcd 10")
	end
end)

add_raw_chat_script_redirect("/inv", "Searching inventory.", function(query_string)
	return get_page("/inventory.php", { ftext = query_string })
end)

add_chat_redirect("/activate", "Activating Greatest American Pants.", "/inventory.php", { action = "activatesuperpants" })

local function match_item(line)
	local pattern = line:gsub("^%s*", "")
	local text = get_page("/submitnewchat.php", { graf = "/closet? " .. pattern, pwd = session.pwd, j = 1 })
	local json = json_to_table(text)
	local item = json.output:match("Closeting 1 (.*)%.</font>$")
	if not item then
		return nil, json.output:match("Would produce: (.*)</font>") or "{ Unknown error. }"
	end
	return item
end

local function parse_name_and_amount(line)
	local amount, pattern = line:match("^%s*(%d+)%s+(.*)$")
	if not amount then
		pattern = line:match("^%s*%*%s+(.*)$")
		if pattern then
			amount = "*"
		end
	end
	if not amount then
		amount = 1
		pattern = line
	end
	return pattern:gsub("^%s*", ""), amount
end

local function match_amount_and_item(line)
	local pattern, amount = parse_name_and_amount(line)
	item, err = match_item(pattern)
	if not item then
		return item, err
	elseif amount == "*" then
		amount = count_inventory_item(item)
	end
	return tonumber(amount), item
end

add_chat_command("/sell", "Selling.", function(line)
	if line:match("^%s*$") then
		return usage_error('What do you want to autosell? "/sell itemname"')
	end
	local amount, item = match_amount_and_item(line)
	if not amount then
		return usage_error(item)
	end
	if not setting_enabled("enable dangerous chat commands") then
		return usage_error("You need to enable /sell and /stock chat commands in kolproxy settings first.")
	end
	return autosell_item(item, amount)()
end)

add_chat_command("/stock", "Stocking.", function(line)
	if line:match("^%s*$") then
		return usage_error('What do you want to stock in your store? "/stock itemname"')
	end
	local amount, item = match_amount_and_item(line)
	if not amount then
		return usage_error(item)
	end
	if not setting_enabled("enable dangerous chat commands") then
		return usage_error("You need to enable /sell and /stock chat commands in kolproxy settings first.")
	end
	return add_store_item(item, amount)()
end)

add_custom_chat_redirect("/maximizer", "Maximizing...", function(line)
	print("DEBUG: /maximizer param was [[" .. tostring(line) .."]]")
	return make_href("/kolproxy-automation-script", { ["automation-script"] = "custom-modifier-maximizer", pwd = sendchat_pwd, fuzzy = line })
end)

add_chat_alias("/maximize", "/maximizer")
add_chat_alias("/max", "/maximizer")

function fuzzy_matching_results(input, options)
	input = input:lower()
	local exact = {}
	local atstart_or_acronymed = {}
	local substring = {}
	for _, o in pairs(options) do
		local find_pos = o:lower():find(input)
		local o_acronym = o:lower():gsub("[%s]*([^%s])[^%s]*", "%1")
		if input == o then
			table.insert(exact, o)
		elseif find_pos == 1 then
			table.insert(atstart_or_acronymed, o)
		elseif input == o_acronym then
			table.insert(atstart_or_acronymed, o)
		elseif find_pos then
			table.insert(substring, o)
		end
	end
	local function check_unique(tbl)
		if not tbl[2] then
			return tbl[1]
		else
			return nil, tbl
		end
	end
	if exact[1] then
		return exact[1]
	elseif atstart_or_acronymed[1] then
		return check_unique(atstart_or_acronymed)
	elseif substring[1] then
		return check_unique(substring)
	else
		return nil, nil
	end
end

add_chat_command("/kpbuy", "Trying...", function(line)
	local pattern, amount = parse_name_and_amount(line)

	local possible = {}
	for _, i in pairs(datafile("stores")) do
		for n, _ in pairs(i) do
			table.insert(possible, n)
		end
	end

	local chosen, options = fuzzy_matching_results(pattern, possible)
	if chosen then
		return buy_item(chosen, amount)()
	elseif options then
		return usage_error("Too many matches found, be more specific: " .. table.concat(options, ", "))
	else
		return usage_error("Hmmm, not sure what you're trying to buy.")
	end
end)
