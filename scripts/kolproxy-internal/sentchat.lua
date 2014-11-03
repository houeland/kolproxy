function doloadfile(path) loadfile(path)() end

doloadfile("scripts/base/datafile.lua")

local function run_wrapped_function(f_env)

text = f_env.text

doloadfile("scripts/base/util.lua")
doloadfile("scripts/base/base-lua-functions.lua")

function load_file(category, name)
	function add_json_chat_printer() end
	function add_chat_printer() end
	function add_interceptor() end
	function add_chat_trigger() end
	if category == "chat" then
		doloadfile("scripts/"..name)
	end
end

doloadfile("scripts/kolproxy-internal/loaders.lua")

do
	local f = io.open("logs/chat/sentchat-dump.raw", "a+")
	f:write(tostring(text).."\n")
	f:close()
end

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

if text:contains([["msgs":]]) then
	local chat_tbl = json_to_table(text)
	for i, msg in ipairs(chat_tbl.msgs) do
		if msg.type == "private" then
			if msg.who and msg.who.name and msg["for"] and msg["for"].name then
				log_file_line("private-" .. msg["for"].name .. ".html", format_chat_message(msg))
			end
		end
	end
end

return ""

end

return run_wrapped_function
