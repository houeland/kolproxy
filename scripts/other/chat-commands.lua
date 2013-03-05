add_chat_redirect("/hottub", "Relaxing in the hot tub.", "/clan_viplounge.php", { action = "hottub" })

add_chat_redirect("/telescope", "Looking into the telescope.", "/campground.php", { action = "telescopelow" })
add_chat_alias("/scope", "/telescope")
add_chat_alias("/lairchecklist", "/telescope")

add_chat_command("/kolproxy_example_test_chat_command", "Testing things.", function()
	return "Hello, world."
end)

add_chat_command("/arrowme", "Kmailing time's arrow to kbay.", function()
	if not ascensionstatus("Aftercore") then
		return "Not in aftercore."
	elseif not have_item("time's arrow") then
		return "No time's arrows to send."
	else
		post_page("/sendmessage.php", { action = "send", pwd = session.pwd, towho = "kbay", whichitem1 = get_itemid("time's arrow"), howmany1 = 1 })
		return "Sent."
	end
end)

add_chat_trigger("/stop", function()
	block_lua_scripting()
	return [[<span style="color: green">{ Page loading halted! }</span><br>]]
end)

local function match_item(line)
	local pattern = line:gsub("^%s*", "")
	local text = get_page("/submitnewchat.php", { graf = "/closet? " .. pattern, pwd = session.pwd, j = 1 })
	local json = json_to_table(text)
	local item = json.output:match("Closeting 1 (.*)%.</font>$")
	if not item then
		return nil, text:match("Would produce: (.*)</font><br>$")
	end
	return item
end

local function match_amount_and_item(line)
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
	item, err = match_item(pattern)
	if err then
		return err
	elseif amount == "*" then
		amount = count_inventory(item)
	end
	return tonumber(amount), item
end

local function command_error(error_text)
	return make_kol_html_frame(error_text), requestpath
end

add_raw_chat_command("/sell", "Selling", function(line)
	if line:match("^%s*$") then
		return command_error('What do you want to autosell? "/sell itemname"')
	end
	local amount, item = match_amount_and_item(line)
	if type(amount) == "string" then
		return command_error(amount)
	end
	return sell_item(item, amount)()
end)

add_raw_chat_command("/stock", "Stocking", function(line)
	if line:match("^%s*$") then
		return command_error('What do you want to stock in your store? "/stock itemname"')
	end
	local amount, item = match_amount_and_item(line)
	if type(amount) == "string" then
		return command_error(amount)
	end
	return stock_item(item, amount)()
end)

add_raw_chat_script_redirect("/mcd", "Setting MCD.", function(mcdparam)
        local amount = tonumber(mcdparam)
	if amount and amount >= 0 then
		return set_mcd(amount)()
	else
		return make_kol_html_frame("Example usage: /mcd 10", "Results:", "darkorange"), requestpath
	end
end)
