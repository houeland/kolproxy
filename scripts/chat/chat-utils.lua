function submitnewchat(msg)
	return get_page("/submitnewchat.php", { graf = msg, pwd = session.pwd, j = 1 })
end

function submitnewchat_noajax(msg)
	return get_page("/submitnewchat.php", { graf = msg, pwd = session.pwd })
end

function who_channel(channel)
	local response = submitnewchat_noajax("/who " .. channel)
	local players = {}
	for line in response:gmatch([[<a.-</a>]]) do
		local playerid = tonumber(line:match([[href="showplayer.php%?who=([0-9-]*)"]]))
		local playername = line:match([[<font color=.->(.-)</font>]])
		local afk = line:match([[class="afk"]]) ~= nil
		local in_channel = line:match([[<font color=black>]]) ~= nil
		if playerid and playername then
			players[playerid] = {
				name = playername,
				afk = afk,
				in_channel = in_channel,
			}
		end
	end
	return players
end

function curse_playerid(playerid, item)
	return async_post_page("/curse.php", { action = "use", pwd = session.pwd, whichitem = get_itemid(item), targetplayer = playerid })
end
