register_setting {
	name = "break hippy stone when ascending",
	description = "Break Hippy Stone when ascending to enable PvP",
	group = "automation",
	default_level = "enthusiast",
}

function automate_pvp_fights(numtimes, stance, attacktype)
	local tbl = {}
	for i = 1, numtimes do
		local pf = async_post_page("/peevpee.php", { action = "fight", place = "fight", pwd = session.pwd, ranked = 1, stance = stance, attacktype = attacktype })
		table.insert(tbl, pf)
	end
	for i, pf in ipairs(tbl) do
		pf()
		print("INFO: got result for fight " .. i)
	end
end

local automate_pvp_fights_href = add_automation_script("automate-pvp-fights", function()
	local numtimes = tonumber(params.numtimes)
	if numtimes then
		automate_pvp_fights(numtimes, params.stance, params.attacktype)
		text, url = get_page("/peevpee.php", { place = "logs" })
		return text, url
	end
end)

add_printer("/peevpee.php", function()
	text = text:gsub([[<p>You have [0-9,]+ fights remaining today.</p>]], [[%0
<script language="javascript">
function fight_N_times() {
	N = prompt('Fight how many times?')
	stance = document.getElementsByName("stance")[0].value
	attacktype = document.getElementsByName("attacktype")[0].value
	if (N > 0) {
		top.mainpane.location.href = ("]] .. automate_pvp_fights_href { pwd = session.pwd } .. [[&numtimes=" + N + "&stance=" + stance + "&attacktype=" + attacktype)
	}
}
</script>
<p><a href="javascript:fight_N_times()" style="color: green">{ Fight N random opponents }</a></p>]])
end)

-- /campground.php [("smashstone","Yep."),("pwd","34e80db63287568e4219715385c710c6"),("confirm","on")]
