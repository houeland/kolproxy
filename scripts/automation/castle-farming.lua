local daily_familiars = {
	["Astral Badger"] = { item = "astral mushroom", counter = "familiar.badger.mushroom" },
	["Bloovian Groose"] = { item = "groose grease", counter = "familiar.bloovian groose.grease" },
	["Llama Lama"] = { item = "llama lama gong", counter = "familiar.llama.gong" },
	["Green Pixie"] = { item = "tiny bottle of absinthe", counter = "familiar.pixie.absinthe" },
	["Rogue Program"] = { item = "Game Grid token", counter = "familiar.rogue program.tokens" },
	["Baby Sandworm"] = { item = "agua de vida", counter = "familiar.sandworm.agua" },
	["Li'l Xenomorph"] = { item = "transporter transponder", counter = "familiar.lil xenomorph.transponders" },
}

function run_castle_turns(numturns, preferfamid)
	script = get_automation_scripts()
	local start_advs = adventures()
	local have_familiars = {}
	for a, b in pairs(daily_familiars) do
		switch_familiarid(get_familiarid(a))
		if familiarid() == get_familiarid(a) then
			table.insert(have_familiars, a)
			print(a, daily_familiars[a].item, estimate_mallsell_profit(daily_familiars[a].item), get_daily_counter(b.counter))
		end
	end
	table.sort(have_familiars, function(a, b)
		return estimate_mallsell_profit(daily_familiars[a].item) < estimate_mallsell_profit(daily_familiars[b].item)
	end)
	for i = 1, 1000 do
		print("automating turn "..tostring(start_advs - adventures() + 1).. " / " .. numturns)

		script.heal_up()
		script.ensure_buffs { "Musk of the Moose", "Leash of Linguini" }

		-- TODO: sort by expected value
		local wantfamid = preferfamid
		for ctrtest = 5, 1, -1 do
			for _, a in pairs(have_familiars) do
				b = daily_familiars[a]
				if get_daily_counter(b.counter) < ctrtest then
					wantfamid = get_familiarid(a)
				end
			end
		end
		if familiarid() ~= wantfamid then
			switch_familiarid(wantfamid)
		end

		text, url, advagain = autoadventure { zoneid = 324, noncombatchoices = {
			["Melon Collie and the Infinite Lameness"] = "End His Suffering",
			["Yeah, You're for Me, Punk Rock Giant"] = "Get the Punk's Attention",
			["Flavor of a Raver"] = "Pick a Fight",
			["Copper Feel"] = "Go through the Crack",
		} }

		if not advagain then
			return text, url
		elseif start_advs - adventures() >= numturns then
			return text, url
		end
	end
	return text, url
end

local castle_farming_href = add_automation_script("castle-farming", function()
	if not autoattack_is_set() then
		stop "Setting an Auto-Attack is required for automated castle farming. This can be done in KoL options &rarr; Combat, or with the /autoattack chat command (or the /aa abbreviation)."
	end
	local numturns = tonumber(params.numturns)
	if numturns then
		local famid = familiarid()
		local ret = { run_castle_turns(numturns, famid) }
		switch_familiarid(famid)
		return unpack(ret)
	end
end)

add_printer("/place.php", function()
	if params.whichplace ~= "beanstalk" and params.whichplace ~= "giantcastle" then return end
	if not setting_enabled("enable turnplaying automation") then return end
	if not ascensionstatus("Aftercore") then return end
	local scriptsource = [[
<script language="javascript">
function automate_castle() {
	var N = prompt('Automate how many turns of castle farming?')
	if (N > 0) {
		top.mainpane.location.href = ("]].. castle_farming_href { pwd = session.pwd } ..[[&numturns=" + N)
	}
}
</script>
]]
	text = text:gsub([[</head>]], function(x) return scriptsource .. x end)
	text = text:gsub([[</body>]], [[<center><a href="javascript:automate_castle()" style="color: green;">{ Automate castle farming. }</a></center>%0]])
end)
