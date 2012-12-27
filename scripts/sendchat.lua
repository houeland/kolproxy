dofile("scripts/base/util.lua")
dofile("scripts/base/base-lua-functions.lua")

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
		dofile("scripts/"..name)
	end
end

dofile("scripts/loaders.lua")

-- print("sendchat rawinput", f_env.raw_input_params)

local allparams = parse_params(f_env.raw_input_params)

if not allparams or not allparams.graf then return "" end

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
	[ [[PRIVATE: /listenoff clan PRIVATE:]] ] = true,
}

if tonumber(allparams.j) == 1 and ignore_grafs[allparams.graf] then
	return table_to_json { output = "", msgs = {} }
end

if allparams.graf:match("^PRIVATE: /") then
	allparams.graf = allparams.graf:gsub("^PRIVATE: ", "")
elseif allparams.graf:match("^/clan PRIVATE: /") then
	allparams.graf = allparams.graf:gsub("^/clan PRIVATE: ", "")
elseif allparams.graf:match("^/[A-Za-z0-9]+ /") then
	allparams.graf = allparams.graf:gsub("^/[A-Za-z0-9]+ ", "")
end

function sendchat_run_command_raw(cmd, rest)
	if chatcommands[cmd] then
		sendchat_pwd = allparams.pwd
		return chatcommands[cmd].f(rest)
	end
end

local cmd, rest = allparams.graf:match("(/[^ ]+)(.*)")

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

return ""

end

return run_wrapped_function
