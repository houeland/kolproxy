local highlights

local function init_highlights()
	if highlights then return end

	highlights = {}

	local charname = get_chat_state("chat highlighting.player name")
	if charname == "" then
		charname = get_character_name()
		set_chat_state("chat highlighting.player name", charname)
	end

	if charname ~= "" then
		highlights[charname] = "mediumvioletred"
	end
end

add_chat_printer(function(chatmsg)
	init_highlights()
--~ 	print("chat msg", pre, chatmsg, post)
	local triggered = false
	local triggered_color = nil
	for match, color in pairs(highlights) do
		if chatmsg:lower():find(match:lower()) then
			triggered = true
			triggered_color = color
		end
	end
	if triggered == true then
		highlight_msg = function(pre, msg)
			br_last = msg:match("^(.+)<br>$")
			if br_last then
				return pre .. "<font color=" .. triggered_color .. ">" .. br_last .. "</font><br>"
			else
				return pre .. "<font color=" .. triggered_color .. ">" .. msg .. "</font>"
			end
		end
		chatmsg = chatmsg:gsub("(</font></b></a>: )(.+)$", highlight_msg)
		chatmsg = chatmsg:gsub("(</b></font></a> )(.+)$", highlight_msg)
	end
	return chatmsg
end)

add_json_chat_printer(function(msg)
	init_highlights()
	for match, color in pairs(highlights) do
		if msg.msg:lower():contains(match:lower()) then
			msg.msg = [[<span style="color: ]]..color..[[">]] .. msg.msg .. [[</span>]]
		end
	end
end)
