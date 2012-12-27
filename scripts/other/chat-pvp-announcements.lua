add_json_chat_printer(function(msg)
	if msg.channel == "pvp" then
		if tonumber(msg.who.id) == -43 then
			msg.channel = "pvp-announcements"
		elseif tonumber(msg.who.id) == -69 then
			msg.channel = "pvp-announcements"
		end
	end
end)
