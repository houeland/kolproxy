local trickortreat_scanner = nil
add_submit_page_listener(function(ptf)
        if trickortreat_scanner then
                trickortreat_scanner(ptf)
        end
end)

function automate_trick_or_treat_block()
	async_get_page("/town.php", { action = "trickortreat" })
	local pt = get_page("/choice.php")
	local houses = {}
	for whichhouse, img in pt:gmatch("whichhouse=([0-9]*)><img(.-)>") do
		houses[whichhouse] = img:match("otherimages/trickortreat/(house_.-.gif)") or img:match("otherimages/trickortreat/(starhouse.gif)")
	end
	for whichhouse, img in pairs(houses) do
		if img:contains("house_l") then
			print("DEBUG hit", whichhouse)
			async_get_page("/choice.php", { whichchoice = 804, pwd = params.pwd, option = 3, whichhouse = whichhouse })
		end
	end
	for whichhouse, img in pairs(houses) do
		if img:contains("starhouse") then
			print("DEBUG star", whichhouse)
			async_get_page("/choice.php", { whichchoice = 804, pwd = params.pwd, option = 3, whichhouse = whichhouse })
			async_get_page("/choice.php", { whichchoice = 806, pwd = params.pwd, option = 2 })
		end
	end
	for whichhouse, img in pairs(houses) do
		if img:contains("house_d") then
			print("DEBUG fight", whichhouse)
			async_get_page("/town.php", { action = "trickortreat" })
			set_result(get_page("/choice.php", { whichchoice = 804, pwd = params.pwd, option = 3, whichhouse = whichhouse }))
			if not get_result():contains("WINWINWIN") then
				text, url = get_result()
				return
			end
		end
	end
	async_get_page("/town.php", { action = "trickortreat" })
	text, url = get_page("/choice.php")
	return text, url
end

local trick_or_treat_href = add_automation_script("automate-trick-or-treat", function()
	text, url = "Not automation done.", requestpath
	local scan = setup_automation_scan_page_results()
	trickortreat_scanner = scan
	pcall(function()
		local times = tonumber(params.numblocks) or 0
		while times > 0 do
			automate_trick_or_treat_block()
			times = times - 1
			if times > 0 then
				async_get_page("/town.php", { action = "trickortreat" })
				async_get_page("/choice.php", { whichchoice = 804, pwd = params.pwd, option = 1 })
			end
		end
	end)
	trickortreat_scanner = nil
	text = setup_automation_display_page_results(scan, text)
	return text, url
end)

add_printer("/choice.php", function()
	if not text:contains("<b>Trick or Treat!</b>") or not text:contains("/house_") then return end
        local scriptsource = [[
<script language="javascript">
function automate_trick_or_treat() {
        var N = prompt('Automate how many blocks? (5 turns each after the first)')
        if (N > 0) {
                top.mainpane.location.href = ("]].. trick_or_treat_href { pwd = session.pwd } ..[[&numblocks=" + N)
        }
}
</script>
]]
	text = text:gsub([[</head>]], function(x) return scriptsource .. x end)
	text = text:gsub("(Click on a house to go Trick%-or%-Treating!)(<p>)", [[%1 <a style="color: green" href="javascript:automate_trick_or_treat()">{&nbsp;Automate&nbsp;}</a>%2]])
end)
