-- TODO: simplify functions

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
			return "Not enough skeletons."
		end
		for i = 1, 5 do
			use_item("skeleton")
			async_get_page("/choice.php", { forceoption = 0 })
			async_get_page("/choice.php", { pwd = session.pwd, whichchoice = 603, option = i })
		end
		return "Done."
	else
		print("DEBUG: /skeleton param was [[" .. tostring(param) .."]]")
		return [[Unknown skeleton. Use /skeleton x, where "x" is one of "warrior", "cleric", "wizard", "rogue", "buddy", or "all" to use all 5.]]
	end
end)

add_chat_command("/pyec", "Using PYEC.", function()
	if not ascensionstatus("Aftercore") then
		return "Not in aftercore.", "darkorange"
	end
	if have_item("Platinum Yendorian Express Card") then
		local pt = use_item("Platinum Yendorian Express Card")()
		return pt
	end
	local clanstash = get_page("/clan_stash.php")
	local pyec_line = clanstash:match([[<option value=1687 descid=298008237>Platinum Yendorian Express Card.-</option>]])
	if not pyec_line then
		return "No PYEC in clan stash.", "darkorange"
	end
	if not clanstash:contains("You are exempt from your Clan's Karma requirements.") then
		return "Not Karma exempt.", "darkorange"
	end
	take_stash_item("Platinum Yendorian Express Card")
	if not have_item("Platinum Yendorian Express Card") then
		return "Error taking PYEC from clan stash!", "red"
	else
		local _, pt = pcall(function() return use_item("Platinum Yendorian Express Card")() end)
		add_stash_item("Platinum Yendorian Express Card")
		local newclanstash = get_page("/clan_stash.php")
		if newclanstash:match([[<option value=1687 descid=298008237>Platinum Yendorian Express Card.-</option>]]) ~= pyec_line then
			return "Error returning PYEC to clan stash!", "red"
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
		return make_kol_html_frame("Example usage: /mcd 10", "Results:", "darkorange"), requestpath
	end
end)

add_chat_redirect("/activate", "Activating Greatest American Pants.", "/inventory.php", { action = "activatesuperpants" })

