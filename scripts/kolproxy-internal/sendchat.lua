function doloadfile(path) loadfile(path)() end

doloadfile("scripts/base/datafile.lua")
doloadfile("scripts/base/util.lua")
doloadfile("scripts/base/base-lua-functions.lua")

local function run_wrapped_function(f_env)

local chatcommands = {}

function load_file(category, name)
	function add_json_chat_printer() end
	function add_chat_printer() end
	function add_interceptor() end
	function add_chat_trigger(keyword, func)
		chatcommands[keyword] = { scriptname = name, f = func }
	end
	if category == "chat" then
		doloadfile("scripts/"..name)
	end
end

doloadfile("scripts/kolproxy-internal/loaders.lua")

-- print("sendchat rawinput", f_env.raw_input_params)

local allparams = parse_params(f_env.raw_input_params)

if not allparams or not allparams.graf then return "" end

local original_graf = allparams.graf

do
	local f = io.open("logs/chat/sendchat-dump.raw", "a+")
	f:write(tostring(allparams.graf).."\n")
	f:close()
end

local ignore_grafs = {
	[ [[/who pvp-announcements]] ] = true,
	[ [[/clan /who clan PRIVATE:]] ] = true,
	[ [[/clan PRIVATE: /listenoff clan PRIVATE:]] ] = true,
	[ [[/who clan PRIVATE:]] ] = true,
	[ [[/who clan PRIVATE: OFFTOPIC:]] ] = true,
	[ [[/who clan OFFTOPIC:]] ] = true,
	[ [[PRIVATE: /listenoff clan PRIVATE:]] ] = true,
}

if tonumber(allparams.j) == 1 and ignore_grafs[allparams.graf] then
	return table_to_json { output = "", msgs = {} }
end

allparams.graf = allparams.graf:gsub("^PRIVATE: /me ", "/me PRIVATE: ")
allparams.graf = allparams.graf:gsub("^PRIVATE: /em ", "/em PRIVATE: ")
allparams.graf = allparams.graf:gsub("^PRIVATE: /", "/")

allparams.graf = allparams.graf:gsub("^OFFTOPIC: /me ", "/me OFFTOPIC: ")
allparams.graf = allparams.graf:gsub("^OFFTOPIC: /em ", "/em OFFTOPIC: ")
allparams.graf = allparams.graf:gsub("^OFFTOPIC: /", "/")

allparams.graf = allparams.graf:gsub("^PRIVATE: OFFTOPIC: /me ", "/me PRIVATE: OFFTOPIC: ")
allparams.graf = allparams.graf:gsub("^PRIVATE: OFFTOPIC: /em ", "/em PRIVATE: OFFTOPIC: ")
allparams.graf = allparams.graf:gsub("^PRIVATE: OFFTOPIC: /", "/")

allparams.graf = allparams.graf:gsub("^/clan PRIVATE: /me ", "/clan /me PRIVATE: ")
allparams.graf = allparams.graf:gsub("^/clan PRIVATE: /em ", "/clan /em PRIVATE: ")
allparams.graf = allparams.graf:gsub("^/clan PRIVATE: /", "/")

allparams.graf = allparams.graf:gsub("^/clan OFFTOPIC: /me ", "/clan /me OFFTOPIC: ")
allparams.graf = allparams.graf:gsub("^/clan OFFTOPIC: /em ", "/clan /em OFFTOPIC: ")
allparams.graf = allparams.graf:gsub("^/clan OFFTOPIC: /", "/")

allparams.graf = allparams.graf:gsub("^/clan PRIVATE: OFFTOPIC: /me ", "/clan /me PRIVATE: OFFTOPIC: ")
allparams.graf = allparams.graf:gsub("^/clan PRIVATE: OFFTOPIC: /em ", "/clan /em PRIVATE: OFFTOPIC: ")
allparams.graf = allparams.graf:gsub("^/clan PRIVATE: OFFTOPIC: /", "/")

if allparams.graf:match("^/[A-Za-z0-9]+ /me ") then
elseif allparams.graf:match("^/[A-Za-z0-9]+ /em ") then
elseif allparams.graf:match("^/[A-Za-z0-9]+ /") then
	allparams.graf = allparams.graf:gsub("^/[A-Za-z0-9]+ ", "")
end

function sendchat_run_command_raw(cmd, rest)
	if chatcommands[cmd] then
		sendchat_pwd = allparams.pwd
		return chatcommands[cmd].f(rest)
	end
end

local cmd, rest = allparams.graf:match("(/[^ ]+) *(.*)")

-- print("DEBUG sendchat: ", allparams, "cmd is", cmd, "|", rest)

if cmd then
	local output = sendchat_run_command_raw(cmd, rest)
	if output then
		if tonumber(allparams.j) == 1 then
			return table_to_json { output = output, msgs = {} }
		else
			return output
		end
	end
end

if allparams.graf ~= original_graf then
	return "//kolproxy:sendgraf:" .. allparams.graf
else
	return ""
end

end

return run_wrapped_function
