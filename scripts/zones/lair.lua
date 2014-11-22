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
	return not ascensionpath("Bees Hate You") and not ascensionpath("Avatar of Boris") and not ascensionpath("Bugbear Invasion") and not ascensionpath("Zombie Slayer") and not ascensionpath("Avatar of Jarlsberg") and not ascensionpath("KOLHS") and not ascensionpath("Avatar of Sneaky Pete") and not ascensionpath("Heavy Rains")
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

add_automator("/lair1.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if params.action == "mirror" and text:contains("You try to break it") then
		local eq = equipment()
		set_equipment {}
		text, url = get_page(path, params)
		set_equipment(eq)
	elseif params.action == "gates" and text:contains("cave1mirror.gif") then
		local eq = equipment()
		set_equipment {}
		text, url = get_page("/lair1.php", { action = "mirror" })
		set_equipment(eq)
	end
end)

add_printer("/lair2.php", function()
	if text:contains([[value="sorcriddle]]) then
		text = text:gsub([[(<input type=hidden name=prepreaction value="sorcriddle1">What am I%? <input name=answer class=text type=text size=10)(>)]], [[%1 value="fish"%2]])
		text = text:gsub([[(<input type=hidden name=prepreaction value="sorcriddle2">Who are we%? <input name=answer class=text type=text size=10)(>)]], [[%1 value="phish"%2]])
		text = text:gsub([[(<input type=hidden name=prepreaction value="sorcriddle3">What am I%? <input name=answer class=text type=text size=10)(>)]], [[%1 value="fsh"%2]])
	end
	if text:contains([[<input type=hidden name=prepreaction value="sequence">First:]]) then
		local choices = { seq1 = "Up", seq2 = "Up", seq3 = "Down", seq4 = "Down", seq5 = "Left", seq6 = "Right", seq7 = "Left", seq8 = "Right", seq9 = "B", seq10 = "A" }
		for a, b in pairs(choices) do
			text = text:gsub([[(<select name=]]..a..[[>.-<option value=".-")(>]]..b..[[</option>.-</select>)]], [[%1 selected="selected"%2]])
		end
	end
end)

function automate_smithing_stone_banjo()
	if have_item("stone banjo") then
		return make_kol_html_frame("Error: Already have stone banjo.", "Automation results:", "darkorange")
	end

	if not have_item("big rock") then
		if have_buff("Teleportitis") or have_equipped_item("ring of teleportation") then
			return make_kol_html_frame("Error: Cannot pick up big rock while under the effect of teleportitis.", "Automation results:", "darkorange")
		end
		if not have_item("ten-leaf clover") then
			use_item("disassembled clover")
		end
		if have_item("ten-leaf clover") then
			if not have_item("casino pass") then
				store_buy_item("casino pass", "m")
			end
			get_page("/casino.php", { action = "slot", whichslot = 11 })
		end
	end
	if not have_item("big rock") then
		return make_kol_html_frame("Error: Failed to pick up big rock.", "Automation results:", "darkorange")
	end

	if not have_item("banjo strings") then
		local script = get_automation_scripts()
		script.ensure_worthless_item()
		post_page("/hermit.php", { action = "trade", whichitem = get_itemid("banjo strings"), quantity = 1 })
	end

	return smith_items("banjo strings", "big rock")()
end

local smith_stone_banjo_href = add_automation_script("smith-stone-banjo", automate_smithing_stone_banjo)

function automate_lair_statues(text)
	local missing_stuff = {}
	if text:contains("sit motionless") then
		local scuba_keys = {
			{ prepreaction = "sorcriddle1", answer = "fish", key = "Boris's key", have_item = function() return have_item("fishbowl") or have_item("hosed fishbowl") end },
			{ prepreaction = "sorcriddle2", answer = "phish", key = "Jarlsberg's key", have_item = function() return have_item("fishtank") or have_item("hosed tank") end },
			{ prepreaction = "sorcriddle3", answer = "fsh", key = "Sneaky Pete's key", have_item = function() return have_item("fish hose") or have_item("hosed tank") or have_item("hosed fishbowl") end },
		}
		local missing_scuba_keys = {}
		for _, x in ipairs(scuba_keys) do
			if x.have_item() then
			elseif have_item(x.key) then
				print("using", x.key)
				post_page("/lair2.php", { prepreaction = x.prepreaction, answer = x.answer })
			else
				table.insert(missing_scuba_keys, x.key)
			end
		end
		if not have_item("makeshift SCUBA gear") then
			meatpaste_items("fish hose", "fishbowl")
			meatpaste_items("hosed fishbowl", "fishtank")
		end
		if have_item("makeshift SCUBA gear") then
			local eq = equipment()
			equip_item("makeshift SCUBA gear", 3)
			get_page("/lair2.php", { action = "odor" })
			set_equipment(eq)
			text, url = get_page("/lair2.php", { action = "statues" })
		else
			if next(missing_scuba_keys) then
				local count_key_and_item = 0
				for _, x in ipairs(scuba_keys) do
					if have_item(x.key) and x.have_item() then
						count_key_and_item = count_key_and_item + 1
					end
				end
				local show_wand_link = nil
-- 					print("key+item count", count_key_and_item)
				local zapping_is_safe = nil
				if count_key_and_item == 2 then
					local wand_data = get_wand_data()
					if wand_data then
						show_wand_link = wand_data.name
						zapping_is_safe = (wand_data.heat == 0)
					end
				end
				if show_wand_link then
					if zapping_is_safe then
						table.insert(missing_stuff, "makeshift SCUBA gear (" .. table.concat(missing_scuba_keys, ", ") .. [[) <a href="wand.php?whichwand=]]..get_itemid(show_wand_link)..[[" style="color:green">[zap]</a>]])
					else
						table.insert(missing_stuff, "makeshift SCUBA gear (" .. table.concat(missing_scuba_keys, ", ") .. [[) <a href="wand.php?whichwand=]]..get_itemid(show_wand_link)..[[" style="color:darkorange">[wand can blow up when zapping]</a>]])
					end
				else
					table.insert(missing_stuff, "makeshift SCUBA gear (" .. table.concat(missing_scuba_keys, ", ") .. ")")
				end
			else
				table.insert(missing_stuff, "makeshift SCUBA gear")
			end
		end
		text, url = get_page("/lair2.php", { action = "statues" })
	end

	if text:contains("You gather up your instruments") or text:contains("no reason to mess with them anymore") then
		return
	end

	if not have_item("stone tablet (Squeezings of Woe)") then
		local pixels = count_item("white pixel") + math.min(count_item("red pixel"), count_item("green pixel"), count_item("blue pixel"))
		if not have_item("digital key") and setting_enabled("automate simple tasks") and pixels >= 30 then
			if count_item("white pixel") < 30 then
				local to_make = 30 - count_item("white pixel")
				shop_buy_item({ ["white pixel"] = to_make }, "mystic")
			end
			shop_buy_item("digital key", "mystic")
		end
		if have_item("digital key") then
			async_post_page("/lair2.php", { prepreaction = "sequence", seq1= "up", seq2 = "up", seq3 = "down", seq4 = "down", seq5 = "left", seq6 = "right", seq7 = "left", seq8 = "right", seq9 = "b", seq10 = "a" })
		else
			table.insert(missing_stuff, "digital key")
		end
	end

	if not have_item("stone tablet (Sinister Strumming)") then
		if not have_item("Richard's star key") then
			buy_item("Richard's star key")()
		end
		if have_item("Richard's star key") then
			local eq = equipment()
			local fam = familiarid()
			switch_familiar("Star Starfish")
			equip_item("star sword")
			equip_item("star staff")
			equip_item("star crossbow")
			equip_item("star hat")
			async_post_page("/lair2.php", { prepreaction = "starcage" })
			switch_familiarid(fam)
			set_equipment(eq)
		else
			table.insert(missing_stuff, "Richard's star key")
		end
		if not have_item("stone tablet (Sinister Strumming)") then
			table.insert(missing_stuff, "stone tablet (Sinister Strumming) [star outfit]")
		end
	end

	if not have_item("stone tablet (Really Evil Rhythm)") then
		if have_item("skeleton key") then
			table.insert(missing_stuff, "complete skeleton game")
		else
			table.insert(missing_stuff, "skeleton key")
		end
	end

	text, url = get_page("/lair2.php", { action = "statues" })
	if text:contains("You gather up your instruments") or text:contains("no reason to mess with them anymore") then
		return
	end

	if text:contains("no instrument to give to the first") then
		if have_item("ten-leaf clover") or have_item("disassembled clover") or have_item("big rock") then
			table.insert(missing_stuff, string.format([[a guitar <span style="color: green">(smith a stone banjo)</span> <a href="%s" style="color: green">{ automate (1) }</a>]], smith_stone_banjo_href { pwd = session.pwd }))
		else
			table.insert(missing_stuff, "a guitar")
		end
	end
	if text:contains("no instrument to give to the second") then
		table.insert(missing_stuff, [[an accordion <span style="color:green">(use chewing gum on a string)</span>]])
	end
	if text:contains("no instrument to give to the third") then
		table.insert(missing_stuff, "a drum")
	end

	text, url = get_page("/lair2.php", { action = "statues" })
	if text:contains("You gather up your instruments") or text:contains("no reason to mess with them anymore") then
		return
	end

	return missing_stuff
end

local automate_statues_href = add_automation_script("automate-lair-statues", function()
	text, url = get_page("/lair2.php", { action = "statues" })
	local missing_stuff = automate_lair_statues(text)

	text, url = get_page("/lair2.php", { action = "statues" })
	if missing_stuff then
		local missingtext = ""
		for _, x in ipairs(missing_stuff) do
			missingtext = missingtext .. [[<li style="color: darkorange">]] .. x .. "</li>"
		end
		text = text:gsub("</td></tr></table>", [[<p style="color: darkorange">Missing:<ul>]] .. missingtext .. "</ul></p>%0", 1)
	end
	return text, url
end)

add_printer("/lair2.php", function()
	text = text:gsub([[</body>]], [[<center><a href="]] .. automate_statues_href { pwd = session.pwd } .. [[" style="color: green;">{ Automate the statues. }</a></center>%0]])
end)

function solve_hedge_maze_puzzle()
	-- 1 2 3
	-- 4 5 6
	-- 7 8 9
	local pt = get_page("/hedgepuzzle.php")
	local tile_data = {}
	local enter_tile = nil
	local enter_dir = nil
	local exit_tile = nil
	local exit_dir = nil
	local whereid_tbl = {
		["Upper-Left Tile"] = 1,
		["Upper-Middle Tile"] = 2,
		["Upper-Right Tile"] = 3,
		["Middle-Left Tile"] = 4,
		["Center Tile"] = 5,
		["Middle-Right Tile"] = 6,
		["Lower-Left Tile"] = 7,
		["Lower-Middle Tile"] = 8,
		["Lower-Right Tile"] = 9,
	}
	local dir_chars = { north = "N", west = "W", east = "E", south = "S" }
	do
		local enterwhere, enterwhat = pt:match("The entrance to this hedge maze is accessible when the (.-) can exit (.-)%.")
		enter_tile = whereid_tbl[enterwhere]
		enter_dir = dir_chars[enterwhat]
		local exitwhere, exitwhat = pt:match("The exit of the hedge maze is accessible when the (.-) can exit (.-)%.")
		exit_tile = whereid_tbl[exitwhere]
		exit_dir = dir_chars[exitwhat]
	end
	for x in pt:gmatch([[<img alt="(.-)"]]) do
		local where, what = x:match("^(.-): (.-)%.")
		local whereid = whereid_tbl[where]
		if what:contains("90 degree bend") then
			local exit1, exit2 = what:match("([a-z]+) and ([a-z]+)")
			tile_data[whereid] = dir_chars[exit1] .. dir_chars[exit2]
		elseif what:contains("Straight") then
			local exit1, exit2 = what:match("([a-z]+)/([a-z]+)")
			tile_data[whereid] = dir_chars[exit1] .. dir_chars[exit2]
		elseif what:contains("Dead end") then
			local exit1 = what:match("to the ([a-z]+)")
			tile_data[whereid] = dir_chars[exit1]
		end
-- 		print(x, where, what)
-- 		print(" => ", whereid, tile_data[whereid])
	end

	if enter_tile and enter_dir and exit_tile and exit_dir then
	else
		error "Error determining entrance/exit for hedge maze puzzle"
	end
	for i = 1, 9 do
		if not tile_data[i] then
			error "Error determining maze layout for hedge maze puzzle"
		end
	end

	local q = {}
	local function turned_tile_dirs(dirs, times)
		local newdirs = ""
		local turnit = { N = "E", E = "S", S = "W", W = "N" }
		for x = 1, dirs:len() do
			local d = dirs:sub(x, x)
			for i = 1, times do
				d = turnit[d]
			end
			newdirs = newdirs .. d
		end
		return newdirs
	end
	local turns = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	local move_targets = {
		[1] = { N = nil, E = 2, S = 4, W = nil },
		[2] = { N = nil, E = 3, S = 5, W = 1 },
		[3] = { N = nil, E = nil, S = 6, W = 2 },
		[4] = { N = 1, E = 5, S = 7, W = nil },
		[5] = { N = 2, E = 6, S = 8, W = 4 },
		[6] = { N = 3, E = nil, S = 9, W = 5 },
		[7] = { N = 4, E = 8, S = nil, W = nil },
		[8] = { N = 5, E = 9, S = nil, W = 7 },
		[9] = { N = 6, E = nil, S = nil, W = 8 },
	}
	local locked = { false, false, false, false, false, false, false, false, false }
	local move_stack = {}
	local winner = {}
	local best_winner = 1000000
	local function add_for(tile, from, have_key)
		local prevturns = turns[tile]
		for i = 0, 3 do
			if locked[tile] == false or i == 0 then
				turns[tile] = prevturns + i
				local newdirs = turned_tile_dirs(tile_data[tile], turns[tile])
				if newdirs:contains(from) and newdirs:len() == 2 then
					local leave_dir = newdirs:gsub(from, "")
					local to_tile = move_targets[tile][leave_dir]
					local enter_dir = turned_tile_dirs(leave_dir, 2)
					if to_tile then
-- 						print(i, newdirs, "adding", to_tile, enter_dir, table_to_str(turns))
						locked[tile] = true
						table.insert(move_stack, { what = "turn", tile = tile, times = i })
						add_for(to_tile, enter_dir, have_key)
						table.remove(move_stack)
						locked[tile] = false
					elseif leave_dir == exit_dir and tile == exit_tile and have_key == true then
						table.insert(move_stack, { what = "turn", tile = tile, times = i })
						table.insert(move_stack, { what = "unlock door" })
-- 						print(i, newdirs, "winning", tile, from, table_to_str(turns))
						local solution = {}
						local cost = 0
						for a, b in pairs(move_stack) do
							solution[a] = b
							if b.what == "turn" then
								cost = cost + b.times
-- 								print("cost += ", b.times)
							end
						end
-- 						print("directions to winning in " .. cost .. ":", table_to_str(solution))
						if cost < best_winner then
							winner = solution
							best_winner = cost
						end
						table.remove(move_stack)
						table.remove(move_stack)
					end
				elseif newdirs:contains(from) and newdirs:len() == 1 and have_key == false then
-- 					print(i, newdirs, "keying", tile, from, table_to_str(turns))
					local prev_locked = locked
					locked = { false, false, false, false, false, false, false, false, false }
					table.insert(move_stack, { what = "turn", tile = tile, times = i })
					table.insert(move_stack, { what = "pick up key" })
					add_for(enter_tile, enter_dir, true)
					table.remove(move_stack)
					table.remove(move_stack)
					locked = prev_locked
				end
			end
		end
		turns[tile] = prevturns
	end
	add_for(enter_tile, enter_dir, have_item("hedge maze key"))
-- 	print("directions to win in " .. tostring(best_winner) .. ":", table_to_str(winner))
	local function perform_winning_solution(winner)
		for _, x in ipairs(winner) do
			if x.what == "turn" and x.times == 0 then
			else
				if x.what == "turn" and x.times > 0 then
-- 					/hedgepuzzle.php [("action","2")]
					print("turning hedge maze tile:", x.tile)
					post_page("/hedgepuzzle.php", { action = x.tile })
					return true, x
				else
					print("do in hedge maze:", tostring(x))
					return false, x
				end
			end
		end
	end
	if best_winner <= 10 then
		local turned, x = perform_winning_solution(winner)
		if turned and have_item("hedge maze puzzle") then
			return solve_hedge_maze_puzzle()
		else
			if not have_item("hedge maze puzzle") then
				session["hedge maze result"] = string.format("Automated, %s left.", make_plural(best_winner, "tile turn", "tile turn"))
			else
				session["hedge maze result"] = string.format("Automated, next step: %s.", x.what)
			end
		end
	end
end

-- TODO: decorate key drop, redo this functionality

add_automator("/fight.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if text:contains("WINWINWIN") or text:contains("state['fightover'] = true;") or text:contains([[<a href="lair3.php">Go back to the Sorceress' Hedge Maze</a>]]) then
		-- TODO: would prefer a perfect trigger after fights
		if text:contains("topiary golem") and have_item("hedge maze puzzle") then
			-- Only trigger vs topiary golems, since the hedge maze puzzle doesn't go away when you're through the maze, unless you keep turning it until it's stolen.
			-- TODO?: Use it until it goes away when you're done?
			session["hedge maze result"] = nil
			solve_hedge_maze_puzzle()
		end
	end
end)

add_itemdrop_counter("hedge maze puzzle", function(c)
	-- TODO: This is really not a counter. Do in automator.
	local result = session["hedge maze result"]
	if result then
		return "{ " .. result .. " }"
	end
end)

add_automator("/lair3.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if text:contains("You see a key lying") then
		if have_item("hedge maze key") then
			session["hedge maze result"] = nil
			solve_hedge_maze_puzzle()
		end
	end
end)

add_printer("/lair3.php", function()
	local result = session["hedge maze result"]
	if result then
		text = text:gsub([[<center><table class="item" style="float: none" rel="[^"]*"><tr><td><img src="http://images.kingdomofloathing.com/itemimages/[^"]+.gif" alt="[^"]*" title="[^"]*" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire .-</td></tr></table></center>]], function(droptext)
			return droptext .. [[<center style="color: green">{ ]] .. result .. [[ }</center>]]
		end)
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

add_processor("/fight.php", function()
	if not monstername() then return end

	local page_offset = ({ ["/lair4.php"] = 0, ["/lair5.php"] = 3 })[requestpath]
	local level_offset = ({ level1 = 1, level2 = 2, level3 = 3 })[params.action]

	if page_offset and level_offset then
		local level = page_offset + level_offset
		if not get_lair_tower_monster_items()[level] then
			local tbl = ascension["zone.lair.tower monsters"] or {}
			tbl["level" .. level] = monstername()
			ascension["zone.lair.tower monsters"] = tbl
		end
	end
end)

local function missing_tower_item()
	local where1, where2
	if requestpath == "/lair4.php" then
		where1 = 0
	elseif requestpath == "/lair5.php" then
		where1 = 3
	end
	where2 = tonumber((params.action or ""):match("^level([0-9]+)$"))
	if where1 and where2 then
		local level = where1 + where2
		local tower_items = get_lair_tower_monster_items()
		if tower_items[level] then
			return not have_item(tower_items[level])
		end
	end
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
	message = "You might want to buff up with Frigidalmatian before killing tower monsters.",
	path = { "/lair4.php", "/lair5.php" },
	type = "extra",
	when = "ascension",
	check = function()
		return params.action and missing_tower_item() and not have_buff("Frigidalmatian") and have_skill("Frigidalmatian")
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

add_automator("/fight.php", function()
	local function known_win(level)
		local tower_items = get_lair_tower_monster_items()
		local needitem = tower_items[level]
		return needitem and have_item(needitem)
	end
	if text:contains([[<a href="lair4.php">Go back to the Sorceress' Tower</a>]]) and text:contains("WINWINWIN") then
		local lair4pt = get_page("/lair4.php")
		if lair4pt:contains([[value="level1"]]) and known_win(1) then
			print("goto lair4:level1")
			text = text:gsub([[<center><a href="lair4.php">Go back to the Sorceress' Tower</a></center>]], [[<p><a href="lair4.php?action=level1" style="color: green">{ Climb to the next floor (Level 1) }</a>%0]])
		elseif lair4pt:contains([[value="level2"]]) and known_win(2) then
			print("goto lair4:level2")
			text = text:gsub([[<center><a href="lair4.php">Go back to the Sorceress' Tower</a></center>]], [[<p><a href="lair4.php?action=level2" style="color: green">{ Climb to the next floor (Level 2) }</a>%0]])
		elseif lair4pt:contains([[value="level3"]]) and known_win(3) then
			print("goto lair4:level3")
			text = text:gsub([[<center><a href="lair4.php">Go back to the Sorceress' Tower</a></center>]], [[<p><a href="lair4.php?action=level3" style="color: green">{ Climb to the next floor (Level 3) }</a>%0]])
		else
			local lair5pt = get_page("/lair5.php")
			if lair5pt:contains([[value="level1"]])  and known_win(4) then
				print("goto lair5:level1")
				text = text:gsub([[<center><a href="lair4.php">Go back to the Sorceress' Tower</a></center>]], [[<p><a href="lair5.php?action=level1" style="color: green">{ Climb to the next floor (Level 4) }</a>%0]])
			end
		end
	elseif text:contains([[<a href="lair5.php">Go back to the Sorceress' Tower</a>]]) and text:contains("WINWINWIN") then
		local lair4pt = get_page("/lair5.php")
		if lair4pt:contains([[value="level1"]]) and known_win(4) then
			print("goto lair5:level1")
			text = text:gsub([[<center><a href="lair5.php">Go back to the Sorceress' Tower</a></center>]], [[<p><a href="lair5.php?action=level1" style="color: green">{ Climb to the next floor (Level 4) }</a>%0]])
		elseif lair4pt:contains([[value="level2"]]) and known_win(5) then
			print("goto lair5:level2")
			text = text:gsub([[<center><a href="lair5.php">Go back to the Sorceress' Tower</a></center>]], [[<p><a href="lair5.php?action=level2" style="color: green">{ Climb to the next floor (Level 5) }</a>%0]])
		elseif lair4pt:contains([[value="level3"]]) and known_win(6) then
			print("goto lair5:level3")
			text = text:gsub([[<center><a href="lair5.php">Go back to the Sorceress' Tower</a></center>]], [[<p><a href="lair5.php?action=level3" style="color: green">{ Climb to the next floor (Level 6) }</a>%0]])
		else
			local lair6pt = get_page("/lair6.php")
			if lair6pt:contains([[lair6.php]]) then
				print("goto lair6")
				text = text:gsub([[<center><a href="lair5.php">Go back to the Sorceress' Tower</a></center>]], [[<p><a href="lair6.php" style="color: green">{ Climb to the top of the tower }</a>%0]])
			end
		end
	end
end)

add_processor("/lair6.php", function()
	if text:contains("As you approach the door, you notice that someone has scrawled a message on it with a pencil: &quot;BEWARE: One of the guards always tells the truth, one of them always lies, one of them alternates between the two, and one craves the taste of human flesh!&quot; Ominous.") then
		if text:contains("You're full of it") then
			first = text:match("&quot;Well,&quot; says South, &quot;the first digit is ([0-9]).&quot;")
			second = text:match("North grumbles, &quot;It's definitely more than that %-%- it's ([0-9]).&quot;")
			third = text:match("&quot;No, it is ([0-9]), I'm sure of it,&quot; says North.")
		else
			truth, third = text:match("&quot;Don't listen to him,&quot; says (.-). &quot;It's ([0-9]).&quot;")
			second = text:match("&quot;The second digit now %-%- that's ([0-9]),&quot; says South.")
			if (truth == "South") then
				first = text:match("&quot;Well,&quot; says South, &quot;the first digit is ([0-9]).&quot;")
			elseif (truth == "East") then
				first = text:match("&quot;No it isn't,&quot; says East. &quot;It's ([0-9]).&quot;")
			end
		end
		print("INFO: lair6 door", first, second, third)
		if first and second and third then
			session["zone.lair.doorcode"] = first..second..third
		end
	end
end)

add_printer("/lair6.php", function()
	if text:contains("You approach the heavy door.  Next to it is a panel with a bunch of buttons on it.  On the buttons are numbers.") then
		local code = session["zone.lair.doorcode"]
		if code then
			text = text:gsub("(<input type=text class=text size=5 name=code)(>)", [[%1 value="]]..code..[["%2]])
		end
	end
end)

function automate_lair6_place(place, text)
	if place == 0 then
		if text:contains("At the top of the steps leading to the Sorceress' Chamber, you encounter two doors.") then
			session["zone.lair.doorcode"] = nil
			post_page("/lair6.php", { preaction = "lightdoor" })
			code = session["zone.lair.doorcode"]
			print("INFO: lair6 code", code, "params", params)
			if code then
				text = post_page("/lair6.php", { action = "doorcode", code = code })
			end
		end
	end

	if place == 3 or place == 4 then
		if text:contains("Disappointed by your failure, you stomp off in a huff, and stub your toe.") then
			local which = text:match([[<img src="http://images.kingdomofloathing.com/adventureimages/([a-z]+).gif" width=100 height=100>]])
			print("INFO: Sorceress familiar = " .. tostring(which))
			local familiar_lookup = {
				barrrnacle = { id = 4, name = "Angry Goat", },
				goat = { id = 1, name = "Mosquito", },
				lime = { id = 3, name = "Levitating Potato", },
				mosquito = { id = 5, name = "Sabre-Toothed Lime", },
				potato = { id = 8, name = "Barrrnacle", },
			}
			if familiar_lookup[which] then
				print("  Familiar used to defeat it:", familiar_lookup[which].name)
				session["NS lair familiar needed for place " .. place] = familiar_lookup[which].name
				local famid = familiarid()
				switch_familiarid(familiar_lookup[which].id)
				if familiarid() == familiar_lookup[which].id then
					get_page("/charpane.php") -- Workaround for CDM updating bug
					local eq = equipment()
					local weight = buffedfamiliarweight()
					if weight and weight < 20 and have_inventory_item("sugar shield") then
						equip_item("sugar shield")
						get_page("/charpane.php") -- Workaround for CDM updating bug
						weight = buffedfamiliarweight()
					elseif weight and weight < 20 and have_inventory_item("astral pet sweater") then
						equip_item("astral pet sweater")
						get_page("/charpane.php") -- Workaround for CDM updating bug
						weight = buffedfamiliarweight()
					end
					if weight and weight >= 20 then
						newtext = get_page("/lair6.php", { place = place })
						if newtext:contains("You move further into the tower, while huge chunks of stone fall from the walls for no good reason.") then
							text = newtext
							print("INFO: Won vs NS familiar")
						else
							print("WARNING: Error fighting NS familiar")
							error("Error, expected to win this fight with a " .. weight .. " lbs. " .. familiar_lookup[which].name .. ".")
						end
					else
						print("INFO: Familiar weight is only", weight)
					end
					set_equipment(eq)
				else
					print("INFO: Missing familiar")
				end
				switch_familiarid(famid)
			else
				print("INFO: Unknown NS familiar", which)
			end
		end
	end
	return text
end

add_automator("/lair6.php", function()
	if not setting_enabled("automate simple tasks") then return end

	text = automate_lair6_place(tonumber(params.place), text)
end)

add_interceptor("/lair6.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if tonumber(params.place) == 1 then
		local eq = equipment()
		equip_item("huge mirror shard")
		text, url = get_page(requestpath, params)
		set_equipment(eq)
		return text, url
	end
end)

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
	if session["NS lair familiar needed for place 3"] then
		placedescs[4] = "Beat the first familiar (need 20+ lbs. " .. session["NS lair familiar needed for place 3"] .. ")"
	end
	if session["NS lair familiar needed for place 4"] then
		placedescs[5] = "Beat the first familiar (need 20+ lbs. " .. session["NS lair familiar needed for place 4"] .. ")"
	end
	if ascensionpath("Bees Hate You") then
		placedescs[6] = "Defeat The Naughty Sorceress and The Guy Made Of Bees (requires antique hand mirror)"
	elseif ascensionpath("Avatar of Boris") then
		placedescs[4] = "Beat the first familiar (requires nothing)"
		placedescs[5] = "Beat the second familiar (requires nothing)"
		placedescs[6] = "Defeat The Naughty Sorceress and The Avatar of Sneaky Pete"
	elseif ascensionpath("Zombie Slayer") then
		placedescs[4] = "Beat the first familiar (requires 10+ Horde)"
		placedescs[5] = "Beat the second familiar (requires 10+ Horde)"
		placedescs[6] = "Defeat The Naughty Sorceress and Rene C. Corman"
	elseif ascensionpath("Avatar of Jarlsberg") then
		placedescs[4] = "Defeat Clancy"
		placedescs[5] = "(skipped)"
		placedescs[6] = "Defeat The Avatar of Boris"
	elseif ascensionpath("KOLHS") then
		placedescs[6] = "Defeat Principal Mooney"
	elseif ascensionpath("Avatar of Sneaky Pete") then
		placedescs[4] = "Beat the first familiar (requires nothing)"
		placedescs[5] = "Beat the second familiar (requires nothing)"
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
