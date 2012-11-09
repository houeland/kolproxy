function do_leaflet()
	local text = ""
	local pagefuncs = {}
	local function pp(cmds)
		local t = nil
		for _, c in ipairs(cmds) do
			t = async_post_page("/leaflet.php", { pwd = pwd, command = c })
			table.insert(pagefuncs, t)
		end
		return t
	end
	pp { "open door", "east", "take sword", "look at tinder", "take parchment" }
	local manteltext, manteluri = (pp { "look at mantel" })()
	local magic_words = {
		["small brick building"] = "plugh",
		["model ship inside a bottle"] = "yoho",
		["carved driftwood bird"] = "plover",
		["small white house"] = "xyzzy",
	}
	local magic = nil
	for a, b in pairs(magic_words) do
		if manteltext:match(a) then
			magic = b
		end
	end
	if magic == nil then
		text = manteltext
	else
		print("the magic word is", magic)
		pp { magic }
		pp { "west", "north", "take stick", "cut hedge", "west", "light stick", "east" }
		pp { "north", "kill snake", "open chest", "look behind chest", "look in hole", "south", "south" }
		pp { "east", "light fire", "take boots", "wear boots", "west" }
		pp { "south", "south" }
		pp { "south", "south" }

		print("exploring maze")
		for i = 1, 10 do
			pp { "north", "west", "east", "south" }
		end

		print("finishing leaflet")
		pp { "up", "take egg", "throw egg at roadrunner", "down" }
		pp { "move leaves", "up", "throw ruby at bowl" }
		pp { "gnusto cleesh", "up", "cleesh giant", "take ring", "win game" }
		ppexitf = pp { "exit" }

		print("leaflet done")

		text = ppexitf()
		local leafletresults = {}
		for ptf in table.values(pagefuncs) do
			local pt = ptf()
			for x in pt:gmatch("<td>(.-)</td>") do
				if x:match("You gain.-%.") then
					x = x:match(".+<td>(.+)") or x
					table.insert(leafletresults, "<center>" .. x .. "</center>")
				end
			end
			for x in pt:gmatch([[<center><table class="item" style="float: none" rel="[^"]*"><tr><td><img src="http://images.kingdomofloathing.com/itemimages/[^"]+.gif" alt="[^"]*" title="[^"]*" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire .-</td></tr></table></center>]]) do
				table.insert(leafletresults, x)
			end
			for x in pt:gmatch("<b>(.-)</b>") do
				if x:match("reappears in your spellbook") then
					table.insert(leafletresults, "<center>" .. x .. "</center>")
				end
			end
		end
		text = [[<script type="text/javascript">top.charpane.location.href="charpane.php";</script>]] .. text
		text = text:gsub("<body>", function(x) return x .. make_kol_html_frame(table.concat(leafletresults), "Results:") end)
	end
	return text, "/leaflet.php"
end

add_automator("/leaflet.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if params.justgothere == "yes" then
		if text:contains("You are standing in an open field west of a white house.") then
			text = do_leaflet()
		end
	end
end)
