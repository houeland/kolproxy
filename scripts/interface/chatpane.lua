register_setting {
	name = "rewrite PRIVATE: chat commands",
	description = "Make chat commands work for PRIVATE: and OFFTOPIC: tabs",
	hidden = true,
	group = "chat",
	default_level = "limited",
}

register_setting {
	name = "show seconds in chat timestamp",
	description = "Show seconds in chat timestamp",
	group = "chat",
	default_level = "detailed",
}

register_setting {
	name = "disable dragging chat tabs",
	description = "Disable dragging chat tabs to reorder them",
	group = "chat",
	default_level = "enthusiast",
}

register_setting {
	name = "use ctrl+shift to change chat tabs",
	description = "Use ctrl+shift as the key combination to change chat tabs",
	group = "chat",
	default_level = "enthusiast",
}

register_setting {
	name = "do not unlisten when closing tabs",
	description = "Do not stop listening to channels when you close their tab",
	group = "chat",
	default_level = "enthusiast",
}

register_setting {
	name = "ask chatbot on logon",
	description = "Ask chatbot for clover and bounty status on login",
	group = "chat",
	default_level = "enthusiast",
}

register_setting {
	name = "enable chat spellcheck",
	description = "Enable spell checking (if the browser supports it)",
	group = "chat",
	default_level = "detailed",
}

register_setting {
	name = "retrieve latest chat",
	description = "Retrieve latest chat from server when starting chat",
	group = "chat",
	default_level = "enthusiast",
}


add_printer("/lchat.php", function()
	text = text:gsub("font%-size: 12px;", "font-size: 13px;")
end)

add_printer("/mchat.php", function()
	text = text:gsub("font%-size: 12px;", "font-size: 13px;")
end)

-- TODO: HACK: workaround for bad CDM script
add_printer("/mchat.php", function()
--	text = text:gsub("timeout: 5000", [[timeout: 50000, error: function(a,b,c) { console.log("chat error", b, c) }]])
	text = text:gsub("timeout: 5000", [[timeout: 50000]])
end)

-- TODO: apply to mchat too?
add_printer("/lchat.php", function()
	text = text:gsub("(onLoad=)(%b'')", function(prefix, onload)
		-- /r messages can scroll off the screen when logging on if we show too much
-- 		onload = string.gsub(onload, ";'$", ";submitchat(\"/trivial && /updates && /who && /friends\");'%0")
		req = [[submitchat("/friends");]]
		if setting_enabled("ask chatbot on logon") then
			req = req .. [[ submitchat("/msg chatbot Does the hermit have clover today?"); submitchat("/msg chatbot What does the bounty hunter hunter want today?");]]
		end
		onload = onload:gsub(";'$", [[;]] .. req .. [[']])
		return prefix .. onload
	end)
end)

-- $('#tabs').sortable({
-- 		appendTo: 'body',
-- 		stop: function(e, ui) {
-- 			var diff = Math.abs(ui.position.left - ui.originalPosition.left);
-- 			if (diff < 10) ui.item.click();
-- 		}
-- 	});

add_printer("/mchat.php", function()
	if setting_enabled("disable dragging chat tabs") then
		text = text:gsub([[$%('#tabs'%).sortable%(]], [[$('#kolproxy_no_matches_to_discard_sortable').sortable(]])
	end
end)

add_printer("/mchat.php", function()
	if setting_enabled("use ctrl+shift to change chat tabs") then
		text = text:gsub([[if %(e%[KEYS%[opts.modifier%]%]%)]], [[if (e.ctrlKey && e.shiftKey)]])
	end
end)

add_printer("/mchat.php", function()
	if setting_enabled("do not unlisten when closing tabs") then
		text = text:gsub([[submitchat%('/listenoff ' %+ parts%[1%], endtab%);]], [[endtab();]])
	end
end)

add_printer("/mchat.php", function()
	if setting_enabled("rewrite PRIVATE: chat commands") or true then
		text = text:gsub([[if %(parts%[0%] == 'public'%) return '/' %+ parts%[1%] %+ ' ' %+ msg;]], [[if (parts[0] == 'public' && !(mparts[0].match(/^\//) && (parts[1].match(/ /) && !parts[1].match(/clan /)))) return '/' + parts[1] + ' ' + msg;]])
	end
end)

add_printer("/mchat.php", function()
	if setting_enabled("show seconds in chat timestamp") then
		text = text:gsub([['%[' %+ h%+ ':' %+ m %+ '%] ']], [['[' + h + ':' + m + ':' + s + '] ']])
	end
end)

add_printer("/mchat.php", function()
	if setting_enabled("enable chat spellcheck") then
		text = text:gsub([[id="graf"]], [[%0 spellcheck="true"]])
	end
end)

add_printer("/mchat.php", function()
	if setting_enabled("retrieve latest chat") then
		text = text:gsub([[var lastlast = 0;]], [[var lastlast = 1;]])
	end
end)
