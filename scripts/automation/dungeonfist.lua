local automate_dungeon_fist_href = add_automation_script("automate-dungeonfist", function ()
	local numtimes = tonumber(params.numtimes)
	if numtimes then
		local pt, pturl
		for i = 1, numtimes do
			pt, pturl = get_page("/arcade.php", { action = "game", whichgame = "3", pwd = get_pwd() })

			if pt:match("bgcolor=blue><b>Dungeon Fist!</b>") then
				print("Dungeon Fisting " .. i .. " / " .. numtimes)
			else
				break
			end

			local opts = {3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 3, 3, 1, 1, 1, 1, 1}

			for x, o in ipairs(opts) do
				async_get_page("/choice.php", { whichchoice = "486", option = o, pwd = get_pwd() })
			end

			pt, pturl = get_page("/choice.php", { whichchoice = "486", option = "3", pwd = get_pwd() })

			if pt:match("class=effect>You acquire <b>30 Game Grid tickets</b>") then
				print("A Winner is You!")
			else
				break
			end
		end
		return pt, pturl
	end
end)

add_printer("/arcade.php", function()
	if setting_enabled("run automation scripts") then
		local function newtext(x)
			return [[
<script language="javascript">
function automate_N_times(url) {
	N = prompt('Play how many games of Dungeon Fist?');
	if (N > 0) {
		top.mainpane.location.href = (url + "&numtimes=" + N);
	}
}
</script><br><a href="javascript:automate_N_times('/kolproxy-automation-script?pwd=]] .. session.pwd .. [[&automation-script=automate-dungeonfist')" style="color:green">{ Automate Dungeon Fist (]] .. count_inventory("Game Grid token") .. [[ Game Grid token]] .. (count_inventory("Game Grid token") == 1 and "" or "s") .. [[ available) }</a>]]
		end
		text = text:gsub("(<a href=town_wrong.php>Back [^<]+</a>)", function(alltext, a, b, c) return alltext .. " " .. newtext(a, b, c) .. "\n" end)
	end
end)
