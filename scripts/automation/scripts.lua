function reuse_equipment_slots(neweq)
	local remap = {}
	local used = {}
	for _, x in ipairs { "acc1", "acc2", "acc3" } do
		if neweq[x] then
			for _, y in ipairs { "acc1", "acc2", "acc3" } do
				if neweq[x] == equipment()[y] and not used[y] then
					remap[x] = y
					used[y] = true
					break
				end
			end
		end
	end

	for _, x in ipairs { "acc1", "acc2", "acc3" } do
		if not remap[x] then
			for _, y in ipairs { "acc1", "acc2", "acc3" } do
				if not used[y] then
					remap[x] = y
					used[y] = true
					break
				end
			end
		end
	end

	local remapitems = {}
	remapitems[remap.acc1] = neweq.acc1
	remapitems[remap.acc2] = neweq.acc2
	remapitems[remap.acc3] = neweq.acc3

	neweq.acc1 = remapitems.acc1
	neweq.acc2 = remapitems.acc2
	neweq.acc3 = remapitems.acc3
	return neweq
end

function solve_knapsack(size, datalist)
	local array = {}
	local arrayitems = {}
	array[0] = 0
	for _, d in ipairs(datalist) do
		for i = size, 0, -1 do
			for num = 1, 100 do
				local j = i + d.size * num
				if num > d.amount or j > size or not array[i] then break end
				local v = array[i] + d.value * num
				if v > (array[j] or 0) then
					array[j] = v
					arrayitems[j] = { name = d.name, amount = num, previous = arrayitems[i] }
				end
			end
		end
	end
	return array, arrayitems
end

function get_available_drinks(minquality)
	local drinks = {}
	for id, amount in pairs(inventory()) do
		if id == get_itemid("astral pilsner") then
			if level() >= 11 then
				table.insert(drinks, { name = get_itemname(id), amount = amount, size = 1, value = 11 })
			end
		else
			local d = maybe_get_itemdata(id)
			if d and d.drunkenness and d.drunkenness >= 1 and level() >= (d.levelreq or 1) then
				local value = (d.advmin + d.advmax) / 2
				if value / d.drunkenness >= minquality then
					table.insert(drinks, { name = get_itemname(id), amount = amount, size = d.drunkenness, value = value })
				end
			end
		end
	end
	return drinks
end

function determine_drink_option(min_space, max_space, available_drinks)
	local array, arrayitems = solve_knapsack(max_space, available_drinks)
	local best_space = nil
	for space = min_space, max_space do
		if array[space] then
			if not best_space or array[space] / space > array[best_space] / best_space then
				best_space = space
			end
		end
	end
	if not best_space then return end
	local drinks = {}
	local function recur(x)
		if not x then return end
		for i = 1, x.amount do
			table.insert(drinks, x.name)
		end
		recur(x.previous)
	end
	recur(arrayitems[best_space])
	return drinks, best_space, array[best_space]
end

__allow_global_writes = true

local script_cached_stuff = {}

function get_automation_scripts(cached_stuff)
	if not get_pwd then
		function get_pwd() return session.pwd end
	end
	local f = {}
	local script = f
	cached_stuff = cached_stuff or script_cached_stuff

	local function feed_slimeling()
		if ascensionstatus() == "Aftercore" then return end
		local function feed(name)
-- 			print("feeding", name)
			return post_page("/familiarbinger.php", { action = "binge", pwd = get_pwd(), qty = 1, whichitem = get_itemid(name) })
		end
		local feed_items = get_ascension_automation_settings().slimeling_feed_items
		local feed_except_one = get_ascension_automation_settings().slimeling_feed_except_one
		for i in table.values(feed_items) do
			if have_item(i) then
				feed(i)
			end
		end
		for tbl in table.values(feed_except_one) do
			for i in table.values(tbl) do
				if count_item(i) > 1 then
					if count_item(i) > 10 then
						stop("More than 10 of " .. i .. " when feeding slimeling")
					end
					feed(i)
				end
			end
		end
	end

	-- TODO: remove this, handle as generic "want items, mprestore" etc.
	local familiar_data = {
		["Kolproxy Test Fam"] = { id = 12345, fallback = "Midget Clownfish" },
		["Leprechaun"] = {},
		["Baby Gravy Fairy"] = {},
		["Flaming Gravy Fairy"] = { fallback = "Frozen Gravy Fairy" },
		["Frozen Gravy Fairy"] = { fallback = "Stinky Gravy Fairy" },
		["Stinky Gravy Fairy"] = {},
		["Star Starfish"] = { mpregen = true, attack = true },
		["Smiling Rat"] = {},
		["Reassembled Blackbird"] = {},
		["Slimeling"] = { f = feed_slimeling, mpregen = true, attack = true, fallback = "Baby Gravy Fairy" },
		["Mini-Hipster"] = { mpregen = true, attack = true, familiarequip = "fixed-gear bicycle", fallback = "Artistic Goth Kid" },
		["Artistic Goth Kid"] = { fallback = "Rogue Program" },
		["Rogue Program"] = { mpregen = true, attack = true, fallback = "Midget Clownfish" },
		["Jumpsuited Hound Dog"] = { fallback = "Slimeling" },
		["Frumious Bandersnatch"] = { fallback = "Mini-Hipster" },
		["Rock Lobster"] = { mpregen = true, attack = true, fallback = "Rogue Program" },
		["Knob Goblin Organ Grinder"] = { attack = true, fallback = "Llama Lama" },
		["Midget Clownfish"] = { mpregen = true, attack = true, fallback = "Star Starfish" },
		["Stocking Mimic"] = { mpregen = true, attack = true, familiarequip = "bag of many confections", fallback = "Rogue Program" },
		["Hobo Monkey"] = { fallback = "He-Boulder" },
		["He-Boulder"] = { mpregen = true, fallback = "Leprechaun" },
		["Baby Bugged Bugbear"] = { familiarequip = "bugged balaclava", fallback = "Frumious Bandersnatch" },
		["Llama Lama"] = { fallback = "Bloovian Groose" },
		["Exotic Parrot"] = { fallback = "Llama Lama" },
		["Pair of Stomping Boots"] = { attack = true, fallback = "Slimeling" },
		["Tickle-Me Emilio"] = { mpregen = true, attack = true, fallback = "Rogue Program" },
		["Bloovian Groose"] = { fallback = "Midget Clownfish" },
		["Obtuse Angel"] = { fallback = "Slimeling" },
		["Reanimated Reanimator"] = { fallback = "Obtuse Angel" },
		["Reagnimated Gnome"] = { familiarequip = "gnomish housemaid's kgnee", fallback = "Hovering Sombrero" },
		["Hovering Sombrero"] = { fallback = "(ignore familiar)" },
		["Angry Jung Man"] = { fallback = "Slimeling" },
		["Gelatinous Cubeling"] = { fallback = "Slimeling" },
		["Mad Hatrack with spangly sombrero"] = { id = 82, familiarequip = "spangly sombrero", fallback = "Slimeling even in fist", needsequip = true },
		["Scarecrow with spangly mariachi pants"] = { id = 152, familiarequip = "spangly mariachi pants", fallback = "Mad Hatrack with spangly sombrero", needsequip = true },
		["Scarecrow with studded leather boxer shorts"] = { id = 152, familiarequip = "studded leather boxer shorts", needsequip = true, fallback = "Llama Lama" },
		["Scarecrow with Boss Bat britches"] = { id = 152, familiarequip = "Boss Bat britches", needsequip = true, mpregen = true, fallback = "Rogue Program" },
		["Jumpsuited Hound Dog for +combat"] = { id = 69, fallback = "Llama Lama" },
		["Slimeling even in fist"] = { id = 112, f = feed_slimeling, mpregen = true, attack = true, fallback = "Slimeling" },
	}
	-- TODO: check when using the id instead
	for a, b in pairs(familiar_data) do
		local famid = maybe_get_familiarid(a)
		if famid then
			b.id = famid
		end
	end

	local function raw_want_familiar(famname_input)
		-- TODO: improve fallbacks and priorities
		local missing_fams = session["__script.missing familiars"] or {}
		local famname, next_famname_input
		if type(famname_input) == "table" then
			for f in table.values(famname_input) do
				if not missing_fams[f] then
					local d = familiar_data[f]
					if not (d.needsequip and not have_item(d.familiarequip)) then
						if not famname then
							famname = f
						elseif not next_famname_input then
							next_famname_input = famname_input
						end
					end
				end
			end
			if not famname then
				famname = famname_input[1]
			end
		elseif type(famname_input) == "string" then
			famname = famname_input
		else
			error("Unknown familiar input: " .. tostring(famname_input))
		end
		if famname == "(ignore familiar)" then
			return
		end
		local d = familiar_data[famname]
		if missing_fams[famname] or (d and d.needsequip and not have_item(d.familiarequip)) then
			if famname == "Rogue Program" and spleen() < 12 then
				return raw_want_familiar("Bloovian Groose")
			else
				if not familiar_data[famname].fallback or highskill_at_run then
					critical("No fallback familiar for " .. famname)
				end
				return raw_want_familiar(next_famname_input or (d and d.fallback))
			end
		end
		if not d then
			local df = datafile("familiars")[famname]
			if df and df.famid then
				if df.famid ~= familiarid() then
					switch_familiarid(df.famid)
				end
				if df.famid == familiarid() then
					return {}
				end
			end
			critical("Don't have familiar " .. tostring(famname) .. ", and no fallback data (from "..tostring(famname_input) .. ")")
		end
		if d then
			if d.id ~= familiarid() then
				if equipment().familiarequip then
					unequip_slot("familiarequip")
				end
				if not script_ignore_familiars_without_fallback or not d.fallback then
					switch_familiarid(d.id)
				end
				if d.id ~= familiarid() then
					if not d.fallback then
						critical("No fallback familiar for " .. famname)
					end
					missing_fams[famname] = true
					session["__script.missing familiars"] = missing_fams
					print("Using fallback familiar", famname, "->", d.fallback)
					return raw_want_familiar(d.fallback)
				end
				if show_spammy_automation_events then
					print("  changed familiar", famname)
				end
			end
			if d.f then
				d.f()
			end
			if familiar_data[famname].familiarequip and not have_item(familiar_data[famname].familiarequip) then
				if not have_item("fixed-gear bicycle") and have_item("ironic moustache") then
					unequip_slot("familiarequip")
					use_item("ironic moustache")
					use_item("chiptune guitar")
					if not have_item("fixed-gear bicycle") then
						critical "Failed to turn moustache into bicycle"
					end
				end
				if familiar_data[famname].familiarequip == "bugged balaclava" then
					async_get_page("/arena.php")
					if have_item("bugged beanie") then
						use_item("bugged beanie")
					end
					if not have_item(familiar_data[famname].familiarequip) then
						critical "Failed to get bugged balaclava"
					end
				end
			end
			return { mpregen = familiar_data[famname].mpregen, familiarequip = familiar_data[famname].familiarequip and have_item(familiar_data[famname].familiarequip) and familiar_data[famname].familiarequip }
		else
			error("Unknown familiar: " .. tostring(famname))
		end
	end

	-- TODO: set the familiar equipment here
	function f.want_familiar(famname)
		if not can_change_familiar() or ascension_script_option("100% familiar run") then
			return {}
		end
		if challenge == "zombie" and famname ~= "Reassembled Blackbird" then
			famname = "Reagnimated Gnome"
		end
		if famname == "Slimeling" and highskill_at_run then
			famname = "Scarecrow with spangly mariachi pants"
		elseif have_item("spangly mariachi pants") and (famname == "Slimeling" or famname == "Jumpsuited Hound Dog") then
			famname = "Scarecrow with spangly mariachi pants"
		elseif have_item("spangly sombrero") and (famname == "Slimeling" or famname == "Jumpsuited Hound Dog") then
			famname = "Mad Hatrack with spangly sombrero"
		end
		if famname == "Slimeling" and daysthisrun() >= 2 and not have_item("digital key") and not have_item("psychoanalytic jar") and get_daily_counter("familiar.jungman.jar") == 0 then
			famname = "Angry Jung Man"
		elseif famname == "Slimeling" and not have_gelatinous_cubeling_items() then
			famname = "Gelatinous Cubeling"
		end
		return raw_want_familiar(famname)
	end

	function f.have_familiar(famname)
		if not cached_stuff.have_familiars then
			cached_stuff.have_familiars = {}
		end
		if cached_stuff.have_familiars[famname] == nil then
			print("INFO: checking for familiar", famname)
			f.want_familiar(famname)
			cached_stuff.have_familiars[famname] = (familiar_data[famname].id == familiarid())
		end
		return cached_stuff.have_familiars[famname]
	end

	local fam = f.want_familiar

	local want_bonus = {}
	function f.bonus_target(targets)
		want_bonus.boris_song = have_skill("Song of Accompaniment") and "Song of Accompaniment"
		want_bonus.clancy_item = "Clancy's sackbut"
		if level() < 13 then
			if mp() >= 50 and have_item("Clancy's crumhorn") or clancy_instrumentid() == 2 then
				want_bonus.clancy_item = "Clancy's crumhorn"
			end
			if have_skill("Song of Cockiness") and (mp() >= 50 or have_buff("Song of Cockiness")) and level() >= 4 then
				want_bonus.boris_song = "Song of Cockiness"
			end
		end
		if ascensionpath("Avatar of Boris") or ascensionpath("Zombie Slayer") or ascensionpath("Avatar of Sneaky Pete") then
			want_bonus.not_casting_spells = true
		end
		-- Checked in reverse order, to let first item have highest priority by overriding previous choices
		for t_i = #targets, 1, -1 do
			local t = targets[t_i]
			if t == "item" then
				want_bonus.clancy_item = "Clancy's lute"
				want_bonus.plusitems = true
				if have_skill("Song of Fortune") then
					want_bonus.boris_song = "Song of Fortune"
				elseif have_skill("Song of Accompaniment") then
					want_bonus.boris_song = "Song of Accompaniment"
				end
			elseif t == "extraitem" then
				want_bonus.extraplusitems = true
			elseif t == "minoritem" then
				want_bonus.minoritem = true
				want_bonus.clancy_item = "Clancy's lute"
			elseif t == "extranoncombat" then
				want_bonus.extranoncombat = true
			elseif t == "noncombat" then
				want_bonus.noncombat = true
				if have_skill("Song of Solitude") then
					want_bonus.boris_song = "Song of Solitude"
				end
				want_bonus.jarlsberg_sphere = "Chocolatesphere"
			elseif t == "combat" then
				want_bonus.combat = true
				if have_skill("Song of Battle") then
					want_bonus.boris_song = "Song of Battle"
				end
				want_bonus.jarlsberg_sphere = "Coffeesphere"
			elseif t == "easy combat" then
				want_bonus.easy_combat = true
				want_bonus.boris_song = "Song of Accompaniment"
				if have_intrinsic("Overconfident") then
					set_result(script.cast_buff("Pep Talk"))
				end
				if have_intrinsic("Overconfident") then
					critical "Failed to remove Overconfident"
				end
				want_bonus.jarlsberg_sphere = "Oilsphere"
				set_mcd(0)
			elseif t == "initiative" then
				want_bonus.plusinitiative = true
			elseif t == "monster level" then
				want_bonus.monster_level = true
			elseif t == "elemental weapon damage" then
				want_bonus.elemental_weapon_damage = true
			elseif t == "rollover adventures" then
				want_bonus.rollover_adventures = true
			else
				error("Unknown bonus target: " .. t)
			end
		end
	end

	function f.set_runawayfrom(runawayfrom)
		if not runawayfrom then
			set_macro_runawayfrom_monsters(nil)
		end
		set_macro_runawayfrom_monsters(runawayfrom)
		want_bonus.runawayfrom = runawayfrom
	end

	function f.burn_mp(downto, hundreds, recursed)
		if not hundreds then
			hundreds = 50
		end
		if not downto then
			error "No downto parameter specified for burn_mp()"
		end
		local distance = 30
		if level() >= 8 then
			distance = 50
		end
		if ascensionpath("BIG!") and downto < 150 then
			downto = 150
		end
		distance = distance + maxmp() / 5
		local ignore_buffs = get_ascension_automation_settings().ignore_buffs
-- 		print("burn_mp", maxmp(), (maxmp() - mp()), mp(), downto)
		if maxmp() > 50 and (maxmp() - mp()) < distance and mp() > downto and hundreds < 1000 then
			if show_spammy_automation_events and not recursed then
				print("  burning excess MP from " .. mp() .. " down to " .. downto)
			end
			local toburn = mp() - downto
			infoline("burning " .. toburn .. " excess MP")
-- 			print("burn mp", toburn, hundreds, "level", level())
			if have_buff("Salamanderenity") and buffturns("Salamanderenity") < hundreds and toburn >= 5 then
				cast_skillid(65, math.floor(toburn / 5)) -- salamander
			elseif level() < 7 and (buffturns("The Magical Mojomuscular Melody") < 50 or toburn < 10) and not highskill_at_run then
				cast_skillid(6004, math.floor(toburn / 5)) -- madrigal
				cast_skillid(6007, math.floor(toburn / 5)) -- mojo
			elseif buffturns("Leash of Linguini") < hundreds and toburn >= 12 then
				cast_skillid(3010, math.floor(toburn / 12)) -- leash of linguini
			elseif level() >= 6 and level() < 13 and buffturns("Ur-Kel's Aria of Annoyance") < hundreds and toburn >= 30 and not ignore_buffs["Ur-Kel's Aria of Annoyance"] then
				cast_skillid(6017, math.floor(toburn / 30)) -- aria
			elseif buffturns("Empathy") < hundreds and toburn >= 15 and challenge ~= "fist" and not ignore_buffs["Empathy"] then
				cast_skillid(2009, math.floor(toburn / 15)) -- empathy of the newt
			elseif level() >= 6 and buffturns("Fat Leon's Phat Loot Lyric") < hundreds and toburn >= 11 then
				cast_skillid(6010, math.floor(toburn / 11)) -- phat loot
			elseif buffturns("Springy Fusilli") < hundreds and toburn >= 10 then
				cast_skillid(3015, math.floor(toburn / 10)) -- springy fusilli
			elseif buffturns("Ghostly Shell") < hundreds and toburn >= 6 and challenge ~= "fist" and not ignore_buffs["Ghostly Shell"] then
				cast_skillid(2007, math.floor(toburn / 6)) -- ghostly shell
			elseif buffturns("Astral Shell") < hundreds and toburn >= 10 and challenge ~= "fist" and not ignore_buffs["Astral Shell"] then
				cast_skillid(2012, math.floor(toburn / 10)) -- astral shell
			elseif level() >= 8 and buffturns("A Few Extra Pounds") < hundreds and toburn >= 10 then
				cast_skillid(1024, math.floor(toburn / 10)) -- holiday weight gain
			elseif buffturns("Antibiotic Saucesphere") < hundreds and toburn >= 10 and not ignore_buffs["Antibiotic Saucesphere"] then
				cast_skill("Antibiotic Saucesphere", math.floor(toburn / 10))
			else
				return f.burn_mp(downto, hundreds + 100, true)
			end
-- 		else
-- 			print("skipping mp burn")
		end
	end

	function f.trade_for_clover()
		if challenge == "fist" and meat() < 150 then return end
		if not have_item("hermit permit") then
			inform "buying hermit permit"
			buy_item("hermit permit", "m")
			if not have_item("hermit permit") then
				critical "Failed to buy hermit permit"
			end
		end
		f.ensure_worthless_item()
		local hermitpt = get_page("/hermit.php")
		if hermitpt:contains("left in stock") then
			inform "trading for clover"
			local c = count_item("ten-leaf clover")
			result, resulturl = post_page("/hermit.php", { action = "trade", whichitem = get_itemid("ten-leaf clover"), quantity = 1 })
			if count_item("ten-leaf clover") <= c then
				critical "Failed to trade for ten-leaf clover"
			end
			if ascensionpath("Bees Hate You") then
				closet_item("ten-leaf clover")
			else
				use_item("ten-leaf clover")
			end
			if count_item("ten-leaf clover") > c then
				critical "Failed to hide ten-leaf clover"
			end
			did_action = true
		end
		return did_action
	end

	function f.use_and_sell_items()
		local use_items = get_ascension_automation_settings().use_items
		local use_except_one = get_ascension_automation_settings().use_except_one

		-- TODO: don't use wallets on fist path
		for w in table.values(use_items) do
			if have_item(w) then
				if count_item(w) >= 100 then
					stop("Somehow have 100+ of " .. tostring(w) .. " when trying to use items")
				end
				set_result(use_item(w))
				did_action = true
			end
		end
		for w in table.values(use_except_one) do
			if count_item(w) >= 2 then
				if count_item(w) >= 100 then
					stop("Somehow have 100+ of " .. tostring(w) .. " when trying to use items")
				end
				set_result(use_item(w))
				did_action = true
			end
		end

		if challenge ~= "fist" and ((ascensionstatus() == "Hardcore" and meat() < 14000) or meat() < 7000) then
			local sell_items = get_ascension_automation_settings().sell_items
			local sell_except_one = get_ascension_automation_settings().sell_except_one
			for s in table.values(sell_items) do
				if have_item(s) then
					if count_item(s) >= 100 then
						stop("Somehow have 100+ of " .. tostring(s) .. " when trying to sell items")
					end
					set_result(sell_item(s))
					did_action = true
				end
			end
			for s in table.values(sell_except_one) do
				if count_item(s) >= 2 then
					if count_item(s) >= 100 then
						stop("Somehow have 100+ of " .. tostring(s) .. " when trying to sell items")
					end
					set_result(sell_item(s))
					did_action = true
				end
			end
		end
		return did_action
	end

	function f.ensure_mp(amount, recursed)
		if challenge == "zombie" then return end
		--print("DEBUG: ensure_mp()", mp(), maxmp())
		local need_extra = 0
		if challenge == "trendy" then
			if level() >= 10 then
				need_extra = 40
			end
		end
		if highskill_at_run and level() >= 6 then
			need_extra = 20
		end
		if ascensionpath("BIG!") and amount < 50 then
			amount = 50
		end
		if challenge == "boris" then
			if have_skill("Banishing Shout") and maxmp() >= 60 and level() >= 6 then
				amount = 55
			elseif ascensionstatus() == "Hardcore" and maxmp() >= 40 and level() >= 6 then
				amount = math.min(amount, 30)
			else
				amount = math.min(amount, 15)
			end
		end
		if maxmp() < amount + need_extra then
			if challenge == "boris" or challenge == "jarlsberg" then
				return
			elseif maxmp() < 20 and level() < 6 then
				if not session["__script.low maxmp"] then
					print("SCRIPT WARNING: Max MP is very low.")
					session["__script.low maxmp"] = true
				end
				return
			else
				critical("Maxmp < " .. (amount + need_extra) .. " when trying to ensure MP")
			end
		end
		if mp() < amount + need_extra then
			local need = amount + need_extra - mp()
			if show_spammy_automation_events and not recursed then
				infoline("restoring MP to " .. (amount + need_extra) .. "+, need " .. need)
			end
			if need > 1000 then
				stop "Trying to restore more than 1000 MP at once"
			elseif need > 100 and not ascensionstatus("Aftercore") then
				stop "Trying to restore more than 100 MP at once (in-run)"
			end
			local restore_items = {
				["natural fennel soda"] = 120,
				["carbonated soy milk"] = 80,
				["bottle of Monsieur Bubble"] = 60,
				["carbonated water lily"] = 65,
				["Knob Goblin superseltzer"] = 30,
				["sugar shard"] = 10,
				["ancient Magi-Wipes"] = 55,
				["phonics down"] = 50,
				["honey-dipped locust"] = 35,
				["magical mystery juice"] = 1.5 * level() + 6,
				["tonic water"] = 45,
				["black cherry soda"] = 11,
				["Knob Goblin seltzer"] = 12,
				["tiny house"] = 24,
			}
			for name, limit in pairs(restore_items) do
				if have_item(name) and (mp() + limit < maxmp()) then
					use_item(name)
					return f.ensure_mp(amount, true)
				end
			end
			for name, limit in pairs(restore_items) do
				if have_item(name) and (mp() + limit * 0.75 < maxmp()) then
					use_item(name)
					return f.ensure_mp(amount, true)
				end
			end
			for name, limit in pairs(restore_items) do
				if have_item(name) and (mp() + limit * 0.5 < maxmp()) then
					use_item(name)
					return f.ensure_mp(amount, true)
				end
			end
			if session["__script.used all free rests"] ~= "yes" and not ascensionpath("Avatar of Jarlsberg") then
				local camppt = get_page("/campground.php")
				local restlink = camppt:match([[<a href="campground.php%?action=rest">.-</a>]])
				if restlink:contains("free.gif") then
					local before_advs = advs()
					local before_mp = mp()
					print("  free resting")
					async_get_page("/campground.php", { action = "rest" })
					if advs() ~= before_advs or mp() <= before_mp then
						critical("Error using free rests: " .. tostring(advs()) .. " vs " .. tostring(before_advs) .. "advs, " .. tostring(mp()) .. " vs " .. tostring(before_mp) .. "mp")
					end
					return f.ensure_mp(amount, true)
				else
					session["__script.used all free rests"] = "yes"
					return f.ensure_mp(amount, true)
				end
			elseif (classid() == 3 or classid() == 4) and (session["__script.opened myst guild store"] == "yes" or level() >= 8) and challenge ~= "fist" and not have_item("magical mystery juice") then
				buy_item("magical mystery juice", "2")
				if have_item("magical mystery juice") then
					return f.ensure_mp(amount, true)
				else
					critical "Failed to buy MMJ as myst"
				end
			elseif classid() == 6 and level() >= 9 and challenge ~= "fist" and not have_item("magical mystery juice") then
				buy_item("magical mystery juice", "2")
				if have_item("magical mystery juice") then
					return f.ensure_mp(amount, true)
				else
					critical "Failed to buy MMJ as lvl 9+ AT"
				end
			elseif cached_stuff.kgs_available and not have_item("Knob Goblin seltzer") then
				buy_item("Knob Goblin seltzer", "k", 5)
				if have_item("Knob Goblin seltzer") then
					return f.ensure_mp(amount, true)
				else
					critical "Failed to buy knob goblin seltzer (should already be available)"
				end
			elseif have_item("your father's MacGuffin diary") and not have_item("black cherry soda") then
				shop_buyitem({ ["black cherry soda"] = 5 }, "blackmarket")
				if have_item("black cherry soda") then
					return f.ensure_mp(amount, true)
				else
					critical "Failed to buy black cherry soda"
				end
			elseif (challenge == "boris" or challenge == "jarlsberg") and need <= 60 then
				post_page("/galaktik.php", { action = "curemp", pwd = get_pwd(), quantity = need })
				if mp() < amount then
					stop("Failed to reach " .. amount .. " MP using galaktik")
				end
			elseif challenge or highskill_at_run then
				-- TODO: choose using it earlier if we need a lot of MP, and remember whether it's been used
				local pt = get_page("/clan_viplounge.php", { action = "shower" })
				if pt:contains("<option value=5>Hot</option>") then
					-- TODO: burn it all first!
					async_post_page("/clan_viplounge.php", { preaction = "takeshower", temperature = 5 })
					if mp() < amount then
						critical "Failed to restore enough MP with clan shower"
					end
					return f.ensure_mp(amount, true)
				elseif not have_item("tonic water") and not highskill_at_run then
					if not have_item("soda water") then
						buy_item("soda water", "m", 1)
					end
					async_post_page("/guild.php", { action = "stillfruit", whichitem = get_itemid("soda water"), quantity = 1 })
					if have_item("tonic water") then
						return f.ensure_mp(amount, true)
					end
				end
				stop "Out of MP in challenge path"
			elseif level() >= 8 and not (ascensionpath("Avatar of Sneaky Pete") and meat() >= 7500) then
				stop "Trying to use galaktik to restore mp at level 8+"
			elseif need > 50 then
				stop "Trying to use galaktik to restore more than 50 MP"
			else
				if show_spammy_automation_events then
					print("  restoring " .. tostring(need) .. " MP with galaktik")
				end
				post_page("/galaktik.php", { action = "curemp", pwd = get_pwd(), quantity = need })
				if mp() < amount then
					stop("Failed to reach " .. amount .. " MP using galaktik")
				end
			end
		end
-- 		print("ensured mp to ", amount, " now ", mp())
	end

	local ensure_mp = f.ensure_mp

	local function is_cursed()
		return have_buff("Thrice-Cursed") or have_buff("Twice-Cursed") or have_buff("Once-Cursed")
	end

	function f.heal_up(target)
		target = target or maxhp() * 0.8
		--print("DEBUG: heal_up()", hp(), maxhp())
		if hp() < target and (maxhp() - hp() >= 20 or maxhp() < 50) then
			local oldhp = hp()
			if maxhp() - hp() >= 70 and have_skill("Cannelloni Cocoon") then
				ensure_mp(20)
				cast_skill("Cannelloni Cocoon")
			elseif have_skill("Shake It Off") and not is_cursed() and maxmp() >= 40 then
				ensure_mp(30)
				cast_skill("Shake It Off")
			elseif have_skill("Tongue of the Walrus") then
				ensure_mp(10)
				cast_skill("Tongue of the Walrus")
			elseif challenge == "boris" and have_item("your father's MacGuffin diary") and (hp() < 200 or hp() / maxhp() < 0.5 or ascensionstatus() == "Hardcore") then
				ensure_mp(10)
				cast_skillid(11031, 10)
			elseif challenge == "zombie" then
				cast_skillid(12001)
			elseif have_skill("Disco Power Nap") then
				ensure_mp(12)
				cast_skillid("Disco Power Nap")
			elseif have_skill("Lasagna Bandages") then
				ensure_mp(6)
				cast_skillid("Lasagna Bandages")
			elseif maxhp() - hp() <= 20 and have_item("cast") then
				use_item("cast")
			elseif maxhp() < 50 then
				-- Do nothing
			elseif have_item("Camp Scout pup tent") then
				use_item("Camp Scout pup tent")
			elseif have_item("scroll of drastic healing") then
				use_item("scroll of drastic healing")
			elseif have_item("bag of pygmy blood") and not ascensionpath("Bees Hate You") then
				use_item("bag of pygmy blood")
			elseif have_item("phonics down") then
				use_item("phonics down")
			elseif have_item("honey-dipped locust") then
				use_item("honey-dipped locust")
			elseif have_item("tiny house") then
				use_item("tiny house")
			elseif have_item("cast") then
				use_item("cast")
			elseif meat() >= 5000 and challenge ~= "zombie" then
				post_page("/galaktik.php", { action = "curehp", pwd = get_pwd(), quantity = 10 })
			end
			if hp() > oldhp then
				if show_spammy_automation_events then
					print("  restored hp:", oldhp, "to", hp(), "max is", maxhp())
				end
				return f.heal_up()
			else
				if challenge == "boris" and hp() / maxhp() >= 0.55 then
				elseif challenge == "zombie" and hp() / maxhp() >= 0.3 then
				elseif challenge == "boris" or challenge == "zombie" then
					if not is_cursed() then
						use_hottub()
					end
					if hp() < maxhp() then
						if challenge == "boris" then
							ensure_mp(10)
							cast_skillid(11031, 10)
							if hp() > oldhp then
								return f.heal_up()
							else
								critical "Failed to restore HP!"
							end
						else
							critical "Failed to restore all HP with hot tub!"
						end
					end
				elseif ascensionpath("Avatar of Jarlsberg") and not is_cursed() then
					if hp() / maxhp() <= 0.3 and daysthisrun() == 1 then
						use_hottub()
					end
				else
					if hp() < maxhp() / 2 then
						session["__script.cannot restore HP"] = true
--						critical "Failed to restore HP!"
					end
				end
			end
		end
	end

	function f.force_heal_up()
		f.heal_up(maxhp())
		if hp() < maxhp() and not is_cursed() then
			use_hottub()
		end
		if hp() < maxhp() and challenge ~= "zombie" then
			post_page("/galaktik.php", { action = "curehp", pwd = get_pwd(), quantity = maxhp() - hp() })
			if hp() < maxhp() then
				stop("Failed to reach full HP using galaktik")
			end
		end
	end

	local buffs = {
		["Go Get 'Em, Tiger!"] = function()
			buy_item("Ben-Gal&trade; Balm", "m", 5)
			return use_item("Ben-Gal&trade; Balm", 5)
		end,
		["Glittering Eyelashes"] = function()
			buy_item("glittery mascara", "m", 5)
			return use_item("glittery mascara", 5)
		end,
		["Butt-Rock Hair"] = function()
			buy_item("hair spray", "m", 5)
			return use_item("hair spray", 5)
		end,
		["Heavy Petting"] = function()
			if not have_item("Knob Goblin pet-buffing spray") then
				buy_item("Knob Goblin pet-buffing spray", "k", 1)
			end
			return use_item("Knob Goblin pet-buffing spray")
		end,
		["Peeled Eyeballs"] = function()
			if not have_item("Knob Goblin eyedrops") then
				buy_item("Knob Goblin eyedrops", "k", 1)
			end
			return use_item("Knob Goblin eyedrops")
		end,
		["Sugar Rush"] = function()
			-- TODO: only try summoning once per day
			local f = cast_skillid(53) -- summon crimbo candy
			local candies = { "Angry Farmer candy", "Crimbo fudge", "Crimbo peppermint bark", "Crimbo candied pecan" }
			for _, x in ipairs(candies) do
				if have_item(x) then
					return use_item(x)
				end
			end
			return f
		end,
		["Hippy Stench"] = function()
			return use_item("handful of pine needles")
		end,
		["Fresh Scent"] = function()
			return use_item("chunk of rock salt")
		end,
		["Starry-Eyed"] = function()
			return async_post_page("/campground.php", { action = "telescopehigh" })
		end,
		["Brother Flying Burrito's Blessing"] = function()
			return async_post_page("/friars.php", { pwd = get_pwd(), action = "buffs", bro = 1 })
		end,
		["Brother Corsican's Blessing"] = function()
			return async_post_page("/friars.php", { pwd = get_pwd(), action = "buffs", bro = 2 })
		end,
		["Brother Smothers's Blessing"] = function()
			return async_post_page("/friars.php", { pwd = get_pwd(), action = "buffs", bro = 3 })
		end,
		["Billiards Belligerence"] = function()
			return async_get_page("/clan_viplounge.php", { preaction = "poolgame", stance = 1 })
		end,
		["Mental A-cue-ity"] = function()
			return async_get_page("/clan_viplounge.php", { preaction = "poolgame", stance = 2 })
		end,
		["Hustlin'"] = function()
			return async_get_page("/clan_viplounge.php", { preaction = "poolgame", stance = 3 })
		end,
		["Silent Running"] = function()
			return async_post_page("/clan_viplounge.php", { preaction = "goswimming", subaction = "submarine" })
		end,
		["Lapdog"] = function()
			return async_post_page("/clan_viplounge.php", { preaction = "goswimming", subaction = "laps" })
		end,
		["Pisces in the Skyces"] = function()
			if not have_item("tobiko marble soda") then
				script.ensure_mp(5)
				set_result(cast_skill("Summon Alice's Army Cards"))
				get_page("/place.php", { whichplace = "forestvillage" })
				get_page("/gamestore.php")
				get_page("/gamestore.php", { place = "cashier" })
				async_post_page("/gamestore.php", { action = "buysnack", whichsnack = get_itemid("tobiko marble soda") })
			end
			return use_item("tobiko marble soda")
		end,
		["Cat-Alyzed"] = function()
			if cached_stuff.used_hatter_buff_today then return end
			local pt, pturl
			if not have_buff("Down the Rabbit Hole") then
				async_get_page("/clan_viplounge.php", { action = "lookingglass" })
				pt, pturl = use_item("&quot;DRINK ME&quot; potion")()
			end
			local previous_hat = equipment().hat
			if not have_item("snorkel") then
				buy_item("snorkel", "z")
			end
			equip_item("snorkel")
			if equipment().hat == get_itemid("snorkel") then
				async_get_page("/rabbithole.php", { action = "teaparty" })
				pt, pturl = post_page("/choice.php", { pwd = get_pwd(), whichchoice = "441", option = "1" }) -- get hatter buff
				cached_stuff.used_hatter_buff_today = true
			end
			equip_item(previous_hat)
			return function() return pt, pturl end
		end,
		["Red Door Syndrome"] = function()
			if not have_item("can of black paint") then
				shop_buyitem("can of black paint", "blackmarket")
			end
			return use_item("can of black paint")
		end,
	}
	local spells = {
		["Ghostly Shell"] = { item = "totem" },
		["Empathy"] = { item = "totem" },
		["Astral Shell"] = { item = "totem" },
		["Curiosity of Br'er Tarrypin"] = { item = "totem" },
		["Elemental Saucesphere"] = { item = "saucepan" },
		["Jalape&ntilde;o Saucesphere"] = { item = "saucepan" },
		["Scarysauce"] = { item = "saucepan" },

		["The Moxious Madrigal"] = { effectid = 61 },
		["Polka of Plenty"] = { effectid = 63 },
		["The Magical Mojomuscular Melody"] = { effectid = 64 },
		["Power Ballad of the Arrowsmith"] = { effectid = 65 },
		["Fat Leon's Phat Loot Lyric"] = { effectid = 67 },
		["Ode to Booze"] = { effectid = 71 },
		["The Sonata of Sneakiness"] = { effectid = 162, shrug_first = "Carlweather's Cantata of Confrontation" },
		["Carlweather's Cantata of Confrontation"] = { effectid = 163, shrug_first = "The Sonata of Sneakiness" },
		["Ur-Kel's Aria of Annoyance"] = { effectid = 164 },

		["Pep Talk"] = { skillid = 11005, mpcost = 1 },
	}

	function f.shrug_buff(buffname)
		if have_buff(buffname) then
			print("  shrugging buff", buffname, spells[buffname].effectid)
			async_get_page("/charsheet.php", { pwd = get_pwd(), ajax = 1, action = "unbuff", whichbuff = spells[buffname].effectid })
			if have_buff(buffname) then
				critical("Failed to shrug buff: " .. buffname)
			end
		end
	end

	local shrug_buff = f.shrug_buff

	for name, skillname in pairs(datafile("buff recast skills")) do
		local data = datafile("skills")[skillname]
		buffs[name] = function()
			if show_spammy_automation_events then
				infoline("casting buff", name, "[current mp: " .. mp() .. "]")
			end
			if spells[name] and spells[name].shrug_first then
				shrug_buff(spells[name].shrug_first)
			end
			ensure_mp(data.mpcost)
			return cast_skill(skillname)
		end
	end

	do
		local duplicates = {}
		local effect_items = {}
		for name, d in pairs(datafile("items")) do
			if d.use_effect then
				duplicates[d.use_effect] = effect_items[d.use_effect]
				effect_items[d.use_effect] = name
			end
		end
		for x, _ in pairs(duplicates) do
			effect_items[x] = nil
		end
		for effect, item in pairs(effect_items) do
			if not buffs[effect] then
				buffs[effect] = function()
					return use_item(item)
				end
			end
		end
	end

	for _, name in pairs { "Pep Talk" } do
		local data = spells[name]
		buffs[name] = function()
			if show_spammy_automation_events then
				infoline("casting buff", name, "[current mp: " .. mp() .. "]")
			end
			if spells[name] and spells[name].shrug_first then
				shrug_buff(spells[name].shrug_first)
			end
			ensure_mp(data.mpcost)
			return cast_skillid(data.skillid)
		end
	end

	function f.cast_buff(buffname)
--		print("DEBUG castbuff", buffname)
		if buffs[buffname] then
			return buffs[buffname]()
		else
			error("Trying to cast unknown buff: " .. buffname)
		end
	end

	function f.ensure_buffs(xs, ok_to_fail, even_in_fist)
		local ignore_failure = {
			["Heavy Petting"] = true,
			["Peeled Eyeballs"] = true,
			["Silent Running"] = true,
		}
		if ascensionpath("Avatar of Boris") and not ignore_buffing_and_outfit then
			if want_bonus.boris_song then
				table.insert(xs, want_bonus.boris_song)
			end
			if want_bonus.clancy_item and have_item(want_bonus.clancy_item) then
				use_item(want_bonus.clancy_item)
			end
		elseif ascensionpath("Avatar of Jarlsberg") and not ignore_buffing_and_outfit then
			if want_bonus.jarlsberg_sphere and have_skill(want_bonus.jarlsberg_sphere) then
				table.insert(xs, want_bonus.jarlsberg_sphere)
			end
		end
		if not even_in_fist and not ignore_buffing_and_outfit then
			if want_bonus.plusitems then
				table.insert(xs, "Fat Leon's Phat Loot Lyric")
				table.insert(xs, "Leash of Linguini")
				table.insert(xs, "Empathy")
				table.insert(xs, "Singer's Faithful Ocelot")
				if want_bonus.extraplusitems then
					if can_change_familiar() then
						table.insert(xs, "Heavy Petting")
					end
					table.insert(xs, "Peeled Eyeballs")
				end
			elseif level() <= 4 then
				table.insert(xs, "The Moxious Madrigal")
				table.insert(xs, "The Magical Mojomuscular Melody")
			end
			if maxmp() >= 30 and (want_bonus.plusitems or want_bonus.minoritem) then
				table.insert(xs, "Of Course It Looks Great")
			end
			if want_bonus.plusinitiative then
				table.insert(xs, "Living Fast")
			end
			if want_bonus.noncombat then
				table.insert(xs, "Brooding")
				if sneaky_pete_motorcycle_upgrades()["Muffler"] == "Extra-Quiet Muffler" then
					table.insert(xs, "Muffled")
				end
			end
			if want_bonus.extranoncombat then
				table.insert(xs, "Silent Running")
				if have_item("pile of ashes") then
					table.insert(xs, "Ashen")
				end
			end
			if want_bonus.combat then
				if sneaky_pete_motorcycle_upgrades()["Muffler"] == "Extra-Loud Muffler" then
					table.insert(xs, "Unmuffled")
				end
			end
			if mainstat_type("Mysticality") and level() >= 6 then
				table.insert(xs, "A Few Extra Pounds")
			end
			if level() >= 6 then
				table.insert(xs, "Leash of Linguini")
				if meat() >= 7000 then
					table.insert(xs, "Empathy")
				end
			end
			if ((mainstat_type("Mysticality") and level() >= 9) or (level() >= 11) or (highskill_at_run and mmj_available)) and level() < 13 and challenge ~= "fist" then
				table.insert(xs, "Ur-Kel's Aria of Annoyance")
			end
		end
		if challenge == "fist" and not even_in_fist then
			local function tabledel(t)
				for x, y in pairs(t) do
					-- TODO: do more generally?
					if (spells[y] and spells[y].item) or y == "Heavy Petting" or y == "Peeled Eyeballs" or y == "A Few Extra Pounds" or y == "Butt-Rock Hair" or y == "Red Door Syndrome" then
						table.remove(t, x)
						return tabledel(t)
					end
				end
				return t
			end
			xs = tabledel(xs)
			if fist_level >= 3 then
				table.insert(xs, "Salamanderenity")
			end
		end
		if not cached_stuff.kgs_available or meat() < 2000 then
			local function tabledel(t)
				for x, y in pairs(t) do
					-- TODO: do more generally?
					if y == "Heavy Petting" or y == "Peeled Eyeballs" then
						table.remove(t, x)
						return tabledel(t)
					end
				end
				return t
			end
			xs = tabledel(xs)
		end
		local want_buffs = {}
		for x in table.values(xs) do
			want_buffs[x] = true
		end
		local at_shruggable = {
			"Ode to Booze",
			"Polka of Plenty",
			"Carlweather's Cantata of Confrontation",
			"The Sonata of Sneakiness",
			"The Moxious Madrigal",
			"The Magical Mojomuscular Melody",
			"Fat Leon's Phat Loot Lyric",
		}
		if want_bonus.monster_level then
			if mcd() < 10 then
				set_mcd(10) -- HACK: don't want this to be done here!
			end
			table.insert(xs, "Pride of the Puffin")
			table.insert(xs, "Ur-Kel's Aria of Annoyance")
		elseif level() >= 13 and have_buff("Ur-Kel's Aria of Annoyance") and not want_buffs["Ur-Kel's Aria of Annoyance"] then
			shrug_buff("Ur-Kel's Aria of Annoyance")
			set_mcd(0) -- HACK: don't want this to be done here!
		end
		if have_item("Flaskfull of Hollow") and buffturns("Merry Smithsness") < 10 and not ascensionstatus("Aftercore") then
			use_item("Flaskfull of Hollow")
		end
		if playerclass("Pastamancer") and maxmp() >= 12 and pastathrallid() == 0 and have_skill("Bind Vampieroghi") then
			script.ensure_mp(12)
			cast_skill("Bind Vampieroghi")
		end
		local function try_casting_buff(buffname, try_shrugging)
			if buffs[buffname] then
				local pt = f.cast_buff(buffname)()
				if not have_buff(buffname) and not have_intrinsic(buffname) then
					if pt:contains("can't fit") and pt:contains("songs in your head") and try_shrugging then
						for _, atname in ipairs(at_shruggable) do
							if have_buff(atname) and not want_buffs[atname] then
								shrug_buff(atname)
								return try_casting_buff(buffname, false)
							end
						end
						critical("Too many AT songs to cast buff: " .. buffname)
					elseif pt:contains("can't use that skill") and ascensionpath("Way of the Surprising Fist") and AT_song_duration() == 0 then
						return
					elseif not ok_to_fail and not ignore_failure[buffname] then
						critical("Failed to ensure buff: " .. buffname)
					end
				end
			else
				error("Trying to ensure unknown buff: " .. buffname)
			end
		end
		local ignore_buffs = get_ascension_automation_settings().ignore_buffs
		for _, x in ipairs(xs) do
			if not have_buff(x) and not have_intrinsic(x) and not ignore_buffs[x] then
				try_casting_buff(x, true)
			end
			if have_buff(x) and (x == "A Few Extra Pounds" or x == "The Magical Mojomuscular Melody") and buffturns(x) < 2 then
				-- TODO: do this more generally than matching on name for buffs to be extended?
				try_casting_buff(x, false)
-- 				print("bumped", x, have_buff(x))
			end
		end
	end

	function f.ensure_buff_turns(buff, duration)
		f.ensure_buffs { buff }
		local turns = buffturns(buff)
		if turns > 0 and turns < duration then
			f.cast_buff(buff)
			if buffturns(buff) <= turns then
				critical("Failed to cast " .. buff)
			end
			f.ensure_buff_turns(buff, duration)
		end
	end

	local ensure_buffs = f.ensure_buffs
	function f.maybe_ensure_buffs(xs)
		ensure_buffs(xs, true)
	end
	local maybe_ensure_buffs = f.maybe_ensure_buffs
	function f.maybe_ensure_buffs_in_fist(xs)
		ensure_buffs(xs, true, true)
	end
	local maybe_ensure_buffs_in_fist = f.maybe_ensure_buffs_in_fist

	local wear_slots = { "hat", "container", "shirt", "weapon", "offhand", "pants", "acc1", "acc2", "acc3" }

	function f.unequip_if_worn(itemname)
		for _, s in ipairs(wear_slots) do
			if equipment()[s] == get_itemid(itemname) then
				unequip_slot(s)
			end
		end
	end

	function f.fold_item(itemname)
		if have_item(itemname) then return end
		local fold_orders = {
			{ "stinky cheese diaper", "stinky cheese wheel", "stinky cheese eye", "Staff of Queso Escusado", "stinky cheese sword" },
		}
		local fold_targeted = {
			{ "Loathing Legion abacus", "Loathing Legion can opener", "Loathing Legion chainsaw", "Loathing Legion corkscrew", "Loathing Legion defibrillator", "Loathing Legion double prism", "Loathing Legion electric knife", "Loathing Legion hammer", "Loathing Legion helicopter", "Loathing Legion jackhammer", "Loathing Legion kitchen sink", "Loathing Legion knife", "Loathing Legion many-purpose hook", "Loathing Legion moondial", "Loathing Legion necktie", "Loathing Legion pizza stone", "Loathing Legion rollerblades", "Loathing Legion tape measure", "Loathing Legion tattoo needle", "Loathing Legion universal screwdriver" }
		}
		for _, xs in ipairs(fold_orders) do
			for _, x in ipairs(xs) do
				if x == itemname then
					for _, y in ipairs(xs) do
						if have_item(y) then
							f.unequip_if_worn(y)
							if have_item(itemname) then return end
							use_item(y)
							f.heal_up()
						end
					end
					for _, y in ipairs(xs) do
						if have_item(y) then
							f.unequip_if_worn(y)
							if have_item(itemname) then return end
							use_item(y)
							f.heal_up()
						end
					end
				end
			end
		end
		for _, xs in ipairs(fold_targeted) do
			for _, x in ipairs(xs) do
				if x == itemname then
					for _, y in ipairs(xs) do
						if have_item(y) then
							f.unequip_if_worn(y)
							async_get_page("/inv_use.php", { whichitem = get_itemid(y), switch = 1, fold = itemname, pwd = get_pwd() })
						end
					end
				end
			end
		end

		local fold_twisthorns = { "Boris's Helm", "Boris's Helm (askew)" }
		for _, x in ipairs(fold_twisthorns) do
			if x == itemname then
				for _, y in ipairs(fold_twisthorns) do
					if have_equipped_item(y) then
						get_page("/inventory.php", { action = "twisthorns", slot = "hat", pwd = session.pwd })
						if have_item(itemname) then return end
					elseif have_item(y) then
						use_item(y)
						if have_item(itemname) then return end
					end
				end
			end
		end

		local fold_popcollar = { "Sneaky Pete's leather jacket", "Sneaky Pete's leather jacket (collar popped)" }
		for _, x in ipairs(fold_popcollar) do
			if x == itemname then
				for _, y in ipairs(fold_popcollar) do
					if have_equipped_item(y) then
						get_page("/inventory.php", { action = "popcollar", slot = "shirt", pwd = session.pwd })
						if have_item(itemname) then return end
					elseif have_item(y) then
						use_item(y)
						if have_item(itemname) then return end
					end
				end
			end
		end
	end

	function f.wear(tbl)
		if want_bonus.plusinitiative then
			f.fold_item("Loathing Legion rollerblades")
		elseif want_bonus.rollover_adventures then
			f.fold_item("Loathing Legion moondial")
		elseif level() < 13 then
			f.fold_item("Loathing Legion necktie")
		end

		if want_bonus.plusitems then
			f.fold_item("stinky cheese eye")
		elseif not tbl.pants then
			f.fold_item("stinky cheese diaper")
		end

		if want_bonus.easy_combat then
			f.fold_item("Boris's Helm")
		elseif want_bonus.monster_level then
			f.fold_item("Boris's Helm (askew)")
		end

		if want_bonus.rollover_adventures or want_bonus.easy_combat then
			f.fold_item("Sneaky Pete's leather jacket")
		elseif want_bonus.monster_level then
			f.fold_item("Sneaky Pete's leather jacket (collar popped)")
		end

		if not tbl.pants and want_bonus.runawayfrom and have_item("Greatest American Pants") and get_daily_counter("item.fly away.free runaways") < 9 then
			tbl.pants = "Greatest American Pants"
		end

		local settingstbl = get_ascension_automation_settings(want_bonus)
		local defaults, canwear_itemname = settingstbl.default_equipment, settingstbl.canwear_itemname
		defaults.acc1 = defaults.accessories
		defaults.acc2 = defaults.accessories
		defaults.acc3 = defaults.accessories
		local neweq = {}

		if have_buff("Super Structure") and not tbl.pants then
			tbl.pants = "Greatest American Pants"
		end
		if have_buff("Super Speed") and not tbl.pants then
			tbl.pants = "Greatest American Pants"
		end
		if have_buff("Super Vision") and not tbl.pants then
			tbl.pants = "Greatest American Pants"
		end

		local do_not_wear = {}

		local halos = { ["frosty halo"] = true, ["furry halo"] = true, ["shining halo"] = true, ["time halo"] = true }

		local ignore_slots = {}

		for a, b in pairs(tbl) do
			if b ~= "empty" then
				neweq[a] = get_itemid(b)
				do_not_wear[b] = true
				if halos[b] or a == "weapon" or a == "offhand" then
					for h in pairs(halos) do
						do_not_wear[h] = true
					end
				end
				if halos[b] then
					ignore_slots.weapon = true
					ignore_slots.offhand = true
				end
			end
		end

		for _, a in ipairs(wear_slots) do
			if not tbl[a] and not neweq[a] and not ignore_slots[a] then
				for _, x in ipairs(defaults[a] or {}) do
					local itemname = canwear_itemname(x)
					if itemname and a == "weapon" and tbl.offhand and is_twohanded_weapon(itemname) then
					elseif itemname and not do_not_wear[itemname] then
						neweq[a] = get_itemid(itemname)
						do_not_wear[itemname] = true
						if halos[itemname] or a == "weapon" or a == "offhand" then
							for h in pairs(halos) do
								do_not_wear[h] = true
							end
						end
						break
					end
				end
			end
		end

		if neweq.weapon and is_twohanded_weapon(neweq.weapon) then
			neweq.offhand = nil
		end

		neweq = reuse_equipment_slots(neweq)
--		print("DEBUG: setting equipment: ", table_to_str(neweq))
		set_equipment(neweq)
	end

	local wear = f.wear

	function f.check_sr()
		-- Commented out warning when something strange happens.
		-- Semirares automation sometimes gets screwed up when previous ones are missed, but just continue the ascension instead of requiring manual intervention
		-- TODO: Handle?
		-- TODO: just finish fights that happen when an SR was attempted?
		turns_to_next_sr = nil
		for a, b in pairs(ascension["fortune cookie numbers"] or {}) do
			if turnsthisrun() == tonumber(b) then
				print "  checking for SR"

				local ls = ascension["last semirare"] or {}
				local lastsemi = ls.encounter
				local lastturn = ls.turn

				if (turnsthisrun() < 70) or (lastturn and lastturn + 159 > turnsthisrun()) then
					print("  skipping impossible SR", b, turnsthisrun(), "last", lastsemi, lastturn)
				else
					if challenge == "boris" then
						if daysthisrun() == 1 and ascensionstatus() ~= "Hardcore" and not lastsemi and count_item("Moon Pie") >= 2 and count_item("milk of magnesium") >= 1 and have_item("Wrecked Generator") and not have_item("tasty tart") then
							inform "Pick up boris SR, make it tarts"
							result, resulturl, advagain = autoadventure { zoneid = 113, ignorewarnings = true }
							did_action = count_item("tasty tart") >= 3
							return result, resulturl, did_action
						elseif daysthisrun() == 2 and ascensionstatus() and ascensionstatus() ~= "Hardcore" and lastsemi == "Bad ASCII Art" and fullness() == estimate_max_fullness() then
							local got_scrolls = false
							if level() >= 9 and not quest("A Quest, LOL") then
								got_scrolls = true
							elseif count_item("334 scroll") >= 2 and have_item("30669 scroll") and have_item("33398 scroll") then
								got_scrolls = true
							end
							if got_scrolls then
								inform "Pick up boris SR, make it baabaaburan"
								script.bonus_target { "item" }
								script.ensure_buffs {}
								script.wear {}
								result, resulturl, advagain = autoadventure { zoneid = 280, ignorewarnings = true, macro = [[
if (monstername baa'baa'bu'ran)

]] .. macro_softcore_boris() .. [[

endif

]]}
								did_action = count_item("stone wool") >= 2
								return result, resulturl, did_action
							end
						end
						script.bonus_target { "item" }
						script.ensure_buffs {}
						script.wear {}
						stop "Pick up semirare in Boris"
					end
					if lastturn and lastturn + 250 < turnsthisrun() then
-- 						critical "Last semirare was a long time ago"
						return
					end
					print("pick up SR, last semi", lastsemi, lastturn)
					wear {}
					if (not lastsemi and not lastturn and turnsthisrun() < 85) or (lastsemi ~= "In the Still of the Alley") then
						inform "Pick up SR, make it wines"
						result, resulturl, advagain = autoadventure { zoneid = 112, ignorewarnings = true }
						if get_result():contains("In the Still of the Alley") then
							if not highskill_at_run then
								buy_item("fortune cookie", "m")
								local old_full = fullness()
								set_result(eat_item("fortune cookie"))
								did_action = (fullness() == old_full + 1) or (old_full == estimate_max_fullness())
							else
								did_action = true
							end
						else
							result = add_message_to_page(get_result(), "Tried to pick up wine semirare", nil, "darkorange")
						end
						return result, resulturl, did_action
					else
						inform "Pick up SR, make it lunchbox"
						result, resulturl, advagain = autoadventure { zoneid = 114, ignorewarnings = true }
						if get_result():contains("Lunchboxing") then
							if not highskill_at_run then
								buy_item("fortune cookie", "m")
								local old_full = fullness()
								set_result(eat_item("fortune cookie"))
								did_action = (fullness() == old_full + 1) or (old_full == estimate_max_fullness())
							else
								did_action = true
							end
						else
							result = add_message_to_page(get_result(), "Tried to pick up lunchbox semirare", nil, "darkorange")
						end
						return result, resulturl, did_action
					end
				end
			elseif tonumber(b) >= turnsthisrun() then
				local turns = tonumber(b) - turnsthisrun()
				if (not turns_to_next_sr) or (turns < turns_to_next_sr) then
					turns_to_next_sr = turns
				end
			end
		end
-- 		do
-- 			local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info(turnsthisrun())
-- 			if #good_numbers == 0 and turnsthisrun() < 700 then
-- 				if SRmin and SRmin <= 10 then
-- 					critical "Semirare soon, without fortune cookie numbers"
-- 				end
-- 			end
-- 		end
-- 		if not have_numbers then
-- 			if have_item(want_itemname) and not ascension["fortune cookie numbers"] then
-- 				buy_item("fortune cookie", "m")
-- 				if not have_item("fortune cookie") then
-- 					critical("Failed to buy a fortune cookie")
-- 				end
-- 				eat_item("fortune cookie")
-- 				eat_item(want_itemname)
-- 				if not ascension["fortune cookie numbers"] then
-- 					critical("Failed to get fortune cookie numbers set")
-- 				end
-- 			end
-- 		end
		return turns_to_next_sr
	end

	function f.go(info, zoneid, macro, noncombattbl, buffslist, famname, minmp, extra)
		--print("DEBUG: go()", info, famname, minmp)
		local specialnoncombatfunction = nil
		local towear = {}
		local finalcheckfunc = nil
		if extra then
			if extra.olfact and have_skill("Transcendent Olfaction") then
				if not trailed then
					minmp = minmp + 40
				elseif trailed ~= extra.olfact then
					stop("Trailing " .. trailed .. " when trying to olfact " .. extra.olfact)
				end
			end
			extra.olfact = nil
			if extra.choice_function then
				specialnoncombatfunction = extra.choice_function
				extra.choice_function = nil
			end
			if extra.equipment then
				towear = extra.equipment
				extra.equipment = nil
			end
			if extra.finalcheck then
				finalcheckfunc = extra.finalcheck
				extra.finalcheck = nil
			end
			unhandled = false
			for a, b in pairs(extra) do
				print("extra." .. a .. " = " .. tostring(b) .. " unhandled!")
				unhandled = "extra." .. a .. " = " .. tostring(b)
			end
			if unhandled then
				error("Unhandled go() parameter: " .. unhandled)
			end
		end
		if mcd() < 10 and level() < 13 and have_item("detuned radio") and not want_bonus.easy_combat then
			set_mcd(10)
		elseif mcd() ~= 0 and level() == 13 and have_item("detuned radio") then
			set_mcd(0)
		end
		if arrowed_possible and minmp < 60 then
			minmp = 60
		end
		inform(info)
		ensure_buffs(buffslist)
		local famt = fam(famname)
		local fammpregen, famequip = famt.mpregen, famt.familiarequip
		if fammpregen then
			if challenge then
				f.burn_mp(minmp + 40)
			else
				f.burn_mp(minmp + 20)
			end
		end
		if towear.familiarequip == "sugar shield" and not have_item("sugar shield") then
			towear.familiarequip = nil
		end
		if famequip and not towear.familiarequip and have_item(famequip) then
			towear.familiarequip = famequip
		elseif (famequip == "spangly sombrero" or famequip == "spangly mariachi pants") and have_item(famequip) then -- TODO: hackish for spanglerack
			towear.familiarequip = famequip
		end
		if not towear.familiarequip and have_item("astral pet sweater") then
			towear.familiarequip = "astral pet sweater"
		end
		script.wear(towear)
		script.heal_up()
		if mp() < minmp then
			infoline("ensuring " .. minmp .. " MP to fight")
		end
		script.ensure_mp(minmp)
		if finalcheckfunc then
			finalcheckfunc()
		end
		result, resulturl, advagain = autoadventure { zoneid = zoneid, macro = macro, noncombatchoices = noncombattbl, specialnoncombatfunction = specialnoncombatfunction, ignorewarnings = true }
		did_action = advagain
		return result, resulturl, advagain
	end

	local go = f.go

	function f.coffee_pixie_stick()
		inform "using coffee pixie stick"
		async_get_page("/town_wrong.php")
		async_get_page("/arcade.php", { action = "skeeball", pwd = get_pwd() })
		async_post_page("/arcade.php", { action = "redeem", whichitem = tostring(get_itemid("coffee pixie stick")), quantity = 1 })
		if have_item("coffee pixie stick") then
			local a = advs()
			set_result(use_item("coffee pixie stick"))
			if advs() > a then
				did_action = true
				return result, resulturl, did_action
			else
				critical "Tried to use pixie stick but didn't gain any adventures"
			end
		else
			critical "Didn't get coffee pixie stick"
		end
	end

	function f.finger_cuffs()
		inform "buying finger cuffs"
		async_get_page("/town_wrong.php")
		async_get_page("/arcade.php", { action = "skeeball", pwd = get_pwd() })
		result, resulturl = post_page("/arcade.php", { action = "redeem", whichitem = get_itemid("finger cuffs"), quantity = 10 })
		if count_item("finger cuffs") >= 10 then
			did_action = true
			return result, resulturl, did_action
		else
			critical "Didn't get finger cuffs"
		end
	end

	function f.ensure_worthless_item()
		if not (have_item("worthless trinket") or have_item("worthless gewgaw") or have_item("worthless knick-knack")) then
			print "  getting worthless item"
			if not have_item("chewing gum on a string") then
				buy_item("chewing gum on a string", "m")
			end
			result, resulturl = use_item("chewing gum on a string")()
			if get_result():match("You acquire") then
				f.ensure_worthless_item()
			else
				critical "Failed to use chewing gum"
			end
		end
		return result, resulturl, did_action
	end

	function f.make_reagent_pasta()
		if count_item("dry noodles") < 1 and have_skill("Pastamastery") and level() >= 4 and maxmp() >= 15 then
			ensure_mp(10)
			cast_skill("Pastamastery") -- pastamastery
		end
		if count_item("scrumptious reagent") < 1 and have_skill("Advanced Saucecrafting") and level() >= 4 and maxmp() >= 15 then
			ensure_mp(10)
			cast_skill("Advanced Saucecrafting") -- advanced saucecrafting
		end
		if have_item("Hell broth") and have_item("dry noodles") then
			inform "make hell ramen"
			set_result(cook_items("Hell broth", "dry noodles"))
			did_action = get_result():contains("Hell ramen")
		elseif have_item("fancy schmancy cheese sauce") and have_item("dry noodles") then
			inform "make fettucini inconnu"
			set_result(cook_items("fancy schmancy cheese sauce", "dry noodles"))
			did_action = get_result():contains("fettucini Inconnu")
		elseif have_item("hellion cube") and have_item("scrumptious reagent") and have_item("dry noodles") and have_skill("Advanced Saucecrafting") then
			inform "make hell broth"
			set_result(cook_items("hellion cube", "scrumptious reagent"))
			did_action = get_result():contains("Hell broth")
		elseif have_item("goat cheese") and have_item("scrumptious reagent") and have_item("dry noodles") and have_skill("Advanced Saucecrafting") then
			inform "make cheese sauce"
			set_result(cook_items("goat cheese", "scrumptious reagent"))
			did_action = get_result():contains("fancy schmancy cheese sauce")
		elseif not have_skill("Advanced Saucecrafting") and have_item("dry noodles") then
			inform "make painful penne pasta"
			script.ensure_worthless_item()
			if not have_item("jaba&ntilde;ero pepper") then
				buy_hermit_item("jaba&ntilde;ero pepper")
			end
			set_result(cook_items("jaba&ntilde;ero pepper", "dry noodles"))
			did_action = get_result():contains("painful penne pasta")
		end
		return result, resulturl, did_action
	end

	function f.get_turns_until_sr()
		local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info(turnsthisrun())
		--print("DEBUG get_turns_until_sr", get_semirare_info(turnsthisrun()))
		if good_numbers[1] then
			return good_numbers[1]
		end
		if SRmin and SRmin < 0 and all_numbers[1] then
			return all_numbers[1]
		end
	end

	function f.eat_food(out_of_advs)
		if ascension_script_option("eat manually") then return end
		if challenge == "fist" then return end
		if challenge == "boris" then return end
		if challenge == "zombie" then return end
		if challenge == "jarlsberg" then
			if fullness() == estimate_max_fullness() then
				return
			elseif estimate_max_fullness() == 15 and fullness() == 0 and have_skill("Conjure Meat Product") and have_skill("Slice") and have_skill("Conjure Cheese") and have_skill("Fry") then
				if count_item("Ultimate Breakfast Sandwich") >= 2 and count_item("consummate sauerkraut") >= 1 then
					if not have_skill("The Most Important Meal") then
						return
					end
					if not ascensionstatus("Hardcore") then
						pull_in_softcore("milk of magnesium")
						script.ensure_buffs { "Got Milk" }
					end
					eat_item("Ultimate Breakfast Sandwich")
					eat_item("Ultimate Breakfast Sandwich")
					eat_item("consummate sauerkraut")
					if fullness() == 15 then
						return f.eat_food()
					else
						critical "Failed to eat food"
					end
				elseif count_item("cosmic egg") >= 2 and count_item("cosmic potted meat product") >= 2 and count_item("cosmic cheese") >= 2 and count_item("cosmic dough") >= 2 and count_item("cosmic vegetable") >= 1 and cached_stuff.summoned_jarlsberg_ingredients then
					craft_cosmic_kitchen { pwd = session.pwd, ["Ultimate Breakfast Sandwich"] = 2, ["consummate sauerkraut"] = 1 }
					shop_buyitem({ ["Staff of Fruit Salad"] = 1, ["Staff of the Healthy Breakfast"] = 1, ["Staff of the Hearty Dinner"] = 1, ["Staff of the Light Lunch"] = 1, ["Staff of the All-Steak"] = 1, ["Staff of the Cream of the Cream"] = 1, ["Staff of the Staff of Life"] = 1, ["Staff of the Standalone Cheese"] = 1 }, "jarl")
					if count_item("Ultimate Breakfast Sandwich") >= 2 and count_item("consummate sauerkraut") >= 1 then
						return f.eat_food()
					else
						critical "Failed to cook food"
					end
				elseif have_skill("Food Coma") then
					if maxmp() < 30 then
						if not have_item("Bright Water") then
							script.ensure_mp(2)
							async_post_page("/campground.php", { preaction = "summoncliparts" })
							async_post_page("/campground.php", { pwd = get_pwd(), action = "bookshelf", preaction = "combinecliparts", clip1 = "06", clip2 = "06", clip3 = "04" })
						end
						use_item("Bright Water")
					end
					if maxmp() < 30 then
						stop "TODO: Buff maxmp (use +100 from clip art?)"
					end
					local function r()
						if mp() < 30 then
							get_page("/campground.php", { action = "rest" })
						end
					end
					r() cast_skill("Conjure Meat Product")
					r() cast_skill("Conjure Cheese")
					r() cast_skill("Conjure Dough")
					r() cast_skill("Conjure Potato")
					r() cast_skill("Conjure Vegetables")
					r() cast_skill("Conjure Eggs")
					if level() <= 3 then
						r() cast_skill("Hippotatomous")
					else
						r() cast_skill("Egg Man")
					end
					r() cast_skill("Conjure Cream")
					r() cast_skill("Conjure Fruit")
					cached_stuff.summoned_jarlsberg_ingredients = true
					if count_item("cosmic egg") >= 2 and count_item("cosmic potted meat product") >= 2 and count_item("cosmic cheese") >= 2 and count_item("cosmic dough") >= 2 and count_item("cosmic vegetable") >= 1 then
						return f.eat_food()
					else
						critical "Failed to conjure cosmic ingredients"
					end
				else
					stop "TODO: Conjure cosmic ingredients"
				end
			elseif cached_stuff.trained_jarlsberg_skills_level == level() then
				stop "TODO: Eat food in jarlsberg"
			end
			return
		end

		local function space()
			return estimate_max_fullness() - fullness()
		end

		if highskill_at_run then return end

		local function eat_fortune_cookie()
			local f = fullness()
			inform "eat fortune cookie"
			buy_item("fortune cookie", "m")
			set_result(eat_item("fortune cookie")())
			if not (fullness() == f + 1 and script.get_turns_until_sr() ~= nil) then
				print("WARNING fortune cookie result:", script.get_turns_until_sr())
				critical "Error getting fortune cookie numbers"
			end
			did_action = (fullness() == f + 1 and script.get_turns_until_sr() ~= nil)
			return result, resulturl, did_action
		end

		local function pull_and_eat_key_lime_pie(which)
			local f = fullness()
			local keyname = which .. "'s key"
			local piename = which .. "'s key lime pie"
			inform("pull and eat " .. piename)
			pull_in_softcore(piename)
			set_result(eat_item(piename)())
			did_action = (fullness() == f + 4 and have_item(keyname))
			return result, resulturl, did_action
		end

		if ascensionpath("Avatar of Sneaky Pete") and not ascensionstatus("Hardcore") then
			if (space() % 4) > 0 and script.get_turns_until_sr() == nil and meat() >= 40 then
				return eat_fortune_cookie()
			elseif space() >= 4 and level() >= 6 then
				if not have_item("Jarlsberg's key") then
					return pull_and_eat_key_lime_pie("Jarlsberg")
				elseif not have_item("Boris's key") then
					return pull_and_eat_key_lime_pie("Boris")
				end
			end
		end

		if ascensionpath("Avatar of Sneaky Pete") and ascensionstatus("Hardcore") then
			if space() > 0 and script.get_turns_until_sr() == nil and meat() >= 40 then
				return eat_fortune_cookie()
			end
			return
		end

		if ascensionstatus() ~= "Hardcore" then return end

		if not can_eat_normal_food() then return end

		if space() > 0 then
			if (space() % 6) > 0 then
				local f = fullness()
				if script.get_turns_until_sr() == nil and meat() >= 40 then
					return eat_fortune_cookie()
				elseif have_item("Ur-Donut") and level() < 4 then
					inform "eat ur-donut"
					eat_item("Ur-Donut")
					did_action = (fullness() == f + 1)
					return result, resulturl, did_action
				elseif have_item("Knob pasty") then
					inform "eat knob pasty"
					eat_item("Knob pasty")
					did_action = (fullness() == f + 1)
					return result, resulturl, did_action
				elseif out_of_advs then
					if have_item("bag of QWOP") and get_remaining_hottub_uses() >= 2 then
						inform "eat bag of qwop"
						eat_item("bag of QWOP")
						if have_buff("QWOPped Up") and not is_cursed() then
							use_hottub()
						end
						did_action = (fullness() == f + 1)
						return result, resulturl, did_action
					elseif have_item("Knob nuts") then
						inform "eat knob nuts"
						eat_item("Knob nuts")
						did_action = (fullness() == f + 1)
						return result, resulturl, did_action
					elseif have_item("bag of GORF") then
						inform "eat knob bag of gorf"
						eat_item("bag of GORF")
						did_action = (fullness() == f + 1)
						return result, resulturl, did_action
					elseif meat() >= 40 then
						return eat_fortune_cookie()
					end
				end
			end
			if space() >= 3 and not have_skill("Advanced Saucecrafting") and advs() < 30 then
				if have_item("painful penne pasta") then
					inform "eat painful penne pasta"
					script.heal_up()
					local f = fullness()
					result, resulturl = eat_item("painful penne pasta")()
					did_action = (fullness() == f + 3)
					return result, resulturl, did_action
				elseif level() >= 3 and meat() >= 500 then
					return script.make_reagent_pasta()
				end
			end
			if space() >= 6 then
				local f = fullness()
				if count_item("Hell ramen") + count_item("fettucini Inconnu") >= 2 then
					if have_buff("Got Milk") then
						inform "eating reagent pasta with milk"
						eat_item("Hell ramen")
						eat_item("Hell ramen")
						eat_item("fettucini Inconnu")
						eat_item("fettucini Inconnu")
						did_action = (fullness() >= 12)
						return result, resulturl, did_action
					elseif have_item("milk of magnesium") then
						inform "using milk"
						set_result(use_item("milk of magnesium"))
						did_action = have_buff("Got Milk")
						return result, resulturl, did_action
					elseif have_item("glass of goat's milk") then
						inform "making milk"
						if count_item("scrumptious reagent") < 1 then
							ensure_mp(10)
							cast_skill("Advanced Saucecrafting")
						end
						cook_items("glass of goat's milk", "scrumptious reagent")
						did_action = have_item("milk of magnesium")
						return result, resulturl, did_action
					elseif advs() < 30 then
						inform "eating reagent pasta without milk"
						eat_item("Hell ramen")
						eat_item("Hell ramen")
						eat_item("fettucini Inconnu")
						eat_item("fettucini Inconnu")
						did_action = (fullness() >= 12)
						return result, resulturl, did_action
					end
				else
					return script.make_reagent_pasta()
				end
			end
		end
	end

	function f.drink_booze()
		if ascension_script_option("eat manually") then return end
		if challenge == "fist" then return end
		if challenge == "boris" then return end
		if challenge == "zombie" then return end
		if challenge == "jarlsberg" then
			if estimate_max_safe_drunkenness() == 19 and drunkenness() == 0 and have_skill("Blend") and have_skill("Freeze") and have_skill("Bake") and have_skill("Fry") then
				if count_item("Bologna Lambic") >= 2 and count_item("Chunky Mary") >= 2 and count_item("Nachojito") >= 1 and count_item("Le Roi") >= 1 and count_item("Over Easy Rider") >= 1 then
					drink_item("Bologna Lambic")
					drink_item("Bologna Lambic")
					drink_item("Chunky Mary")
					drink_item("Nachojito")
					drink_item("Le Roi")
					drink_item("Over Easy Rider")
					if drunkenness() == 19 then
						return f.drink_booze()
					else
						critical "Failed to drink booze"
					end
				elseif count_item("cosmic egg") >= 1 and count_item("cosmic fruit") >= 3 and count_item("cosmic potted meat product") >= 2 and count_item("cosmic potato") >= 3 and count_item("cosmic cheese") >= 1 and count_item("cosmic vegetable") >= 2 and count_item("cosmic dough") >= 2 then
					craft_cosmic_kitchen { pwd = session.pwd, ["Bologna Lambic"] = 2, ["Chunky Mary"] = 2, ["Nachojito"] = 1, ["Le Roi"] = 1, ["Over Easy Rider"] = 1 }
					if count_item("Bologna Lambic") >= 2 and count_item("Chunky Mary") >= 2 and count_item("Nachojito") >= 1 and count_item("Le Roi") >= 1 and count_item("Over Easy Rider") >= 1 then
						return f.drink_booze()
					else
						critical "Failed to mix booze"
					end
				end
			end
			return
		end

		if have_item("steel margarita") then
			drink_item("steel margarita")
		end

		if drunkenness() >= estimate_max_safe_drunkenness() then return end

		if ascensionpath("KOLHS") and meat() >= 3000 then
			if have_item("single swig of vodka") and drunkenness() + 2 <= estimate_max_safe_drunkenness() then
				script.ensure_buffs { "Ode to Booze" }
				drink_item("single swig of vodka")
			elseif have_item("bottle of fruity &quot;wine&quot;") and drunkenness() + 2 <= estimate_max_safe_drunkenness() then
				script.ensure_buffs { "Ode to Booze" }
				drink_item("bottle of fruity &quot;wine&quot;")
			elseif have_item("can of the cheapest beer") and drunkenness() + 1 <= estimate_max_safe_drunkenness() then
				script.ensure_buffs { "Ode to Booze" }
				drink_item("can of the cheapest beer")
			end
		end

		if ascensionstatus() ~= "Hardcore" then return end

		if not can_drink_normal_booze() then return end

		if advs() >= 20 then return end

		if ascensionpath("Avatar of Sneaky Pete") and ascensionstatus("Hardcore") then
			if not have_item("Ice Island Long Tea") and estimate_max_safe_drunkenness() - drunkenness() >= 4 and level() < 6 and count_item("snow berries") >= 1 and count_item("ice harvest") >= 3 then
				shop_buyitem("Ice Island Long Tea", "snowgarden")
			elseif level() >= 6 then
				--stop("TODO: craft SHCs")
			end
			if have_item("Ice Island Long Tea") then
				drink_item("Ice Island Long Tea")
			end
			return
		end

		for i = 1, 5 do
			if have_item("peppermint sprout") or have_item("peppermint twist") then
				for _, x in ipairs { "bottle of rum", "bottle of gin", "bottle of tequila", "bottle of vodka", "bottle of whiskey", "boxed wine" } do
					if have_item(x) then
						if not have_item("peppermint twist") then
							use_item("peppermint sprout")
						end
						local twists = count_item("peppermint twist")
						inform "mixing peppermint booze"
						set_result(mix_items(x, "peppermint twist"))

						if get_result():contains("Your cocktail set is not advanced enough") then
							if have_item("Queue Du Coq cocktailcrafting kit") then
								print "  using cocktailcrafting kit"
								set_result(use_item("Queue Du Coq cocktailcrafting kit"))
								did_action = not have_item("Queue Du Coq cocktailcrafting kit")
							else
								print "  buying cocktailcrafting kit"
								set_result(buy_item("Queue Du Coq cocktailcrafting kit", "m"))
								session["__script.have cocktailcrafting kit"] = "yes"
								did_action = have_item("Queue Du Coq cocktailcrafting kit")
							end
							local pt, pturl = get_result()
							return pt, pturl, did_action
						elseif count_item("peppermint twist") ~= twists - 1 then
							critical "Failed to mix peppermint booze"
						end
						break
					end
				end
			end
		end

		if not have_item("pumpkin beer") and have_item("pumpkin") then
			buy_item("fermenting powder", "m")
			mix_items("pumpkin", "fermenting powder")
		end

		ensure_mp(5)
		cast_skill("Summon Alice's Army Cards")

		return script.craft_and_drink_quality_booze(2)
	end

	function f.craft_and_drink_quality_booze(minquality)
--[[--
			if not have_item("coconut shell") and not have_item("little paper umbrella") and not have_item("magical ice cubes") then
				ensure_mp(10)
				cast_skillid(5014, 1) -- advanced cocktailcrafting
				ensure_mp(10)
				cast_skillid(5014, 1) -- advanced cocktailcrafting
				ensure_mp(10)
				cast_skillid(5014, 1) -- advanced cocktailcrafting
				ensure_mp(10)
				cast_skillid(5014, 1) -- advanced cocktailcrafting
				ensure_mp(10)
				cast_skillid(5014, 1) -- advanced cocktailcrafting
			end

			if not have_item("blended frozen swill") and not have_item("fruity girl swill") and not have_item("tropical swill") then
				local f = nil
				if have_item("little paper umbrella") then
					f = mix_items("Typical Tavern swill", "little paper umbrella")
				elseif have_item("magical ice cubes") then
					f = mix_items("Typical Tavern swill", "magical ice cubes")
				elseif have_item("coconut shell") then
					f = mix_items("Typical Tavern swill", "coconut shell")
				end
				if have_item("blended frozen swill") or have_item("fruity girl swill") or have_item("tropical swill") then
					did_action = true
				elseif f():contains("Your cocktail set is not advanced enough") then
					if have_item("Queue Du Coq cocktailcrafting kit") then
						print "  using cocktailcrafting kit"
						set_result(use_item("Queue Du Coq cocktailcrafting kit"))
						did_action = not have_item("Queue Du Coq cocktailcrafting kit")
					else
						print "  buying cocktailcrafting kit"
						set_result(buy_item("Queue Du Coq cocktailcrafting kit", "m"))
						session["__script.have cocktailcrafting kit"] = "yes"
						did_action = have_item("Queue Du Coq cocktailcrafting kit")
					end
				end
			end
--]]--

		local function warn_imported_beer()
			if not ascension_script_option("stop on imported beer") then return end
			if cached_stuff.warned_imported_beer == turnsthisrun() then return end
			cached_stuff.warned_imported_beer = turnsthisrun()
			stop "Script would drink imported beer. Drink something else manually instead, or run again to proceed."
		end

		local max_space = estimate_max_safe_drunkenness() - drunkenness()
		local min_space = math.min(max_space, 5)
		local available_drinks = get_available_drinks(minquality)
		local todrink, space, turngen = determine_drink_option(min_space, max_space, available_drinks)

		local have_crafted = false
		local function try_craft(when, name, penalty, craftf)
			local d = maybe_get_itemdata(name)
			if not have_crafted and when and d and d.drunkenness and d.drunkenness >= 1 and level() >= (d.levelreq or 1) then
				local value = (d.advmin + d.advmax) / 2
				local drink_quality = (value - penalty) / d.drunkenness
				if drink_quality < minquality then return end
				table.insert(available_drinks, { ["value"] = value - penalty, ["size"] = d.drunkenness, ["name"] = name, ["amount"] = 1 })
				local newtodrink, newspace, newturngen = determine_drink_option(min_space, max_space, available_drinks)
				table.remove(available_drinks)
				local old_goodness = space and (turngen / space) or -2
				local new_goodness = newspace and (newturngen / newspace) or -1
				if new_goodness > old_goodness then
					result, resulturl = craftf()()
					have_crafted = true
					available_drinks = get_available_drinks(minquality)
					todrink, space, turngen = determine_drink_option(min_space, max_space, available_drinks)
					if turngen ~= newturngen then
						critical "Error crafting drinks"
					end
				end
			end
		end

		local function try_crafting_improvements()
			have_crafted = false
			try_craft(have_item("handful of Smithereens"), "Paint A Vulgar Pitcher", 0, function() buy_item("plain old beer", "v") return craft_item("Paint A Vulgar Pitcher") end)
			try_craft(meat() >= 100, "overpriced &quot;imported&quot; beer", 0, function() warn_imported_beer() return buy_item("overpriced &quot;imported&quot; beer", "v") end)
			if have_crafted then return try_crafting_improvements() end
		end

		try_crafting_improvements()

		if space then
			print("drink_booze():", space)
			script.ensure_buff_turns("Ode to Booze", space)
			for _, x in ipairs(todrink) do
				drink_item(x)
			end
		end
	end

	function f.get_photocopied_monster()
		if have_item("photocopied monster") then
			local itempt = get_page("/desc_item.php", { whichitem = "835898159" })
			local copied = itempt:match([[blurry likeness of [a-zA-Z]* (.-) on it.]])
			return copied
		else
			return nil
		end
	end

	function f.unlock_cobbs_knob()
		if have_item("Knob Goblin encryption key") then
			set_result(use_item("Cobb's Knob map"))
			refresh_quest()
			if not quest_text("haven't figured out how to decrypt it yet") then
				did_action = true
			end
		else
			script.set_runawayfrom { "Knob Goblin Barbecue Team", "sleeping Knob Goblin Guard" }
			go("get encryption key", 114, macro_stasis, {
				["Up In Their Grill"] = "Grab the sausage, so to speak.  I mean... literally.",
				["Knob Goblin BBQ"] = "Kick the chef",
				["Ennui is Wasted on the Young"] = "&quot;Since you're bored, you're boring.  I'm outta here.&quot;",
				["Malice in Chains"] = "Plot a cunning escape",
				["When Rocks Attack"] = "&quot;Sorry, gotta run.&quot;",
			}, {}, "Mini-Hipster", 15)
			if have_item("Knob Goblin encryption key") then
				did_action = true
			end
		end
	end

	function f.do_barrr(insults)
		if insults >= 7 and have_item("Cap'm Caronch's Map") then
			inform "use cap'm's map"
			ensure_buffs { "Springy Fusilli", "Spirit of Peppermint", "A Few Extra Pounds" }
			fam "Rogue Program"
			f.heal_up()
			ensure_mp(40)
			use_item("Cap'm Caronch's Map")
			local pt, url = get_page("/fight.php")
			result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_noodlecannon)
		elseif insults >= 7 and not have_item("Cap'm Caronch's Map") then
			stop "Handle: 7 insults and no map?"
		else
-- 			print("map", have_item("Cap'm Caronch's Map"), "insults", insults)
			local function get_barrr_noncombattbl()
				if mainstat_type("Muscle") then
					return {
						["Yes, You're a Rock Starrr"] = "Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;",
						["A Test of Testarrrsterone"] = "Cheat",
						["That Explains All The Eyepatches"] = "Carefully throw the darrrt at the tarrrget",
					}
				elseif mainstat_type("Mysticality") then
					return {
						["Yes, You're a Rock Starrr"] = "Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;",
						["A Test of Testarrrsterone"] = "Cheat",
						["That Explains All The Eyepatches"] = "Pull one over on the pirates",
					}
				elseif mainstat_type("Moxie") then
					return {
						["Yes, You're a Rock Starrr"] = "Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;",
						["A Test of Testarrrsterone"] = "Wuss out",
						["That Explains All The Eyepatches"] = "Carefully throw the darrrt at the tarrrget",
					}
				end
			end
			if not have_item("The Big Book of Pirate Insults") then
				critical "No insult book when doing pirates!"
			end
			go("doing barrr: " .. insults .. " insults", 157, macro_barrr, get_barrr_noncombattbl(), { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease", "Ghostly Shell", "Astral Shell", "A Few Extra Pounds", "Leash of Linguini", "Empathy" }, "Slimeling even in fist", 30, { equipment = { hat = "eyepatch", pants = "swashbuckling pants", acc3 = "stuffed shoulder parrot" } })
		end
	end

	function f.beat_ibp()
		inform "beat IBP"
		wear { hat = "eyepatch", pants = "swashbuckling pants", acc3 = "stuffed shoulder parrot" }

-- 		TODO: merge with pirates.lua
		local beer_pong_responses = {
			["Arrr, the power of me serve'll flay the skin from yer bones!"] = "Obviously neither your tongue nor your wit is sharp enough for the job.",
			["Do ye hear that, ye craven blackguard?  It be the sound of yer doom!"] = "It can't be any worse than the smell of your breath!",
			["Suck on <i>this</i>, ye miserable, pestilent wretch!"] = "That reminds me, tell your wife and sister I had a lovely time last night.",
			["The streets will run red with yer blood when I'm through with ye!"] = "I'd've thought yellow would be more your color.",
			["Yer face is as foul as that of a drowned goat!"] = "I'm not really comfortable being compared to your girlfriend that way.",
			["When I'm through with ye, ye'll be crying like a little girl!"] = "It's an honor to learn from such an expert in the field.",
			["In all my years I've not seen a more loathsome worm than yerself!"] = "Amazing!  How do you manage to shave without using a mirror%?",
			["Not a single man has faced me and lived to tell the tale!"] = "It only seems that way because you haven't learned to count to one.",
		}

		local function solve_beerpong(n)
			if n <= 0 then return end
			local choice = nil
			for from, to in pairs(beer_pong_responses) do
				if get_result():contains(from) then
					choice = to
				end
			end
			if choice and get_result():match(choice) then
				responsenum = tonumber(get_result():match("<option value=([0-9]+)>"..choice.."</option>"))
				print("choose choice ", choice, responsenum)
				if responsenum then
					result, resulturl = post_page("/beerpong.php", { response = responsenum })
					return solve_beerpong(n - 1)
				end
			end
		end
		result, resulturl, advagain = autoadventure { zoneid = 157, ignorewarnings = true }
		result, resulturl = post_page("/choice.php", { pwd = get_pwd(), whichchoice = 187, option = 1 })
		solve_beerpong(3)
		refresh_quest()
		if not quest_text("wants you to defeat Old Don Rickets") then
			did_action = true
		elseif get_result():match("Insult Beer Pong") then
			local attempts = tonumber(session["__script.failed insult beer pong attempts"]) or 0
			if attempts < 5 then
				session["__script.failed insult beer pong attempts"] = attempts + 1
				result, resulturl = post_page("/beerpong.php", { response = 11 })
				did_action = true
			end
		end
	end

	function f.do_battlefield()
		if have_item("heart of the filthworm queen") then
			print("  trying to turn in filthworm heart")
			wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { place = "orchard", action = "stand", pwd = get_pwd() })
			async_get_page("/bigisland.php", { place = "orchard", action = "stand", pwd = get_pwd() })
		end
-- 		error "TODO use PADL"
		use_dancecard()
		function macro_battlefield()
			local geys = macro_noodlegeyser(3)
			if type(geys) ~= "string" then
				geys = geys()
			end
			return [[
if monstername green ops
]] .. geys .. [[

  goto m_done
endif

]] .. macro_noodlecannon() .. [[

mark m_done

]]
		end
		if meat() >= 5000 then
			script.bonus_target { "minoritem" }
		end
		local kills = (ascension["battlefield.kills.frat boy"] or {}).min or 0
		go("fight on battlefield: " .. kills .. " hippies killed", 132, macro_battlefield, nil, { "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling even in fist", 80, { equipment = { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" } })
		if get_result():contains("There are no hippy soldiers left") then
			local turnins = {
				"green clay bead",
				"pink clay bead",
				"purple clay bead",
				"communications windchimes",
			}
			if challenge == "boris" then
				table.insert(turnins, "didgeridooka")
				table.insert(turnins, "fire poi")
				table.insert(turnins, "Lockenstock&trade; sandals")
				table.insert(turnins, "hippy medical kit")
			end
			for x in table.values(turnins) do
				if have_item(x) then
					async_get_page("/bigisland.php", { action = "turnin", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid(x), quantity = count_item(x) })
				end
			end
			local camppt = get_page("/bigisland.php", { place = "camp", whichcamp = 2 })
			if camppt:contains("You don't have any quarters on file") then
				inform "fight hippy boss"
				fam "Frumious Bandersnatch"
				f.heal_up()
				if challenge == "boris" then
					async_post_page("/campground.php", { action = "telescopehigh" })
					script.maybe_ensure_buffs { "Billiards Belligerence" }
					script.ensure_buffs { "Go Get 'Em, Tiger!", "Butt-Rock Hair" }
					use_hottub()
					if have_buff("Billiards Belligerence") and have_buff("Starry-Eyed") and hp() / maxhp() >= 0.9 then
					else
						stop "TODO: Fight hippy boss in Boris"
					end
				elseif challenge == "jarlsberg" then
					async_post_page("/campground.php", { action = "telescopehigh" })
					script.maybe_ensure_buffs { "Mental A-cue-ity", "Pisces in the Skyces" }
					script.ensure_buffs { "Go Get 'Em, Tiger!", "Butt-Rock Hair" }
					script.force_heal_up()
					if have_buff("Mental A-cue-ity") and have_buff("Pisces in the Skyces") and hp() / maxhp() >= 0.9 and have_skill("Blend") then
					else
						stop "TODO: Fight hippy boss in AoJ"
					end
				end
				ensure_mp(150)
				ensure_buffs { "Spirit of Bacon Grease", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds" }
				maybe_ensure_buffs { "Mental A-cue-ity" }
				async_get_page("/bigisland.php", { place = "camp", whichcamp = 1 })
				result, resulturl = async_get_page("/bigisland.php", { action = "bossfight", pwd = get_pwd() })()
				result, resulturl, did_action = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(20))
			else
				if count_item("gauze garter") < 10 then
					inform "buying gauze garters"
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("gauze garter"), quantity = 10 })
					did_action = (count_item("gauze garter") >= 10)
				else
					inform "spending remaining quarters"
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("superamplified boom box"), quantity = 2 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("superamplified boom box"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("gauze garter"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("gauze garter"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("superamplified boom box"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 32 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 16 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 8 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 4 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 2 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("commemorative war stein"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("superamplified boom box"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("gauze garter"), quantity = 1 })
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("sake bomb"), quantity = 1 })
					local newcamppt = get_page("/bigisland.php", { place = "camp", whichcamp = 2 })
					did_action = newcamppt:contains("You don't have any quarters on file")
				end
			end
		end
	end

	function f.get_flyers()
		inform "get rock band flyers"
		wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
		async_get_page("/bigisland.php", { place = "concert" })
		async_get_page("/bigisland.php", { action = "junkman", pwd = get_pwd() })
		if have_item("rock band flyers") then
			did_action = true
		else
			inform "check if done with war sidequests"
			wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { place = "concert" })
			async_get_page("/bigisland.php", { action = "junkman", pwd = get_pwd() })
			async_get_page("/bigisland.php", { place = "lighthouse", action = "pyro", pwd = get_pwd() })
			local concertptf = async_get_page("/bigisland.php", { place = "concert" })
			local junkmanptf = async_get_page("/bigisland.php", { action = "junkman", pwd = get_pwd() })
			local pyroptf = async_get_page("/bigisland.php", { place = "lighthouse", action = "pyro", pwd = get_pwd() })
			if concertptf():contains("has already taken the stage") and junkmanptf():contains("next shipment of cars ready") and pyroptf():contains("gave you the big boom today") then
				inform "pick up padl phone"
				result, resulturl, advagain = autoadventure { zoneid = 132 }
				did_action = have_item("PADL Phone")
			else
				stop "Not done with war sidequests when starting to fight war"
			end
		end
	end

	function f.do_manor_of_spooking()
		local manorpt = get_page("/manor.php")
		if not manorpt:match("To The Cellar") then
			script.bonus_target { "noncombat" }
			go("unlock cellar", 109, macro_noodlecannon, {
				["Curtains"] = "Watch the dancers",
				["Strung-Up Quartet"] = "&quot;Play nothing, please.&quot;",
			}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic" }, "Slimeling", 30)
		elseif not have_item("Lord Spookyraven's spectacles") then
			script.bonus_target { "noncombat" }
			go("get spectacles", 108, macro_noodleserpent, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Springy Fusilli", "Spirit of Garlic" }, "Rogue Program", 50, { choice_function = function(advtitle, choicenum)
				if choicenum == 82 then
					return "Kick it and see what happens"
				elseif choicenum == 83 then
					return "Check the bottom drawer"
				elseif choicenum == 84 then
					return "Look behind the nightstand"
				elseif choicenum == 85 then
					if mainstat_type("Moxie") then
						return "Check the top drawer"
					else
						return "Investigate the jewelry"
					end
				end
			end })
		elseif not session["zone.manor.wines needed"] then
			inform "determine cellar wines"
			determine_cellar_wines()
			did_action = (session["zone.manor.wines needed"] ~= nil)
		else
			local manor3pt = get_page("/manor3.php")
			local wines_needed_list = session["zone.manor.wines needed"]
			local need = 0
			local got = 0
			local missing = {}
			for wine in table.values(wines_needed_list) do
				need = need + 1
				if have_item(wine) then
					got = got + 1
				else
					missing[wine] = true
				end
			end
			if need ~= 3 then
				critical "Couldn't identify 3 wines needed for cellar"
			elseif manor3pt:match("Summoning Chamber") then
				inform "fight spookyraven"
				ensure_buffs { "Springy Fusilli", "Astral Shell", "Spirit of Bacon Grease" }
				maybe_ensure_buffs_in_fist { "Astral Shell" }
				fam "Frumious Bandersnatch"
				use_hottub()
				ensure_mp(50)
				if have_buff("Astral Shell") or challenge == "boris" or have_buff("Red Door Syndrome") then
					-- TODO: check resistance instead
					local pt, url = get_page("/manor3.php", { place = "chamber" })
					result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_spookyraven)
				elseif meat() >= 3000 then
					script.ensure_buffs { "Red Door Syndrome" }
					did_action = have_buff("Red Door Syndrome")
				else
					stop "TODO: Beat Lord Spookyraven"
				end
			elseif got >= need then
				inform "open chamber"
				for _, wine in ipairs(wines_needed_list) do
					async_post_page("/manor3.php", { action = "pourwine", whichwine = get_itemid(wine) })
				end
				local manor3pt = get_page("/manor3.php")
				did_action = manor3pt:contains("Summoning Chamber")
			else
				script.bonus_target { "item" }
				-- TODO: get +booze% buff?
				if ascensionstatus() ~= "Hardcore" then
					maybe_ensure_buffs { "Brother Smothers's Blessing" }
				end
				softcore_stoppable_action("get cellar wines")
				local wines, _ = get_wine_cellar_data(ascension["zone.manor.wine cellar zone bottles"] or {})
--				print("wines", table_to_str(wines))
				local best = -1
				local best_zones = nil
				for z, ztbl in pairs(wines) do
					local score = 0
					for x, xv in pairs(ztbl) do
						if missing[x] then score = score + xv end
					end
--					print("zone", z, score)
					if score > best then
						best = score
						best_zones = { z }
					elseif score == best then
						table.insert(best_zones, z)
					end
				end
				local next_zone = best_zones[math.random(#best_zones)]
--				print("bestzone", table_to_str(best_zones), best, "going to", next_zone)
				go("get cellar wines", next_zone, macro_noodleserpent, {}, { "Spirit of Bacon Grease", "Fat Leon's Phat Loot Lyric", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Slimeling", 50)
			end
		end
	end

	function f.prepare_physically_resistant()
		if ascensionpath("Avatar of Sneaky Pete") and not have_skill("Smoke Break") and ascensionstatus("Hardcore") then
			script.bonus_target { "elemental weapon damage" }
		end
	end

	function f.do_hidden_city()
		-- TODO: Remove redundant information, put in zones/hiddencity.lua
		local places = {
			{ zone = "A Massive Ziggurat", choice = "Legend of the Temple in the Hidden City", option = "Leave" },
			{ zone = "An Overgrown Shrine (Southwest)", choice = "Water You Dune", option = "Place your head in the impression", fallback = "Back away", sphere = "dripping" },
			{ zone = "An Overgrown Shrine (Northwest)", choice = "Earthbound and Down", option = "Place your head in the impression", fallback = "Step away from the altar", sphere = "moss-covered" },
			{ zone = "An Overgrown Shrine (Southeast)", choice = "Fire When Ready", option = "Place your head in the impression", fallback = "Back off", sphere = "scorched" },
			{ zone = "An Overgrown Shrine (Northeast)", choice = "Air Apparent", option = "Place your head in the impression", fallback = "Leave the altar", sphere = "crackling" },
		}
		local citypt = get_page("/place.php", { whichplace = "hiddencity" })
		script.prepare_physically_resistant()
		if count_item("stone triangle") >= 4 then
			return run_task {
				message = "kill hidden city boss",
				minmp = 70,
				action = adventure {
					zone = "A Massive Ziggurat",
					macro_function = macro_noodlegeyser(5),
					noncombats = { ["Legend of the Temple in the Hidden City"] = "Open the door" },
				}
			}
		elseif citypt:contains("Hidden Apartment Building") and citypt:contains("Hidden Hospital") and citypt:contains("Hidden Office Building") and citypt:contains("Hidden Bowling Alley") then
			local spherecount = count_item("scorched stone sphere") + count_item("moss-covered stone sphere") + count_item("crackling stone sphere") + count_item("dripping stone sphere")

			if spherecount + count_item("stone triangle") >= 4 then
				for _, x in ipairs(places) do
					if x.sphere and have_item(x.sphere .. " stone sphere") then
						return run_task {
							message = "place " .. x.sphere .. " stone sphere at " .. x.zone,
							action = adventure {
								zone = x.zone,
								noncombats = { [x.choice] = "Place the " .. x.sphere .. " sphere in the impression" },
							}
						}
					end
				end
				critical "Error picking up stone triangles"
			elseif have_item("stone triangle") then
				stop "Hidden city partially completed, finish it manually"
			end

			-- use "book of matches" if we have it, buy drink

			if not have_item("moss-covered stone sphere") then
				return run_task {
					message = "do apartment building",
					minmp = 50,
					action = adventure {
						zone = "The Hidden Apartment Building",
						macro_function = macro_hiddencity,
						noncombats = {
							["Action Elevator"] = have_buff("Thrice-Cursed") and "Go to the Thrice-Cursed Penthouse" or "Go to the mezannine",
						},
					}
				}
			elseif not have_item("crackling stone sphere") then
				use_item("boring binder clip")
				local function choose()
					if have_item("McClusky file (complete)") then
						return "Knock on the boss's office door"
					elseif not have_item("boring binder clip") then
						return "Raid the supply cabinet"
					else
						return "Pick a fight with a cubicle drone"
					end
				end
				return run_task {
					message = "do office building",
					minmp = 50,
					buffs = { "Spirit of Peppermint" },
					action = adventure {
						zone = "The Hidden Office Building",
						macro_function = macro_hiddencity,
						noncombats = { ["Working Holiday"] = choose() },
					}
				}
			elseif not have_item("scorched stone sphere") then
				-- sniff pygmy bowler?
				script.bonus_target { "item" }
				return run_task {
					message = "do bowling alley",
					fam = "Slimeling",
					minmp = 50,
					action = adventure {
						zone = "The Hidden Bowling Alley",
						macro_function = macro_hiddencity,
						noncombats = { ["Life is Like a Cherry of Bowls"] = "Let's roll" },
					}
				}
			elseif not have_item("dripping stone sphere") then
				-- sniff witch surgeon?
				return run_task {
					message = "do hospital",
					minmp = 50,
					equipment = {
						shirt = first_wearable { "surgical apron" },
						weapon = can_wear_weapons() and first_wearable { "half-size scalpel" } or nil,
						pants = first_wearable { "bloodied surgical dungarees" },
						acc1 = first_wearable { "head mirror" },
						acc2 = first_wearable { "surgical mask" },
					},
					action = adventure {
						zone = "The Hidden Hospital",
						macro_function = macro_hiddencity,
						noncombats = { ["You, M. D."] = "Enter the Operating Theater" },
					}
				}
			else
				critical "Should have all hidden city spheres"
			end
		elseif can_wear_weapons() and not have_item("antique machete") then
			return run_task {
				message = "get antique machete",
				buffs = { "Smooth Movements", "The Sonata of Sneakiness" },
				fam = "Slimeling",
				minmp = 50,
				action = adventure {
					zone = "The Hidden Park",
					macro_function = macro_noodleserpent,
					noncombats = {
						["Where Does The Lone Ranger Take His Garbagester?"] = "Knock over the dumpster",
					}
				}
			}
		elseif not can_wear_weapons() then
			local remaining = remaining_hidden_city_liana_zones()
			remaining["A Massive Ziggurat"] = nil
			local function findplace(name)
				for _, x in ipairs(places) do
					if x.zone == name then
						return x
					end
				end
			end
			local x
			if not cached_stuff.unlocked_massive_ziggurat then
				x = findplace("A Massive Ziggurat")
			elseif next(remaining) then
				x = findplace(next(remaining))
			end
			if not x then
				critical("Kill lianas without machete")
			end
			run_task {
				message = "cut liana at "..x.zone.." (without machete)",
				fam = "Angry Jung Man",
				action = adventure {
					zone = x.zone,
					macro_function = macro_noodleserpent,
					choice_function = function(advtitle, choicenum, pagetext)
						if advtitle == x.choice then
							if x.zone == "A Massive Ziggurat" then
								cached_stuff.unlocked_massive_ziggurat = true
							end
							if pagetext:contains(x.option) then
								return x.option
							else
								return x.fallback
							end
						end
					end,
				}
			}
			if get_result():contains("New Area Unlocked") then
				did_action = true
			end
		else
			-- TODO: Merge with code above
			for _, x in ipairs(places) do
				for i = 1, 5 do
					did_action = false
					local t = turnsthisrun()
					run_task {
						message = "cut liana at " .. x.zone,
						fam = "Angry Jung Man",
						equipment = { weapon = "antique machete" },
						action = adventure {
							zone = x.zone,
							choice_function = function(advtitle, choicenum, pagetext)
								if advtitle == x.choice then
									if pagetext:contains(x.option) then
										return x.option
									else
										return x.fallback
									end
								end
							end,
						}
					}
					if get_result():contains("New Area Unlocked") then
					elseif not did_action or turnsthisrun() ~= t then
						critical "Failed to cut liana for free"
					end
				end
			end
			citypt = get_page("/place.php", { whichplace = "hiddencity" })
			if citypt:contains("Hidden Apartment Building") and citypt:contains("Hidden Hospital") and citypt:contains("Hidden Office Building") and citypt:contains("Hidden Bowling Alley") then
				did_action = true
			else
				did_action = false
			end
		end
	end

	function f.do_gotta_worship_them_all()
		local woodspt = get_page("/woods.php")
		if not woodspt:contains("The Hidden Temple") then
			f.unlock_hidden_temple()
		elseif not woodspt:match("hiddencity") then
			if not have_buff("Stone-Faced") and have_item("stone wool") then
				use_item("stone wool")
			end
			if have_buff("Stone-Faced") or ascensionstatus() == "Hardcore" then
				ignore_buffing_and_outfit = true
				if not have_item("the Nostril of the Serpent") and ascension["zone.hidden temple.placed Nostril of the Serpent"] ~= "yes" then
					go("unlock hidden city", 280, macro_noodlecannon, {}, {}, "Mini-Hipster", 25, { choice_function = function(advtitle, choicenum, pagetext)
						if advtitle == "Fitting In" then
							return "Explore the higher levels"
						elseif advtitle == "Such Great Heights" then
							return "Climb down some vines"
						elseif advtitle == "Such Great Depths" then
							return "The growling"
						elseif advtitle == "The Hidden Heart of the Hidden Temple" then
							if pagetext:contains("Go through the door (3 Adventures)") then
								return "Go through the door (3 Adventures)"
							else
								return "Go back the way you came"
							end
						end
					end })
				else
					go("unlock hidden city", 280, macro_noodlecannon, {}, {}, "Mini-Hipster", 25, { choice_function = function(advtitle, choicenum, pagetext)
						if advtitle == "Fitting In" then
							return "Poke around the ground floor"
						elseif advtitle == "Such Great Heights" then
							return "Head towards the top of the temple"
						elseif advtitle == "Such Great Depths" then
							return "The growling"
						elseif advtitle == "The Hidden Heart of the Hidden Temple" then
							if pagetext:contains("Go through the door (3 Adventures)") then
								return "Go through the door (3 Adventures)"
							else
								return "Go down the stairs"
							end
						elseif advtitle == "Unconfusing Buttons" then
							return "The one with the cute little lightning-tailed guy on it"
						elseif advtitle == "At Least It's Not Full Of Trash" then
							return "Raise your hands up toward the heavens"
						end
					end })
--					print("DEBUG: hidden city result", get_result())
					result, resulturl = get_page("/choice.php")
					if resulturl:match("/tiles.php") then
						print("doing temple tiles")
						result, resulturl = automate_tiles()
					end
					result, resulturl = get_page("/choice.php")
					if resulturl:match("/choice.php") then
						result, resulturl = handle_adventure_result(get_result(), resulturl, "?", nil, { ["No Visible Means of Support"] = "Do nothing" })
					end
					if get_result():contains("You mark its location on your map, and carefully climb down the side of the Temple, back to ground level.") then
						did_action = true
					end
				end
			else
				pull_in_softcore("stone wool")
				if have_item("stone wool") then
					did_action = true
				else
					stop "TODO: Do hidden temple."
				end
			end
		else
			return script.do_hidden_city()
		end
	end

	function f.do_pyramid()
		local pyramidpt = get_page("/pyramid.php")
		if pyramidpt:match("pyramid3a.gif") then
			if not have_item("carved wooden wheel") then
				script.bonus_target { "item" }
				go("find carved wheel", 124, macro_noodleserpent, nil, { "Spirit of Bacon Grease" }, "Mini-Hipster", 45)
			else
				script.bonus_target { "extranoncombat", "noncombat" }
				script.set_runawayfrom { "Iiti Kitty", "tomb bat" }
				go("place wheel in middle chamber", 125, macro_noodleserpent, {
					["Wheel in the Pyramid, Keep on Turning"] = "Turn the wheel",
				}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Bacon Grease" }, "Rogue Program", 45)
			end
		else
-- 			pyramid4_1.gif -> nuke
-- 			pyramid4_2.gif -> turn
-- 			pyramid4_3.gif -> bomb
-- 			pyramid4_4.gif -> token
-- 			pyramid4_5.gif -> turn
			if pyramidpt:match("pyramid4_1b.gif") then
				-- TODO: check if this will overlap with SR
				inform "fight ed"
				fam "Frumious Bandersnatch"
				f.heal_up()
				ensure_buffs { "Spirit of Garlic", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds" }
				maybe_ensure_buffs { "Mental A-cue-ity" }
				ensure_mp(100)
				if maxmp() >= 200 then
					ensure_mp(150)
				end
				result, resulturl = get_page("/pyramid.php", { action = "lower" })
				result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(5))
				while get_result():contains([[<!--WINWINWIN-->]]) and get_result():contains([[fight.php]]) do
					result, resulturl = get_page("/fight.php")
					result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(5))
				end
				did_action = have_item("Holy MacGuffin")
			elseif pyramidpt:match("pyramid4_1.gif") and have_item("ancient bomb") then
				inform "use bomb"
				async_get_page("/pyramid.php", { action = "lower" })
				pyramidpt = get_page("/pyramid.php")
				did_action = pyramidpt:contains("pyramid4_1b.gif")
			elseif pyramidpt:match("pyramid4_3.gif") and not have_item("ancient bomb") and have_item("ancient bronze token") then
				inform "buy bomb"
				async_get_page("/pyramid.php", { action = "lower" })
				did_action = have_item("ancient bomb")
			elseif pyramidpt:match("pyramid4_4.gif") and not have_item("ancient bomb") and not have_item("ancient bronze token") then
				inform "get token"
				async_get_page("/pyramid.php", { action = "lower" })
				did_action = have_item("ancient bronze token")
			elseif pyramidpt:match("pyramid4_[12345].gif") then
				if have_item("tomb ratchet") then
					local c = count_item("tomb ratchet")
					use_item("tomb ratchet")
					did_action = count_item("tomb ratchet") < c
				else
					script.bonus_target { "extranoncombat", "noncombat" }
					script.set_runawayfrom { "Iiti Kitty", "tomb bat" }
					go("turn middle chamber wheel", 125, macro_noodleserpent, {
						["Wheel in the Pyramid, Keep on Turning"] = "Turn the wheel",
					}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Bacon Grease" }, "Rogue Program", 45)
				end
			end
		end
	end

	function f.do_filthworms()
		script.bonus_target { "item", "extraitem" }
		if not have_buff("Super Vision") and have_item("Greatest American Pants") then
			wear { pants = "Greatest American Pants" }
			script.get_gap_buff("Super Vision")
		end
		if daysthisrun() <= 2 and not ascensionstatus("Hardcore") and not have_buff("Super Vision") then
			ensure_buffs {}
			wear {}
			stop "TODO: Do filthworms [not automated when it's day 2 without super vision]"
		end
		if have_buff("Filthworm Guard Stench") then
			go("fight queen", 130, macro_noodlecannon, {}, { "Spirit of Bacon Grease" }, "Hobo Monkey", 30, { equipment = { familiarequip = "sugar shield" } })
		elseif have_item("filthworm royal guard scent gland") then
			inform "using guard stench"
			set_result(use_item("filthworm royal guard scent gland"))
			did_action = have_buff("Filthworm Guard Stench")
		elseif have_buff("Filthworm Drone Stench") then
			if daysthisrun() >= 3 then
				pull_in_softcore("peppermint crook")
			end
			go("fight guard", 129, (challenge == "boris" and have_item("peppermint crook") and macro_softcore_boris_crook) or macro_ppnoodlecannon, {}, { "Spirit of Bacon Grease", "Fat Leon's Phat Loot Lyric", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Slimeling", 30, { equipment = { familiarequip = "sugar shield", pants = (challenge == "boris" and have_item("Greatest American Pants")) and "Greatest American Pants" or nil } })
		elseif have_item("filthworm drone scent gland") then
			inform "using drone stench"
			set_result(use_item("filthworm drone scent gland"))
			did_action = have_buff("Filthworm Drone Stench")
		elseif have_buff("Filthworm Larva Stench") then
			if daysthisrun() >= 3 then
				pull_in_softcore("peppermint crook")
			end
			go("fight drone", 128, (challenge == "boris" and count_item("peppermint crook") >= 2 and macro_softcore_boris_crook) or macro_ppnoodlecannon, {}, { "Spirit of Bacon Grease", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy" }, "Slimeling", 30, { equipment = { familiarequip = "sugar shield", pants = (challenge == "boris" and have_item("Greatest American Pants")) and "Greatest American Pants" or nil } })
		elseif have_item("filthworm hatchling scent gland") then
			inform "using hatchling stench"
			set_result(use_item("filthworm hatchling scent gland"))
			did_action = have_buff("Filthworm Larva Stench")
		else
			-- TODO: use GAP +item% buff if available, GAP structure buff
			softcore_stoppable_action("fight hatchling")
			go("fight hatchling", 127, (challenge == "boris" and count_item("peppermint crook") >= 3 and macro_softcore_boris_crook) or macro_ppnoodlecannon, {}, { "Spirit of Bacon Grease", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy" }, "Slimeling", 30, { equipment = { familiarequip = "sugar shield", pants = (challenge == "boris" and have_item("Greatest American Pants")) and "Greatest American Pants" or nil } })
		end
	end

	function f.do_sonofa()
		local macro = macro_noodleserpent
		if not ascensionstatus("Hardcore") then
			macro = macro_softcore_lfm
		end
		if count_item("barrel of gunpowder") >= 5 then
			inform "talk to lighthouse guy"
			wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { place = "lighthouse", action = "pyro", pwd = get_pwd() })
			async_get_page("/bigisland.php", { place = "lighthouse", action = "pyro", pwd = get_pwd() })
			did_action = (have_item("tequila grenade") and have_item("molotov cocktail cocktail"))
		elseif have_item("Rain-Doh box full of monster") then
			if challenge == "boris" then
				macro = macro_softcore_boris([[

if monstername lobsterfrogman
  use Rain-Doh black box
endif

]])
				if count_item("barrel of gunpowder") >= 4 then
					macro = macro_softcore_boris
				end
			end
			local copied = retrieve_raindoh_monster()
			if copied:contains("lobsterfrogman") then
				inform "fight copied LFM"
				script.heal_up()
				script.ensure_mp(40)
				if hp() < maxhp() * 0.8 then
					stop "Heal up before using Rain-Doh box full of monster"
				end
				use_item("Rain-Doh box full of monster")
				local pt, url = get_page("/fight.php")
				result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro)
				if advagain then
					did_action = true
				end
			else
				stop("Fight unexpected rain-doh copied monster (not a lobsterfrogman)")
			end
		else
			script.bonus_target { "combat" }
			if not have_buff("Hippy Stench") and have_item("reodorant") then
				-- TODO: use maybe_ensure_buffs
				use_item("reodorant")
			end
			if ascensionpath("Avatar of Jarlsberg") then
				script.ensure_buffs { "Coffeesphere" }
			end
			-- TODO: Split into hardcore / softcore-copy, and do buffing per-path
			if challenge == "boris" then
				script.ensure_buffs {}
				if have_buff("Song of Battle") and ascensionstatus() == "Hardcore" then
					go("do sonofa beach, " .. make_plural(count_item("barrel of gunpowder"), "barrel", "barrels"), 136, macro_hardcore_boris, {}, { "Spirit of Bacon Grease", "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Heavy Petting", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog for +combat", 50, { equipment = { familiarequip = "sugar shield" } })
				elseif have_buff("Song of Battle") and have_item("Rain-Doh black box") then
					go("do sonofa beach, " .. make_plural(count_item("barrel of gunpowder"), "barrel", "barrels"), 136, macro_copy_lfm, {}, { "Spirit of Bacon Grease", "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Heavy Petting", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog for +combat", 50, { equipment = { familiarequip = "sugar shield" } })
				else
					stop "TODO: Do sonofa in Boris"
				end
			elseif challenge == "zombie" and not have_buff("Waking the Dead") then
				if have_skill("Summon Horde") then
					cast_skillid(12021, 1)
					async_get_page("/choice.php", { forceoption = 0 })
					async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 600, option = 1 })
					async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 600, option = 2 })
				end
				if have_buff("Waking the Dead") then
					go("do sonofa beach, " .. make_plural(count_item("barrel of gunpowder"), "barrel", "barrels"), 136, macro_noodleserpent, {}, { "Spirit of Bacon Grease", "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Heavy Petting", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog for +combat", 50, { equipment = { familiarequip = "sugar shield" } })
				else
					stop "TODO: Do sonofa in zombie"
				end
			else
				go("do sonofa beach, " .. make_plural(count_item("barrel of gunpowder"), "barrel", "barrels"), 136, macro, {}, { "Spirit of Bacon Grease", "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Heavy Petting", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog for +combat", 50, { equipment = { familiarequip = "sugar shield" } })
			end
			if have_buff("Beaten Up") then
				use_hottub()
				did_action = not have_buff("Beaten Up")
			end
		end
	end

	function f.get_gap_buff(buff)
		async_get_page("/inventory.php", { action = "activatesuperpants" })
		result, resulturl = get_page("/choice.php")
		result, resulturl = handle_adventure_result(get_result(), resulturl, "?", nil, { ["Pants-Gazing"] = buff })
		if have_buff(buff) then
			print("  gap buff: " .. tostring(buff))
		else
			result, resulturl = handle_adventure_result(get_result(), resulturl, "?", nil, { ["Pants-Gazing"] = "Ignore the pants" })
		end
	end

	function f.do_junkyard()
		if not have_item("molybdenum magnet") then
			wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { action = "junkman", pwd = get_pwd() })
		end
		local function get_gremlin_data()
			if not have_item("molybdenum hammer") then
				return "get gremlin hammer", 182, make_gremlin_macro("batwinged gremlin", "a bombing run")
			elseif not have_item("molybdenum crescent wrench") then
				return "get gremlin wrench", 184, make_gremlin_macro("erudite gremlin", "random junk")
			elseif not have_item("molybdenum pliers") then
				return "get gremlin pliers", 183, make_gremlin_macro("spider gremlin", "fibula")
			elseif not have_item("molybdenum screwdriver") then
				return "get gremlin screwdriver", 185, make_gremlin_macro("vegetable gremlin", "picks a")
			end
		end
		local i, z, m = get_gremlin_data()
		if z then
			if ascensionstatus() ~= "Hardcore" then
				if not have_buff("Super Structure") and have_item("Greatest American Pants") then
					wear { pants = "Greatest American Pants" }
					script.get_gap_buff("Super Structure")
				end
				if challenge and not have_buff("Super Structure") and not have_skill("Louder Bellows") then
					stop "TODO: Do gremlins in challenge path without Super Structure"
				end
			end
			if ascensionpathid() ~= 0 and not have_skill("Tao of the Terrapin") then
				script.bonus_target { "easy combat" }
				script.maybe_ensure_buffs { "Standard Issue Bravery" }
				script.ensure_buffs { "Go Get 'Em, Tiger!", "Butt-Rock Hair" }
			end
			inform(i)
			ensure_buffs { "Spirit of Bacon Grease", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds" }
			fam "Frumious Bandersnatch"
			wear {}
			script.heal_up()
			if ascensionpathid() ~= 0 and (not have_buff("Super Structure") or not have_skill("Tao of the Terrapin")) then
				script.force_heal_up()
			end
			ensure_mp(60)
			result, resulturl, did_action = autoadventure { zoneid = z, macro = m, ignorewarnings = true }
		else
			if not have_item("molybdenum hammer") or not have_item("molybdenum crescent wrench") or not have_item("molybdenum pliers") or not have_item("molybdenum screwdriver") then
				critical "Missing items when finishing junkyard quest"
			end
			wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { action = "junkman", pwd = get_pwd() })
			if not have_item("molybdenum hammer") and not have_item("molybdenum crescent wrench") and not have_item("molybdenum pliers") and not have_item("molybdenum screwdriver") then
				did_action = true
			end
		end
	end

	function f.get_mining_whichid()
		result, resulturl = get_page("/mining.php", { mine = 1 })
		local tbl = ascension["mining.results.1"] or {}
		local trapper_wants = { asbestos = "2", chrome = "3", linoleum = "1" }
		local wantore = trapper_wants[session["trapper.ore"]]
		local pcond, values = compute_mine_spoiler(result, tbl, wantore)
		local x = result:match([[<table cellpadding=0 cellspacing=0 border=0 background='http://images.kingdomofloathing.com/otherimages/mine/mine_background.gif'>(.-)</table>]])
		local best_value = -1000
		local best_which = nil
		for celltext in x:gmatch([[<td[^>]*>(.-)</td>]]) do
			local which = tonumber(celltext:match([[<a href='mining.php%?mine=[0-9]+&which=([0-9]+)&pwd=[0-9a-f]+'>]]))
			if which and values[mining_which_to_idx(which)] > best_value then
				best_value = values[mining_which_to_idx(which)]
				best_which = which
			end
		end
		return best_which
	end

	function f.do_trapper_quest()
		if quest_text("go talk to the Trapper") then
			async_get_page("/place.php", { whichplace = "mclargehuge", action = "trappercabin" })
			refresh_quest()
			did_action = not quest_text("go talk to the Trapper")
		elseif quest_text("ready to ascend to the Icy Peak") or quest_text("close to figuring out what's going on at the Icy Peak") or quest_text("have slain Groar") then
			async_get_page("/place.php", { whichplace = "mclargehuge", action = "trappercabin" })
			refresh_quest()
			if not quest_text("ready to ascend to the Icy Peak") and not quest_text("close to figuring out what's going on at the Icy Peak") then
				did_action = true
			else
				if have_item("eXtreme mittens") and have_item("eXtreme scarf") and have_item("snowboarder pants") then
					wear { hat = "eXtreme scarf", pants = "snowboarder pants", acc3 = "eXtreme mittens" }
				else
					wear {}
					script.ensure_buffs { "Elemental Saucesphere", "Astral Shell" }
				end
				fam "Frumious Bandersnatch"
				ensure_buffs { "Springy Fusilli", "Spirit of Cayenne" }
				ensure_mp(40)
				if get_resistance_level("Cold") <= 0 and not have_buff("Super Structure") and have_item("Greatest American Pants") then
					wear { pants = "Greatest American Pants" }
					script.get_gap_buff("Super Structure")
				end
				inform "exploring the icy peak"
				local pt, url = get_page("/place.php", { whichplace = "mclargehuge", action = "cloudypeak2" })
				result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_noodlecannon)
				did_action = advagain
				if not did_action and pt:contains("get back into your warm clothes") then
					print("   need more cold resistance, postponing until later")
					cached_stuff.missing_cold_resistance_for_icy_peak = true
					did_action = true
				end
			end
		elseif ascensionpath("Avatar of Sneaky Pete") and sneaky_pete_motorcycle_upgrades()["Tires"] == "Snow Tires" then
			get_page("/place.php", { whichplace = "mclargehuge", action = "cloudypeak" })
			refresh_quest()
			did_action = quest_text("close to figuring out what's going on at the Icy Peak")
		elseif quest_text("gather up some cheese and ore for him") then
			local trappercabin = get_page("/place.php", { whichplace = "mclargehuge", action = "trappercabin" })
			refresh_quest()
			if not quest_text("gather up some cheese and ore for him") then
				did_action = true
			elseif count_item("goat cheese") < 3 then
				ignore_buffing_and_outfit = false
				script.bonus_target { "item" }
				maybe_ensure_buffs { "Brother Flying Burrito's Blessing" }
				local bufftbl = { "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy", "Spirit of Garlic" }
				if count_item("glass of goat's milk") < 2 or not have_buff("Brother Flying Burrito's Blessing") then
					table.insert(bufftbl, "Heavy Petting")
					table.insert(bufftbl, "Peeled Eyeballs")
				end
				go("get goat cheese for trapper", 271, make_cannonsniff_macro("dairy goat"), nil, bufftbl, "Slimeling", 35, { olfact = "dairy goat" })
			elseif (challenge == "fist") or (have_item("miner's helmet") and have_item("7-Foot Dwarven mattock") and have_item("miner's pants")) then
				if challenge == "fist" then
					ensure_buffs { "Earthen Fist" }
				else
					wear { hat = "miner's helmet", weapon = "7-Foot Dwarven mattock", pants = "miner's pants" }
				end
				local best_which = script.get_mining_whichid()
				inform("mine for ore [tile " .. tostring(best_which) .. "]")
				script.heal_up()
				set_result(get_page("/mining.php", { mine = 1, which = best_which, pwd = session.pwd }))
				if challenge == "fist" then
					ensure_buffs { "Earthen Fist" }
				else
					wear { hat = "miner's helmet", weapon = "7-Foot Dwarven mattock", pants = "miner's pants" }
				end
				did_action = script.get_mining_whichid() ~= best_which
			elseif not ascensionstatus("Hardcore") then
				local want_ore = trappercabin:match("fix the lift until you bring me that cheese and ([a-z]+ ore)")
				local got = count_item(want_ore)
				if got >= 3 then
					critical "Trapper ore+cheese quest should be finished already."
				end
				if false and want_ore == "chrome ore" and not have_item("acoustic guitarrr") and not have_item("heavy metal thunderrr guitarrr") then
					-- TODO: do this when we can untinker
					pull_in_softcore("heavy metal thunderrr guitarrr")
					did_action = have_item("heavy metal thunderrr guitarrr")
				else
					ascension_automation_pull_item(want_ore)
					did_action = count_item(want_ore) > got
				end
			else
				go("get mining outfit", 270, macro_noodlecannon, {}, { "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy", "Spirit of Garlic" }, "Slimeling", 35, { choice_function = function(advtitle, choicenum)
					print("DEBUG mining", advtitle, choicenum)
					if advtitle == "100% Legal" then
						if not have_item("miner's helmet") then
							return "Demand loot"
						else
							return "Ask for ore"
						end
					elseif advtitle == "A Flat Miner" then
						if not have_item("miner's pants") then
							return "Loot the dwarf's belongings"
						else
							return "Hijack the Meat vein"
						end
					elseif advtitle == "See You Next Fall" then
						if not have_item("7-Foot Dwarven mattock") then
							return "DOOOOON'T GIVE 'IM THE STICK!"
						else
							return "Give 'im the stick"
						end
					elseif advtitle == "More Locker Than Morlock" then
						return "Open the locka'"
					end
				end })
			end
		elseif quest_text("like you to investigate the summit") then
			local slope_outfit = {}
			if have_item("eXtreme mittens") and have_item("eXtreme scarf") and have_item("snowboarder pants") then
				slope_outfit = { hat = "eXtreme scarf", pants = "snowboarder pants", acc3 = "eXtreme mittens" }
				wear(slope_outfit)
			end
			if have_item("ninja rope") and have_item("ninja crampons") and have_item("ninja carabiner") then
				script.ensure_buffs { "Elemental Saucesphere", "Astral Shell" }
			end
			get_page("/place.php", { whichplace = "mclargehuge", action = "cloudypeak" })
			refresh_quest()
			if not quest_text("like you to investigate the summit") then
				did_action = true
			elseif have_item("ninja rope") and have_item("ninja crampons") and have_item("ninja carabiner") then
				stop "TODO: Buff up cold resistance and climb peak."
			else
				script.bonus_target { "noncombat" }
				go("explore the extreme slope", 273, macro_noodlecannon, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Peppermint" }, "Slimeling", 35, { choice_function = function(advtitle, choicenum)
					if advtitle == "Generic Teen Comedy Snowboarding Adventure" then
						if not have_item("eXtreme mittens") then
							return "Give him a pep-talk"
						else
							return "Give him some boarding tips"
						end
					elseif advtitle == "Saint Beernard" then
						if not have_item("snowboarder pants") then
							return "Help the heroic dog"
						else
							return "Flee in terror"
						end
					elseif advtitle == "Yeti Nother Hippy" then
						if not have_item("eXtreme scarf") then
							return "Let irony take its course"
						else
							return "Help the hippy"
						end
					elseif advtitle == "Duffel on the Double" then
						if have_item("eXtreme scarf") and have_item("snowboarder pants") and have_item("eXtreme mittens") then
							return "Scram"
						else
							return "Open the bag"
						end
					end
				end, equipment = slope_outfit })
				if get_result():contains("red glow surrounding you") then
					did_action = true
				end
			end
		else
			critical "Failed to finish trapper quest"
		end
-- 			if have_item("astral shirt") or have_item("cane-mail shirt") then
-- 				did_action = true
-- 			elseif challenge == "fist" then
-- 				did_action = true
-- 			elseif highskill_at_run and not have_item("hipposkin poncho") then
-- 				async_post_page("/trapper.php", { action = "Yep.", pwd = get_pwd(), whichitem = get_itemid("hippopotamus skin"), qty = 1 })
-- 				if have_item("hippopotamus skin") then
-- 					inform "smith hipposkin poncho stuff"
-- 					if not have_item("tenderizing hammer") then
-- 						buy_item("tenderizing hammer", "s")
-- 					end
-- 					if not have_item("shirt kit") then
-- 						buy_item("shirt kit", "s")
-- 					end
-- 					smith_items("shirt kit", "hippopotamus skin")
-- 					did_action = have_item("hipposkin poncho")
-- 				end
-- 			elseif not have_item("yak anorak") and not highskill_at_run and have_skill("Torso Awaregness") and have_skill("Armorcraftiness") then
-- 				async_post_page("/trapper.php", { action = "Yep.", pwd = get_pwd(), whichitem = get_itemid("yak skin"), qty = 1 })
-- 				if have_item("yak skin") then
-- 					inform "smith and wear yak stuff"
-- 					if not have_item("tenderizing hammer") then
-- 						buy_item("tenderizing hammer", "s")
-- 					end
-- 					if not have_item("shirt kit") then
-- 						buy_item("shirt kit", "s")
-- 					end
-- 					smith_items("shirt kit", "yak skin")
-- 					did_action = have_item("yak anorak")
-- 				end
-- 			end
	end

	function f.do_muscle_powerleveling()
-- 		print("  mainstat", basemainstat(), "advs", advs())
		if have_item("Spookyraven gallery key") then
			script.bonus_target { "noncombat" }
			go("muscle powerleveling", 106, macro_noodlecannon, { ["Out in the Garden"] = "None of the above" }, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic", "A Few Extra Pounds" }, "Rogue Program", 35)
			if result:contains("Louvre It or Leave It") and not did_action then
				local found, reached = compute_louvre_paths(91)
				if found.Muscle then
					local function golouvre(cid)
						if reached[cid] ~= -1000 then
							golouvre(reached[cid].whichchoice)
							async_post_page("/choice.php", { pwd = get_pwd(), whichchoice = reached[cid].whichchoice, option = reached[cid].option })
						end
					end
					golouvre(found.Muscle.whichchoice)
					text, url = post_page("/choice.php", { pwd = get_pwd(), whichchoice = found.Muscle.whichchoice, option = found.Muscle.option })
					did_action = text:contains("You help him push his cart back onto dry land")
				else
					result, resulturl = louvre_automate_looking_for_muscle(get_pwd())
					result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, 106)
					did_action = advagain
				end
			end
		elseif ascension["zone.conservatory.gallery key"] == "unlocked" then
			go("pick up gallery key", 103, macro_stasis, {}, {}, "Mini-Hipster", 15)
		else
			script.bonus_target { "noncombat" }
			go("unlock gallery key", 104, macro_stasis, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Butt-Rock Hair", "A Few Extra Pounds" }, "Rogue Program", 5, { choice_function = function(advtitle, choicenum)
				if advtitle == "Take a Look, it's in a Book!" then
					if choicenum == 80 then
						return "Reading is for losers.  I'm outta here."
					elseif choicenum == 81 then
						return "Read &quot;The Fall of the House of Spookyraven&quot;"
					end
				elseif advtitle == "History is Fun!" then
					return "Read Chapter 2: Stephen and Elizabeth"
				elseif advtitle == "Melvil Dewey Would Be Ashamed" then
					return "Gaffle the purple-bound book"
				end
			end })
		end
	end

	function f.do_mysticality_powerleveling()
-- 		print("  mainstat", basemainstat(), "advs", advs())
		script.bonus_target { "noncombat" }
		go("mysticality powerleveling", 107, macro_noodlecannon, {
			["Don't Hold a Grudge"] = "Declare a thumb war",
			["Having a Medicine Ball"] = "Gaze deeply into the mirror",
		}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic" }, "Rogue Program", 35)
	end

	function f.do_moxie_powerleveling()
		script.do_moxie_use_dancecard()
-- 		print("  mainstat", basemainstat(), "dance cards", count_item("dance card"), "advs", advs(), "trail turns", buffturns("On the Trail"))
		script.bonus_target { "noncombat", "item" }
		go("moxie powerleveling", 109, make_cannonsniff_macro("zombie waltzers"), {
			["Curtains"] = "Watch the dancers",
			["Strung-Up Quartet"] = "&quot;Play 'Sono Un Amanten Non Un Combattente'&quot;",
		}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric" }, "Slimeling", 35, { olfact = "zombie waltzers" })
	end

	function f.do_moxie_use_dancecard()
		if have_item("dance card") and level() < 13 then
			local dance_card_turn = tonumber(ascension["dance card turn"]) or -1000
			if dance_card_turn < turnsthisrun() then
				return use_item("dance card")
			end
		end
	end

	function f.get_dinghy()
		if not have_item("dinghy plans") then
			if count_item("Shore Inc. Ship Trip Scrip") >= 3 then
				inform "buy dinghy plans"
				buy_shore_inc_item("dinghy plans")
				did_action = have_item("dinghy plans")
			else
				inform "shore for dinghy plans"
				local scrip = count_item("Shore Inc. Ship Trip Scrip")
				result, resulturl = script.take_shore_trip()
				did_action = count_item("Shore Inc. Ship Trip Scrip") > scrip
			end
		elseif not have_item("dingy planks") then
			inform "buy dingy planks"
			set_result(buy_item("dingy planks", "m"))
			did_action = have_item("dingy planks")
		else
			inform "use dinghy plans"
			set_result(use_item("dinghy plans"))
			did_action = have_item("dingy dinghy")
		end
	end

	function f.get_big_book_of_pirate_insults()
		if have_item("eyepatch") and have_item("swashbuckling pants") and have_item("stuffed shoulder parrot") and not have_item("The Big Book of Pirate Insults") then
			if meat() >= 1500 then
				inform "buy insult book and dictionary"
				wear { hat = "eyepatch", pants = "swashbuckling pants", acc3 = "stuffed shoulder parrot" }
				buy_item("The Big Book of Pirate Insults", "r")
				buy_item("abridged dictionary", "r")
				did_action = (have_item("The Big Book of Pirate Insults") and have_item("abridged dictionary"))
			else
				if challenge == "fist" then
					go("farm > sign for meat", 226, macro_noodlecannon, { ["Typographical Clutter"] = "The lower-case L" }, { "Smooth Movements", "The Sonata of Sneakiness", "Polka of Plenty" }, "Slimeling", 25)
				else
					stop "Not enough meat for insult book + dictionary."
				end
			end
		elseif not ascensionstatus("Hardcore") and challenge then
			pull_in_softcore("eyepatch")
			pull_in_softcore("swashbuckling pants")
			pull_in_softcore("stuffed shoulder parrot")
			did_action = have_item("eyepatch") and have_item("swashbuckling pants") and have_item("stuffed shoulder parrot")
		else
			script.bonus_target { "noncombat", "item" }
			go("get swashbuckling outfit", 66, macro_noodlecannon, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric" }, "Slimeling", 25, { choice_function = function(advtitle, choicenum)
				if advtitle == "Amatearrr Night" then
					if not have_item("stuffed shoulder parrot") then
						return "What's orange and sounds like a parrot?" -- stuffed shoulder parrot
					else
						return "What's gold and sounds like a pirate?" -- eyepatch
					end
				elseif advtitle == "The Arrrbitrator" then
					if not have_item("eyepatch") then
						return "Vote for Jack Robinson" -- eyepatch
					else
						return "Vote for Sergeant Hook" -- swashbuckling pants
					end
				elseif advtitle == "Barrie Me at Sea" then
					if not have_item("swashbuckling pants") then
						return "Help Captain Ladle" -- swashbuckling pants
					else
						return "Help Sammy Skillet" -- stuffed shoulder parrot
					end
				end
			end })
		end
		return result, resulturl, did_action
	end

	function f.buy_use_chewing_gum()
		inform "use chewing gum"
		if not have_item("chewing gum on a string") then
			buy_item("chewing gum on a string", "m")
		end
		result, resulturl = use_item("chewing gum on a string")()
		did_action = get_result():contains("You acquire")
		return result, resulturl, did_action
	end

	function f.unlock_hidden_temple()
		-- spooky forest
		if have_item("Spooky Temple map") and have_item("Spooky-Gro fertilizer") and have_item("spooky sapling") then
			inform "use spooky temple map"
			set_result(use_item("Spooky Temple map"))
			local newwoodspt = get_page("/woods.php")
			did_action = newwoodspt:contains("The Hidden Temple")
		else
			if meat() < 100 then
				stop "Not enough meat for spooky sapling."
			end
			script.bonus_target { "noncombat" }
			softcore_stoppable_action("unlock hidden temple")
			script.set_runawayfrom { "bar", "spooky mummy", "spooky vampire", "triffid", "warwelf", "wolfman" }
			go("get parts to unlock hidden temple", 15, macro_stasis, {}, { "Smooth Movements", "The Sonata of Sneakiness" }, "Rogue Program", 10, { choice_function = function(advtitle, choicenum)
				if advtitle == "Arboreal Respite" then
					if not have_item("Spooky Temple map") then
						if not have_item("tree-holed coin") then
							return "Explore the stream"
						else
							return "Brave the dark thicket"
						end
					elseif not have_item("Spooky-Gro fertilizer") then
						return "Brave the dark thicket"
					elseif not have_item("spooky sapling") then
						return "Follow the old road"
					end
				elseif advtitle == "Consciousness of a Stream" then
					if not have_item("Spooky Temple map") and not have_item("tree-holed coin") then
						inform "get coin"
						return "Squeeze into the cave"
					end
				elseif advtitle == "Through Thicket and Thinnet" then
					if not have_item("Spooky Temple map") then
						return "Follow the coin"
					elseif not have_item("Spooky-Gro fertilizer") then
						inform "get fertilizer"
						return "Investigate the dense foliage"
					end
				elseif advtitle == "O Lith, Mon" then
					inform "get map"
					return "Insert coin to continue"
				elseif advtitle == "The Road Less Traveled" then
					if not have_item("spooky sapling") then
						return "Talk to the hunter"
					end
				elseif advtitle == "Tree's Last Stand" then
					if not have_item("spooky sapling") then
						inform "buying sapling"
						return "Buy a tree for 100 Meat"
					else
						return "Take your leave"
					end
				end
			end })
-- BUG: reads adventure title as Results. temp. workaround.
-- noncombat: {Results:} (504)
-- fallback for	Results:	504
-- 			if not did_action and have_item("spooky sapling") and get_result():contains("Results:") then
-- 				result, resulturl = post_page("/choice.php", { pwd = get_pwd(), whichchoice = 504, option = 4 })
-- 				result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, 15, nil, {})
-- 				did_action = advagain
-- 			end
		end
		return result, resulturl, did_action
	end

	function f.knob_goblin_king_with_cake(killmacro)
		if have_item("Knob cake") then
			inform "fight king in guard outfit"
			wear { hat = "Knob Goblin elite helm", weapon = "Knob Goblin elite polearm", pants = "Knob Goblin elite pants" }
			ensure_buffs { "Springy Fusilli", "Spirit of Garlic" }
			ensure_mp(40)
			fam "Frumious Bandersnatch"
			set_mcd(7) -- TODO: moxie-specific
			local pt, url = get_page("/cobbsknob.php", { action = "throneroom" })
			result, resulturl, advagain = handle_adventure_result(pt, url, "?", killmacro)
			did_action = advagain
		elseif have_item("unfrosted Knob cake") and have_item("Knob frosting") then
			inform "frost cake"
			set_result(cook_items("unfrosted Knob cake", "Knob frosting"))
			did_action = have_item("Knob cake")
		elseif have_item("Knob cake pan") and have_item("Knob batter") then
			inform "make unfrosted knob cake"
			set_result(cook_items("Knob cake pan", "Knob batter"))
			did_action = have_item("unfrosted Knob cake")
		else
			inform "get cake bits in guard outfit"
			wear { hat = "Knob Goblin elite helm", weapon = "Knob Goblin elite polearm", pants = "Knob Goblin elite pants" }
			result, resulturl, did_action = autoadventure { zoneid = 258, ignorewarnings = true }
		end
		return result, resulturl, did_action
	end

	function f.open_myst_guildstore()
		if meat() < 200 then
			stop "Not enough meat for buying MMJ at guild store."
		end
		if not have_item("magical mystery juice") then
			async_get_page("/guild.php", { place = "challenge" })
			buy_item("magical mystery juice", "2")
		end
		-- TODO: Check *actual* buying, not just having one from somewhere
		if have_item("magical mystery juice") then
			inform "opened myst guild store"
			session["__script.opened myst guild store"] = "yes"
			did_action = true
		else
			go("doing myst guild quest", 113, macro_stasis, {
				["A Sandwich Appears!"] = "sudo exorcise me a sandwich",
				["Oh No, Hobo"] = "Give him a beating",
				["Trespasser"] = "Tackle him",
				["The Singing Tree"] = "&quot;No singing, thanks.&quot;",
				["The Baker's Dilemma"] = "&quot;Sorry, I'm busy right now.&quot;",
			}, {}, "Mini-Hipster", 15)
		end
	end

	function f.unlock_guild_and_get_tonic_water()
		async_get_page("/guild.php", { place = "challenge" })
		local guildpt = get_page("/guild.php")
		if guildpt:match("scg") then
			inform "unlocked moxie guild"
			cached_stuff.have_moxie_guild_access = true
			if have_skill("Superhuman Cocktailcrafting") then
				inform "get tonic water"
				if challenge ~= "fist" then
					if count_item("soda water") < 10 then
						buy_item("soda water", "m", 10)
					end
					async_post_page("/guild.php", { action = "stillfruit", whichitem = get_itemid("soda water"), quantity = 10 })
				end
			end
			did_action = true
		else
			if not quest("Suffering For His Art") then
				async_get_page("/town_wrong.php", { place = "artist" })
				async_post_page("/town_wrong.php", { place = "artist", getquest = 1 })
			end
			go("do mox guild quest", 112, macro_stasis, {
				["Now's Your Pants!  I Mean... Your Chance!"] = "Yoink!",
				["Aww, Craps"] = "Walk away",
				["Dumpster Diving"] = "Punch the hobo",
				["The Entertainer"] = "Introduce them to avant-garde",
				["Under the Knife"] = "Umm, no thanks.  Seriously.",
				["Please, Hammer"] = "&quot;Sure, I'll help.&quot;",
			}, {}, "Mini-Hipster", 15)
		end
	end

	function f.make_star_key()
		local got_enough = false
		if count_item("star chart") >= 3 or ((challenge == "fist" or challenge == "boris") and count_item("star chart") >= 2) then
			if count_item("star") >= 8+5 and count_item("line") >= 7+3 then
				sparestars = count_item("star") - 8 - 5
				sparelines = count_item("line") - 7 - 3
				if sparestars >= 5 and sparelines >= 6 then
					got_enough = true
				elseif sparestars >= 6 and sparelines >= 5 then
					got_enough = true
				elseif sparestars >= 7 and sparelines >= 4 then
					got_enough = true
				elseif challenge == "fist" then
					got_enough = true
				end
			end
		end
		if got_enough then
			inform "make star stuff"
			if not have_item("Richard's star key") then
				shop_buyitem("Richard's star key", "starchart")
			end
			if not have_item("star hat") then
				shop_buyitem("star hat", "starchart")
			end
			if not have_item("star crossbow") and not have_item("star staff") and not have_item("star sword") and can_wear_weapons() then
				if count_item("star") >= 5 and count_item("line") >= 6 then
					shop_buyitem("star crossbow", "starchart")
				elseif count_item("star") >= 6 and count_item("line") >= 5 then
					shop_buyitem("star staff", "starchart")
				elseif count_item("star") >= 7 and count_item("line") >= 4 then
					shop_buyitem("star sword", "starchart")
				end
			end
			if have_item("Richard's star key") and have_item("star hat") and (have_item("star crossbow") or have_item("star staff") or have_item("star sword") or not can_wear_weapons()) then
				did_action = true
			end
		else
			if trailed and trailed == "Astronomer" then
				stop("Trailing " .. trailed .. " when finishing hits")
			end
			script.bonus_target { "item", "extraitem" }
			go("finish hits", 83, macro_noodlecannon, {}, { "Spirit of Peppermint", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy" }, "Slimeling", 40)
		end
		return result, resulturl, did_action
	end

	function f.make_star_key_only()
		if count_item("star") >= 8 and count_item("line") >= 7 then
			if not have_item("star chart") then
				pull_in_softcore("star chart")
			end
			shop_buyitem("Richard's star key", "starchart")
			did_action = have_item("Richard's star key")
			return
		end
		script.bonus_target { "item", "extraitem" }
		go("collect stars and lines", 83, macro_noodlecannon, {}, { "Spirit of Peppermint", "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy" }, "Slimeling", 40)
		return result, resulturl, did_action
	end

	function f.do_tavern(withfam, minmp, macrofunc)
		-- TODO: wrap in task
		if quest_text("You should head back to Bart") then
			result, resulturl = get_page("/tavern.php", { place = "barkeep" })
			did_action = have_item("Typical Tavern swill")
		elseif quest_text("Bart Ender wants you to head down") then
			cellarpt = get_page("/cellar.php")
			local function explore()
				tiles = { 4, 3, 2, 1, 6, 11, 16, 17, 21, 22 }
				for _, x in ipairs(tiles) do
					if cellarpt:contains("whichspot=" .. x .. ">") then
						inform("exploring rat cellar tile " .. x)
						return get_page("/cellar.php", { action = "explore", whichspot = x })
					end
				end
				critical "No suitable tile found for rat cellar"
			end
			fam(withfam or "Rogue Program")
			f.heal_up()
			f.burn_mp(20 + (minmp or 0))
			ensure_mp(5 + (minmp or 0))
			local pt, url = explore()
			-- TODO: handle barrels better?
			result, resulturl, did_action = handle_adventure_result(pt, url, "?", (macrofunc or macro_stasis)(), {
				["1984 Had Nothing on This Cellar"] = "Dump out the crate",
				["A Rat's Home..."] = "Kick over the castle",
				["Crate Expectations"] = "Smash the crates",
				["Staring Down the Barrel"] = "Smash the barrel",
				["Those Who Came Before You"] = "Search the body",
				["Of Course!"] = "Turn off the faucet",
			})
			if get_result():contains("You close the valve") or get_result():contains("Go back to the Typical Tavern Cellar") then
				did_action = true
			end
		else
			inform "do guild, talk to bartender"
			local guildpt = get_page("/guild.php")
			async_get_page("/guild.php", { place = "ocg" })
			async_get_page("/guild.php", { place = "ocg" })
			async_get_page("/guild.php", { place = "scg" })
			async_get_page("/guild.php", { place = "scg" })
			local pt = get_page("/tavern.php", { place = "susguy" })
			if pt:contains("First bottle's free") and pt:contains("for free!") then
				local m = meat()
				async_post_page("/tavern.php", { action = "buygoofballs" })
				if not have_item("bottle of goofballs") or meat() ~= m then
					critical "Error getting free goofballs"
				end
			end
			result, resulturl = get_page("/tavern.php", { place = "barkeep" })
			refresh_quest()
			did_action = quest_text("Bart Ender wants you to head down")
		end
		return result, resulturl, did_action
	end

	function f.do_azazel()
		local macro_smash_and_graagh = ""
		if challenge == "zombie" then
			if have_skill("Smash & Graaagh") and horde_size() >= 10 then
				macro_smash_and_graagh = "cast Smash & Graaagh"
			else
				stop "TODO: do azazel, use smash & graaagh"
			end
		end
		script.bonus_target { "item" }
		if not have_buff("Super Vision") and have_item("Greatest American Pants") then
			wear { pants = "Greatest American Pants" }
			script.get_gap_buff("Super Vision")
		end
		if not challenge then
			maybe_ensure_buffs { "Mental A-cue-ity" }
		end
		if ascensionpath("Avatar of Jarlsberg") and tonumber(status().jarlcompanion) ~= 1 and have_skill("Egg Man") and have_item("cosmic egg") then
			script.ensure_mp(15)
			cast_skill("Egg Man")
		end
		if not have_item("Azazel's lollipop") then
			if count_item("imp air") >= 5 and have_item("observational glasses") then
				inform "solve mourn"
				if not challenge then
					wear { weapon = "hilarious comedy prop", offhand = "Victor, the Insult Comic Hellhound Puppet" }
					result, resulturl = post_page("/pandamonium.php", { action = "mourn", preaction = "prop" })
					result, resulturl = post_page("/pandamonium.php", { action = "mourn", preaction = "insult" })
				end
				wear { acc3 = "observational glasses" }
				result, resulturl = post_page("/pandamonium.php", { action = "mourn", preaction = "observe" })
				did_action = have_item("Azazel's lollipop")
			else
				function macro_laughfloor()
					return [[
if monstername imp
]] .. macro_smash_and_graagh .. [[


]] .. macro_ppnoodlecannon() .. [[

  goto m_done
endif

]] .. macro_noodleserpent() .. [[

mark m_done

]]
				end
				if challenge == "fist" then
					macro_laughfloor = macro_fist
				end
				if count_item("imp air") < 5 then
					script.bonus_target { "item", "combat" }
					go("mourn, imp air: " .. count_item("imp air"), 242, macro_laughfloor, nil, { "Leash of Linguini", "Empathy", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling", 35)
				else
					script.bonus_target { "combat" }
					go("mourn, getting bosses", 242, macro_laughfloor, nil, { "Leash of Linguini", "Empathy", "Spirit of Garlic", "A Few Extra Pounds" }, "Rogue Program", 35)
				end
			end
		elseif not have_item("Azazel's unicorn") then
			if count_item("bus pass") >= 5 and (count_item("sponge cake") + count_item("comfy pillow") + count_item("booze-soaked cherry")) >= 2 and (count_item("gin-soaked blotter paper") + count_item("giant marshmallow") + count_item("beer-scented teddy bear")) >= 2 then
				inform "solve sven golly"
				local bognort = have_item("giant marshmallow") and "giant marshmallow" or "gin-soaked blotter paper"
				local stinkface = have_item("beer-scented teddy bear") and "beer-scented teddy bear" or "gin-soaked blotter paper"
				local flargwurm = have_item("booze-soaked cherry") and "booze-soaked cherry" or "sponge cake"
				local jim = have_item("comfy pillow") and "comfy pillow" or "sponge cake"
				async_post_page("/pandamonium.php", { action = "sven", preaction = "help" })
				async_post_page("/pandamonium.php", { action = "sven", bandmember = "Bognort", togive = get_itemid(bognort), preaction = "try" })
				async_post_page("/pandamonium.php", { action = "sven", bandmember = "Stinkface", togive = get_itemid(stinkface), preaction = "try" })
				async_post_page("/pandamonium.php", { action = "sven", bandmember = "Flargwurm", togive = get_itemid(flargwurm), preaction = "try" })
				result, resulturl = post_page("/pandamonium.php", { action = "sven", bandmember = "Jim", togive = get_itemid(jim), preaction = "try" })
				did_action = have_item("Azazel's unicorn")
			else
				if count_item("bus pass") < 5 then
				function macro_backstage()
					return [[
]] .. macro_smash_and_graagh .. [[


]] .. macro_ppnoodlecannon()
				end
					script.bonus_target { "item", "noncombat" }
					go("sven golly, bus passes: " .. count_item("bus pass"), 243, macro_backstage, nil, { "Leash of Linguini", "Empathy", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling", 35)
				else
					script.bonus_target { "noncombat" }
					go("sven golly, getting items", 243, macro_noodlecannon, nil, { "Leash of Linguini", "Empathy", "Spirit of Garlic", "A Few Extra Pounds" }, "Rogue Program", 35)
				end
			end
		elseif not have_item("Azazel's tutu") then
			inform "solve stranger"
			async_get_page("/pandamonium.php", { action = "moan" })
			async_get_page("/pandamonium.php", { action = "moan" })
			did_action = have_item("Azazel's tutu")
		else
			inform "solve azazel"
			async_get_page("/pandamonium.php", { action = "temp" })
			did_action = have_item("steel margarita") or have_item("steel lasagna") or have_item("steel-scented air freshener")
		end
		return result, resulturl, did_action
	end

	function f.do_boss_bat(macrofunc, extra_mp)
		ignore_buffing_and_outfit = false
		local batholept = get_page("/bathole.php")
		if not batholept:match("Boss") then
			script.bonus_target { "item" }
			if have_item("sonar-in-a-biscuit") then
				inform "using sonar"
				use_item("sonar-in-a-biscuit")
				did_action = true
			elseif not batholept:match("Beanbat") then
				f.trade_for_clover()
				if not have_item("ten-leaf clover") then
					use_item("disassembled clover")
				end
				if have_item("ten-leaf clover") then
					local eq = { hat = first_wearable { "Knob Goblin harem veil", "bum cheek" } }
					script.wear(eq)
					if get_resistance_level("Stench") <= 0 then
						script.ensure_buffs { "Astral Shell" }
					end
					if get_resistance_level("Stench") <= 0 then
						script.maybe_ensure_buffs { "Elemental Saucesphere", "Oilsphere" }
					end
					if get_resistance_level("Stench") <= 0 and not have_buff("Super Structure") and have_item("Greatest American Pants") then
						wear { pants = "Greatest American Pants" }
						script.get_gap_buff("Super Structure")
					end
					go("clovering sonars", 31, nil, nil, { "Leash of Linguini", "Empathy", "Astral Shell" }, "Exotic Parrot", 10, { equipment = eq })
					did_action = (count_item("sonar-in-a-biscuit") >= 2)
					if get_result():contains("need some sort of stench protection") then
						print("SCRIPT INFO: need some sort of stench protection")
						if session["__script.no stench resist"] then
							stop "Need stench resistance."
						end
						session["__script.no stench resist"] = true
						did_action = true
					end
				else
					stop "No ten-leaf clover for sonars!"
				end
			elseif have_item("enchanted bean") then
				go("getting sonars", 32, (macrofunc or macro_autoattack), nil, { "Leash of Linguini", "Empathy", "Fat Leon's Phat Loot Lyric", "Butt-Rock Hair" }, "Slimeling", 10 + (extra_mp or 0))
			else
				go("getting sonars / enchanted bean", 33, (macrofunc or macro_autoattack), nil, { "Leash of Linguini", "Empathy", "Fat Leon's Phat Loot Lyric", "Butt-Rock Hair" }, "Slimeling", 10 + (extra_mp or 0))
			end
		else
			-- TODO: only increment turns played when we actually enter the zone, not if something goes wrong
			local played = tonumber(session["__script.boss bat turns"]) or 0
			session["__script.boss bat turns"] = played + 1
			if played < 4 then
				go("killing boss bat guardians", 34, macro_noodlecannon, nil, { "Spirit of Garlic", "Leash of Linguini", "Empathy", "Polka of Plenty" }, { --[["Kolproxy Test Fam", --]]"Bloovian Groose", "Hobo Monkey" }, 30)
			else
				go("killing boss bat", 34, macro_noodlecannon, nil, { "Spirit of Garlic", "Leash of Linguini", "Empathy", "Polka of Plenty" }, "Knob Goblin Organ Grinder", 35, {
					finalcheck = function()
						set_mcd(4) -- TODO: moxie-specific
					end
				})
			end
		end
		return result, resulturl, did_action
	end

	function f.make_meatcar()
		if not have_item("Degrassi Knoll shopping list") and challenge ~= "boris" and challenge ~= "zombie" and challenge ~= "jarlsberg" and not ascensionpath("Avatar of Sneaky Pete") then
			inform "get shopping list"
			set_result(async_get_page("/guild.php", { place = "paco" }))
			if have_item("Degrassi Knoll shopping list") then
				did_action = true
			else
				async_post_page("/guild.php", { action = "chal" })
				async_get_page("/guild.php", { place = "paco" })
				did_action = have_item("Degrassi Knoll shopping list")
			end
		else
			inform "build meatcar"
			if not have_item("meat stack") then
				async_get_page("/inventory.php", { quantity = 1, action = "makestuff", pwd = get_pwd(), whichitem = get_itemid("meat stack"), ajax = 1 })
			end
			local function check_buy_item(name, where)
				if not have_item(name) then
					buy_item(name, where)
				end
				if not have_item(name) then
					stop("Failed to buy item: " .. tostring(name))
				end
			end
			check_buy_item("cog", "4")
			check_buy_item("empty meat tank", "4")
			check_buy_item("tires", "4")
			check_buy_item("spring", "4")
			check_buy_item("sprocket", "4")
			check_buy_item("sweet rims", "m")
			meatpaste_items("empty meat tank", "meat stack")
			meatpaste_items("spring", "sprocket")
			meatpaste_items("sprocket assembly", "cog")
			meatpaste_items("cog and sprocket assembly", "full meat tank")
			meatpaste_items("tires", "sweet rims")
			meatpaste_items("meat engine", "dope wheels")
			if not have_item("bitchin' meatcar") then
				critical "Failed to build bitchin' meatcar"
			end
			inform "unlock beach (with meatcar)"
			do_degrassi_untinker_quest()
			local rf = async_get_page("/guild.php", { place = "paco" }) -- TODO: need the topmenu refreshed from this
			use_item("Degrassi Knoll shopping list")
			local b = get_page("/place.php", { whichplace = "desertbeach" })
			did_action = b:contains("The Shore")
			result, resulturl = rf()
		end
		return result, resulturl, did_action
	end

	function f.do_crypt()
		local cyrpt = get_page("/crypt.php")
		if have_item("skeleton bone") and have_item("loose teeth") then
			meatpaste_items("skeleton bone", "loose teeth")
		end
		if have_item("evil eye") then
			use_item("evil eye")
		end
		softcore_stoppable_action("do crypt")
		local noncombattbl = {}
		if mainstat_type("Muscle") then
			noncombattbl["Turn Your Head and Coffin"] = "Investigate the fancy coffin"
			noncombattbl["Skull, Skull, Skull"] = "Leave the skulls alone"
			noncombattbl["Urning Your Keep"] = "Turn away"
			noncombattbl["Death Rattlin'"] = "Open the rattling one"
		elseif mainstat_type("Mysticality") then
			noncombattbl["Turn Your Head and Coffin"] = "Leave them all be"
			noncombattbl["Skull, Skull, Skull"] = "Leave the skulls alone"
			noncombattbl["Urning Your Keep"] = "Investigate the first urn"
			noncombattbl["Death Rattlin'"] = "Open the rattling one"
		elseif mainstat_type("Moxie") then
			noncombattbl["Turn Your Head and Coffin"] = "Leave them all be"
			noncombattbl["Skull, Skull, Skull"] = "Check behind the first one"
			noncombattbl["Urning Your Keep"] = "Turn away"
			noncombattbl["Death Rattlin'"] = "Open the rattling one"
		end
		if challenge == "fist" and meat() < 2000 then
			noncombattbl["Turn Your Head and Coffin"] = "Check out the pine box"
			noncombattbl["Skull, Skull, Skull"] = "Look inside the second one"
			noncombattbl["Urning Your Keep"] = "See what's behind Urn #3"
			ensure_buffs { "Smooth Movements" }
		end
		if cyrpt:match("Defiled Alcove") then
			if challenge == "boris" then
				local alcove_macro = macro_softcore_boris()
				if parse_evilometer().Alcove >= 32 and have_item("Rain-Doh black box") then
					alcove_macro = macro_softcore_boris([[

if monstername modern zmobie
  use Rain-Doh black box
endif

]])
				end
				if have_item("Rain-Doh box full of monster") then
					local copied = retrieve_raindoh_monster()
					if copied:contains("modern zmobie") then
						use_item("Rain-Doh box full of monster")
						local pt, url = get_page("/fight.php")
						result, resulturl, advagain = handle_adventure_result(pt, url, "?", alcove_macro)
						if advagain then
							did_action = true
						end
					else
						stop("TODO: fight rain-doh copied monster")
					end
				else
					script.bonus_target { "initiative", "noncombat" }
					script.maybe_ensure_buffs { "Hustlin'", "Sugar Rush" }
					go("do crypt alcove", 261, alcove_macro, noncombattbl, { "Butt-Rock Hair", "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds", "Springy Fusilli", "Spirit of Garlic" }, "Rogue Program", 20)
				end
			else
				-- TODO: hustlin pool buff in nonboris?
				-- TODO: cletus +init?
				-- TODO: heart of yellow?
				-- TODO: Happy Medium?
				script.bonus_target { "initiative", "noncombat" }
				maybe_ensure_buffs { "Sugar Rush" }
				go("do crypt alcove", 261, (challenge == "fist" and macro_fist or macro_stasis), noncombattbl, { "Butt-Rock Hair", "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds", "Springy Fusilli", "Spirit of Garlic" }, "Rogue Program", 20)
			end
		elseif cyrpt:match("Defiled Cranny") then
			script.bonus_target { "noncombat", "monster level" }
			maybe_ensure_buffs { "Mental A-cue-ity", "Ur-Kel's Aria of Annoyance" }
			go("do crypt cranny", 262, macro_noodlecannon, noncombattbl, { "Spirit of Garlic", "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds", "Ur-Kel's Aria of Annoyance" }, "Baby Bugged Bugbear", 35)
		elseif cyrpt:match("Defiled Niche") and (not trailed or trailed == "dirty old lihc") then
			go("do crypt niche", 263, make_cannonsniff_macro("dirty old lihc"), noncombattbl, { "Spirit of Garlic", "Butt-Rock Hair", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Rogue Program", 25, { olfact = "dirty old lihc" })
		elseif cyrpt:match("Defiled Nook") then
			script.bonus_target { "item", "extraitem" }
			if challenge == "boris" and not have_buff("Super Vision") and have_item("Greatest American Pants") then
				wear { pants = "Greatest American Pants" }
				script.get_gap_buff("Super Vision")
			end
			go("do crypt nook", 264, macro_noodlecannon, noncombattbl, { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds", "Leash of Linguini", "Empathy" }, "Slimeling", 25)
		else
			inform "kill bonerdagon"
			if challenge == "boris" then
				local toequip = {}
				if buffedmainstat() < 120 then
					ensure_buffs { "Go Get 'Em, Tiger!" }
				end
				if buffedmainstat() < 120 and have_item("Crown of the Goblin King") then
					toequip = { hat = "Crown of the Goblin King" }
				end
				wear(toequip)
				if buffedmainstat() < 120 and not have_buff("Starry-Eyed") then
					local gazept = post_page("/campground.php", { action = "telescopehigh" })
				end
				if buffedmainstat() >= 120 then
					f.heal_up()
					ensure_mp(50)
					local pt, url = get_page("/crypt.php", { action = "heart" })
					result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_softcore_boris_bonerdagon, { ["The Haert of Darkness"] = "When I...  Yes?" })
				else
					stop "TODO: Fight bonerdagon in Boris"
				end
			else
				ensure_buffs { "A Few Extra Pounds", "Springy Fusilli", "Spirit of Garlic", "Astral Shell", "Ghostly Shell" }
				maybe_ensure_buffs_in_fist { "A Few Extra Pounds", "Astral Shell", "Ghostly Shell" }
				fam "Knob Goblin Organ Grinder"
				f.heal_up()
				ensure_mp(50)
				local pt, url = get_page("/crypt.php", { action = "heart" })
				result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_noodlegeyser(7), { ["The Haert of Darkness"] = "When I...  Yes?" })
			end
		end
		return result, resulturl, did_action
	end

	function f.get_ballroom_key()
		local manor = get_page("/manor.php")
		if not manor:match("Stairs Up") then
			script.bonus_target { "noncombat" }
			go("unlock upstairs", 104, macro_noodlecannon, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Butt-Rock Hair", "A Few Extra Pounds", "Spirit of Garlic" }, "Rogue Program", 30, {
				choice_function = function(advtitle, choicenum)
					if advtitle == "Take a Look, it's in a Book!" then
						return "", 99
					elseif advtitle == "Melvil Dewey Would Be Ashamed" then
						return "Gaffle the purple-bound book"
					end
				end
			})
		else
			script.bonus_target { "extranoncombat", "noncombat" }
			maybe_ensure_buffs { "Mental A-cue-ity" }
			local macro = macro_noodlegeyser(4)
			if challenge == "fist" then
				macro = macro_fist
			end
			local should_get_key = false
			-- TODO: use tobiko marble soda??
			if challenge == "boris" or challenge == "zombie" then
				if not have_buff("Super Structure") and have_item("Greatest American Pants") then
					wear { pants = "Greatest American Pants" }
					script.get_gap_buff("Super Structure")
				end
				if not have_buff("Super Structure") and level() < 7 then
					stop "TODO: Do bedroom in challenge path at level < 7"
				end
			end
			go("do bedroom", 108, macro, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Springy Fusilli", "Spirit of Garlic" }, "Frumious Bandersnatch", 50, { choice_function = function(advtitle, choicenum)
				if choicenum == 82 then
					return "Kick it and see what happens"
				elseif choicenum == 83 then
					return "Check the bottom drawer"
				elseif choicenum == 84 then
					if have_item("Lord Spookyraven's spectacles") then
						return "Open the bottom drawer"
					else
						return "Look behind the nightstand"
					end
				elseif choicenum == 85 then
					print("bedroom key adventure", ascension["zone.manor.unlocked ballroom key"], session["__script.done ballroom key"])
					if not ascension["zone.manor.unlocked ballroom key"] and not session["__script.done ballroom key"] then
						session["__script.done ballroom key"] = "yes"
						return "Check the top drawer"
					else
						should_get_key = true
						return "Check the bottom drawer"
					end
				end
			end })
			if should_get_key and not have_item("Spookyraven ballroom key") then
				critical "Didn't get ballroom key when expected"
			end
		end
		return result, resulturl, did_action
	end

	function f.do_friars()
-- 		TODO: more buffs?
		local zone_stasis_macro = macro_stasis
		script.bonus_target { "noncombat", "extranoncombat", "item" }
		if challenge == "fist" then
			maybe_ensure_buffs { "Mental A-cue-ity" }
			zone_stasis_macro = macro_fist
		elseif mainstat_type("Mysticality") and (not have_skill("Astral Shell") or not have_skill("Tolerance of the Kitchen")) then
			maybe_ensure_buffs { "Mental A-cue-ity" }
			zone_stasis_macro = macro_noodlecannon
		end
		if fullness() + count_item("hellion cube") * 6 + 6 <= estimate_max_fullness() and script_want_reagent_pasta() then
			go("getting hellion cubes", 239, make_cannonsniff_macro("Hellion"), nil, { "Smooth Movements", "The Sonata of Sneakiness", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling", 20, { olfact = "Hellion" })
		elseif not have_item("box of birthday candles") then
			go("getting candles", 238, zone_stasis_macro, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Astral Shell", "Ghostly Shell", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "A Few Extra Pounds" }, { "Scarecrow with Boss Bat britches", "Rogue Program" }, 15)
		elseif (count_item("hot wing") < 3 or (meat() < 1000 and fullness() < 5)) and not have_item("box of birthday candles") then
			go("getting hot wings", 238, macro_noodlecannon, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "A Few Extra Pounds" }, "Slimeling even in fist", 20)
--		elseif have_reagent_pastas < 4 and not highskill_at_run and ascensionstatus() == "Hardcore" and challenge ~= "zombie" then
--			go("getting more hellion cubes", 239, macro_noodlecannon, nil, { "Leash of Linguini", "Empathy", "Butt-Rock Hair", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling", 20, { olfact = "Hellion" })
		elseif not have_item("dodecagram") then
			go("getting dodecagram", 239, macro_noodlecannon, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling even in fist", 20)
		elseif not have_item("eldritch butterknife") then
			go("getting butterknife", 237, zone_stasis_macro, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Astral Shell", "Ghostly Shell", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "A Few Extra Pounds" }, { "Scarecrow with Boss Bat britches", "Rogue Program" }, 15)
		elseif count_item("hot wing") < 3 then
			go("getting hot wings", 238, macro_noodlecannon, nil, { "Leash of Linguini", "Empathy", "Butt-Rock Hair", "A Few Extra Pounds" }, "Slimeling", 20)
		else
			inform "do ritual"
			async_post_page("/friars.php", { pwd = get_pwd(), action = "ritual" })
			async_get_page("/pandamonium.php")
			refresh_quest()
			did_action = not quest("Trial By Friar") and quest_text("this is Azazel in Hell")
		end
		return result, resulturl, did_action
	end

	function f.unlock_manor()
		local townright = get_page("/town_right.php")
		if townright:match("The Haunted Pantry") then
			script.set_runawayfrom { "flame-broiled meat blob", "overdone flame-broiled meat blob", "undead elbow macaroni" }
			go("unlock manor", 113, macro_stasis, {
				["Oh No, Hobo"] = "Give him a beating",
				["Trespasser"] = "Tackle him",
				["The Singing Tree"] = "&quot;No singing, thanks.&quot;",
				["The Baker's Dilemma"] = "&quot;Sorry, I'm busy right now.&quot;",
			}, {}, "Mini-Hipster", 25)
			if get_result():contains("The Manor in Which You're Accustomed") then
				did_action = true
			end
		end
	end

	function f.get_library_key()
		local townright = get_page("/town_right.php")
		if townright:match("The Haunted Pantry") then
			f.unlock_manor()
		else
			local manor = get_page("/manor.php")
			if manor:match("Stairs Up") then
				inform "breaking spookyraven stairs"
				set_result(get_page("/place.php", { whichplace = "spookyraven1", action = "sr1_stairs1" })) -- breaking stairs so they reflect state
				did_action = not get_page("/manor.php"):match("Stairs Up")
			else
				if have_item("pool cue") and have_item("handful of hand chalk") and not have_buff("Chalky Hand") then
					use_item("handful of hand chalk") -- TODO: ensure_buffs
				end
				script.bonus_target { "noncombat" }
				if ascensionpath("Avatar of Sneaky Pete") and ascensionstatus("Hardcore") and not have_skill("Smoke Break") and not have_skill("Flash Headlight") then
					-- TODO: do this better
					script.bonus_target { "noncombat", "easy combat" }
				end
				go("unlock library", 105, macro_stasis, {
					["Minnesota Incorporeals"] = "Let the ghost break",
					["Broken"] = "Go for a solid",
					["A Hustle Here, a Hustle There"] = "Go for the 8-ball",
				}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic" }, "Stocking Mimic", 15)
			end
		end
		return result, resulturl, did_action
	end

	function f.get_dod_wand()
		-- TODO: don't get teleportitis that overlaps with SR
		local dapt = get_page("/da.php")
		if dapt:contains("The Enormous Greater-Than Sign") then
			if advs() < 20 then
				stop "Fewer than 20 advs for > sign"
			elseif meat() < 1000 then
				stop "Need 1k meat for > sign"
			elseif have_item("plus sign") and have_buff("Teleportitis") then
				fam "Frumious Bandersnatch"
				ensure_buffs { "Ode to Booze" }
				stop "TODO: find oracle, then do DD to wear off teleportitis"
			else
				go("unlock dod", 226, macro_noodlecannon, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic" }, "Slimeling", 25, { choice_function = function(advtitle, choicenum)
					if advtitle == "Typographical Clutter" then
						if not have_item("plus sign") then
							return "The big apostrophe"
						else
							return "The upper-case Q"
						end
					end
				end })
			end
		else
			if have_item("dead mimic") then
				set_result(use_item("dead mimic"))
				did_action = have_item("pine wand") or have_item("ebony wand") or have_item("hexagonal wand") or have_item("aluminum wand") or have_item("marble wand")
			elseif meat() < 5000 then
				stop "Need 5k meat for DoD wand"
			else
				go("get dod wand", 39, macro_noodlecannon, {
					["Ouch!  You bump into a door!"] = "Buy what appears to be some sort of cloak (5,000 Meat)",
				}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Leash of Linguini", "Empathy" }, "Slimeling", 20, {
					finalcheck = function()
						if meat() < 5000 then
							stop "Need 5k meat for DoD wand"
						end
					end
				})
			end
		end
		return result, resulturl, did_action
	end

	local function castlego(backupf, ...)
		set_result("(no result)")
		go(...)
		if get_result():contains("have to learn to walk before you can learn to fly") then
			backupf()
		elseif get_result():contains("but the door at the top is closed") then
			backupf()
		elseif get_result():contains("still too short to reach a doorknob") then
			backupf()
		end
	end

	function f.unlock_top_floor()
		castlego(script.unlock_ground_floor, "unlock top floor", 323, macro_noodleserpent, {}, { "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Butt-Rock Hair" }, "Slimeling", 40, { choice_function = function(advtitle, choicenum)
			if advtitle == "There's No Ability Like Possibility" then
				return "Go out the Way You Came In"
			elseif advtitle == "Putting Off Is Off-Putting" then
				return "Get out of this Junk"
			elseif advtitle == "Huzzah!" then
				return "Seek the Egress Anon"
			end
		end})
		if get_result():contains("ground floor is lit much better than the basement") then
			did_action = true
		end
	end

	function f.unlock_ground_floor()
		-- TODO: Wear amulet/umbrella
		script.bonus_target { "noncombat", "item" }
		go("unlock ground floor", 322, macro_noodleserpent, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Butt-Rock Hair" }, "Slimeling", 40, { choice_function = function(advtitle, choicenum)
			if advtitle == "You Don't Mess Around with Gym" then
				if have_equipped_item("amulet of extreme plot significance") then
					return "Check out the Mirror"
				elseif not have_item("massive dumbbell") then
					return "Grab a Dumbbell"
				else
					return "Work Out"
				end
			elseif advtitle == "Out in the Open Source" then
				if have_item("massive dumbbell") then
					return "Check out the Dumbwaiter"
				else
					return "Crawl through the Heating Vent"
				end
			elseif advtitle == "The Fast and the Furry-ous" then
				return "Crawl Through the Heating Duct"
			end
		end})
	end

	function f.do_castle()
		if ascension_script_option("manual castle quest") then
			stop "STOPPED: Ascension script option set to do castle quest manually"
		end

		script.bonus_target { "noncombat", "item" }
		castlego(script.unlock_top_floor, "finish castle quest", 324, macro_noodleserpent, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Butt-Rock Hair" }, "Slimeling", 50, { choice_function = function(advtitle, choicenum)
			if advtitle == "Copper Feel" then
				if not have_item("steam-powered model rocketship") then
					return "Investigate the Whirligigs and Gimcrackery"
				elseif have_item("model airship") then
					return "Harrumph in Disdain"
				else
					return "Go through the Crack"
				end
			elseif advtitle == "Melon Collie and the Infinite Lameness" then
				if have_item("model airship") or not have_item("steam-powered model rocketship") then
					return "Gimme Steam"
				elseif have_item("drum 'n' bass 'n' drum 'n' bass record") then
					return "Change up the Music"
				else
					return "End His Suffering"
				end
			elseif advtitle == "Yeah, You're for Me, Punk Rock Giant" then
				return "Look Behind the Poster"
			elseif advtitle == "Flavor of a Raver" then
				if not have_item("drum 'n' bass 'n' drum 'n' bass record") then
					return "Raid the Crate"
				else
					return "Pick a Fight"
				end
			elseif advtitle == "Keep On Turnin' the Wheel in the Sky" then
				return "Spin That Wheel, Giants Get Real"
			end
		end})
		if not did_action and not locked() then
			get_page("/council.php")
			refresh_quest()
			did_action = not quest("The Rain on the Plains is Mainly Garbage")
		end
	end

	function f.unlock_hits()
		if ascension_script_option("manual castle quest") then
			stop "STOPPED: Ascension script option set to do castle quest manually"
		end

		script.bonus_target { "noncombat", "item" }
		castlego(script.unlock_top_floor, "unlock hits", 324, macro_noodleserpent, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Butt-Rock Hair" }, "Slimeling", 40, { choice_function = function(advtitle, choicenum)
			if advtitle == "Copper Feel" then
				return "Investigate the Whirligigs and Gimcrackery"
			elseif advtitle == "Melon Collie and the Infinite Lameness" then
				return "Gimme Steam"
			elseif advtitle == "Yeah, You're for Me, Punk Rock Giant" then
				return "Look Behind the Poster"
			elseif advtitle == "Flavor of a Raver" then
				if not have_item("drum 'n' bass 'n' drum 'n' bass record") then
					return "Raid the Crate"
				else
					return "Pick a Fight"
				end
			end
		end})
	end

	function f.find_black_market()
		use_dancecard()
		local have_blackbird_parts = (have_item("broken wings") and have_item("sunken eyes")) or have_item("reassembled blackbird")
		if have_item("black market map") and (can_change_familiar() or have_blackbird_parts) then
			inform "locate black market"
			meatpaste_items("broken wings", "sunken eyes")
			fam "Reassembled Blackbird"
			set_result(use_item("black market map"))
			did_action = not have_item("black market map")
		else
			if have_blackbird_parts then
				script.bonus_target { "noncombat" }
			else
				script.bonus_target { "item" }
			end
			go("do black forest", 111, macro_noodleserpent, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling", 45)
		end
	end

	function f.take_shore_trip()
		local choices = {
			Muscle = "Distant Lands Dude Ranch Adventure",
			Mysticality = "Tropical Paradise Island Getaway",
			Moxie = "Large Donkey Mountain Ski Resort",
		}
		result, resulturl, advagain = autoadventure { zoneid = 355, noncombatchoices = { ["Welcome to The Shore, Inc."] = choices[mainstat_type()] } }
		return result, resulturl, advagain
	end

	function f.get_macguffin_diary()
		inform "shore for macguffin diary"
		if not have_item("forged identification documents") then
			if challenge == "fist" then
				maybe_ensure_buffs_in_fist { "Astral Shell", "Ghostly Shell", "Empathy" }
				local towear = {}
				local famt = fam "Slimeling"
				local fammpregen, famequip = famt.mpregen, famt.familiarequip
				if famequip and have_item(famequip) then
					towear.familiarequip = famequip
				end
				wear(towear)
				if have_buff("Astral Shell") and have_skill("Drunken Baby Style") and drunkenness() >= 8 then
					inform "fighting wu tang the betrayer"
					use_hottub()
					ensure_mp(50)
					local pt, url = get_page("/woods.php", { action = "fightbmguy" })
					result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_fist)
					did_action = (advagain and have_item("forged identification documents"))
				else
					stop "TODO: Get identification documents in fist"
				end
			else
				shop_buyitem("forged identification documents", "blackmarket")
				if not have_item("forged identification documents") then
					critical "Failed to buy identification documents"
				end
			end
		end
		if have_item("forged identification documents") and not have_item("your father's MacGuffin diary") then
			result, resulturl = script.take_shore_trip()
		end
		if have_item("your father's MacGuffin diary") then
			result, resulturl = get_page("/diary.php", { whichpage = "1" })
			did_action = true
		end
	end

	function f.do_oasis_and_desert()
		if have_item("worm-riding hooks") and have_item("drum machine") then
			inform "using drum machine"
			set_result(use_item("drum machine"))
			did_action = not have_item("worm-riding hooks")
			return
		elseif have_item("desert sightseeing pamphlet") then
			inform "using desert sightseeing pamphlet"
			set_result(use_item("desert sightseeing pamphlet"))
			did_action = not have_item("desert sightseeing pamphlet")
			return
		end
		local beachpt = get_page("/place.php", { whichplace = "desertbeach" })
		if not beachpt:contains("Gnasir") then
			set_result(run_task {
				message = "find gnasir",
				minmp = 70,
				equipment = { offhand = can_wear_weapons() and "UV-resistant compass" or nil },
				action = adventure {
					zone = "The Arid, Extra-Dry Desert",
					macro_function = macro_noodleserpent,
					noncombats = { ["A Sietch in Time"] = "Whoops." },
				}
			})
			if not did_action and not locked() then
				local beachpt = get_page("/place.php", { whichplace = "desertbeach" })
				did_action = beachpt:contains("Gnasir")
			end
			return
		end
		local need_stone_rose
		local need_killing_jar
		local need_black_paint
		local need_manual_pages
		local need_count

		local function update_tracker()
			local trackerpt = get_charpane_quest_status()
			need_stone_rose = trackerpt:contains("<br>&nbsp;&nbsp;&nbsp;*  a stone rose")
			need_killing_jar = trackerpt:contains("<br>&nbsp;&nbsp;&nbsp;*  a banshee's killing jar")
			need_black_paint = trackerpt:contains("<br>&nbsp;&nbsp;&nbsp;*  a can of black paint")
			need_manual_pages = trackerpt:contains("<br>&nbsp;&nbsp;&nbsp;*  the 15 pages of his worm-riding manual")
			need_count = (need_stone_rose and 1 or 0) + (need_killing_jar and 1 or 0) + (need_black_paint and 1 or 0) + (need_manual_pages and 1 or 0)
		end
		update_tracker()
		local original_count = need_count

		local function give_to_gnasir()
			get_page("/place.php", { whichplace = "desertbeach", action = "db_gnasir" })
			result, resulturl = post_page("/choice.php", { pwd = session.pwd, whichchoice = 805, option = 2 })
			async_post_page("/choice.php", { pwd = session.pwd, whichchoice = 805, option = 1 })
			update_tracker()
		end

		if need_black_paint then
			inform "giving gnasir black paint"
			if not have_item("can of black paint") then
				shop_buyitem("can of black paint", "blackmarket")
			end
			if not have_item("can of black paint") then
				critical "Failed to buy can of black paint"
			end
			give_to_gnasir()
			did_action = need_count < original_count
			return
		elseif need_killing_jar and have_item("killing jar") then
			inform "giving killing jar"
			give_to_gnasir()
			did_action = need_count < original_count
			return
		elseif need_stone_rose then
			if have_item("stone rose") then
				inform "giving stone rose"
				give_to_gnasir()
				did_action = need_count < original_count
				return
			else
				return run_task {
					message = "get stone rose",
					minmp = 60,
					buffs = { "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" },
					familiar = "Slimeling",
					bonus_target = { "item" },
					runawayfrom = { "oasis monster", "rolling stone" },
					action = adventure {
						zone = "The Oasis",
						macro_function = macro_noodleserpent,
					}
				}
			end
		else
			if count_item("worm-riding manual page") >= 15 then
				inform "giving manual pages"
				give_to_gnasir()
				did_action = need_count < original_count
				return
			end
			if have_item("worm-riding hooks") and not have_item("drum machine") and not ascensionstatus("Hardcore") then
				pull_in_softcore("drum machine")
			end
			if have_item("worm-riding hooks") and have_item("drum machine") then
				set_result(use_item("drum machine"))
				did_action = not have_item("worm-riding hooks")
				return
			end
			if not have_buff("Ultrahydrated") then
				run_task {
					message = "getting ultrahydrated",
					action = adventure { zone = "The Oasis" }
				}
				did_action = have_buff("Ultrahydrated")
				return
			end
			return run_task {
				message = "explore desert",
				minmp = 70,
				equipment = { offhand = can_wear_weapons() and "UV-resistant compass" or nil },
				action = adventure {
					zone = "The Arid, Extra-Dry Desert",
					macro_function = macro_noodleserpent,
				}
			}
		end
	end

	function f.do_never_odd_or_even_quest()
		if not have_item("Talisman o' Nam") then
			if not have_item("pirate fledges") then
				if have_item("ball polish") then
					use_item("ball polish")
				end
				if have_item("mizzenmast mop") then
					use_item("mizzenmast mop")
				end
				if have_item("rigging shampoo") then
					use_item("rigging shampoo")
				end
				script.bonus_target { "item", "combat", "extraitem" }
				softcore_stoppable_action("do fcle")
				go("doing fcle", 158, macro_noodleserpent, {
					["Chatterboxing"] = "Fight chatty fire with chatty fire",
				}, { "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog", 40, { equipment = { hat = "eyepatch", pants = "swashbuckling pants", acc3 = "stuffed shoulder parrot" } })
				if get_result():match("You quickly scribble a random phone number onto the napkin and hand it to the clingy pirate.") then
					advagain = true
				end
			else
				use_dancecard()
				wear { acc3 = "pirate fledges" }
				local covept = get_page("/cove.php")
				if not covept:match("Belowdecks") then
					-- TODO: set sail! OK to be low on meat if we've done it already
					-- choice	O Cap'm, My Cap'm	189
					-- opt	1	Front the meat and take the wheel
					-- opt	2	Step away from the helm
					-- posting page /choice.php params: Just [("pwd","78c111d81e1e56105e9a2c33124f31f9"),("whichchoice","189"),("option","1")]
					-- got uri: /ocean.php | ?intro=1 (from /choice.php), size 2100
					-- posting page /ocean.php params: Just [("lon","22"),("lat","62")]
					-- got uri: /ocean.php |  (from /ocean.php), size 2741
					script.bonus_target { "noncombat" }
					script.set_runawayfrom { "wacky pirate", "warty pirate", "wealthy pirate", "whiny pirate", "witty pirate" }
					go("do poop deck", 159, macro_noodlecannon, { ["O Cap'm, My Cap'm"] = "Step away from the helm" }, { "Butt-Rock Hair", "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Bacon Grease" }, "Rogue Program", 35, { equipment = { acc3 = "pirate fledges" } })
					if get_result():contains("It's Always Swordfish") then
						did_action = true
					end
				elseif count_item("snakehead charrrm") >= 2 then
					inform "pasting talisman"
					meatpaste_items("snakehead charrrm", "snakehead charrrm")
					did_action = have_item("Talisman o' Nam")
				elseif have_item("gaudy key") then
					inform "using gaudy key"
					local charms = count_item("snakehead charrrm")
					set_result(use_item("gaudy key"))
					did_action = (count_item("snakehead charrrm") > charms)
				else
					if have_item("Rain-Doh box full of monster") then
						local copied = retrieve_raindoh_monster()
						if copied:contains("gaudy pirate") then
							use_item("Rain-Doh box full of monster")
							local pt, url = get_page("/fight.php")
							result, resulturl, advagain = handle_adventure_result(pt, url, "?", make_cannonsniff_macro("gaudy pirate"))
							if advagain then
								did_action = true
							end
						else
							stop("TODO: fight rain-doh copied monster")
						end
					else
						go("get gaudy keys", 160, make_cannonsniff_macro("gaudy pirate"), nil, { "Spirit of Bacon Grease" }, "Rogue Program", 40, { equipment = { acc3 = "pirate fledges" }, olfact = "gaudy pirate" })
					end
				end
			end
		else
			-- WORKAROUND: doesn't appear until plains is loaded
			if not have_equipped_item("Talisman o' Nam") then
				wear { acc3 = "Talisman o' Nam" }
				async_get_page("/plains.php")
			end
			if have_item("Mega Gem") then
				inform "fighting Dr. Awkward"
				fam "Knob Goblin Organ Grinder"
				script.ensure_buffs { "A Few Extra Pounds", "Spirit of Garlic" }
				script.wear { acc3 = "Mega Gem", acc2 = "Talisman o' Nam" }
				script.ensure_mp(60)
				script.heal_up()
				result, resulturl = get_page("/place.php", { whichplace = "palindome", action = "pal_droffice" })
				result, resulturl = handle_adventure_result(get_result(), resulturl, "?", macro_noodleserpent, { ["Dr. Awkward"] = "War, sir, is raw!" })
				did_action = have_item("Staff of Fats")
			elseif quest_text("wants some wet stew in return") then
				if have_item("wet stunt nut stew") then
					inform "getting mega gem"
					get_page("/place.php", { whichplace = "palindome", action = "pal_mroffice" })
					did_action = have_item("Mega Gem")
				else
					script.bonus_target { "combat" }
					go("find wet stunt nut stew", 386, macro_noodleserpent, {
						["No sir, away!  A papaya war is on!"] = "Give the men a pep talk",
						["Sun at Noon, Tan Us"] = "A little while",
						["Rod Nevada, Vendor"] = "Accept (500 Meat)",
						["Do Geese See God?"] = "Buy the photograph (500 meat)",
						["A Pre-War Dresser Drawer, Pa!"] = "Ignawer the drawer",
					}, { "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling", 40, { equipment = { acc3 = "Talisman o' Nam" } })
				end
			elseif quest_text("track down this Mr. Alarm guy") then
				if have_item("&quot;2 Love Me, Vol. 2&quot;") then
					use_item("&quot;2 Love Me, Vol. 2&quot;")
				end
				inform "talking to Mr. Alarm"
				set_result(get_page("/place.php", { whichplace = "palindome", action = "pal_mroffice" }))
				refresh_quest()
				did_action = quest_text("wants some wet stew in return")
			else
				if have_item("&quot;I Love Me, Vol. I&quot;") then
					use_item("&quot;I Love Me, Vol. I&quot;")
				end
				if have_item("photograph of God") and have_item("photograph of a dog") and have_item("photograph of a red nugget") and have_item("photograph of an ostrich egg") then
					local pt = get_page("/place.php", { whichplace = "palindome" })
					if pt:contains("Dr. Awkward's Office") then
						inform "placing palindome photos"
						get_page("/place.php", { whichplace = "palindome", action = "pal_droffice" })
						result, resulturl = post_page("/choice.php", { pwd = session.pwd, whichchoice = 872, option = 1, photo1 = get_itemid("photograph of God"), photo2 = get_itemid("photograph of a red nugget"), photo3 = get_itemid("photograph of a dog"), photo4 = get_itemid("photograph of an ostrich egg") })
						use_hottub()
						did_action = have_item("&quot;2 Love Me, Vol. 2&quot;")
						return
					end
				end
				if meat() < 500 then
					stop "Not enough meat for palindome"
				end
				script.bonus_target { "noncombat" }
				go("find photographs", 386, macro_noodleserpent, {
					["No sir, away!  A papaya war is on!"] = "Give the men a pep talk",
					["Sun at Noon, Tan Us"] = "A little while",
					["Rod Nevada, Vendor"] = "Accept (500 Meat)",
					["Do Geese See God?"] = "Buy the photograph (500 meat)",
					["A Pre-War Dresser Drawer, Pa!"] = "Ignawer the drawer",
				}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling", 40, { equipment = { acc3 = "Talisman o' Nam" } })
			end
		end
	end

	-- TODO: make this possible from fax page, not just automation
	local function try_getting_faxbot_monster(target, code)
		if f.get_photocopied_monster() == nil then
			local function timestamp()
				local t = os.date("*t")
				return t.hour * 3600 + t.min * 60 + t.sec
			end
			async_get_page("/submitnewchat.php", { pwd = get_pwd(), graf = ("/msg FaxBot "..code) })
			local tstart = timestamp()
			for i = 1, 100 do
				local pt = get_page("/clan_log.php")
				local faxedtext = pt:match("faxed in .-<")
				if not faxedtext then
					if i >= 5 and timestamp() >= tstart + 10 then
						async_get_page("/clan_viplounge.php", { preaction = "receivefax" })
						break
					elseif i > 50 then
						critical "Error when checking clan log for faxbot"
					end
				elseif faxedtext:contains(target) then
					async_get_page("/clan_viplounge.php", { preaction = "receivefax" })
					break
				end
				if timestamp() > tstart + 300 then
					break
				end
			end
		end
	end

	function f.get_faxbot_fax(target)
		if playername():match("^Devster[0-9]+$") then
			stop("Get fax for devster: " .. target)
		end
		if f.get_photocopied_monster() ~= target then
			local code = get_faxbot_command(target)
			print("  photocopied:", f.get_photocopied_monster(), "getting", target, code)
			try_getting_faxbot_monster(target, code)
			try_getting_faxbot_monster(target, code)
			try_getting_faxbot_monster(target, code)
		end
		if f.get_photocopied_monster() ~= target then
			stop("Didn't get "..target.." from faxbot")
		end
	end

	-- TODO: more with bander if heavier
	function f.spooky_forest_runaways()
		if ascensionpath("BIG!") then return end
		local woodspt = get_page("/woods.php")
		if woodspt:contains("The Hidden Temple") then return end
		fam "Pair of Stomping Boots"
		if familiarid() ~= familiar_data["Pair of Stomping Boots"].id then
			return
		end
		ensure_buffs { "Leash of Linguini", "Empathy" }
		local weareq = {}
		wear(weareq)
		if buffedfamiliarweight() < (1 + get_daily_counter("familiar.free butt runaways")) * 5 then
			if have_item("sugar shield") then
				weareq = { familiarequip = "sugar shield" }
				wear(weareq)
			end
			ensure_buffs { "Heavy Petting" }
		end
-- 		print("weareq:", table_to_str(weareq))
		if buffedfamiliarweight() >= (1 + get_daily_counter("familiar.free butt runaways")) * 5 then
			-- TODO: copy-pasted, merge this
			if have_item("Spooky Temple map") and have_item("Spooky-Gro fertilizer") and have_item("spooky sapling") then
				inform "use spooky temple map"
				set_result(use_item("Spooky Temple map"))
				local newwoodspt = get_page("/woods.php")
				did_action = newwoodspt:contains("The Hidden Temple")
			else
				if meat() < 100 and have_item("Spooky Temple map") and have_item("Spooky-Gro fertilizer") then
					stop "Not enough meat for spooky sapling"
				end
				script.bonus_target { "noncombat" }
				go("runaways to unlock hidden temple, " .. buffedfamiliarweight() .. " lb, already done " .. get_daily_counter("familiar.free butt runaways") .. " runaways", 15, macro_spooky_forest_runaway, {}, { "Smooth Movements", "The Sonata of Sneakiness" }, "Pair of Stomping Boots", 10, { choice_function = function(advtitle, choicenum)
					if advtitle == "Arboreal Respite" then
						if not have_item("Spooky Temple map") then
							if not have_item("tree-holed coin") then
								return "Explore the stream"
							else
								return "Brave the dark thicket"
							end
						elseif not have_item("Spooky-Gro fertilizer") then
							return "Brave the dark thicket"
						elseif not have_item("spooky sapling") then
							return "Follow the old road"
						end
					elseif advtitle == "Consciousness of a Stream" then
						if not have_item("Spooky Temple map") and not have_item("tree-holed coin") then
							inform "get coin"
							return "Squeeze into the cave"
						end
					elseif advtitle == "Through Thicket and Thinnet" then
						if not have_item("Spooky Temple map") then
							return "Follow the coin"
						elseif not have_item("Spooky-Gro fertilizer") then
							inform "get fertilizer"
							return "Investigate the dense foliage"
						end
					elseif advtitle == "O Lith, Mon" then
						inform "get map"
						return "Insert coin to continue"
					elseif advtitle == "The Road Less Traveled" then
						if not have_item("spooky sapling") then
							return "Talk to the hunter"
						end
					elseif advtitle == "Tree's Last Stand" then
						if not have_item("spooky sapling") then
							inform "buying sapling"
							return "Buy a tree for 100 Meat"
						else
							return "Take your leave"
						end
					end
				end, equipment = weareq, finalcheck = function()
-- 					print("final bander weight check:", buffedfamiliarweight())
-- 					print("  wearing", table_to_str(equipment()))
					if buffedfamiliarweight() < (1 + get_daily_counter("familiar.free butt runaways")) * 5 then
						critical "Fam weight somehow got too low!"
					end
				end })
	-- BUG: reads adventure title as Results. -> workaround.
	-- noncombat: {Results:} (504)
	-- fallback for	Results:	504
				if not did_action and have_item("spooky sapling") and get_result():contains("Results:") then
					result, resulturl = post_page("/choice.php", { pwd = get_pwd(), whichchoice = 504, option = 4 })
					result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, 15, nil, {})
					did_action = advagain
				end
-- 				print(resulturl, resulturl:contains("fight.php"), result:contains("tosses you onto his back, and flooms away"))
				if resulturl:contains("fight.php") and not (get_result():contains("tosses you onto his back, and flooms away") or get_result():contains("kicks you in the butt to speed your escape.")) then
					print("failed to run away, wtf?", resulturl, ", page text:")
					print("   +++   ")
					print(get_result())
					print("   ---   ")
					critical "Failed to use free butt-runaway"
				end
			end
			wear {}
			return result, resulturl, did_action
		end
	end

	return f
end

function get_faxbot_command(monstername)
	for _, cat in pairs(datafile("faxbot-monsters").categories) do
		for a, b in pairs(cat) do
			if b.name == monstername then
				return a
			end
		end
	end
end

function do_degrassi_untinker_quest()
	async_get_page("/place.php", { whichplace = "forestvillage" })
	async_get_page("/place.php", { whichplace = "forestvillage", action = "fv_untinker_quest" })
	async_post_page("/place.php", { whichplace = "forestvillage", preaction = "screwquest", action = "fv_untinker_quest" })
	async_get_page("/place.php", { whichplace = "knoll_friendly", action = "dk_innabox" })
	async_get_page("/place.php", { whichplace = "forestvillage", action = "fv_untinker" })
end

function get_charpane_quest_status()
	local charpt = get_page("/charpane.php")
	local tblstr = charpt:match([[<table id="nudges".-</table>]])
	if not tblstr then
		critical "Charpane quest tracker not found"
	end
	return tblstr
end

function vamp_out(targetstat)
	result, resulturl = get_page("/town.php", { action = "vampout" })
	result, resulturl = handle_adventure_result(result, resulturl, "?", nil, { ["Interview With You"] = "Visit Isabella's" })
	if result:contains("A small bell chimes above the door of Isabella's as you enter.") then
		for _, x in ipairs(interview_with_you_stat_choices[targetstat]) do
			async_post_page("/choice.php", { pwd = session.pwd, whichchoice = 546, option = x })
		end
	end
end

function can_change_familiar()
	return not ascensionpath("Avatar of Boris") and not ascensionpath("Avatar of Jarlsberg") and not ascensionpath("Avatar of Sneaky Pete")
end

function have_gelatinous_cubeling_items()
	return have_item("eleven-foot pole") and have_item("ring of Detect Boring Doors") and have_item("Pick-O-Matic lockpicks")
end

function check_buying_from_knob_dispensary()
	local pt = get_page("/submitnewchat.php", { graf = "/buy Knob Goblin seltzer", pwd = session.pwd })
	-- TODO: elseif pt:contains not sure then return false else error
	return pt:contains("whichstore=k")
end

function buy_shore_inc_item(item)
	autoadventure { zoneid = get_zoneid("The Shore, Inc. Travel Agency"), noncombatchoices = { ["Welcome to The Shore, Inc."] = "Check out the gift shop" } }
	return shop_buyitem(item, "shore")
end

