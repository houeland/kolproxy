add_choice_text("Turn Your Head and Coffin", { -- choice adventure number: 153
	["Investigate the fancy coffin"] = "Gain muscle",
	["Check out the pine box"] = { getmeatmin = 200, getmeatmax = 300 },
	["Look in the wet one"] = "Gain half-rotten brain",
	["Leave them all be"] = { leave_noturn = true, good_choice = true },
})

add_choice_text("Skull, Skull, Skull", function()
	if ascensionpath("Zombie Slayer") then
		return { -- choice adventure number: 155
			["Check behind the first one"] = "Gain moxie, or get Hovering Skull familiar if you don't already have it",
			["Look inside the second one"] = { getmeatmin = 200, getmeatmax = 300 },
			["See what's under the third one"] = "Gain rusty bonesaw",
			["Leave the skulls alone"] = { leave_noturn = true, good_choice = true },
		}
	else
		return { -- choice adventure number: 155
			["Check behind the first one"] = "Gain moxie",
			["Look inside the second one"] = { getmeatmin = 200, getmeatmax = 300 },
			["See what's under the third one"] = "Gain rusty bonesaw",
			["Leave the skulls alone"] = { leave_noturn = true, good_choice = true },
		}
	end
end)

add_choice_text("Urning Your Keep", { -- choice adventure number: 157
	["Investigate the first urn"] = "Gain mysticality",
	["Check out the second one"] = "Get plus-sized phylactery",
	["See what's behind Urn #3"] = { getmeatmin = 200, getmeatmax = 300 },
	["Turn away"] = { leave_noturn = true, good_choice = true },
})

add_choice_text("Death Rattlin'", { -- choice adventure number: 523
	["Open up the closed one"] = { getmeatmin = 200, getmeatmax = 300 },
	["Crawl inside the open one"] = { text = "Gain stats, HP and MP" },
	["Dig through the rubble on the ground"] = { text = "Gain can of Ghuol-B-Gone" },
	["Open the rattling one"] = { text = "Fight ghuol whelps", good_choice = true },
	["Leave the drawers alone"] = { leave_noturn = true },
})

function parse_evilometer()
	if have_item("Evilometer") then
		local pagetext = use_item("Evilometer")()
		local evilometer = {}
		for zonename, amount in pagetext:gmatch(">([A-Za-z ]*): <b>([0-9]*)</b>") do
			evilometer["The Defiled " .. zonename] = tonumber(amount)
		end
		if evilometer["The Defiled Alcove"] then
			return evilometer
		end
	end
end

local function add_zone_info(evilometer)
	local function add_zone_info(zoneinfo, zone, leftoffset)
		local evilstring = ""
		if evilometer and evilometer[zone] then
			evilstring = [[Evil: ]] .. evilometer[zone] .. [[</br>]]
		end
		local tablestring = [[<table style="height: 100px; vertical-align: middle;"><tr><td><span style="color: green">]] .. zoneinfo .. [[</span></td></tr></table>]]
		text = text:gsub([[(<td width=[0-9]* height=[0-9]*>)(<A href="adventure.php%?snarfblat=]]..zoneid..[[".-)(</td>)]], function(tdbegin, contents, tdend)
			return tdbegin .. [[<div style="position: relative;"><div style="position: absolute; left: ]] .. leftoffset .. [[; top: 65px; width: 100px; height: 100px;">]] .. evilstring .. tablestring .. [[</div>]] .. contents .. [[</div>]] .. tdend
		end)
	end
	add_zone_info("Drops evil eyes (+item%)", "The Defiled Nook", "-105px")
	add_zone_info("Dirty old lich (olfaction, banishing)", "The Defiled Niche", "155px")
	add_zone_info("Swarm of whelps (+ML, +noncombat%)", "The Defiled Cranny", "-105px")
	add_zone_info("Modern zmobie (+initiative%, +noncombat% to skip and reroll)", "The Defiled Alcove", "155px")
end

add_automator("/crypt.php", function()
	if not setting_enabled("show extra warnings") then return end
	add_zone_info(parse_evilometer())
	text = text:gsub("<body>", "%0<!-- already added kolproxy crypt zone info -->")
end)

add_automator("/fight.php", function()
	if not setting_enabled("show extra warnings") then return end
	if text:contains([[<a href="crypt.php">Go back to ]]) then
		local evilometer = parse_evilometer()
		if not evilometer then return end
		local crypt_zone = get_adventure_zoneid() and maybe_get_zonename(get_adventure_zoneid())
		if not crypt_zone then return end
		local evil_remaining = evilometer[crypt_zone]
		if not evil_remaining then return end
		text = text:gsub("(Evilometer.-)(<)", function(a, b)
			return a .. [[<br><span style="color: green">{ Evil remaining here: ]] .. evil_remaining .. [[ }</span>]] .. b
		end)
	end
end)

add_printer("/crypt.php", function()
	if not text:contains("already added kolproxy crypt zone info") then
		add_zone_info()
	end
end)

-- TODO: split in two, remove message="custom" support
add_warning {
	message = "custom",
	type = "notice",
	when = "ascension",
	check = function(zoneid)
	if zoneid and zoneid >= 261 and zoneid <= 264 then
		local evilometer = parse_evilometer()
			if evilometer then
				local evil_here = evilometer[maybe_get_zonename(zoneid)]
				if evil_here <= 25 then
					return "The boss is ready to be fought in this zone.", "crypt boss ready zone-" .. zoneid
				elseif evil_here == 26 then
					return "With 26 evil here, the boss will be ready no matter what you kill next.", "crypt evil at 26 zone-" .. zoneid
				end
			end
		end
	end,
}

add_warning {
	message = "You might want to use a marzipan skull for +initiative%.",
	type = "warning",
	zone = "The Defiled Alcove",
	check = function() return moonsign_area("Gnomish Gnomad Camp") and not (have_buff("Sugar Rush") and have_buff("Hombre Muerto Caminando")) end,
}

add_warning {
	message = "You might want to cast Springy Fusilli for +initiative%.",
	type = "warning",
	zone = "The Defiled Alcove",
	check = function() return not have_buff("Springy Fusilli") and have_skill("Springy Fusilli") end,
}

add_on_the_trail_warning("The Defiled Niche", "dirty old lihc")
