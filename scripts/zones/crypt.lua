add_choice_text("Turn Your Head and Coffin", { -- choice adventure number: 153
	["Investigate the fancy coffin"] = "Gain muscle",
	["Check out the pine box"] = { getmeatmin = 200, getmeatmax = 300 },
	["Look in the wet one"] = "Gain half-rotten brain",
	["Leave them all be"] = { leave_noturn = true, good_choice = true },
})

add_choice_text("Skull, Skull, Skull", function() 
	if ascensionpathid() == 10 then
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

add_automator("/fight.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if text:contains("WINWINWIN") or text:contains("state['fightover'] = true;") or text:contains([[<a href="crypt.php">Go back to The Defiled Cyrpt</a>]]) then
		-- TODO: would prefer a perfect trigger after fights
		if have("evil eye") then
			-- This currently uses any evil eyes you have, even if the Nook is completed.
			session["used evil eye"] = nil
			local c = count("evil eye")
			use_item("evil eye")
			if count("evil eye") == c - 1 then
				session["used evil eye"] = "Automatically used."
			end
		end
	end
end)

add_itemdrop_counter("evil eye", function(c)
	-- TODO: really not a counter
	local result = session["used evil eye"]
	if result then
		return "{ " .. result .. " }"
	end
end)

local function parse_evilometer()
	if have("Evilometer") then
		local pagetext = use_item("Evilometer")()
		local evilometer = {}
		for zonename, amount in pagetext:gmatch(">([A-Za-z ]*): <b>([0-9]*)</b>") do
			evilometer[zonename] = tonumber(amount)
		end
		if evilometer["Alcove"] then
			return evilometer
		end
	end
end

local crypt_zone_names = {
	[261] = "Alcove",
	[262] = "Cranny",
	[263] = "Niche",
	[264] = "Nook",
}

get_evilometer_data = parse_evilometer

local function add_zone_info(evilometer)
	local function add_zone_info(zoneinfo, zoneid, leftoffset)
		local evilstring = ""
		if evilometer then
			evilstring = [[Evil: ]] .. evilometer[crypt_zone_names[zoneid]] .. [[</br>]]
		end
		local tablestring = [[<table style="height: 100px; vertical-align: middle;"><tr><td><span style="color: green">]] .. zoneinfo .. [[</span></td></tr></table>]]
		text = text:gsub([[(<td width=[0-9]* height=[0-9]*>)(<A href="adventure.php%?snarfblat=]]..zoneid..[[".-)(</td>)]], function(tdbegin, contents, tdend)
			return tdbegin .. [[<div style="position: relative;"><div style="position: absolute; left: ]] .. leftoffset .. [[; top: 65px; width: 100px; height: 100px;">]] .. evilstring .. tablestring .. [[</div>]] .. contents .. [[</div>]] .. tdend
		end)
	end
	add_zone_info("Drops evil eyes (+item%)", 264, "-105px")
	add_zone_info("Dirty old lich (olfaction, banishing)", 263, "155px")
	add_zone_info("Swarm of whelps (+ML, +noncombat%)", 262, "-105px")
	add_zone_info("Modern zmobie (+initiative%, +noncombat% to skip and reroll)", 261, "155px")
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
		if evilometer and adventure_zone and crypt_zone_names[adventure_zone] then
			text = text:gsub("(Evilometer.-)(<)", function(a, b)
				return a .. [[<br><span style="color: green">{ Evil remaining here: ]] .. evilometer[crypt_zone_names[adventure_zone]] .. [[ }</span>]] .. b
			end)
		end
	end
end)

add_printer("/crypt.php", function()
	if not text:contains("already added kolproxy crypt zone info") then
		add_zone_info()
	end
end)

add_extra_ascension_adventure_warning(function(zoneid)
	if zoneid and zoneid >= 261 and zoneid <= 264 then
		local evilometer = parse_evilometer()
		if evilometer then
			local evil_here = evilometer[crypt_zone_names[zoneid]]
			if evil_here <= 25 then
				return "The boss is ready to be fought in this zone.", "crypt boss ready zone-" .. zoneid
			elseif evil_here == 26 then
				return "With 26 evil here, the boss will be ready no matter what you kill next.", "crypt evil at 26 zone-" .. zoneid
			end
		end
	end
end)

add_ascension_adventure_warning(function(zoneid)
	if zoneid == 261 and moonsign_area() == "Gnomish Gnomad Camp" then
		if not buff("Sugar Rush") or not buff("Hombre Muerto Caminando") then
			return "You might want to use marzipan skulls for +initiative%.", "use marzipan skulls in alcove"
		end
	end
end)
