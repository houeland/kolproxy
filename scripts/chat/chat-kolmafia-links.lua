add_json_chat_printer(function(msg)
	if msg.msg and msg.msg:contains([[href="http://127.0.0.1:6008]]) then
		msg.msg = msg.msg:gsub([[href="http://127%.0%.0%.1:6008[0-9]/]], [[href="http://localhost:18481/]])
	end
end)
