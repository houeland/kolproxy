function doloadfile(path) loadfile(path)() end

local chatprinters = {}
local json_chatprinters = {}

-- TODO: track processed messages, only log them once

local function run_wrapped_function(f_env)

text = f_env.text

-- do
-- 	local f = io.open("logs/chat/chat-dump.raw", "a+")
-- 	f:write(tostring(text).."\n")
-- 	f:close()
-- end

local function log_file_line(filename, line)
	local f = io.open("logs/chat/" .. filename, "a+")
	f:write(tostring(line).."\n")
	f:close()
end

local function format_chat_message(msg)
	local timestamp = [[<span style="color: #666666">]] .. os.date("[%H:%M]", msg.time) .. [[</span>]]
	if msg.type == "private" then
		if msg["for"] then
			return timestamp .. [[ <span style="color: blue"><b style="color: ]] .. (msg.who.color or "black") .. [[">]] .. msg.who.name .. "</b>: " .. msg.msg .. "</span><br>"
		else
			return timestamp .. [[ <span style="color: blue"><b style="color: ]] .. (msg.who.color or "black") .. [[">]] .. msg.who.name .. "</b>: " .. msg.msg .. "</span><br>"
		end
	elseif msg.type == "public" then
		if msg.format == "0" then
			return timestamp .. [[ <b style="color: ]] .. (msg.who.color or "black") .. [[">]] .. msg.who.name .. "</b>: " .. msg.msg .. "<br>"
		else
			return timestamp .. [[ ]] .. msg.msg .. "<br>"
		end
	else
		return timestamp .. [[ ]] .. msg.msg .. "<br>"
	end
end

-- TODO: remove, obsoleted by sqlite3 chatlog(?)
local function log_chat(msg)
	local msgformat = tostring(msg.type) .. (msg.format or "")
	if msgformat == "public0" then
		log_file_line("channel-" .. msg.channel .. ".html", format_chat_message(msg))
	elseif msgformat == "public1" then
		log_file_line("channel-" .. msg.channel .. ".html", format_chat_message(msg))
	elseif msgformat == "event" then
		log_file_line("events.html", format_chat_message(msg))
	elseif msgformat == "private" then
		log_file_line("private-" .. msg.who.name .. ".html", format_chat_message(msg))
	elseif msgformat == "system2" then
		log_file_line("system.html", format_chat_message(msg))
	else
--		print("DEBUG, chat:", msgformat, msg)
	end
end

if text:contains([["last":]]) then
	local chat_tbl = json_to_table(text)
	local new_msgs = {}
	for _, msg in ipairs(chat_tbl.msgs) do
-- 		print("DEBUG msgbefore", msg)
		log_chat(msg)
		for _, printer in ipairs(json_chatprinters) do
			printer.f(msg)
		end
-- 		print("DEBUG msgafter", msg)
		if not msg.kolproxy_hide_message then
			table.insert(new_msgs, msg)
		end
	end
	chat_tbl.msgs = new_msgs
	text = table_to_json(chat_tbl)
elseif text:contains("lastseen:") then
	text = "<!-- buffer br --><br>" .. text
	text = text:gsub("<!%-%-lastseen:[0-9]+%-%->$", "<!-- separator:beforeA -->%0") -- lastseen at the end
	text = text:gsub([[<font color=[^>]+>%b[]</font> <b><a target=mainpane href="showplayer%.php%?who=[0-9]+"><font color=[^>]+>[^<]+</font></b></a>]], "<!-- separator:beforeB --><!-- separator:startB -->%0") -- normal chat
	text = text:gsub([[<font color=[^>]+>%b[]</font> <b><i><a target=mainpane href="showplayer%.php%?who=[0-9]+"><font color=[^>]+>[^<]+</b></font></a>]], "<!-- separator:beforeC --><!-- separator:startC -->%0") -- emote in chat
	text = text:gsub([[<br>(<b><a target=mainpane href="showplayer%.php%?who=[0-9]+"><font color=[^>]+>[^<]+</font></b></a>)]], "<br><!-- separator:beforeD --><!-- separator:startD -->%1") -- normal chat
	text = text:gsub([[<br>(<b><i><a target=mainpane href="showplayer%.php%?who=[0-9]+"><font color=[^>]+>[^<]+</b></font></a>)]], "<br><!-- separator:beforeE --><!-- separator:startE -->%1") -- emote in chat
	text = text:gsub([[<a target=mainpane href="showplayer%.php%?who=[0-9]+"><font color=[^>]+><b>[^<]+</b></a>]], "<!-- separator:beforeF --><!-- separator:startF -->%0") -- private message
	text = text:gsub("<!%-%- separator:start[A-Z] %-%->(.-)<!%-%- separator:before[A-Z] %-%->", function(msg)
		for _, printer in ipairs(chatprinters) do
			msg = printer.f(msg)
		end
		return msg
	end)
	text = text:gsub("<!%-%- separator:[a-zA-Z]+ %-%->", "")
	text = text:gsub("^<!%-%- buffer br %-%-><br>", "")
end

return text

end

doloadfile("scripts/base/datafile.lua")
doloadfile("scripts/base/util.lua")

function load_file(category, name)
	function add_json_chat_printer(func)
		table.insert(json_chatprinters, { scriptname = name, f = func })
	end
	function add_chat_printer(func)
		table.insert(chatprinters, { scriptname = name, f = func })
	end
	function add_chat_trigger() end
	function add_interceptor() end
	if category == "chat" then
		loadfile("scripts/"..name)()
	end
end

doloadfile("scripts/kolproxy-internal/loaders.lua")

return run_wrapped_function
