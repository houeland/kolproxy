add_json_chat_printer(function(msg)
	if msg.type == "public" and msg.channel and not msg.mid and not msg.time then
		msg.kolproxy_hide_message = true
	end
end)
