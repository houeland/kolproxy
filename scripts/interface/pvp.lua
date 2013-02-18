-- 	add_printer("/searchplayer.php", function()
-- 		-- TODO: support setting stance and attacking for other things besides flowers
-- 		mainstat = get_mainstat()
-- 	--~ 	print(mainstat)
-- 		if mainstat == "Muscle" then
-- 			stance = 1
-- 		elseif mainstat == "Mysticality" then
-- 			stance = 2
-- 		elseif mainstat == "Moxie" then
-- 			stance = 3
-- 		end
-- 		text = string.gsub(text, "</head>", [[<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
-- 	<script type="text/javascript">
-- 		function attack_result(name, link, pagetext) {
-- 			if (pagetext.match(/That player is ranked too low compared to you./)) {
-- 				link.innerHTML = '{ Too low rank. }';
-- 			} else if (pagetext.match(/>You've won the fight!</)) {
-- 				if (pagetext.match(/You acquire an item.*pretty flower/)) {
-- 					link.style.color = 'gray';
-- 					link.innerHTML = '{ Won flower. }';
-- 				} else {
-- 					link.style.color = 'gray';
-- 					link.innerHTML = '{ Won. }';
-- 				}
-- 			} else if (pagetext.match(/>You lost the fight!</)) {
-- 				link.style.color = 'darkorange';
-- 				link.innerHTML = '{ Lost. }';
-- 			} else if (pagetext.match(/You've already picked too many fights today./)) {
-- 				link.style.color = 'gray';
-- 				link.innerHTML = '{ Too many fights. }';
-- 			} else if (pagetext.match(/You may not attack players who are in Hardcore mode/)) {
-- 				link.style.color = 'gray';
-- 				link.innerHTML = '{ In Hardcore. }';
-- 			} else if (pagetext.match(/You can only attack other Hardcore players/)) {
-- 				link.style.color = 'gray';
-- 				link.innerHTML = '{ Not in Hardcore. }';
-- 			} else if (pagetext.match(/already won a fight today/)) {
-- 				link.style.color = 'gray';
-- 				link.innerHTML = '{ Already won. }';
-- 			} else if (pagetext.match(/too drunk to pick a fight/)) {
-- 				link.style.color = 'gray';
-- 				link.innerHTML = '{ Too drunk. }';
-- 			} else if (pagetext.match(/once you start hurting yourself/)) {
-- 				link.style.color = 'gray';
-- 				link.innerHTML = '{ Yourself. }';
-- 			} else {
-- 				link.style.color = 'red';
-- 				link.innerHTML = '{ Error. }';
-- 				alert("Fought " + name + "\n\n" + pagetext);
-- 			}
-- 		}
-- 		function attack_player(name, link) {
-- 			link.innerHTML = '{ Attacking... }';
-- 			$.ajax({ type:'POST', url:'/pvp.php', cache:false, data:{ action:"Yep.", pwd:"]] .. session.pwd .. [[", who:name, stance:]] .. stance .. [[, attacktype:"flowers", winmessage:"", losemessage:"" }, global:false, success: function(retdata) { attack_result(name, link, retdata) } });
-- 		}
-- 	</script>%0]])

-- 		text = text:gsub([[(<input type="radio" name="hardcoreonly" value="0")( checked)(>)]], [[%1%3]])
-- 		if ascensionstatus() == "Hardcore" then
-- 			text = text:gsub([[(<input type="radio" name="hardcoreonly" value="1")(>)]], [[%1 checked="checked"%2]])
-- 		else
-- 			text = text:gsub([[(<input type="radio" name="hardcoreonly" value="2")(>)]], [[%1 checked="checked"%2]])
-- 		end
-- 		text = text:gsub([[(<input type="checkbox" name="pvponly")(>)]], [[%1 checked="checked"%2]])
-- 		text = text:gsub([[(<tr><td class=small><b><a target=mainpane href="showplayer.php%?who=[0-9]+">)([^<]+)(</a></b>  %(PvP%).-)(</td>)]], [[%1%2%3 <a href="#" onclick="javascript:attack_player('%2', this); return false;" style="color: green;">{ Attack }</a>%4]])
-- 	end)

-- add_printer("/pvp.php", function()
-- 	text = text:gsub("(name=attacktype value=rank) checked", "%1"):gsub("name=attacktype value=flowers", "%0 checked")
-- end)

local automate_pvp_fights_href = add_automation_script("automate-pvp-fights", function()
	local numtimes = tonumber(params.numtimes)
	if numtimes then
-- 		local tbl = {}
		for i = 1, numtimes do
			local pf = async_post_page("/peevpee.php", { action = "fight", place = "fight", pwd = params.pwd, ranked = 1, stance = params.stance, attacktype = params.attacktype })
-- 			table.insert(tbl, pf)
		end
-- 		for i, pf in ipairs(tbl) do
-- 			pf()
-- 			print("got result for fight " .. i)
-- 		end
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

local cached_equipment_data = nil

local function load_equipment_mafia_datafile()
	local items = {}
	local valid_sections = {
		["Hats"] = "hat",
		["Pants"] = "pants", 
		["Shirts"] = "shirt",
		["Weapons"] = "weapon",
		["Off-hand"] = "offhand",
		["Accessories"] = "accessory",
-- 		["Containers"] = "container",
		["Familiar Items"] = "famequip",
	}
	local requirements = {}
	for l in io.lines("cache/files/equipment.txt") do
		l = l:gsub("\r", "")
		local newsection = l:match("^# ([A-Za-z ]*) section of equipment.txt")
		if newsection then
			section = valid_sections[newsection]
			if section and not items[section] then
-- 				print("NEW SECTION:", section)
				items[section] = {}
			end
		elseif section then
			local itemname, power, req = l:match("^([^\t]*)\t([0-9]+)\t([^\t]+)")
			if itemname and power and req then
				items[section][itemname] = {}
				items[section][itemname].modifiers = {}
				if req == "none" then
					items[section][itemname].requirements = {}
				else
					local which, amount = req:match("^([^:]+): ([0-9]+)$")
					if which and amount then
						amount = tonumber(amount)
						local statname = {
							Mus = "Muscle",
							Mys = "Mysticality",
							Mox = "Moxie",
						}
						if statname[which] and amount then
							items[section][itemname].requirements = { [statname[which]] = amount }
						end
					end
				end
			end
		end
	end
	local section = nil
	local unknown_mods = {}
	for l in io.lines("cache/files/modifiers.txt") do
		l = l:gsub("\r", "")
		local newsection = l:match("^# ([A-Za-z ]*) section of modifiers.txt")
		if newsection then
			section = valid_sections[newsection]
			if section and not items[section] then
-- 				print("NEW SECTION:", section)
				items[section] = {}
			end
		elseif section then
			local itemname, mods = l:match("^([^\t]*)\t(.+)$")
			if itemname and mods and not itemname:match("^#") then
				local function mod_item(modname, bonus)
					if not items[section][itemname] then
-- 						print("Eek!", itemname, "does not exist!")
						items[section][itemname] = {}
						items[section][itemname].modifiers = {}
					end
					items[section][itemname].modifiers[modname] = (items[section][itemname].modifiers[modname] or 0) + bonus
				end
				local function add_modifier(modname, bonus)
					if modname == "Muscle" or modname == "Mysticality" or modname == "Moxie" then
						mod_item(modname, bonus)
					elseif modname == "Item Drop" then
						mod_item("plusitems", bonus)
					elseif modname == "Hobo Power" then
						mod_item("hobopower", bonus)
					elseif modname == "PvP Fights" then
-- 						mod_item("pvpfights", bonus)
					elseif modname == "Adventures" then
-- 						mod_item("adventures", bonus)
					elseif modname == "Muscle Percent" then
						-- TODO: do percent modifiers differently
						mod_item("Muscle", math.floor(basemuscle() * bonus / 100))
					elseif modname == "Mysticality Percent" then
						mod_item("Mysticality", math.floor(basemysticality() * bonus / 100))
					elseif modname == "Moxie Percent" then
						mod_item("Moxie", math.floor(basemoxie() * bonus / 100))
					else
						unknown_mods[modname] = true
					end
				end
				mod_item("namelength", itemname:len())
				for x in (mods .. ", "):gmatch("([^,]*), ") do
					local what, plusminus, amount = x:match("^([^:]*): ([+-])([0-9]+)$")
					if what and plusminus and amount then
						if plusminus == "+" then
							add_modifier(what, tonumber(amount))
						elseif plusminus == "-" then
							add_modifier(what, -tonumber(amount))
						end
					end
				end
			end
		end
	end
	for x, _ in pairs(unknown_mods) do
-- 		print("unknown!", x)
	end
	return items
end

local function load_equipment_data()
	if not cached_equipment_data then
		cached_equipment_data = load_equipment_mafia_datafile()
	end
	return cached_equipment_data
end

-- local function compute_score(itemdata, values)
-- 	local statfuncs = {
-- 		Muscle = basemuscle,
-- 		Mysticality = basemysticality,
-- 		Moxie = basemoxie,
-- 	}
-- 	-- TODO: Currently only famequipment doesn't have requirements in equipment.txt???
-- 	for rstat, rvalue in pairs(itemdata.requirements or {}) do
-- 		if statfuncs[rstat]() < rvalue then
-- 			return nil
-- 		end
-- 	end
-- 	local score = 0
-- 	for modname, modamount in pairs(itemdata.modifiers) do
-- 		score = score + values[modname] * modamount
-- 	end
-- 	return score
-- end

-- local function compute_best_equipment(eqdata, values)
-- 	for s, items in pairs(eqdata) do
-- 		local best_score = nil
-- 		local best_item = nil
-- 		for name, data in pairs(items) do
-- 			local score = compute_score(data, values)
-- 			if score then
-- 				if not best_score or score > best_score then
-- 					best_score = score
-- 					best_item = name
-- 				end
-- 			end
-- 		end
-- 		print("best item", s, best_item, best_score, items[best_item])
-- 	end
-- end

local function dominates(a, b)
	for name, amount in pairs(b) do
		if (a[name] or 0) < amount then
			return false
		end
	end
	return true
end

local function compute_best_equipment(eqdata)
	local besteq = {}
	for s, items in pairs(eqdata) do
		local good_items = {}
		local function add_item(name, data)
			if name == "especially homoerotic frat-paddle" or name == "Staff of the Scummy Sink" then
				return -- broken in mafia data files
			end
			local statfuncs = {
				Muscle = basemuscle,
				Mysticality = basemysticality,
				Moxie = basemoxie,
			}
			for rstat, rvalue in pairs(data.requirements or {}) do
				if statfuncs[rstat]() < rvalue then
-- 					print(name, "ineligible")
-- 					return
				end
			end
			if not have_item(name) then
-- 				print(name, "missing")
-- 				return
			end
			for a, b in pairs(good_items) do
				if dominates(b.modifiers, data.modifiers) then
-- 					print(name, "<", a)
					return
				end
			end
			for a, b in pairs(good_items) do
				if dominates(data.modifiers, b.modifiers) then
-- 					print(name, ">", a)
					good_items[a] = nil
				end
			end
			good_items[name] = data
		end
		for name, data in pairs(items) do
			add_item(name, data)
		end
		local count = 0
		for _, _ in pairs(good_items) do
			count = count + 1
		end
		print("best", s, "count", count)
-- 		for a, b in pairs(good_items) do
-- 			print("", a)
-- 		end
		besteq[s] = good_items
-- 		for a, b in pairs(good_items) do
-- 			print("", a, b.modifiers)
-- 		end
-- 		print("best item", s, best_item, best_score, items[best_item])
	end
	return besteq
end

local function compute_best_outfits(besteq)
	local bestoutfits = {}
	bestoutfits[{}] = {}
	for s, items in pairs(besteq) do
		local bestnew = {}
		for x, y in pairs(bestoutfits) do
			bestnew[x] = y
		end
		local function add_new(name, out)
			for a, b in pairs(bestnew) do
				if dominates(b, out) then
					return
				end
			end
			for a, b in pairs(bestnew) do
				if dominates(out, b) then
					bestnew[a] = nil
				end
			end
			bestnew[name] = out
		end
		for boid, bodata in pairs(bestoutfits) do
			for name, data in pairs(items) do
				local newout = {}
				for x, y in pairs(bodata) do
					newout[x] = y
				end
				for x, y in pairs(data.modifiers) do
					newout[x] = (newout[x] or 0) + y
				end
				local newname = {}
				for _, y in ipairs(boid) do
					table.insert(newname, y)
				end
				table.insert(newname, name)
				add_new(newname, newout)
			end
		end
		bestoutfits = bestnew
		local count = 0
		for _, _ in pairs(bestoutfits) do
			count = count + 1
		end
		print("after", s, "count", count)
	end
-- 	print(bestoutfits)
	return bestoutfits
end

local optimize_pvp_equipment_href = add_automation_script("optimize-pvp-equipment", function()
	local eqdata = load_equipment_data()
	local besteq = compute_best_equipment(eqdata, { Muscle = 100, Mysticality = 100, Moxie = 100, plusitems = 285, hobopower = 400, pvpfights = 0, adventures = 0, namelength = 1000 })
	local bestoutfits = compute_best_outfits(besteq)
	return "Note: Work in progress, currently missing an interface", requestpath
end)

-- add_printer("/peevpee.php", function()
-- 	if params.place then return end
-- 	if not setting_enabled("enable experimental implementations") then return end
-- 	text = text:gsub([[</body>]], [[<center><a href="]] .. optimize_pvp_equipment_href { pwd = session.pwd } .. [[" style="color: green;">{ Optimize PvP equipment. }</a></center>%0]])
-- end)
