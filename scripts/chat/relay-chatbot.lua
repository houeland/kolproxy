local sources = {
	{ "clan", "1736451", "AFH" },
	{ "clan", "1736457", "AFHk" },
	{ "clan", "1736458", "AFHobo" },
	{ "clan", "2402686", "CGRelay" },
}

--~ local contact_color = get_character_state("kol.account.contact chat color") -- TODO-future: can these be moved to chat state?
--~ local contacts = get_character_state("kol.account.contact list")
--~ if (contacts == "") then contacts = {} else contacts = str_to_table(contacts) end

contacts = {}

local function get_contact_color(name, id, default)
-- 	print("color!", id, contacts[id], default, contact_color)
	if contact_color ~= "" and contacts[id] then
		return [["]]..contact_color..[["]]
	end
	return default
end

function lookup_player_id(inputname) -- chat cannot use character state
	if inputname:len() > 20 then
		if inputname:sub(20, 20) == " " then
-- 			print("transforming", inputname)
			inputname = inputname:sub(1, 19) .. inputname:sub(21)
-- 			print("  to", inputname)
		end
	end
	local name = inputname:lower()
	local tbl = get_chat_state("kol.player ids")
	if (tbl == "") then tbl = {} else tbl = str_to_table(tbl) end
	if not tbl[name] then
		local id = get_player_id(name)
		--print("get_player_id", name, "=", id)
		if id == "-1" then
			return "-123", inputname
		else
			tbl[name] = id
			set_chat_state("kol.player ids", table_to_str(tbl))
		end
	end
-- 	print("lookup_player_id.", inputname, tbl[name])
	return tbl[name], inputname
end

local function do_replacement(chatmsg, test)
	local preid, precolor, chatcolor, prename, premsg, msg, after = string.match(chatmsg, test)
	if after then
		local id = lookup_player_id(name)
		chatmsg = prename..id..mid..get_contact_color(string.lower(name), id, color)..premsg..name..w..msg..after
		replaced = true
	end
	return chatmsg
end

add_chat_printer(function(chatmsg)
	for _, b in ipairs(sources) do
		-- TODO-future: revisit these regexes
		local function replace(chatmsg, firsttest, test)
			local prefix, preid, precolor, chatcolor, prename, premsg, msg = chatmsg:match(firsttest)
			if msg then
				local name, msgtext = msg:match(test)
				if name and msgtext then
					local id, newname = lookup_player_id(name)
					local color = get_contact_color(newname:lower(), id, chatcolor)
					chatmsg = prefix .. preid .. id .. precolor .. color .. prename .. newname .. premsg .. msgtext
				end
			end
			return chatmsg
		end
		-- normal text
		local bigtest = [[^(.-)(<b><a target=mainpane href="showplayer%.php%?who=)]]..b[2]..[[("><font color=)([^>]-)(>)]]..b[3]..[[(</font></b></a>: )(.+)$]]
		chatmsg = replace(chatmsg, bigtest, "^%(([^*].-)%) (.-)$")
		chatmsg = replace(chatmsg, bigtest, "^%[([^*].-)%] (.-)$")
		chatmsg = replace(chatmsg, bigtest, "^{([^*].-)} (.-)$")

		-- emote text
		local bigtest = [[^(.-)(<b><i><a target=mainpane href="showplayer%.php%?who=)]]..b[2]..[[("><font color=)([^>]-)(>)]]..b[3]..[[(</b></font></a> )(.+)$]]
		chatmsg = replace(chatmsg, bigtest, "^%(([^*].-)%) (.-)$")
		chatmsg = replace(chatmsg, bigtest, "^%[([^*].-)%] (.-)$")
		chatmsg = replace(chatmsg, bigtest, "^{([^*].-)} (.-)$")
	end
	return chatmsg
end)

-- BOT MSG:	{
--   ["type"] = "public",
--   ["time"] = "1332941421",
--   ["who"] = { ["id"] = "1736451", ["name"] = "AFH", ["color"] = "black" },
--   ["channelcolor"] = "#666666",
--   ["msg"] = "(MasterSilex) like harpoon",
--   ["channel"] = "clan",
--   ["format"] = "0",
-- }

-- msg:	{
--   ["type"] = "public",
--   ["time"] = "1332944421",
--   ["who"] = { ["id"] = "1736451", ["name"] = "AFH", ["color"] = "black" },
--   ["channelcolor"] = "#666666",
--   ["msg"] = "<b><i><a target=mainpane href=\"showplayer.php?who=1736451\"><font color=\"black\">AFH</b></font></a> (Transplanted_Entwif e) returns</i>",
--   ["channel"] = "clan",
--   ["format"] = "1",
-- }

add_json_chat_printer(function(msg)
	for _, b in ipairs(sources) do
		if msg.channel == b[1] and tonumber(msg.who.id) == tonumber(b[2]) and msg.who.name == b[3] then
			if tonumber(msg.format) == 0 then
				local realname, realmsg = msg.msg:match([[[({[](.-)[])}] (.+)]])
				if realname and realmsg then
					local newid, newname = lookup_player_id(realname)
					msg.who.id = tostring(newid)
					msg.who.name = newname
					msg.msg = realmsg
-- 					print("BOT MSG:", newid, newname, realmsg)
				end
			elseif tonumber(msg.format) == 1 then
				local realname, realmsg = msg.msg:match([[<b><i><a target=mainpane href="showplayer.php%?who=]]..msg.who.id..[["><font color="[^"]*">]]..msg.who.name..[[</b></font></a> %((.-)%) (.+)</i>]])
				if realname and realmsg then
					local newid, newname = lookup_player_id(realname)
					msg.who.id = tostring(newid)
					msg.who.name = newname
					msg.msg = [[<b><i><a target=mainpane href="showplayer.php?who=]]..msg.who.id..[["><font color="]]..msg.who.color..[[">]]..msg.who.name..[[</b></font></a> ]]..realmsg..[[</i>]]
-- 					print("BOT EMOTE:", newid, newname, realmsg)
				end
			end
		end
	end
	if msg.channel == "clan" then
		if msg.msg:gsub("%b<>", ""):match("^([Pp][Rr][Ii][Vv][Aa][Tt][Ee]: ?)(.*)") then
			msg.channel = "clan PRIVATE:"
			msg.msg = msg.msg:gsub("[Pp][Rr][Ii][Vv][Aa][Tt][Ee]: ", "", 1)
		end
		if msg.msg:gsub("%b<>", ""):match("^([Oo][Ff][Ff][Tt][Oo][Pp][Ii][Cc]: ?)(.*)") then
			msg.channel = msg.channel .. " OFFTOPIC:"
			msg.msg = msg.msg:gsub("[Oo][Ff][Ff][Tt][Oo][Pp][Ii][Cc]: ", "", 1)
		end
	end
end)

-- local custom_colors = get_character_state("kol.custom chat colors")
-- if (custom_colors == "") then custom_colors = {} else custom_colors = str_to_table(custom_colors) end
-- 
-- for name, color in pairs(custom_colors) do
-- 	text = string.gsub(text, "(<font color=[^>]->%[.-%]</font> <b><a target=mainpane href=\"showplayer%.php%?who=[0-9]-\"><font color=)([^>]-)(>"..name.."</font></b></a>: )", "%1"..color.."%3")
-- 	text = string.gsub(text, "(<font color=[^>]->%[.-%]</font> <b><i><a target=mainpane href=\"showplayer%.php%?who=[0-9]-\"><font color=)([^>]-)(>"..name.."</b></font></a> )", "%1"..color.."%3")
-- end
