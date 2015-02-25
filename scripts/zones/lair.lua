tower_monster_items = {
	["Beer Batter"] = "baseball",
	["best-selling novelist"] = "plot hole",
	["Big Meat Golem"] = "meat vortex",
	["Bowling Cricket"] = "sonar-in-a-biscuit",
	["Bronze Chef"] = "leftovers of indeterminate origin",
	["concert pianist"] = "Knob Goblin firecracker",
	["darkness"] = "inkwell",
	["El Diablo"] = "mariachi G-string",
	["Electron Submarine"] = "photoprotoneutron torpedo",
	["endangered inflatable white tiger"] = "pygmy blowgun",
	["fancy bath slug"] = "fancy bath salts",
	["Fickle Finger of F8"] = "razor-sharp can lid",
	["Flaming Samurai"] = "frigid ninja stars",
	["giant fried egg"] = "black pepper",
	["Giant Desktop Globe"] = "NG",
	["Ice Cube"] = "hair spray",
	["malevolent crop circle"] = "bronzed locust",
	["possessed pipe-organ"] = "powdered organs",
	["Pretty Fly"] = "spider web",
	["Tyrannosaurus Tex"] = "chaos butterfly",
	["Vicious Easel"] = "disease",

	["collapsed mineshaft golem"] = "stick of dynamite",
	["Enraged Cow"] = "barbed-wire fence",
	["giant bee"] = "tropical orchid",
}

lair_gateitems = {
	["Gate of Hilarity"] = { effect = "Comic Violence", item = "gremlin juice" },
	["Gate of Humility"] = { effect = "Wussiness", item = "wussiness potion" },
	["Gate of Morose Morbidity and Moping"] = { effect = "Rainy Soul Miasma", item = "thin black candle" },
	["Gate of Slack"] = { effect = "Extreme Muscle Relaxation", item = "Mick's IcyVapoHotness Rub" },
	["Gate of Spirit"] = { effect = "Woad Warrior", item = "pygmy pygment" },
	["Gate of the Porcupine"] = { effect = "Spiky Hair", item = "super-spiky hair gel" },
	["Twitching Gates of The Suc Rose"] = { effect = "Sugar Rush" },
	["Gate of the Viper"] = { effect = "Deadly Flashing Blade", item = "adder bladder" },
	["Locked Gate"] = { effect = "Locks Like the Raven", item = "Black No. 2" },

	["Gate of Flame"] = { effect = "Spicy Mouth", item = "jaba&ntilde;ero-flavored chewing gum", gnomish_buyable = true },
	["Gate of Intrigue"] = { effect = "Mysteriously Handsome", item = "handsomeness potion", gnomish_buyable = true },
	["Gate of Machismo"] = { effect = "Engorged Weapon", item = "Meleegra&trade; pills", gnomish_buyable = true },
	["Gate of Mystery"] = { effect = "Mystic Pickleness", item = "pickle-flavored chewing gum", gnomish_buyable = true },
	["Gate of the Dead"] = { effect = "Hombre Muerto Caminando", item = "marzipan skull", gnomish_buyable = true },
	["Gate of Torment"] = { effect = "Tamarind Torment", item = "tamarind-flavored chewing gum", gnomish_buyable = true },
	["Gate of Zest"] = { effect = "Spicy Limeness", item = "lime-and-chile-flavored chewing gum", gnomish_buyable = true },

	["Gate of Light"] = { effect = "Izchak's Blessing", potion = "blessing" },
	["Gate of That Which is Hidden"] = { effect = "Object Detection", potion = "detection" },
	["Gate of the Mind"] = { effect = "Strange Mental Acuity", potion = "acuity" },
	["Gate of the Ogre"] = { effect = "Strength of Ten Ettins", potion = "strength" },
	["Gate that is Not a Gate"] = { effect = "Teleportitis", potion = "teleportation" },
}

local scopes = {
	["see a wooden gate with an elaborate carving of an armchair on it."] = "Gate of Spirit",
	["see a wooden gate with an elaborate carving of a cowardly%-looking man on it."] = "Gate of Humility",
	["see a wooden gate with an elaborate carving of a banana peel on it."] = "Gate of Hilarity",
	["see a wooden gate with an elaborate carving of a coiled viper on it."] = "Gate of the Viper",
	["see a wooden gate with an elaborate carving of a rose on it."] = "Twitching Gates of The Suc Rose",
	["see a wooden gate with an elaborate carving of a glum teenager on it."] = "Gate of Morose Morbidity and Moping",
	["see a wooden gate with an elaborate carving of a hedgehog on it."] = "Gate of the Porcupine",
	["see a wooden gate with an elaborate carving of a raven on it."] = "Locked Gate",
	["see a wooden gate with an elaborate carving of a smiling man smoking a pipe on it."] = "Gate of Slack",

-- TODO: resolve to monster instead of item
	["catch a glimpse of a flaming katana."] = "frigid ninja stars",
	["catch a glimpse of a translucent wing."] = "spider web",
	["see a fancy%-looking tophat."] = "sonar-in-a-biscuit",
	["see a flash of albumen."] = "black pepper",
	["see a giant white ear."] = "pygmy blowgun",
	["see a huge face made of Meat."] = "meat vortex",
	["see a large cowboy hat."] = "chaos butterfly",
	["see a periscope."] = "photoprotoneutron torpedo",
	["see a slimy eyestalk."] = "fancy bath salts",
	["see a strange shadow."] = "inkwell",
	["see moonlight reflecting off of what appears to be ice."] = "hair spray",
	["see part of a tall wooden frame."] = "disease",
	["see some amber waves of grain."] = "bronzed locust",
	["see some long coattails."] = "Knob Goblin firecracker",
	["see some pipes with steam shooting out of them."] = "powdered organs",
	["see some sort of bronze figure holding a spatula."] = "leftovers of indeterminate origin",
	["see the neck of a huge bass guitar."] = "mariachi G-string",
	["see what appears to be the North Pole."] = "NG",
	["see what looks like a writing desk."] = "plot hole",
	["see the tip of a baseball bat."] = "baseball",
	["see what seems to be a giant cuticle."] = "razor-sharp can lid",

	["see a formidable stinger."] = "tropical orchid",
	["see a wooden beam."] = "stick of dynamite",
	["see a pair of horns."] = "barbed-wire fence",
}

-- TODO: List automatically from data files(?)
local sugar_rush_items = {
	{ name = "Tasty Fun Good rice candy", usable = true },
	{ name = "Angry Farmer candy", usable = true },
	{ name = "Yummy Tummy bean", usable = false },
	{ name = "Cold Hots candy", usable = true },
	{ name = "Wint-O-Fresh mint", usable = true },
	{ name = "Senior Mints", usable = true },
	{ name = "marzipan skull", usable = true },
	{ name = "Daffy Taffy", usable = true },
	{ name = "black forest cake", usable = false },
	{ name = "brown sugar cane", usable = false },
	{ name = "breath mint", usable = true },
	{ name = "Crimbo peppermint bark", usable = true },
	{ name = "Crimbo fudge", usable = true },
	{ name = "Crimbo candied pecan", usable = true },
	{ name = "bucket of honey", usable = false },
	{ name = "Okee-Dokee soda", usable = true },
}

function get_sugar_rush_item()
	local have_any = nil
	for _, x in ipairs(sugar_rush_items) do
		if have_item(x.name) then
			if x.usable then
				return x.name, x.name
			elseif not have_any then
				have_any = x.name
			end
		end
	end
	return nil, have_any
end

add_printer("/campground.php", function() -- this is also called when using mystical bookshelf skills etc.
	local have_scope_item = function(name)
		if name == "Twitching Gates of The Suc Rose" then
			local _, have_any = get_sugar_rush_item()
			if have_any then
				return true, have_any
			else
				return false, "(Sugar Rush)"
			end
		end
		if lair_gateitems[name] then
			name = lair_gateitems[name].item
		end
		return have_item(name), name
	end

	for from, to in pairs(scopes) do
		if text:match(from) then
			local ok, description = have_scope_item(to)
			if ok then
				text = text:gsub(from, [[%0 (<span style="color: green">]]..description..[[</span>)]])
			else
				text = text:gsub(from, [[%0 <b>(<span style="color: darkorange">]]..description..[[</span>)</b>]])
			end
		end
	end
end)

add_processor("/campground.php", function()
	local itemsneeded = {}
	local whereidx = {}
	for from, to in pairs(scopes) do
		if text:match(from) then
			local where = 0
			for i = 1, 100 do
				where = text:find(from, where + 1)
				if not where then break end
				whereidx[to] = where
-- 				print("scope", to, where)
				table.insert(itemsneeded, to)
			end
		end
	end
-- 	print("itemsneeded: ", table.concat(itemsneeded, "?"))
	table.sort(itemsneeded, function(a, b) return whereidx[a] < whereidx[b] end)
-- 	print("itemsneeded: ", table.concat(itemsneeded, "|"))
	if #itemsneeded > 0 then
		session["zone.lair.itemsneeded"] = itemsneeded
	end
end)

--				if not lair_gateitems[gate_input] then
--					for a, b in pairs(lair_gateitems) do
--						if b.item == gate_input then
--							gate = a
--						end
--					end
--				end

function get_lair_gate_items()
	local gatestatus = session["zone.lair.gates"] or {}
	local scopeitems = session["zone.lair.itemsneeded"] or {}
	local gate_items = {}
	gate_items[1] = gatestatus[1] or scopeitems[1]
	gate_items[2] = gatestatus[2]
	gate_items[3] = gatestatus[3]
	return gate_items
end

function get_lair_tower_monster_items()
	local scopeitems = session["zone.lair.itemsneeded"] or {}
	local tower_monsters = ascension["zone.lair.tower monsters"] or {}

	local function lookup(level)
		local scoped = scopeitems[level + 1]
		if scoped then return scoped end
		local monster = tower_monsters["level" .. level]
		if monster then return tower_monster_items[monster] end
	end

	local tower_items = {}
	for i = 1, 6 do
		tower_items[i] = lookup(i)
	end

	return tower_items
end

function requires_wand_of_nagamar()
	local paths_without_wand = {
		["Bees Hate You"] = true,
		["Avatar of Boris"] = true,
		["Bugbear Invasion"] = true,
		["Zombie Slayer"] = true,
		["Avatar of Jarlsberg"] = true,
		["KOLHS"] = true,
		["Avatar of Sneaky Pete"] = true,
		["Heavy Rains"] = true,
		["Actually Ed the Undying"] = true,
	}
	return not paths_without_wand[ascensionpathname()]
end

add_automator("/campground.php", function()
	if session["zone.lair.gates"] then return end
	if text:contains("peer into the eyepiece of the telescope") or (text:contains("Nope.") and params.action == "telescopelow") then
		if level() >= 13 then
			get_page("/lair1.php", { action = "gates" })
		end
	end
end)

add_printer("/campground.php", function()
	if text:contains("peer into the eyepiece of the telescope") or (text:contains("Nope.") and params.action == "telescopelow") then
		-- telescope lair info

		local function get_gates_display_lines()
			local function mkline(gate)
				if not gate then
					return [[<span style="color: darkorange">(Unknown)</span>]]
				end
				local gatedata = lair_gateitems[gate]
				if gatedata then
					return string.format([[%s: %s]], gate, gate_status_display(gate, gatedata))
				else
					return [[<span style="color: red">{ Unknown gate type: ]] .. gate .. [[ }</span>]]
				end
			end

			local gate_items = get_lair_gate_items()
			local gate_lines = {}
			table.insert(gate_lines, mkline(gate_items[1]))
			table.insert(gate_lines, mkline(gate_items[2]))
			table.insert(gate_lines, mkline(gate_items[3]))
			return gate_lines
		end

		local dod_gate_effects = {
			"acuity",
			"blessing",
			"detection",
			"strength",
			"teleportation",
		}
		local function get_dod_display_lines()
			local tbl, unknown_potions, unknown_effects = get_dod_potion_status()
			local unknowndata = {}
			for x in table.values(unknown_potions) do
				table.insert(unknowndata, x .. " (" .. count_item(x) .. ")")
			end
			local dodpotstatus = {}
			local function handle_eff(eff, overridecolor)
				local color = "darkorange"
				for a, b in pairs(tbl) do
					if b == eff then
						if have_item(a) then
							color = "green"
						end
						return [[<span style="color: ]] .. (overridecolor or color) .. [[">]] .. string.format("%s = %s", eff, a) .. [[</span>]]
					end
				end
				return [[<span style="color: ]] .. (overridecolor or color) .. [[">]] .. string.format("%s = ?", eff) .. [[</span>]]
			end
			local want_type = nil
			local gatestatus = get_lair_gate_items()
			if gatestatus[3] and lair_gateitems[gatestatus[3]] then
				want_type = lair_gateitems[gatestatus[3]].potion
			end
			for eff in table.values(dod_gate_effects) do
				local overridecolor = nil
				if want_type and want_type ~= eff then
					overridecolor = "gray"
				end
				table.insert(dodpotstatus, handle_eff(eff, overridecolor))
			end
			for eff in table.values(dod_potion_effects) do
				local skip = false
				for x in table.values(dod_gate_effects) do
					if eff == x then
						skip = true
					end
				end
				if not skip then
					table.insert(dodpotstatus, handle_eff(eff, "gray"))
				end
			end
			if next(unknown_potions) then
				table.insert(dodpotstatus, string.format("<br>Unknown potions: %s", table.concat(unknowndata, " / ")))
			end
			return dodpotstatus
		end

		local function get_statues_display_lines()
			local statueslines = {}
			local want_items = {
				"Boris's key", "Jarlsberg's key", "Sneaky Pete's key",
				"digital key",
				"Richard's star key",
				"skeleton key",
			}
			local function check_key(x)
				if x == "Boris's key" or x == "Jarlsberg's key" or x == "Sneaky Pete's key" or x == "skeleton key" then
					if have_item(x) then
						return string.format([[<span style="color: green">%s</span>]], x)
					else
						return string.format([[<span style="color: darkorange">%s</span>]], x)
					end
				elseif x == "digital key" then
					local pixels = count_item("white pixel") + math.min(count_item("red pixel"), count_item("green pixel"), count_item("blue pixel"))
					if have_item(x) then
						return string.format([[<span style="color: green">%s</span>]], x)
					elseif pixels >= 30 then
						return string.format([[<span style="color: green">%s</span> (%d pixels)]], x, pixels)
					else
						return string.format([[<span style="color: darkorange">%s</span> (%d / 30 pixels)]], x, pixels)
					end
				elseif x == "Richard's star key" then
					local have_star_weapon = have_item("star sword") or have_item("star staff") or have_item("star crossbow")
					local extrastrs = {}
					local wantstaritems = { "star hat", "star sword", "star staff", "star crossbow" }
					if ascensionpath("Bees Hate You") or ascensionpath("Avatar of Boris") then
						wantstaritems = { "star hat" }
						have_star_weapon = true
					end
					local have_star_everything = have_item("Richard's star key") and have_item("star hat") and have_star_weapon
					for y in table.values(wantstaritems) do
						if have_item(y) then
							table.insert(extrastrs, string.format([[<span style="color: green">%s</span>]], y))
						elseif y == "star hat" or not have_star_weapon then
							table.insert(extrastrs, string.format([[<span style="color: darkorange">%s</span>]], y))
						end
					end
					if not have_star_everything then
						table.insert(extrastrs, make_plural(count_item("star"), "star", "stars"))
						table.insert(extrastrs, make_plural(count_item("line"), "line", "lines"))
						table.insert(extrastrs, make_plural(count_item("star chart"), "chart", "charts"))
					end
					if have_item(x) then
						return string.format([[<span style="color: green">%s</span> (%s)]], x, table.concat(extrastrs, ", "))
					else
						return string.format([[<span style="color: darkorange">%s</span> (%s)]], x, table.concat(extrastrs, ", "))
					end
				end
			end
			for x in table.values(want_items) do
				table.insert(statueslines, check_key(x))
			end
			return statueslines
		end

-- TODO: make-able bone rattle and tambourine

		local function get_other_display_lines()
			local otherlines = {}
			local guitar_items = {
				"4-dimensional guitar",
				"acoustic guitarrr",
				"Crimbo ukulele",
				"Disco Banjo",
				"dueling banjo",
				"half-sized guitar",
				"heavy metal thunderrr guitarrr",
				"massive sitar",
				"out-of-tune biwa",
				"plastic guitar",
				"Seeger's Unstoppable Banjo",
				"Shagadelic Disco Banjo",
				"stone banjo",
				"Zim Merman's guitar",
			}
			local accordion_items = {
				"calavera concertina",
				"stolen accordion",
				"Rock and Roll Legend",
				"Squeezebox of the Ages",
				"The Trickster's Trikitixa",
				"toy accordion",
				"antique accordion",
			}
			local drum_items = {
				"big bass drum",
				"black kettle drum",
				"bone rattle",
				"hippy bongo",
				"jungle drum",
				"tambourine",
			}
			local function check_items(list)
				for _, x in ipairs(list) do
					if have_item(x) then
						return string.format([[<span style="color: green">%s</span>]], x)
					end
				end
				return string.format([[<span style="color: darkorange">%s</span>]], table.concat(list, ", "))
			end
			local function check_wand()
				if have_item("Wand of Nagamar") then
					table.insert(otherlines, check_items { "Wand of Nagamar" })
					return true
				end
				local parts = {}
				if have_item("WA") then
					table.insert(parts, "WA")
				else
					table.insert(parts, "ruby W")
					table.insert(parts, "metallic A")
				end
				if have_item("ND") then
					table.insert(parts, "ND")
				else
					table.insert(parts, "lowercase N")
					table.insert(parts, "heavy D")
				end
				local missing = false
				local strtbl = {}
				for _, x in ipairs(parts) do
					if have_item(x) then
						table.insert(strtbl, string.format([[<span style="color: green">%s</span>]], x))
					else
						table.insert(strtbl, string.format([[<span style="color: darkorange">%s</span>]], x))
						missing = true
					end
				end
				table.insert(otherlines, string.format([[<span style="color: darkorange">Wand of Nagamar</span> (%s)]], table.concat(strtbl, " + ")))
			end
			table.insert(otherlines, check_items(guitar_items))
			table.insert(otherlines, check_items(accordion_items))
			table.insert(otherlines, check_items(drum_items))
			if requires_wand_of_nagamar() then
				check_wand()
			elseif ascensionpath("Bees Hate You") then
				table.insert(otherlines, check_items { "antique hand mirror" })
			end
			return otherlines
		end

		local extratext = {}
		if not ascensionpath("Bees Hate You") then
			table.insert(extratext, [[<h4>Lair gates</h4>]] .. table.concat(get_gates_display_lines(), "<br>") .. [[</p>]])
			table.insert(extratext, [[<h4>Dungeons of Doom potions</h4><p>]] .. table.concat(get_dod_display_lines(), "<br>") .. [[</p>]])
		end
		table.insert(extratext, [[<h4>Mariachi statue keys</h4><p>]] .. table.concat(get_statues_display_lines(), "<br>") .. [[</p>]])
		table.insert(extratext, [[<h4>Other items</h4><p>]] .. table.concat(get_other_display_lines(), "<br>") .. [[</p>]])

		text = add_message_to_page(text, table.concat(extratext, "\n"), "Lair Checklist:", color)
	end
end)

add_processor("/lair1.php", function()
	local whereidx = {}
	local gates = {}
	for a, b in pairs(lair_gateitems) do
		local where = text:find(a)
		if where then
			whereidx[a] = where
			table.insert(gates, a)
		end
	end

	table.sort(gates, function(a, b) return whereidx[a] < whereidx[b] end)

	if next(gates) then
		session["zone.lair.gates"] = gates
	end
end)

function gate_status_display(from, to)
	local dod_reverse = {}
	for a, b in pairs(get_dod_potion_status()) do
		dod_reverse[b] = a
	end

	local effect_status = "(???)"
	local effect_link = nil
	if have_buff(to.effect) then
		effect_status = [[(<span style="color: gray;">have ]]..to.effect..[[</span>)]]
	elseif to.effect == "Teleportitis" and have_item("ring of teleportation") then
		if have_equipped_item("ring of teleportation") then
			effect_status = [[(<span style="color: gray;">have ]]..to.effect..[[</span>)]]
		else
			effect_status = [[(wear ring for <span style="color: green;">(]]..to.effect..[[)</span>)]]
		end
	elseif to.effect == "Sugar Rush" then
		local have_usable, have_any = get_sugar_rush_item()
		if have_usable then
			effect_status = [[(<span style="color: green">use ]]..have_usable.." ("..to.effect..")".. [[</span>)]]
			effect_link = [[(<span class="kolproxy_gate_item_spoiler">use <a href="#" onclick="use_item(this, ]]..get_itemid(have_usable)..[[, &quot;]] .. to.effect .. [[&quot;); return false;" style="color: green;">]]..have_usable..[[</a>]] .." ("..to.effect..")".. [[</span>)]]
		elseif have_any then
			effect_status = [[(get <span style="color: green;">(]]..to.effect..[[)</span>)]]
		else
			effect_status = [[<b>(need <span style="color: darkorange;">(]]..to.effect..[[)</span>)</b>]]
		end
	elseif to.item or (to.potion and dod_reverse[to.potion]) then
		local name = to.item or dod_reverse[to.potion]
		if have_item(name) then
			effect_status = [[(<span style="color: green;">use ]]..name .." ("..to.effect..")".. [[</span>)]]
			effect_link = [[(<span class="kolproxy_gate_item_spoiler">use <a href="#" onclick="use_item(this, ]]..get_itemid(name)..[[, &quot;]] .. to.effect .. [[&quot;); return false;" style="color: green;">]]..name..[[</a>]] .." ("..to.effect..")".. [[</span>)]]
		elseif to.gnomish_buyable and moonsign_area() == "Gnomish Gnomad Camp" then
			effect_status = [[<b>(buy <span>]]..name..[[</span>]].." ("..to.effect..")"..[[)</b>]]
		else
			effect_status = [[<b>(need <span style="color: darkorange;">]]..name..[[</span>]].." ("..to.effect..")"..[[)</b>]]
		end
	else
		effect_status = [[<b>(need <span style="color: darkorange;">(]]..to.effect..[[)</span>)</b>]]
	end
	return effect_status, effect_link
end

add_printer("/lair1.php", function()
	local need = {}
	text = text:gsub([[</head>]], [[<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
<script type="text/javascript">
	function use_item_result(link, pagetext, effectname) {
		var newtext = '<span style="color: gray;">have ' + effectname + '</span>'
		if (pagetext.match(/You acquire an effect:/)) {
			$(link).parents(".kolproxy_gate_item_spoiler").html(newtext)
		} else {
			link.style.color = 'red';
		}
	}
	function use_item(link, itemid, effectname) {
		$.ajax({ type:'GET', url:'/inv_use.php', cache:false, data:{ pwd:"]] .. session.pwd .. [[", whichitem:itemid, ajax:1 }, global:false, success: function(retdata) { use_item_result(link, retdata, effectname); } });
	}
</script>
%0]])
	for from, to in pairs(lair_gateitems) do
		if text:contains("<p>&quot;Through the "..from) then
			local effect_status, effect_link = gate_status_display(from, to)
			text = text:gsub("(<p>&quot;Through the "..from..".-&quot;)( <p>)", "%1 " .. (effect_link or effect_status) .. "%2")
			table.insert(need, to)
		end
	end
end)

local function show_tower_items(levelidxs)
	local tower_items = get_lair_tower_monster_items()
	for _, level in ipairs(levelidxs) do
		local needitem = tower_items[level]
		if needitem then
			local color = have_item(needitem) and "green" or "orange"
			local leveltext = [[<span style="color: ]] .. color .. [[">{ ]] .. needitem .. [[ }</span>]]
			text = text:gsub([[<img src="http://images.kingdomofloathing.com/otherimages/lair/tower]] .. level, function(imgtag)
				return [[<div style="position: relative;"><div style="position: absolute; left: -205px; top: 35px; width: 200px; height: 100px; text-align: right;">]] .. leveltext .. [[</div></div>]] .. imgtag
			end)
		end
	end
end

add_printer("/lair4.php", function()
	show_tower_items { 1, 2, 3 }
end)

add_printer("/lair5.php", function()
	show_tower_items { 4, 5, 6 }
end)

local function missing_tower_item()
end

add_warning {
	message = "You might want to remove +Monster Level modifiers before killing tower monsters.",
	path = { "/lair4.php", "/lair5.php" },
	type = "extra",
	when = "ascension",
	check = function()
		return params.action and missing_tower_item() and estimate_bonus("Monster Level") > 0
	end,
}

add_warning {
	message = "You might want to buff up with Elron's Explosive Etude before killing tower monsters.",
	path = { "/lair4.php", "/lair5.php" },
	type = "extra",
	when = "ascension",
	check = function()
		return params.action and missing_tower_item() and not have_buff("Elron's Explosive Etude") and playerclass("Accordion Thief") and level() >= 15 and have_skill("Elron's Explosive Etude")
	end,
}

add_always_warning("/lair6.php", function()
	if tonumber(params.place) == 5 and not have_item("Wand of Nagamar") and requires_wand_of_nagamar() then
		return "A Wand of Nagamar is recommended for the sorceress fight.", "sorceress-wand-of-nagamar"
	end
end)

add_always_warning("/lair6.php", function()
	if tonumber(params.place) == 5 and ascensionpath("Bees Hate You") and not have_item("antique hand mirror") then
		return "An antique hand mirror is recommended for the guy made of bees fight.", "bees-hate-you-antique-hand-mirror"
	end
end)

add_always_warning("/lair6.php", function()
	if tonumber(params.place) == 6 and ascensionpath("Avatar of Boris") and fullness() < estimate_max_fullness() then
		return "You might want to eat up to fill your remaining stomach space before you free the king and lose the extra capacity.", "break prism in aob with spare stomach"
	end
	if tonumber(params.place) == 6 and ascensionpath("Avatar of Sneaky Pete") and drunkenness() < estimate_max_safe_drunkenness() then
		return "You might want to drink up to fill your remaining liver space before you free the king and lose the extra capacity.", "break prism in aosp with spare liver"
	end
	if tonumber(params.place) == 6 and ascensionpath("Heavy Rains") then
		if (heavyrains_thunder() or 0) >= 20 or (heavyrains_rain() or 0) >= 10 or (heavyrains_lightning() or 0) >= 10 then
			return "You might want to use up your Heavy Rains resources before you free the king and lose them.", "break prism in hr with spare resources"
		end
	end
end)

add_printer("/lair6.php", function()
	local nextplace = tonumber(text:match([[<a href="lair6.php%?place=([0-9])">]]))
	if nextplace == nil then return end
-- 	print("nextplace", nextplace)
	local placedescs = {
		"Pass the heavy and light door riddle",
		"Avoid the electrical attack",
		"Defeat your own shadow (use healing items)",
		"Beat the first familiar (requires 20+ lbs. familiar)",
		"Beat the second familiar (requires 20+ lbs. familiar)",
		"Defeat The Naughty Sorceress (requires Wand of Nagamar)",
		"Free the king",
	}
	if ascensionpath("Bees Hate You") then
		placedescs[6] = "Defeat The Naughty Sorceress and The Guy Made Of Bees (requires antique hand mirror)"
	elseif ascensionpath("Avatar of Boris") then
		placedescs[6] = "Defeat The Naughty Sorceress and The Avatar of Sneaky Pete"
	elseif ascensionpath("Zombie Slayer") then
		placedescs[6] = "Defeat The Naughty Sorceress and Rene C. Corman"
	elseif ascensionpath("Avatar of Jarlsberg") then
		placedescs[4] = "Defeat Clancy"
		placedescs[5] = "(skipped)"
		placedescs[6] = "Defeat The Avatar of Boris"
	elseif ascensionpath("KOLHS") then
		placedescs[6] = "Defeat Principal Mooney"
	elseif ascensionpath("Avatar of Sneaky Pete") then
		placedescs[6] = "Defeat The Naughty Sorceress and The Avatar of Jarlsberg"
	elseif ascensionpath("Heavy Rains") then
		placedescs[6] = "Defeat The Rain King"
	end
	placedescs[4] = "(skipped)"
	placedescs[5] = "(skipped)"
	local status = "<b>Chamber progress</b><br>"
	for x, y in ipairs(placedescs) do
		if y == "(skipped)" then
		elseif nextplace >= x then
			status = status .. [[<span style="color: gray;">]] .. y .. [[</span><br>]]
		elseif nextplace == x - 1 then
			status = status .. [[&rarr; <span style="color: darkgreen;">]] .. y .. [[</span> &larr;<br>]]
		else
			status = status .. y .. [[<br>]]
		end
	end
	text = text:gsub([[</body>]], [[<center>]] .. status .. [[</center>%0]])
end)
