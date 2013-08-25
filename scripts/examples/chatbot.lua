loadfile("scripts/base/base-lua-functions.lua")()
loadfile("scripts/base/kolproxy-core-functions.lua")()

local pwd = nil

function send_message(playerid, msg)
	get_page("/submitnewchat.php", { graf = "/msg " .. playerid .. " " .. msg, pwd = pwd })
end

function roll_dice(c)
	local x, y = c.msg:match("^roll ([0-9]+)d([0-9]+)$")
	x, y = tonumber(x), tonumber(y)
	if x and y and x >= 1 and x <= 100 and y >= 1 and y <= 1000000 then
		local sum = 0
		for i = 1, x do
			sum = sum + math.random(y)
		end
		send_message(c.who.id, "Rolled " .. sum .. " (" .. x .. "d" .. y .. ")")
	end
end

return function(f_env)
	do
		print(f_env)
		print("hello!")
		sleep(1)
		print("getting plains...")
		local pt = get_page("/plains.php")
		print("plains!")
		--print(pt)
	end

	pwd = json_to_table(get_page("/api.php", { what = "status", ["for"] = "kolproxy-botscript by Eleron", format = "json" })).pwd

	print("checking chat...")
	local lastlast = 0
	while true do
		local json = get_page("/newchatmessages.php", { j = 1, lasttime = lastlast })
		if not json:match("^{") then
			break
		end
--		print("chat json!", json)
		local chat = json_to_table(json)
		for _, x in ipairs(chat.msgs or {}) do
			print("  msg", table_to_json(x))
			if x.type == "private" then
				roll_dice(x)
			end
		end
		lastlast = chat.last
		sleep((chat.delay or 5000) / 1000)
	end


	print("done!")
end
