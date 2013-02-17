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

add_raw_chat_script_redirect("/mcd", "Setting MCD.", function(mcdparam)
        local amount = tonumber(mcdparam)
	if amount and amount >= 0 then
		return set_mcd(amount)()
	else
		return make_kol_html_frame("Example usage: /mcd 10", "Results:", "darkorange"), requestpath
	end
end)
