__allow_global_writes = true

local script_cached_stuff = {}

function get_automation_scripts(cached_stuff)
	local f = {}
	local script = f
	cached_stuff = cached_stuff or script_cached_stuff

	local function smith_items_craft(a, b)
		return post_page("/craft.php", { mode = "smith", pwd = get_pwd(), action = "craft", a = get_itemid(a), b = get_itemid(b), qty = 1, ajax = 1 })
	end

	local function feed_slimeling()
		if ascensionstatus() == "Aftercore" then return end
		local function feed(name)
-- 			print("feeding", name)
			return post_page("/familiarbinger.php", { action = "binge", pwd = get_pwd(), qty = 1, whichitem = get_itemid(name) })
		end
		local feed_items = get_ascension_automation_settings().slimeling_feed_items
		local feed_except_one = get_ascension_automation_settings().slimeling_feed_except_one
		for i in table.values(feed_items) do
			if have(i) then
				feed(i)
			end
		end
		for tbl in table.values(feed_except_one) do
			for i in table.values(tbl) do
				if count(i) > 1 then
					if count(i) > 10 then
						stop("More than 10 of " .. i .. " when feeding slimeling")
					end
					feed(i)
				end
			end
		end
	end

	local familiar_data = {
		["Kolproxy Test Fam"] = { id = 12345, fallback = "Midget Clownfish" },
		["Leprechaun"] = { id = 2 },
		["Baby Gravy Fairy"] = { id = 15 },
		["Flaming Gravy Fairy"] = { id = 34, fallback = "Frozen Gravy Fairy" },
		["Frozen Gravy Fairy"] = { id = 35, fallback = "Stinky Gravy Fairy" },
		["Stinky Gravy Fairy"] = { id = 36 },
		["Star Starfish"] = { id = 17, mpregen = true, attack = true },
		["Smiling Rat"] = { id = 142 },
		["Reassembled Blackbird"] = { id = 59 },
		["Slimeling"] = { id = 112, f = feed_slimeling, mpregen = true, attack = true, fallback = "Baby Gravy Fairy" },
		["Mini-Hipster"] = { id = 136, mpregen = true, attack = true, familiarequip = "fixed-gear bicycle", fallback = "Rogue Program" },
		["Rogue Program"] = { id = 135, mpregen = true, attack = true, fallback = "Midget Clownfish" },
		["Jumpsuited Hound Dog"] = { id = 69, fallback = "Slimeling" },
		["Frumious Bandersnatch"] = { id = 105, fallback = "Mini-Hipster" },
		["Rock Lobster"] = { id = 114, mpregen = true, attack = true, fallback = "Rogue Program" },
		["Knob Goblin Organ Grinder"] = { id = 139, attack = true, fallback = "Llama Lama" },
		["Midget Clownfish"] = { id = 106, mpregen = true, attack = true, fallback = "Star Starfish" },
		["Stocking Mimic"] = { id = 120, mpregen = true, attack = true, familiarequip = "bag of many confections", fallback = "Rogue Program" },
		["Hobo Monkey"] = { id = 89, fallback = "He-Boulder" },
		["He-Boulder"] = { id = 113, mpregen = true, fallback = "Leprechaun" },
		["Baby Bugged Bugbear"] = { id = 124, familiarequip = "bugged balaclava", fallback = "Frumious Bandersnatch" },
		["Llama Lama"] = { id = 90, fallback = "Bloovian Groose" },
		["Exotic Parrot"] = { id = 72, fallback = "Llama Lama" },
		["Mad Hatrack with spangly sombrero"] = { id = 82, familiarequip = "spangly sombrero", fallback = "Slimeling even in fist", needsequip = true },
		["Scarecrow with spangly mariachi pants"] = { id = 152, familiarequip = "spangly mariachi pants", fallback = "Mad Hatrack with spangly sombrero", needsequip = true },
		["Scarecrow with studded leather boxer shorts"] = { id = 152, familiarequip = "studded leather boxer shorts", needsequip = true, fallback = "Llama Lama" },
		["Scarecrow with Boss Bat britches"] = { id = 152, familiarequip = "Boss Bat britches", needsequip = true, mpregen = true, fallback = "Rogue Program" },
		["Pair of Stomping Boots"] = { id = 150, attack = true, fallback = "Slimeling" },
		["Jumpsuited Hound Dog for +combat"] = { id = 69, fallback = "Llama Lama" },
		["Slimeling even in fist"] = { id = 112, f = feed_slimeling, mpregen = true, attack = true, fallback = "Slimeling" },
		["Tickle-Me Emilio"] = { id = 157, mpregen = true, attack = true, fallback = "Rogue Program" },
		["Bloovian Groose"] = { id = 154, fallback = "Midget Clownfish" },
		["Obtuse Angel"] = { id = 146, fallback = "Slimeling" },
		["Reagnimated Gnome"] = { id = 162, familiarequip = "gnomish housemaid's kgnee", fallback = "Hovering Sombrero" },
		["Hovering Sombrero"] = { id = 18, fallback = "(ignore familiar)" },
		["Angry Jung Man"] = { id = 165, fallback = "Slimeling" },
	}

	local function raw_want_familiar(famname_input)
		-- TODO: improve fallbacks and priorities
		local missing_fams = session["__script.missing familiars"] or {}
		local famname, next_famname_input
		if type(famname_input) == "table" then
			for f in table.values(famname_input) do
				if not missing_fams[f] then
					local d = familiar_data[f]
					if not (d.needsequip and not have(d.familiarequip)) then
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
		if not d then
			critical("DEBUG, no familiar data for " ..tostring(famname).." from "..tostring(famname_input))
		end
		if missing_fams[famname] or (d.needsequip and not have(d.familiarequip)) then
			if famname == "Rogue Program" and spleen() < 12 then
				return raw_want_familiar("Bloovian Groose")
			else
				if not familiar_data[famname].fallback or highskill_at_run then
					critical("No fallback familiar for " .. famname)
				end
				return raw_want_familiar(next_famname_input or familiar_data[famname].fallback)
			end
		end
		if d then
			if d.id ~= familiarid() then
				if equipment().familiarequip then
					unequip_slot("familiarequip")
				end
				switch_familiarid(d.id)
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
			if familiar_data[famname].familiarequip and not have(familiar_data[famname].familiarequip) then
				if not have("fixed-gear bicycle") and have("ironic moustache") then
					unequip_slot("familiarequip")
					use_item("ironic moustache")
					use_item("chiptune guitar")
					if not have("fixed-gear bicycle") then
						critical "Failed to turn moustache into bicycle"
					end
				end
				if familiar_data[famname].familiarequip == "bugged balaclava" then
					async_get_page("/arena.php")
					if have("bugged beanie") then
						use_item("bugged beanie")
					end
					if not have(familiar_data[famname].familiarequip) then
						critical "Failed to get bugged balaclava"
					end
				end
			end
			return { mpregen = familiar_data[famname].mpregen, familiarequip = familiar_data[famname].familiarequip and have(familiar_data[famname].familiarequip) and familiar_data[famname].familiarequip }
		else
			error("Unknown familiar: " .. tostring(famname))
		end
	end

	-- TODO: set the familiar equipment here
	function f.want_familiar(famname)
		if can_change_familiar == false then
			return {}
		end
		if challenge == "zombie" and famname ~= "Reassembled Blackbird" then
			famname = "Reagnimated Gnome"
		end
		if famname == "Slimeling" and highskill_at_run then
			famname = "Scarecrow with spangly mariachi pants"
		elseif have("spangly mariachi pants") and (famname == "Slimeling" or famname == "Jumpsuited Hound Dog") then
			famname = "Scarecrow with spangly mariachi pants"
		elseif have("spangly sombrero") and (famname == "Slimeling" or famname == "Jumpsuited Hound Dog") then
			famname = "Mad Hatrack with spangly sombrero"
		end
		if famname == "Slimeling" and daysthisrun() >= 2 and not have_item("digital key") and not have_item("psychoanalytic jar") and get_daily_counter("familiar.jungman.jar") == 0 then
			famname = "Angry Jung Man"
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
			if mp() >= 50 and have("Clancy's crumhorn") or clancy_instrumentid() == 2 then
				want_bonus.clancy_item = "Clancy's crumhorn"
			end
			if have_skill("Song of Cockiness") and (mp() >= 50 or buff("Song of Cockiness")) and level() >= 4 then
				want_bonus.boris_song = "Song of Cockiness"
			end
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
				want_bonus.clancy_item = "Clancy's lute"
			elseif t == "noncombat" then
				if have_skill("Song of Solitude") then
					want_bonus.boris_song = "Song of Solitude"
				end
			elseif t == "combat" then
				if have_skill("Song of Battle") then
					want_bonus.boris_song = "Song of Battle"
				end
			elseif t == "easy combat" then
				want_bonus.boris_song = "Song of Accompaniment"
				if have_intrinsic("Overconfident") then
					set_result(script.cast_buff("Pep Talk"))
				end
				if have_intrinsic("Overconfident") then
					critical "Failed to remove Overconfident"
				end
			elseif t == "initiative" then
				want_bonus.plusinitiative = true
			else
				error("Unknown bonus target: " .. t)
			end
		end
	end

	function f.set_runawayfrom(runawayfrom)
		if not runawayfrom then
			macro_runawayfrom_monsters = "none"
		end
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
		distance = distance + maxmp() / 5
		local ignore_buffs = get_ascension_automation_settings().ignore_buffs
-- 		print("burn_mp", maxmp(), (maxmp() - mp()), mp(), downto)
		if maxmp() > 50 and (maxmp() - mp()) < distance and mp() > downto and hundreds < 1000 then
			if show_spammy_automation_events and not recursed then
				print("  burning excess MP from " .. mp() .. " down to " .. downto)
			end
			local toburn = mp() - downto
-- 			print("burn mp", toburn, hundreds, "level", level())
			if buff("Salamanderenity") and buffturns("Salamanderenity") < hundreds and toburn >= 5 then
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
			else
				return f.burn_mp(downto, hundreds + 100, true)
			end
-- 		else
-- 			print("skipping mp burn")
		end
	end

	function f.trade_for_clover()
		if challenge == "fist" and meat() < 150 then return end
		if not have("hermit permit") then
			inform "buying hermit permit"
			buy_item("hermit permit", "m")
			if not have("hermit permit") then
				critical "Failed to buy hermit permit"
			end
		end
		f.ensure_worthless_item()
		local hermitpt = get_page("/hermit.php")
		if hermitpt:contains("left in stock") then
			inform "trading for clover"
			result, resulturl = post_page("/hermit.php", { action = "trade", whichitem = get_itemid("ten-leaf clover"), quantity = 1 })
			if count("ten-leaf clover") == 0 then
				critical "Failed to trade for ten-leaf clover"
			end
			if ascensionpathid() == 4 then
				closet_item("ten-leaf clover")
			else
				use_item("ten-leaf clover")
			end
			if count("ten-leaf clover") > 0 then
				critical "Failed to hide ten-leaf clover"
			end
			did_action = true
		end
		return did_action
	end

	function f.use_and_sell_items()
		local use_items = get_ascension_automation_settings().use_items

		-- TODO: don't use wallets on fist path
		for w in table.values(use_items) do
			if have(w) then
				if count(w) >= 100 then
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
				if have(s) then
					if count(s) >= 100 then
						stop("Somehow have 100+ of " .. tostring(s) .. " when trying to sell items")
					end
					set_result(sell_item(s))
					did_action = true
				end
			end
			for s in table.values(sell_except_one) do
				if count(s) >= 2 then
					if count(s) >= 100 then
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
		local need_extra = 0
		if challenge == "trendy" then
			if level() >= 10 then
				need_extra = 40
			end
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
			if challenge == "boris" then
				return
			else
				critical("Maxmp < " .. (amount + need_extra) .. " when trying to ensure MP")
			end
		end
		if mp() < amount + need_extra then
			local need = amount + need_extra - mp()
			if show_spammy_automation_events and not recursed then
				print("  restoring MP to " .. (amount + need_extra) .. "+, need " .. need)
			end
			if need > 100 then
				stop "Trying to restore more than 100 MP at once"
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
				if have(name) and (mp() + limit < maxmp()) then
					use_item(name)
					return f.ensure_mp(amount, true)
				end
			end
			for name, limit in pairs(restore_items) do
				if have(name) and (mp() + limit * 0.75 < maxmp()) then
					use_item(name)
					return f.ensure_mp(amount, true)
				end
			end
			for name, limit in pairs(restore_items) do
				if have(name) and (mp() + limit * 0.5 < maxmp()) then
					use_item(name)
					return f.ensure_mp(amount, true)
				end
			end
			if session["__script.used all free rests"] ~= "yes" then
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
			elseif get_mainstat() == "Mysticality" and (session["__script.opened myst guild store"] == "yes" or level() >= 8) and challenge ~= "fist" and not have("magical mystery juice") then
				buy_item("magical mystery juice", "2")
				if have("magical mystery juice") then
					return f.ensure_mp(amount, true)
				else
					critical "Failed to buy MMJ as myst"
				end
			elseif classid() == 6 and level() >= 9 and challenge ~= "fist" and not have("magical mystery juice") then
				buy_item("magical mystery juice", "2")
				if have("magical mystery juice") then
					return f.ensure_mp(amount, true)
				else
					critical "Failed to buy MMJ as lvl 9+ AT"
				end
			elseif have("Cobb's Knob lab key") and ((have("Knob Goblin elite helm") and have("Knob Goblin elite polearm") and have("Knob Goblin elite pants")) or level() >= 8) and challenge ~= "fist" and not have("Knob Goblin seltzer") and not highskill_at_run and challenge ~= "boris" and not have_item("Knob Goblin seltzer") then
				buy_item("Knob Goblin seltzer", "k", 5)
				if have("Knob Goblin seltzer") then
					return f.ensure_mp(amount, true)
				else
					critical "Failed to buy knob goblin seltzer"
				end
			elseif kgs_available and not have_item("Knob Goblin seltzer") then
				buy_item("Knob Goblin seltzer", "k", 5)
				if have("Knob Goblin seltzer") then
					return f.ensure_mp(amount, true)
				else
					critical "Failed to buy knob goblin seltzer"
				end
			elseif have("your father's MacGuffin diary") and not have_item("black cherry soda") then
				buy_item("black cherry soda", "l", 5)
				if have("black cherry soda") then
					return f.ensure_mp(amount, true)
				else
					critical "Failed to buy black cherry soda"
				end
			elseif challenge == "boris" and need <= 60 then
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
				elseif not have("tonic water") and not highskill_at_run then
					if not have("soda water") then
						buy_item("soda water", "m", 1)
					end
					async_post_page("/guild.php", { action = "stillfruit", whichitem = get_itemid("soda water"), quantity = 1 })
					if have("tonic water") then
						return f.ensure_mp(amount, true)
					end
				end
				stop "Out of MP in challenge path"
			elseif level() >= 8 then
				stop "Trying to use galaktik to restore mp at level 8+"
			elseif need > 50 then
				stop "Trying to use galaktik to restore more than 50 MP"
			else
				post_page("/galaktik.php", { action = "curemp", pwd = get_pwd(), quantity = need })
				if mp() < amount then
					stop("Failed to reach " .. amount .. " MP using galaktik")
				end
			end
		end
-- 		print("ensured mp to ", amount, " now ", mp())
	end

	local ensure_mp = f.ensure_mp

	function f.heal_up()
		if hp() / maxhp() < 0.8 and (maxhp() - hp() >= 30 or maxhp() < 50) then
			local oldhp = hp()
			if maxhp() - hp() >= 70 and have_skill("Cannelloni Cocoon") then
				ensure_mp(20)
				cast_skillid(3012)
			elseif have_skill("Tongue of the Walrus") then
				ensure_mp(10)
				cast_skillid(1010)
			elseif challenge == "boris" and have("your father's MacGuffin diary") and (hp() < 200 or hp() / maxhp() < 0.5 or ascensionstatus() == "Hardcore") then
				ensure_mp(10)
				cast_skillid(11031, 10)
			elseif challenge == "zombie" then
				cast_skillid(12001)
			elseif have_skill("Disco Power Nap") then
				ensure_mp(12)
				cast_skillid(5011)
			elseif have_skill("Lasagna Bandages") then
				ensure_mp(6)
				cast_skillid(3009)
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
					use_hottub()
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
				elseif ascensionpath("Avatar of Jarlsberg") then
				else
					critical "Failed to restore HP!"
				end
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
			if not have("Knob Goblin pet-buffing spray") then
				buy_item("Knob Goblin pet-buffing spray", "k", 1)
			end
			return use_item("Knob Goblin pet-buffing spray")
		end,
		["Peeled Eyeballs"] = function()
			if not have("Knob Goblin eyedrops") then
				buy_item("Knob Goblin eyedrops", "k", 1)
			end
			return use_item("Knob Goblin eyedrops")
		end,
		["Sugar Rush"] = function()
			local f = cast_skillid(53) -- summon crimbo candy
			local candies = { "Angry Farmer candy", "Crimbo fudge", "Crimbo peppermint bark", "Crimbo candied pecan" }
			for _, x in ipairs(candies) do
				if have(x) then
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
		["Simply Irresistible"] = function()
			return use_item("irresistibility potion")
		end,
		["Simply Invisible"] = function()
			return use_item("invisibility potion")
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
		["Cat-Alyzed"] = function()
			if cached_stuff.used_hatter_buff_today then return end
			local pt, pturl
			if not buff("Down the Rabbit Hole") then
				async_get_page("/clan_viplounge.php", { action = "lookingglass" })
				pt, pturl = use_item("&quot;DRINK ME&quot; potion")()
			end
			local previous_hat = equipment().hat
			if not have("snorkel") then
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
			if not have("can of black paint") then
				buy_item("can of black paint", "l")
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
		["Jaba&ntilde;ero Saucesphere"] = { item = "saucepan" },
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
		if buff(buffname) then
			print("  shrugging buff", buffname, spells[buffname].effectid)
			async_get_page("/charsheet.php", { pwd = get_pwd(), ajax = 1, action = "unbuff", whichbuff = spells[buffname].effectid })
			if buff(buffname) then
				critical("Failed to shrug buff: " .. buffname)
			end
		end
	end

	local shrug_buff = f.shrug_buff

	for name, skillname in pairs(datafile("buff recast skills")) do
		local data = datafile("skills")[skillname]
		buffs[name] = function()
			if show_spammy_automation_events then
				print("  casting buff", name, "[current mp: " .. mp() .. "]")
			end
			ensure_mp(data.mpcost)
			if spells[name] and spells[name].shrug_first then
				shrug_buff(spells[name].shrug_first)
			end
			return cast_skillid(data.skillid)
		end 
	end

	for _, name in pairs { "Pep Talk" } do
		local data = spells[name]
		buffs[name] = function()
			if show_spammy_automation_events then
				print("  casting buff", name, "[current mp: " .. mp() .. "]")
			end
			ensure_mp(data.mpcost)
			if spells[name] and spells[name].shrug_first then
				shrug_buff(spells[name].shrug_first)
			end
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
		}
		if ascensionpathid() == 8 and not ignore_buffing_and_outfit then
			if want_bonus.boris_song then
				table.insert(xs, want_bonus.boris_song)
			end
			if want_bonus.clancy_item and have(want_bonus.clancy_item) then
				use_item(want_bonus.clancy_item)
			end
		end
		if not even_in_fist and not ignore_buffing_and_outfit then
			if level() < 6 and not highskill_at_run then
				table.insert(xs, "The Moxious Madrigal")
				table.insert(xs, "The Magical Mojomuscular Melody")
			end
			if get_mainstat() == "Mysticality" and level() >= 6 then
				table.insert(xs, "A Few Extra Pounds")
			end
			if level() >= 6 then
				table.insert(xs, "Leash of Linguini")
-- 				if get_mainstat() ~= "Muscle" then
-- 					table.insert(xs, "Empathy")
-- 				end
			end
			if ((get_mainstat() == "Mysticality" and level() >= 9) or (level() >= 11) or (highskill_at_run and mmj_available)) and level() < 13 and challenge ~= "fist" then
				table.insert(xs, "Ur-Kel's Aria of Annoyance")
			end
		end
		if challenge == "fist" and not even_in_fist then
			local function tabledel(t)
				for x, y in pairs(t) do
					-- TODO: do more generally?
					if (spells[y] and spells[y].item) or y == "Heavy Petting" or y == "Peeled Eyeballs" or y == "A Few Extra Pounds" or y == "Butt-Rock Hair" then
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
		if not cached_stuff.learned_lab_password or not have("Cobb's Knob lab key") then
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
		if level() >= 13 and buff("Ur-Kel's Aria of Annoyance") and not want_buffs["Ur-Kel's Aria of Annoyance"] then
			shrug_buff("Ur-Kel's Aria of Annoyance")
			set_mcd(0) -- HACK: don't want this to be done here!
		end
		local function try_casting_buff(buffname, try_shrugging)
			if buffs[buffname] then
				local ptf = f.cast_buff(buffname)
				if not ptf then
					print("DEBUG: castbuff returned nil:", buffname)
				end
				if type(ptf) == "string" then
					print("DEBUG: castbuff non-function:", buffname)
				else
					ptf = ptf()
				end
				if not ptf then
					print("DEBUG: castbuff returned nil:", buffname)
				end
				if not have_buff(buffname) and not have_intrinsic(buffname) then
					if ptf:contains("too many songs stuck in your head") and try_shrugging then
						for _, atname in ipairs(at_shruggable) do
							if buff(atname) and not want_buffs[atname] then
								shrug_buff(atname)
								return try_casting_buff(buffname, false)
							end
						end
						critical("Too many AT songs to cast buff: " .. buffname)
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
-- 				print("bumped", x, buff(x))
			end
		end
	end

	function f.ensure_buff_turns(buff, duration)
		f.ensure_buffs { buff }
		local turns = buffturns(buff)
		if turns < duration then
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
	end

	function f.wear(tbl)
		if want_bonus.plusinitiative then
			f.fold_item("Loathing Legion rollerblades")
		else
			f.fold_item("Loathing Legion necktie")
		end

		if want_bonus.plusitems then
			f.fold_item("stinky cheese eye")
		elseif not tbl.pants then
			f.fold_item("stinky cheese diaper")
		end

		if not tbl.pants and want_bonus.runawayfrom and have("Greatest American Pants") and get_daily_counter("item.fly away.free runaways") < 9 then
			tbl.pants = "Greatest American Pants"
			macro_runawayfrom_monsters = want_bonus.runawayfrom
		else
			macro_runawayfrom_monsters = "none"
		end

		local settingstbl = get_ascension_automation_settings(want_bonus)
		local defaults, canwear_itemname = settingstbl.default_equipment, settingstbl.canwear_itemname
		defaults.acc1 = defaults.accessories
		defaults.acc2 = defaults.accessories
		defaults.acc3 = defaults.accessories
		local neweq = {}

		if buff("Super Structure") and not tbl.pants then
			tbl.pants = "Greatest American Pants"
		end
		if buff("Super Speed") and not tbl.pants then
			tbl.pants = "Greatest American Pants"
		end
		if buff("Super Vision") and not tbl.pants then
			tbl.pants = "Greatest American Pants"
		end

		local do_not_wear = {}

		local halos = { ["frosty halo"] = true, ["furry halo"] = true, ["shining halo"] = true, ["time halo"] = true }

		for a, b in pairs(tbl) do
			if b ~= "empty" then
				neweq[a] = get_itemid(b)
				do_not_wear[b] = true
				if halos[b] or a == "weapon" or a == "offhand" then
					for h in pairs(halos) do
						do_not_wear[h] = true
					end
				end
			end
		end

		for _, a in ipairs(wear_slots) do
			if not tbl[a] and not neweq[a] then
				for _, x in ipairs(defaults[a] or {}) do
					local itemname = canwear_itemname(x)
					if itemname and not do_not_wear[itemname] then
						neweq[a] = get_itemid(itemname)
						do_not_wear[itemname] = true
						break
					end
				end
			end
		end

		if neweq.weapon == get_itemid("Knob Goblin elite polearm") or neweq.weapon == get_itemid("Trusty") or neweq.weapon == get_itemid("7-Foot Dwarven mattock") then
			neweq.offhand = nil
		end

		local currently_worn = equipment()
		local function reuse_equipment_slots(neweq)
			for x in table.values { "acc1", "acc2", "acc3" } do
				if neweq[x] then
					for y in table.values { "acc1", "acc2", "acc3" } do
						if x ~= y and neweq[x] ~= neweq[y] and neweq[x] == currently_worn[y] then
							neweq[x], neweq[y] = neweq[y], neweq[x]
							return reuse_equipment_slots(neweq)
						end
					end
				end
			end
			return neweq
		end

		neweq = reuse_equipment_slots(neweq)
-- 		print("setting equipment: ", table_to_str(neweq))
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

				local lastsemi = ascension["last semirare encounter"]
				local lastturn = ascension["last semirare turn"]

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
					if (not lastsemi and not lastturn and turnsthisrun() < 85) or (lastsemi == "Lunchboxing") then
						inform "Pick up SR, make it wines"
						result, resulturl, advagain = autoadventure { zoneid = 112, ignorewarnings = true }
						if get_result():contains("In the Still of the Alley") then
							if not highskill_at_run then
								buy_item("fortune cookie", "m")
								local old_full = fullness()
								set_result(eat_item("fortune cookie"))
								did_action = (fullness() == old_full + 1)
							else
								did_action = true
							end
						else
							result = add_colored_message_to_page(get_result(), "Tried to pick up wine semirare", "darkorange")
						end
						return result, resulturl, did_action
					elseif lastsemi == "In the Still of the Alley" then
						inform "Pick up SR, make it lunchbox"
						result, resulturl, advagain = autoadventure { zoneid = 114, ignorewarnings = true }
						if get_result():contains("Lunchboxing") then
							if not highskill_at_run then
								buy_item("fortune cookie", "m")
								local old_full = fullness()
								set_result(eat_item("fortune cookie"))
								did_action = (fullness() == old_full + 1)
							else
								did_action = true
							end
						else
							result = add_colored_message_to_page(get_result(), "Tried to pick up lunchbox semirare", "darkorange")
						end
						return result, resulturl, did_action
					else
						critical "Unexpected last SR when picking up SR (not wine nor lunchbox)"
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
-- 			if table.maxn(good_numbers) == 0 and turnsthisrun() < 700 then
-- 				if SRmin and SRmin <= 10 then
-- 					critical "Semirare soon, without fortune cookie numbers"
-- 				end
-- 			end
-- 		end
-- 		if not have_numbers then
-- 			if have(want_itemname) and not ascension["fortune cookie numbers"] then
-- 				buy_item("fortune cookie", "m")
-- 				if not have("fortune cookie") then
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

	function f.go(info, zoneid, orig_macro, noncombattbl, buffslist, famname, minmp, extra)
		local specialnoncombatfunction = nil
		local towear = {}
		local finalcheckfunc = nil
		if extra then
			if extra.olfact then
				if not trailed then
					minmp = minmp + 40
				elseif trailed ~= extra.olfact then
					stop("Trailing " .. trailed .. " when trying to olfact " .. extra.olfact)
				end
				extra.olfact = nil
			end
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
		if mcd() < 10 and level() < 13 and have("detuned radio") then
			set_mcd(10)
		elseif mcd() ~= 0 and level() == 13 and have("detuned radio") then
			set_mcd(0)
		end
		if arrowed_possible and minmp < 60 then
			minmp = 60
		end
		inform(info)
		ensure_buffs(buffslist)
		local famt = fam(famname)
		local fammpregen, famequip = famt.mpregen, famt.familiarequip
		f.heal_up()
		if fammpregen then
			if challenge then
				f.burn_mp(minmp + 40)
			else
				f.burn_mp(minmp + 20)
			end
		end
		if towear.familiarequip == "sugar shield" and not have("sugar shield") then
			towear.familiarequip = nil
		end
		if famequip and not towear.familiarequip and have(famequip) then
			towear.familiarequip = famequip
		elseif (famequip == "spangly sombrero" or famequip == "spangly mariachi pants") and have(famequip) then -- TODO: hackish for spanglerack
			towear.familiarequip = famequip
		end
		if not towear.familiarequip and have("astral pet sweater") then
			towear.familiarequip = "astral pet sweater"
		end
		wear(towear)
		ensure_mp(minmp)
		if finalcheckfunc then
			finalcheckfunc()
		end
		local macro = orig_macro
		if macro and type(macro) ~= "string" then
			macro = macro()
		end
		result, resulturl, advagain = autoadventure { zoneid = zoneid, macro = macro, noncombatchoices = noncombattbl, specialnoncombatfunction = specialnoncombatfunction, ignorewarnings = true }
		did_action = advagain
		if not did_action then
			local need_mainstat = tonumber(get_result():match("<center>%(You must have at least ([0-9]+) [A-Za-z]+ to adventure here.%)</center>"))
			if need_mainstat and need_mainstat > buffedmainstat() then
				if get_mainstat() == "Muscle" then
					ensure_buffs { "Go Get 'Em, Tiger!" }
				elseif get_mainstat() == "Mysticality" then
					ensure_buffs { "Glittering Eyelashes" }
				elseif get_mainstat() == "Moxie" then
					ensure_buffs { "Butt-Rock Hair" }
				end
				did_action = (buffedmainstat() >= need_mainstat)
			end
		end
		return result, resulturl, advagain
	end

	local go = f.go

	function f.coffee_pixie_stick()
		inform "using coffee pixie stick"
		async_get_page("/town_wrong.php")
		async_get_page("/arcade.php", { action = "skeeball", pwd = get_pwd() })
		async_post_page("/arcade.php", { action = "redeem", whichitem = tostring(get_itemid("coffee pixie stick")), quantity = 1 })
		if have("coffee pixie stick") then
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
		if count("finger cuffs") >= 10 then
			did_action = true
			return result, resulturl, did_action
		else
			critical "Didn't get finger cuffs"
		end
	end

	function f.ensure_worthless_item()
		if not (have("worthless trinket") or have("worthless gewgaw") or have("worthless knick-knack")) then
			print "  getting worthless item"
			if not have("chewing gum on a string") then
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
		if count("dry noodles") < 1 then
			ensure_mp(10)
			cast_skillid(3006, 1) -- pastamastery
		end
		if count("scrumptious reagent") < 1 then
			ensure_mp(10)
			cast_skillid(4006, 1) -- advanced saucecrafting
		end
		if have("Hell broth") then
			inform "make hell ramen"
			set_result(cook_items("Hell broth", "dry noodles"))
			did_action = have("Hell ramen")
		elseif have("fancy schmancy cheese sauce") then
			inform "make fettucini inconnu"
			set_result(cook_items("fancy schmancy cheese sauce", "dry noodles"))
			did_action = have("fettucini Inconnu")
		elseif have("hellion cube") then
			inform "make hell broth"
			set_result(cook_items("hellion cube", "scrumptious reagent"))
			did_action = have("Hell broth")
		elseif have("goat cheese") then
			inform "make cheese sauce"
			set_result(cook_items("goat cheese", "scrumptious reagent"))
			did_action = have("fancy schmancy cheese sauce")
		end
		return result, resulturl, did_action
	end

	function f.get_turns_until_sr()
		local SRnow, good_numbers, all_numbers, SRmin, SRmax, is_first_semi, lastsemi = get_semirare_info(turnsthisrun())
		--print("DEBUG get_turns_until_sr", get_semirare_info(turnsthisrun()))
		return good_numbers[1]
	end

	function f.eat_food(whichday)
		if challenge == "fist" then return end
		if challenge == "boris" then return end
		if challenge == "zombie" then return end
		if highskill_at_run then return end
		if ascensionstatus() ~= "Hardcore" then return end
-- 		TODO: handle without explicitly checking day
		if fullness() < 15 then
			if whichday == 1 then
				if have("Ur-Donut") and fullness() == 0 then
					inform "eat ur-donut day 1"
					eat_item("Ur-Donut")
					did_action = (fullness() == 1)
					return result, resulturl, did_action
				elseif not ascension["fortune cookie numbers"] and fullness() == 1 and meat() >= 40 then
					local f = fullness()
					inform "eat fortune cookie day 1"
					buy_item("fortune cookie", "m")
					eat_item("fortune cookie")()
					if not (fullness() == f + 1 and script.get_turns_until_sr() ~= nil) then
						print("WARNING fortune cookie result:", script.get_turns_until_sr())
						critical "Error getting fortune cookie numbers"
					end
					did_action = (ascension["fortune cookie numbers"] ~= nil)
					return result, resulturl, did_action
				elseif have("Knob pasty") and fullness() == 2 then
					inform "eat pasty day 1"
					eat_item("Knob pasty")
					did_action = (fullness() == 3)
					return result, resulturl, did_action
				elseif fullness() <= 9 and (have("Hell ramen") or have("Hell broth") or have("hellion cube")) then
					if have("Hell ramen") then
						inform "eat hell ramen day 1"
						local a = advs()
						eat_item("Hell ramen")
						did_action = (advs() > a)
						return result, resulturl, did_action
					else
						result, resulturl, did_action = f.make_reagent_pasta()
						if did_action == false and get_result():contains("You need a more advanced cooking appliance") then
							if have("Dramatic&trade; range") then
								set_result(use_item("Dramatic&trade; range"))
								did_action = not have("Dramatic&trade; range")
							else
								set_result(buy_item("Dramatic&trade; range", "m"))
								did_action = have("Dramatic&trade; range")
							end
						end
						return result, resulturl, did_action
					end
				end
			elseif whichday == 2 then
				if script.get_turns_until_sr() == nil then
					local f = fullness()
					inform "eat fortune cookie day 2"
					buy_item("fortune cookie", "m")
					eat_item("fortune cookie")()
					if not (fullness() == f + 1 and script.get_turns_until_sr() ~= nil) then
						print("WARNING fortune cookie result:", script.get_turns_until_sr())
						critical "Error getting fortune cookie numbers"
					end
					did_action = (fullness() == f + 1 and script.get_turns_until_sr() ~= nil)
					return result, resulturl, did_action
				elseif have("Knob pasty") and (fullness() < 3 or fullness() >= 12) then
					inform "eat pasty day 2"
					eat_item("Knob pasty")
					did_action = (advs() >= 20)
					return result, resulturl, did_action
				elseif fullness() <= 9 then
					if count("Hell ramen") >= 2 then
						if highskill_at_run and not buff("Got Milk") then
							if have("milk of magnesium") then
								inform "using milk"
								set_result(use_item("milk of magnesium"))
								if not buff("Got Milk") then
									critical "Failed to use milk of magnesium"
								end
							elseif have("glass of goat's milk") then
								inform "making milk"
								if count("scrumptious reagent") < 1 then
									ensure_mp(10)
									cast_skillid(4006, 1) -- advanced saucecrafting
								end
								cook_items("glass of goat's milk", "scrumptious reagent")
								did_action = have("milk of magnesium")
								return result, resulturl, did_action
							else
								return nil
							end
						end
						inform "eat hell ramen day 2"
						eat_item("Hell ramen")
						eat_item("Hell ramen")
						did_action = (fullness() >= 12)
						return result, resulturl, did_action
					else
						return f.make_reagent_pasta()
					end
				end
			elseif whichday >= 3 and (advs() <= 100 or script.get_turns_until_sr() == nil) then
				if script.get_turns_until_sr() == nil then
					local f = fullness()
					inform "eat fortune cookie day 3"
					buy_item("fortune cookie", "m")
					eat_item("fortune cookie")()
					if not (fullness() == f + 1 and script.get_turns_until_sr() ~= nil) then
						print("WARNING fortune cookie result:", script.get_turns_until_sr())
						critical "Error getting fortune cookie numbers"
					end
					did_action = (fullness() == f + 1 and script.get_turns_until_sr() ~= nil)
					return result, resulturl, did_action
				elseif have("Knob pasty") and (fullness() < 3 or fullness() >= 12) then
					inform "eating pasty"
					local a = advs()
					eat_item("Knob pasty")
					did_action = (advs() > a)
					return result, resulturl, did_action
-- 				elseif fullness() <= 3 and have_reagent_pastas >= need_total_reagent_pastas then
				elseif fullness() <= 3 then
					if count("Hell ramen") + count("fettucini Inconnu") >= 2 then
						if buff("Got Milk") then
							inform "eating reagent pasta"
							eat_item("Hell ramen")
							eat_item("Hell ramen")
							eat_item("fettucini Inconnu")
							eat_item("fettucini Inconnu")
							did_action = (fullness() >= 12)
							return result, resulturl, did_action
						elseif have("milk of magnesium") then
							inform "using milk"
							set_result(use_item("milk of magnesium"))
							did_action = buff("Got Milk")
							return result, resulturl, did_action
						elseif have("glass of goat's milk") then
							inform "making milk"
							if count("scrumptious reagent") < 1 then
								ensure_mp(10)
								cast_skillid(4006, 1) -- advanced saucecrafting
							end
							cook_items("glass of goat's milk", "scrumptious reagent")
							did_action = have("milk of magnesium")
							return result, resulturl, did_action
						end
					else
						return f.make_reagent_pasta()
					end
				end
			end
		end
	end

	local function warn_imported_beer()
		if ascension["__script.stop on imported beer"] ~= "yes" then return end
		if cached_stuff.warned_imported_beer == turnsthisrun() then return end
		cached_stuff.warned_imported_beer = turnsthisrun()
		stop "Script would drink imported beer. Drink something else manually instead, or run again to proceed."
	end

	function f.drink_booze(whichday, forced)
-- 		local function want_to_drink()
-- 			-- TODO: revamp, improve and use this
-- 			if whichday == 1 and drunkenness() < 3 and have("Typical Tavern swill") and meat() >= 1000 then
-- 				return true
-- 			elseif whichday == 1 and drunkenness() < 12 and have("Typical Tavern swill") and have("thermos full of Knob coffee") and meat() >= 2000 then
-- 				return true
-- 			elseif whichday >= 2 and drunkenness() < 19 and ((meat() >= 2000 and advs() <= 20) or forced) then
-- 				return true
-- 			end
-- 			return false
-- 		end
		if challenge == "fist" then return end
		if challenge == "boris" then return end
		if challenge == "zombie" then return end
		if highskill_at_run then return end
		if ascensionstatus() ~= "Hardcore" then return end
		if whichday == 1 then
			if drunkenness() < 3 and have("Typical Tavern swill") and meat() >= 1000 then
				inform "drinking pumpkin and overpriced beer"
				if not have("pumpkin beer") and have("pumpkin") then
					buy_item("fermenting powder", "m")
					mix_items("pumpkin", "fermenting powder")
				end
				-- IMPROVE?: drink booze and sewerlevel at nice times
				ensure_mp(5)
				cast_skillid(8202) -- summon alice's army cards

				ensure_buffs { "Ode to Booze" }
				for i = 1, 10 do
					if drunkenness() < 8 and drunkenness() < estimate_max_safe_drunkenness() and (buff("Ode to Booze") or not have_skill("The Ode to Booze")) then
						local start_drunk = drunkenness()
						if have("astral pilsner") and level() >= 11 then
							drink_item("astral pilsner")
						elseif have("thermos full of Knob coffee") then
							drink_item("thermos full of Knob coffee")
						elseif have("pumpkin beer") then
							drink_item("pumpkin beer")
						elseif have("distilled fortified wine") then
							drink_item("distilled fortified wine")
						elseif have("Ye Wizard's Shack snack voucher") and drunkenness() <= 7 then
							async_post_page("/gamestore.php", { action = "buysnack", whichsnack = get_itemid("tobiko-infused sake") })
							drink_item("tobiko-infused sake")
						elseif have("cream stout") then
							drink_item("cream stout")
						elseif have("shot of rotgut") then
							f.heal_up()
							drink_item("shot of rotgut")
						elseif have("shot of flower schnapps") then
							drink_item("shot of flower schnapps")
						else
							warn_imported_beer()
							buy_item("overpriced &quot;imported&quot; beer", "v", 1)
							drink_item("overpriced &quot;imported&quot; beer")
						end
						if drunkenness() <= start_drunk then
							critical "Failed to drink..."
						end
					end
				end
				did_action = (drunkenness() >= 3 and buff("Pisces in the Skyces")) or (drunkenness() == estimate_max_safe_drunkenness())
				return result, resulturl, did_action
			elseif (drunkenness() < 12 or (have_skill("Liver of Steel") and drunkenness() < 19)) and have("Typical Tavern swill") and have("distilled fortified wine") and (meat() >= 2000 or session["__script.have cocktailcrafting kit"]) then
				-- TODO: or we already have cocktailcrafting kit...
				inform "drinking rest for day 1"
				-- TODO: redo
				if not have("coconut shell") and not have("little paper umbrella") and not have("magical ice cubes") then
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
				if not have("blended frozen swill") and not have("fruity girl swill") and not have("tropical swill") then
					local f = nil
					if have("little paper umbrella") then
						f = mix_items("Typical Tavern swill", "little paper umbrella")
					elseif have("magical ice cubes") then
						f = mix_items("Typical Tavern swill", "magical ice cubes")
					elseif have("coconut shell") then
						f = mix_items("Typical Tavern swill", "coconut shell")
					end
					if have("blended frozen swill") or have("fruity girl swill") or have("tropical swill") then
						did_action = true
					elseif f():contains("Your cocktail set is not advanced enough") then
						if have("Queue Du Coq cocktailcrafting kit") then
							print "  using cocktailcrafting kit"
							set_result(use_item("Queue Du Coq cocktailcrafting kit"))
							did_action = not have("Queue Du Coq cocktailcrafting kit")
						else
							print "  buying cocktailcrafting kit"
							set_result(buy_item("Queue Du Coq cocktailcrafting kit", "m"))
							session["__script.have cocktailcrafting kit"] = "yes"
							did_action = have("Queue Du Coq cocktailcrafting kit")
						end
					end
				else
					ensure_buffs { "Ode to Booze" }
					f.ensure_buff_turns("Ode to Booze", 8)
					local ode_buffturns = buffturns("Ode to Booze")
					if ode_buffturns < 8 then
						critical "Failed to cast ode to booze"
					end
					if drunkenness() == 8 or (have_skill("Liver of Steel") and drunkenness() == 13) then
						if have("blended frozen swill") then
							drink_item("blended frozen swill")
						elseif have("fruity girl swill") then
							drink_item("fruity girl swill")
						elseif have("tropical swill") then
							drink_item("fruity girl swill")
						end
					end
					for i = 1, 20 do
						local max_drunk = 14
						if have_skill("Liver of Steel") then max_drunk = 19 end
						if drunkenness() < max_drunk then
							local start_drunk = drunkenness()
							ensure_buffs { "Ode to Booze" }
							if have("astral pilsner") and level() >= 11 then
								drink_item("astral pilsner")
							elseif have("thermos full of Knob coffee") then
								drink_item("thermos full of Knob coffee")
							elseif have("pumpkin beer") then
								drink_item("pumpkin beer")
							elseif have("distilled fortified wine") then
								drink_item("distilled fortified wine")
							elseif have("Ye Wizard's Shack snack voucher") and drunkenness() + 3 <= max_drunk then
								async_post_page("/gamestore.php", { action = "buysnack", whichsnack = get_itemid("tobiko-infused sake") })
								drink_item("tobiko-infused sake")
							elseif have("Supernova Champagne") and drunkenness() + 3 <= max_drunk then
								drink_item("Supernova Champagne")
							elseif have("cream stout") then
								drink_item("cream stout")
							elseif have("shot of rotgut") then
								f.heal_up()
								drink_item("shot of rotgut")
							elseif have("shot of flower schnapps") then
								drink_item("shot of flower schnapps")
							else
								warn_imported_beer()
								buy_item("overpriced &quot;imported&quot; beer", "v", 1)
								if not have("overpriced &quot;imported&quot; beer") then
									critical "Failed to buy imported beer"
								end
								drink_item("overpriced &quot;imported&quot; beer")
							end
							if drunkenness() <= start_drunk then
								critical "Failed to drink..."
							end
						end
					end
					if drunkenness() == 19 and have_skill("Liver of Steel") then
						did_action = true
					elseif drunkenness() == 14 and not have_skill("Liver of Steel") then
						did_action = true
					end
				end
				return result, resulturl, did_action
			end
		elseif whichday >= 2 then
			if have("peppermint sprout") or have("peppermint twist") then
				for x in table.values { "bottle of rum", "bottle of gin", "bottle of tequila", "bottle of vodka", "bottle of whiskey", "boxed wine" } do
					if have(x) then
						if not have("peppermint twist") then
							use_item("peppermint sprout")
						end
						local twists = count("peppermint twist")
						inform "mixing peppermint booze"
						result, resulturl = mix_items(x, "peppermint twist")()
						-- TODO: check for cocktailcrafting kit
						if count("peppermint twist") ~= twists - 1 then
							critical "Failed to mix peppermint booze"
						end
						did_action = true
						return result, resulturl, did_action
					end
				end
			end
			if drunkenness() < 19 and ((meat() >= 2000 and advs() <= 20) or (advs() <= 15) or forced) then
-- 				TODOSOON!!! error "Drink better!"
				-- TODO: drink good stuff early, then more good stuff later when you get it from SRs
				if have("pumpkin") then
					buy_item("fermenting powder", "m")
					mix_items("pumpkin", "fermenting powder")
				end
				ensure_mp(5)
				cast_skillid(8202) -- summon alice's army cards
				inform "drinking booze"
				if have("steel margarita") then
					stop "Drink steel margarita first!"
				end
				if not have_skill("Liver of Steel") then
					critical "Get liver of steel first!"
				end
				for i = 1, 20 do
					if drunkenness() < 19 then
						local start_drunk = drunkenness()
						ensure_buffs { "Ode to Booze" }
						if have("astral pilsner") and level() >= 11 then
							drink_item("astral pilsner")
						elseif have("Crimbojito") and drunkenness() <= 17 then
							drink_item("Crimbojito")
						elseif have("Feliz Navidad") and drunkenness() <= 17 then
							drink_item("Feliz Navidad")
						elseif have("Gin Mint") and drunkenness() <= 17 then
							drink_item("Gin Mint")
						elseif have("Mint Yulep") and drunkenness() <= 17 then
							drink_item("Mint Yulep")
						elseif have("Sangria de Menthe") and drunkenness() <= 17 then
							drink_item("Sangria de Menthe")
						elseif have("Vodka Matryoshka") and drunkenness() <= 17 then
							drink_item("Vodka Matryoshka")
						elseif have("thermos full of Knob coffee") then
							drink_item("thermos full of Knob coffee")
						elseif have("pumpkin beer") then
							drink_item("pumpkin beer")
						elseif have("distilled fortified wine") then
							drink_item("distilled fortified wine")
						elseif have("Ye Wizard's Shack snack voucher") and drunkenness() <= 16 then
							async_post_page("/gamestore.php", { action = "buysnack", whichsnack = get_itemid("tobiko-infused sake") })
							drink_item("tobiko-infused sake")
						elseif have("Supernova Champagne") and drunkenness() <= 16 then
							drink_item("Supernova Champagne")
						elseif have("cream stout") then
							drink_item("cream stout")
						elseif have("shot of rotgut") then
							f.heal_up()
							drink_item("shot of rotgut")
						elseif have("shot of flower schnapps") then
							drink_item("shot of flower schnapps")
						else
							warn_imported_beer()
							buy_item("overpriced &quot;imported&quot; beer", "v", 1)
							if not have("overpriced &quot;imported&quot; beer") then
								critical "Failed to buy imported beer"
							end
							drink_item("overpriced &quot;imported&quot; beer")
						end
						if drunkenness() <= start_drunk then
							critical "Failed to drink..."
						end
					end
				end
				did_action = (drunkenness() == 19)
				return result, resulturl, did_action
			end
		end
	end

	function f.get_photocopied_monster()
		if have("photocopied monster") then
			local itempt = get_page("/desc_item.php", { whichitem = "835898159" })
			local copied = itempt:match([[blurry likeness of [a-zA-Z]* (.-) on it.]])
			return copied
		else
			return nil
		end
	end

	function f.unlock_cobbs_knob()
		if have("Knob Goblin encryption key") then
			set_result(use_item("Cobb's Knob map"))
			refresh_quest()
			if not quest_text("haven't figured out how to decrypt it yet") then
				did_action = true
			end
		else
			go("get encryption key", 114, macro_stasis, {
				["Up In Their Grill"] = "Grab the sausage, so to speak.  I mean... literally.",
				["Knob Goblin BBQ"] = "Kick the chef",
				["Ennui is Wasted on the Young"] = "&quot;Since you're bored, you're boring.  I'm outta here.&quot;",
				["Malice in Chains"] = "Plot a cunning escape",
				["When Rocks Attack"] = "&quot;Sorry, gotta run.&quot;",
			}, {}, "Mini-Hipster", 15)
			if have("Knob Goblin encryption key") then
				did_action = true
			end
		end
	end

	function f.do_barrr(insults)
		if insults >= 7 and have("Cap'm Caronch's Map") then
			inform "use cap'm's map"
			ensure_buffs { "Springy Fusilli", "Spirit of Peppermint", "A Few Extra Pounds" }
			fam "Rogue Program"
			f.heal_up()
			ensure_mp(40)
			use_item("Cap'm Caronch's Map")
			local pt, url = get_page("/fight.php")
			result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_noodlecannon())
		elseif insults >= 7 and not have("Cap'm Caronch's Map") then
			stop "Handle: 7 insults and no map?"
		else
-- 			print("map", have("Cap'm Caronch's Map"), "insults", insults)
			local function get_barrr_noncombattbl()
				if get_mainstat() == "Muscle" then
					return {
						["Yes, You're a Rock Starrr"] = "Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;",
						["A Test of Testarrrsterone"] = "Cheat",
						["That Explains All The Eyepatches"] = "Carefully throw the darrrt at the tarrrget",
					}
				elseif get_mainstat() == "Mysticality" then
					return {
						["Yes, You're a Rock Starrr"] = "Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;",
						["A Test of Testarrrsterone"] = "Cheat",
						["That Explains All The Eyepatches"] = "Pull one over on the pirates",
					}
				elseif get_mainstat() == "Moxie" then
					return {
						["Yes, You're a Rock Starrr"] = "Sing the Southern Hey Deze tune &quot;Fiends in Low Places.&quot;",
						["A Test of Testarrrsterone"] = "Wuss out",
						["That Explains All The Eyepatches"] = "Carefully throw the darrrt at the tarrrget",
					}
				end
			end
			if not have("The Big Book of Pirate Insults") then
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
		if have("heart of the filthworm queen") then
			print("  trying to turn in filthworm heart")
			wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { place = "orchard", action = "stand", pwd = get_pwd() })
			async_get_page("/bigisland.php", { place = "orchard", action = "stand", pwd = get_pwd() })
		end
-- 		error "TODO use PADL"
		use_dancecard()
		local macro_battlefield = [[
if monstername green ops
]] .. macro_noodlegeyser(3) .. [[

  goto m_done
endif

]] .. macro_noodlecannon() .. [[

mark m_done

]]
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
				if have(x) then
					async_get_page("/bigisland.php", { action = "turnin", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid(x), quantity = count(x) })
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
					if buff("Billiards Belligerence") and buff("Starry-Eyed") and hp() / maxhp() >= 0.9 then
					else
						stop "TODO: Fight hippy boss in Boris"
					end
				end
				ensure_mp(150)
				ensure_buffs { "Jalape&ntilde;o Saucesphere", "Jaba&ntilde;ero Saucesphere", "Spirit of Garlic", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds" }
				maybe_ensure_buffs { "Mental A-cue-ity" }
				async_get_page("/bigisland.php", { place = "camp", whichcamp = 1 })
				result, resulturl = async_get_page("/bigisland.php", { action = "bossfight", pwd = get_pwd() })()
				result, resulturl, did_action = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(15))
			else
				if count("gauze garter") < 10 then
					inform "buying gauze garters"
					async_post_page("/bigisland.php", { action = "getgear", pwd = get_pwd(), whichcamp = 2, whichitem = get_itemid("gauze garter"), quantity = 10 })
					did_action = (count("gauze garter") >= 10)
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
		if have("rock band flyers") then
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
				did_action = have("PADL Phone")
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
		elseif not have("Lord Spookyraven's spectacles") then
			script.bonus_target { "noncombat" }
			go("get spectacles", 108, macro_noodleserpent, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Springy Fusilli", "Spirit of Garlic" }, "Rogue Program", 50, { choice_function = function(advtitle, choicenum)
				if choicenum == 82 then
					return "Kick it and see what happens"
				elseif choicenum == 83 then
					return "Check the bottom drawer"
				elseif choicenum == 84 then
					return "Look behind the nightstand"
				elseif choicenum == 85 then
					if get_mainstat() == "Moxie" then
						return "Check the top drawer"
					else
						return "Investigate the jewelry"
					end
				end
			end })
		elseif not session["zone.manor.wines needed"] then
			inform "determine cellar wines"
			determine_cellar_wines()
--			print("determine call over")
			if session["zone.manor.wines needed"] then
				print("got wine state set now!")
				did_action = true
			end
--			print("all determine over")
		else
			local manor3pt = get_page("/manor3.php")
			local wines_needed_list = session["zone.manor.wines needed"]
			local need = 0
			local got = 0
			local missing = {}
			for wine in table.values(wines_needed_list) do
				need = need + 1
				if have(wine) then
					got = got + 1
				else
					missing[wine] = true
				end
			end
			if need ~= 3 then
				critical "Couldn't identify 3 wines needed for cellar"
			elseif manor3pt:match("Summoning Chamber") then
				inform "fight spookyraven"
				ensure_buffs { "Springy Fusilli", "Astral Shell", "Jaba&ntilde;ero Saucesphere", "Spirit of Bacon Grease", "Jalape&ntilde;o Saucesphere" }
				maybe_ensure_buffs_in_fist { "Astral Shell" }
				fam "Frumious Bandersnatch"
				use_hottub()
				ensure_mp(50)
				if buff("Astral Shell") or challenge == "boris" or buff("Red Door Syndrome") then
					local pt, url = get_page("/manor3.php", { place = "chamber" })
					result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_spookyraven())
				elseif meat() >= 3000 then
					if not have_item("can of black paint") then
						buy_item("can of black paint", "l")
					end
					use_item("can of black paint")
					did_action = buff("Red Door Syndrome")
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
				local next_zone = best_zones[math.random(table.maxn(best_zones))]
--				print("bestzone", table_to_str(best_zones), best, "going to", next_zone)
				go("get cellar wines", next_zone, macro_noodleserpent, {}, { "Spirit of Bacon Grease", "Fat Leon's Phat Loot Lyric", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Slimeling", 50)
			end
		end
	end

	function f.do_gotta_worship_them_all()
		local woodspt = get_page("/woods.php")
		if not woodspt:contains("The Hidden Temple") then
			f.unlock_hidden_temple()
		elseif not woodspt:match("hiddencity") then
			if not buff("Stone-Faced") and have("stone wool") then
				use_item("stone wool")
			end
			if buff("Stone-Faced") or ascensionstatus() == "Hardcore" then
				ignore_buffing_and_outfit = true
				if not have("the Nostril of the Serpent") and ascension["zone.hidden temple.placed Nostril of the Serpent"] ~= "yes" then
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
			local hiddencitypt = get_page("/hiddencity.php")
			local count_spheres_stones = count("cracked stone sphere") + count("mossy stone sphere") + count("rough stone sphere") + count("smooth stone sphere") + count("triangular stone")
			local altars = 0
			for x in hiddencitypt:gmatch("map_altar.gif") do
				altars = altars + 1
			end
			if count_spheres_stones == 4 and altars == 4 and hiddencitypt:contains("map_temple.gif") then
				if count("triangular stone") == 4 then
					inform "fight hidden city boss"
					local temple_which = nil
					for which, tiletext in hiddencitypt:gmatch([[<a href='hiddencity.php%?which=([0-9]+)'>(.-)</a>]]) do
						if tiletext:contains("map_temple.gif") then
							temple_which = which
						end
					end
					if temple_which then
						ensure_buffs { "Spirit of Peppermint", "Jaba&ntilde;ero Saucesphere", "Jalape&ntilde;o Saucesphere" }
						fam "Mini-Hipster"
						f.heal_up()
						f.burn_mp(90)
						ensure_mp(80)
						async_get_page("/hiddencity.php", { which = temple_which })
						async_post_page("/hiddencity.php", { action = "trisocket" })
						result, resulturl = get_page("/fight.php")
						if challenge == "boris" then
							result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, "?", macro_hiddencity())
						else
							result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(5))
						end
						did_action = have("ancient amulet")
					end
				else
					inform "use spheres, get stones..."
					local altar_solutions = get_stone_sphere_status().altars
					local pre_stones = count("triangular stone")
					for which, tiletext in hiddencitypt:gmatch([[<a href='hiddencity.php%?which=([0-9]+)'>(.-)</a>]]) do
						if tiletext:contains("map_altar.gif") then
-- 								print("hiddencity altar", which, tiletext)
							local altarpt = get_page("/hiddencity.php", { which = which })
							if altarpt:contains("<form") then
								for a, b in pairs(altar_solutions) do
									if altarpt:match("<table><tr><td><table><tr><td valign=center><img src='http://images.kingdomofloathing.com/otherimages/hiddencity/altar[0-9].gif' alt='An altar with a carving of a god of "..a.."' title='An altar with a carving of a god of "..a.."'></td><td><b>Altared Perceptions</b><p>You discover a stone altar, elaborately carved with a depiction of what appears to be some kind of ancient god.</td></tr></table>The top of the altar features a bowl%-like depression %-%- it looks as though you're meant to put something into it. Probably something round.<p>") then
										print("put", b, get_itemid(b .. " stone sphere"), "in", which)
										result, resulturl = post_page("/hiddencity.php", { action = "roundthing", whichitem = get_itemid(b .. " stone sphere") })
										did_action = (count("triangular stone") > pre_stones)
										return result, resulturl, did_action
									end
								end
							end
						end
					end
				end
			else
				local which = hiddencitypt:match([[<a href='hiddencity.php%?which=([0-9]-)'><img src="http://images.kingdomofloathing.com/otherimages/hiddencity/map_unruins]])
				if which then
					inform("do hidden city (" .. which .. ")")
					ensure_buffs { "Spirit of Peppermint", "Jaba&ntilde;ero Saucesphere", "Jalape&ntilde;o Saucesphere" }
					local fam_t = fam "Mini-Hipster"
					f.heal_up()
					if fam_t.mpregen then
						f.burn_mp(90)
					end
					ensure_mp(60)
--					print("DEBUG: fighting in hidden city, did_action: " .. tostring(did_action))
					local pt, url = get_page("/hiddencity.php", { which = which })
					result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_hiddencity())
					if advagain or get_result():match([[Altared Perceptions]]) or get_result():match([[Mansion House of the Black Friars]]) or get_result():match([[Dr. Henry "Dakota" Fanning, Ph.D., R.I.P.]]) then
						did_action = true
					elseif resulturl:match("/adventure.php") and get_result():match([[<a href="hiddencity.php">Go back to The Hidden City</a>]]) then
						did_action = true
					end
--					print("DEBUG: fought in hidden city, did_action: " .. tostring(did_action))
				else
					critical "Nothing to do in hidden city, but don't have all spheres"
				end
			end
		end
	end

	function f.do_pyramid()
		local pyramidpt = get_page("/pyramid.php")
-- 		if challenge == "fist" then
-- 			error "Redo pyramid in fist, do ratchets"
-- 		end
		if pyramidpt:match("pyramid3a.gif") then
			if not have("carved wooden wheel") then
				script.bonus_target { "item" }
				go("find carved wheel", 124, macro_noodleserpent, nil, { "Spirit of Bacon Grease" }, "Mini-Hipster", 45)
			else
				script.bonus_target { "noncombat" }
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
				ensure_buffs { "Jalape&ntilde;o Saucesphere", "Jaba&ntilde;ero Saucesphere", "Spirit of Garlic", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds" }
				maybe_ensure_buffs { "Mental A-cue-ity" }
				ensure_mp(100)
				result, resulturl = get_page("/pyramid.php", { action = "lower" })
				result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(5))
				while get_result():contains([[<!--WINWINWIN-->]]) and get_result():contains([[fight.php]]) do
					result, resulturl = get_page("/fight.php")
					result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, "?", macro_noodlegeyser(5))
				end
				did_action = have("Holy MacGuffin")
			elseif pyramidpt:match("pyramid4_1.gif") and have("ancient bomb") then
				inform "use bomb"
				async_get_page("/pyramid.php", { action = "lower" })
				pyramidpt = get_page("/pyramid.php")
				did_action = pyramidpt:contains("pyramid4_1b.gif")
			elseif pyramidpt:match("pyramid4_3.gif") and not have("ancient bomb") and have("ancient bronze token") then
				inform "buy bomb"
				async_get_page("/pyramid.php", { action = "lower" })
				did_action = have("ancient bomb")
			elseif pyramidpt:match("pyramid4_4.gif") and not have("ancient bomb") and not have("ancient bronze token") then
				inform "get token"
				async_get_page("/pyramid.php", { action = "lower" })
				did_action = have("ancient bronze token")
			elseif pyramidpt:match("pyramid4_[12345].gif") then
				if have("tomb ratchet") then
					local c = count("tomb ratchet")
					use_item("tomb ratchet")
					did_action = count("tomb ratchet") < c
				else
					script.bonus_target { "noncombat" }
					go("turn middle chamber wheel", 125, macro_noodleserpent, {
						["Wheel in the Pyramid, Keep on Turning"] = "Turn the wheel",
					}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Bacon Grease" }, "Rogue Program", 45)
				end
			end
		end
	end

	function f.do_filthworms()
		script.bonus_target { "item", "extraitem" }
		if not buff("Super Vision") and have("Greatest American Pants") then
			wear { pants = "Greatest American Pants" }
			script.get_gap_buff("Super Vision")
		end
		if daysthisrun() <= 2 and not ascensionstatus("Hardcore") and not have_buff("Super Vision") then
			ensure_buffs {}
			wear {}
			stop "TODO: Do filthworms [not automated when it's day 2 without super vision]"
		end
		if buff("Filthworm Guard Stench") then
			go("fight queen", 130, macro_noodlecannon, {}, { "Spirit of Bacon Grease" }, "Hobo Monkey", 30, { equipment = { familiarequip = "sugar shield" } })
		elseif have("filthworm royal guard scent gland") then
			inform "using guard stench"
			set_result(use_item("filthworm royal guard scent gland"))
			did_action = buff("Filthworm Guard Stench")
		elseif buff("Filthworm Drone Stench") then
			if daysthisrun() >= 3 then
				pull_in_softcore("peppermint crook")
			end
			go("fight guard", 129, (challenge == "boris" and have_item("peppermint crook") and macro_softcore_boris_crook) or macro_ppnoodlecannon, {}, { "Spirit of Bacon Grease", "Fat Leon's Phat Loot Lyric", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Slimeling", 30, { equipment = { familiarequip = "sugar shield", pants = (challenge == "boris" and have("Greatest American Pants")) and "Greatest American Pants" or nil } })
		elseif have("filthworm drone scent gland") then
			inform "using drone stench"
			set_result(use_item("filthworm drone scent gland"))
			did_action = buff("Filthworm Drone Stench")
		elseif buff("Filthworm Larva Stench") then
			if daysthisrun() >= 3 then
				pull_in_softcore("peppermint crook")
			end
			go("fight drone", 128, (challenge == "boris" and count_item("peppermint crook") >= 2 and macro_softcore_boris_crook) or macro_ppnoodlecannon, {}, { "Spirit of Bacon Grease", "Fat Leon's Phat Loot Lyric", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Slimeling", 30, { equipment = { familiarequip = "sugar shield", pants = (challenge == "boris" and have("Greatest American Pants")) and "Greatest American Pants" or nil } })
		elseif have("filthworm hatchling scent gland") then
			inform "using hatchling stench"
			set_result(use_item("filthworm hatchling scent gland"))
			did_action = buff("Filthworm Larva Stench")
		else
			-- TODO: use GAP +item% buff if available, GAP structure buff
			softcore_stoppable_action("fight hatchling")
			go("fight hatchling", 127, (challenge == "boris" and count("peppermint crook") >= 3 and macro_softcore_boris_crook) or macro_ppnoodlecannon, {}, { "Spirit of Bacon Grease", "Fat Leon's Phat Loot Lyric", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Slimeling", 30, { equipment = { familiarequip = "sugar shield", pants = (challenge == "boris" and have("Greatest American Pants")) and "Greatest American Pants" or nil } })
		end
	end

	function f.do_sonofa()
		if count("barrel of gunpowder") >= 5 then
			inform "talk to lighthouse guy"
			wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { place = "lighthouse", action = "pyro", pwd = get_pwd() })
			async_get_page("/bigisland.php", { place = "lighthouse", action = "pyro", pwd = get_pwd() })
			did_action = (have("tequila grenade") and have("molotov cocktail cocktail"))
		else
			if not buff("Hippy Stench") and have("reodorant") then
				-- TODO: use maybe_ensure_buffs
				use_item("reodorant")
			end
			if challenge == "boris" then
				local macro_copy_lfm = macro_softcore_boris([[

if monstername lobsterfrogman
  use Rain-Doh black box
endif

]])
				if have("Rain-Doh box full of monster") then
					local copied = retrieve_raindoh_monster()
					if copied:contains("lobsterfrogman") then
						use_item("Rain-Doh box full of monster")
						local pt, url = get_page("/fight.php")
						local m = macro_copy_lfm
						if count("barrel of gunpowder") >= 4 then
							m = macro_softcore_boris()
						end
						result, resulturl, advagain = handle_adventure_result(pt, url, "?", m)
						if advagain then
							did_action = true
						end
					else
						stop("TODO: fight rain-doh copied monster")
					end
				else
					script.bonus_target { "combat" }
					script.ensure_buffs {}
					if buff("Song of Battle") and ascensionstatus() == "Hardcore" then
						go("do sonofa beach, " .. make_plural(count("barrel of gunpowder"), "barrel", "barrels"), 136, macro_hardcore_boris, {}, { "Spirit of Bacon Grease", "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Heavy Petting", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog for +combat", 50, { equipment = { familiarequip = "sugar shield" } })
					elseif buff("Song of Battle") and have("Rain-Doh black box") then
						go("do sonofa beach, " .. make_plural(count("barrel of gunpowder"), "barrel", "barrels"), 136, macro_copy_lfm, {}, { "Spirit of Bacon Grease", "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Heavy Petting", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog for +combat", 50, { equipment = { familiarequip = "sugar shield" } })
					else
						stop "TODO: Do sonofa in Boris"
					end
				end
			elseif challenge == "zombie" and not have_buff("Waking the Dead") then
				if have_skill("Summon Horde") then
					cast_skillid(12021, 1)
					async_get_page("/choice.php", { forceoption = 0 })
					async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 600, option = 1 })
					async_get_page("/choice.php", { pwd = get_pwd(), whichchoice = 600, option = 2 })
				end
				if have_buff("Waking the Dead") then
					go("do sonofa beach, " .. make_plural(count("barrel of gunpowder"), "barrel", "barrels"), 136, macro_noodleserpent, {}, { "Spirit of Bacon Grease", "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Heavy Petting", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog for +combat", 50, { equipment = { familiarequip = "sugar shield" } })
				else
					stop "TODO: Do sonofa in zombie"
				end
			else
				go("do sonofa beach, " .. make_plural(count("barrel of gunpowder"), "barrel", "barrels"), 136, macro_noodleserpent, {}, { "Spirit of Bacon Grease", "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Heavy Petting", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog for +combat", 50, { equipment = { familiarequip = "sugar shield" } })
			end
			if buff("Beaten Up") then
				use_hottub()
				did_action = not buff("Beaten Up")
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
		if not have("molybdenum magnet") then
			wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { action = "junkman", pwd = get_pwd() })
		end
		wear {}
		local function get_gremlin_data()
			if not have("molybdenum hammer") then
				return "get gremlin hammer", 182, make_gremlin_macro("batwinged gremlin", "a bombing run")
			elseif not have("molybdenum crescent wrench") then
				return "get gremlin wrench", 184, make_gremlin_macro("erudite gremlin", "random junk")
			elseif not have("molybdenum pliers") then
				return "get gremlin pliers", 183, make_gremlin_macro("spider gremlin", "fibula")
			elseif not have("molybdenum screwdriver") then
				return "get gremlin screwdriver", 185, make_gremlin_macro("vegetable gremlin", "picks a")
			end
		end
		local i, z, m = get_gremlin_data()
		if z then
			if ascensionstatus() ~= "Hardcore" then
				if not buff("Super Structure") and have("Greatest American Pants") then
					wear { pants = "Greatest American Pants" }
					script.get_gap_buff("Super Structure")
				end
				if challenge and not buff("Super Structure") and not have_skill("Louder Bellows") then
					stop "TODO: Do gremlins in challenge path without Super Structure"
				end
			end
			if challenge and not buff("Super Structure") then
				script.bonus_target { "easy combat" }
				if not have_buff("Standard Issue Bravery") and have_item("CSA bravery badge") then
					use_item("CSA bravery badge")
				end
			end
			inform(i)
			ensure_buffs { "Spirit of Bacon Grease", "Astral Shell", "Ghostly Shell", "A Few Extra Pounds" }
			fam "Frumious Bandersnatch"
			f.heal_up()
			ensure_mp(60)
			result, resulturl, did_action = autoadventure { zoneid = z, macro = m, ignorewarnings = true }
		else
			if not have("molybdenum hammer") or not have("molybdenum crescent wrench") or not have("molybdenum pliers") or not have("molybdenum screwdriver") then
				critical "Missing items when finishing junkyard quest"
			end
			wear { hat = "beer helmet", pants = "distressed denim pants", acc3 = "bejeweled pledge pin" }
			async_get_page("/bigisland.php", { action = "junkman", pwd = get_pwd() })
			if not have("molybdenum hammer") and not have("molybdenum crescent wrench") and not have("molybdenum pliers") and not have("molybdenum screwdriver") then
				did_action = true
			end
		end
	end

	function f.do_trapper_quest()
		if quest_text("go talk to the Trapper") then
			async_get_page("/place.php", { whichplace = "mclargehuge", action = "trappercabin" })
			refresh_quest()
			did_action = not quest_text("go talk to the Trapper")
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
				local famchoice = "Slimeling"
				if count("glass of goat's milk") < 2 or not buff("Brother Flying Burrito's Blessing") then
					table.insert(bufftbl, "Heavy Petting")
					table.insert(bufftbl, "Peeled Eyeballs")
					famchoice = "Slimeling even in fist" -- ??? why?
				end
				go("get goat cheese for trapper", 271, make_cannonsniff_macro("dairy goat"), nil, bufftbl, famchoice, 35, { olfact = "dairy goat" })
			elseif (challenge == "fist") or (have_item("miner's helmet") and have_item("7-Foot Dwarven mattock") and have_item("miner's pants")) then
				inform "TODO: mine for ore"
				if challenge == "fist" then
					ensure_buffs { "Earthen Fist" }
				else
					wear { hat = "miner's helmet", weapon = "7-Foot Dwarven mattock", pants = "miner's pants" }
				end
				result, resulturl = get_page("/mining.php", { mine = 1 })
				result = add_colored_message_to_page(get_result(), "TODO: get 3x " .. (session["trapper.ore"] or "unknown") .. " ore, then run script again", "darkorange")
				did_action = false
			elseif ascensionstatus() == "Softcore" then
				local want_ore = trappercabin:match("fix the lift until you bring me that cheese and ([a-z]+ ore)")
				local got = count_item(want_ore)
				if got >= 3 then
					critical "Trapper ore+cheese quest should be finished already."
				end
				if false and want_ore == "chrome ore" and not have("acoustic guitarrr") and not have("heavy metal thunderrr guitarrr") then
					-- TODO: do this when we can untinker
					ascension_automation_pull_item("heavy metal thunderrr guitarrr")
					did_action = have("heavy metal thunderrr guitarrr")
				else
					ascension_automation_pull_item(want_ore)
					did_action = count(want_ore) > got
				end
			else
				go("get mining outfit", 270, macro_noodlecannon(), {}, { "Fat Leon's Phat Loot Lyric", "Leash of Linguini", "Empathy", "Spirit of Garlic" }, "Slimeling", 35, { choice_function = function(advtitle, choicenum)
					if advtitle == "100% Legal" then
						if not have("miner's helmet") then
							return "Demand loot"
						else
							return "Ask for ore"
						end
					elseif advtitle == "A Flat Miner" then
						if not have("miner's pants") then
							return "Loot the dwarf's belongings"
						else
							return "Hijack the meat vein"
						end
					elseif advtitle == "See You Next Fall" then
						if not have("7-Foot Dwarven mattock") then
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
			async_get_page("/place.php", { whichplace = "mclargehuge", action = "cloudypeak" })
			refresh_quest()
			if not quest_text("like you to investigate the summit") then
				did_action = true
			else
				script.bonus_target { "noncombat" }
				go("explore the extreme slope", 273, macro_noodlecannon(), {}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Peppermint" }, "Slimeling", 35, { choice_function = function(advtitle, choicenum)
					if advtitle == "Generic Teen Comedy Snowboarding Adventure" then
						if not have("eXtreme mittens") then
							return "Give him a pep-talk"
						else
							return "Give him some boarding tips"
						end
					elseif advtitle == "Saint Beernard" then
						if not have("snowboarder pants") then
							return "Help the heroic dog"
						else
							return "Flee in terror"
						end
					elseif advtitle == "Yeti Nother Hippy" then
						if not have("eXtreme scarf") then
							return "Let irony take its course"
						else
							return "Help the hippy"
						end
					elseif advtitle == "Duffel on the Double" then
						if have("eXtreme scarf") and have("snowboarder pants") and have("eXtreme mittens") then
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
		elseif quest_text("ready to ascend to the Icy Peak") or quest_text("close to figuring out what's going on at the Icy Peak") or quest_text("have slain Groar") then
			async_get_page("/place.php", { whichplace = "mclargehuge", action = "trappercabin" })
			refresh_quest()
			if not quest_text("ready to ascend to the Icy Peak") and not quest_text("close to figuring out what's going on at the Icy Peak") then
				did_action = true
			else
				wear { hat = "eXtreme scarf", pants = "snowboarder pants", acc3 = "eXtreme mittens" }
				fam "Frumious Bandersnatch"
				ensure_buffs { "Springy Fusilli", "Spirit of Cayenne" }
				ensure_mp(40)
				inform "exploring the icy peak"
				local pt, url = get_page("/place.php", { whichplace = "mclargehuge", action = "cloudypeak2" })
				result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_noodlecannon())
				did_action = advagain
			end
		else
			critical "Failed to finish trapper quest"
		end
-- 			if have("astral shirt") or have("cane-mail shirt") then
-- 				did_action = true
-- 			elseif challenge == "fist" then
-- 				did_action = true
-- 			elseif highskill_at_run and not have("hipposkin poncho") then
-- 				async_post_page("/trapper.php", { action = "Yep.", pwd = get_pwd(), whichitem = get_itemid("hippopotamus skin"), qty = 1 })
-- 				if have("hippopotamus skin") then
-- 					inform "smith hipposkin poncho stuff"
-- 					if not have("tenderizing hammer") then
-- 						buy_item("tenderizing hammer", "s")
-- 					end
-- 					if not have("shirt kit") then
-- 						buy_item("shirt kit", "s")
-- 					end
-- 					smith_items_craft("shirt kit", "hippopotamus skin")
-- 					did_action = have("hipposkin poncho")
-- 				end
-- 			elseif not have("yak anorak") and not highskill_at_run and have_skill("Torso Awaregness") and have_skill("Armorcraftiness") then
-- 				async_post_page("/trapper.php", { action = "Yep.", pwd = get_pwd(), whichitem = get_itemid("yak skin"), qty = 1 })
-- 				if have("yak skin") then
-- 					inform "smith and wear yak stuff"
-- 					if not have("tenderizing hammer") then
-- 						buy_item("tenderizing hammer", "s")
-- 					end
-- 					if not have("shirt kit") then
-- 						buy_item("shirt kit", "s")
-- 					end
-- 					smith_items_craft("shirt kit", "yak skin")
-- 					did_action = have("yak anorak")
-- 				end
-- 			end
	end

	function f.do_muscle_powerleveling()
-- 		print("  mainstat", basemainstat(), "advs", advs())
		if have("Spookyraven gallery key") then
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
-- 		print("  mainstat", basemainstat(), "dance cards", count("dance card"), "advs", advs(), "trail turns", buffturns("On the Trail"))
		script.bonus_target { "noncombat", "item" }
		go("moxie powerleveling", 109, make_cannonsniff_macro("zombie waltzers"), {
			["Curtains"] = "Watch the dancers",
			["Strung-Up Quartet"] = "&quot;Play 'Sono Un Amanten Non Un Combattente'&quot;",
		}, { "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric" }, "Slimeling", 30, { olfact = "zombie waltzers" })
	end

	function f.do_moxie_use_dancecard()
		if have("dance card") then
			local dance_card_turn = tonumber(ascension["dance card turn"]) or -1000
			if dance_card_turn < turnsthisrun() then
				return use_item("dance card")
			end
		end
	end

	function f.get_shore_trips()
		local pt, pturl = get_page("/shore.php")
		local trips = pt:match("You have taken (.-) trip")
		if trips == "no" then
			trips = 0
		elseif trips == "one" then
			trips = 1
		else
			trips = tonumber(trips)
		end
		if not trips then
			critical "Could not determine number of shore trips taken"
		end
		return trips
	end

	function f.get_dinghy()
		cached_stuff.completed_shore_trips = nil
		inform "make dingy dinghy"
		if not have("dinghy plans") then
			inform "shore for dinghy plans"
			local trips = f.get_shore_trips()
			local function do_trip(tripid)
				result, resulturl = post_page("/shore.php", { pwd = get_pwd(), whichtrip = tripid })
				local new_trips = f.get_shore_trips()
				did_action = (new_trips > trips)
			end
			local shore_tower_items = {
				["stick of dynamite"] = 1,
				["tropical orchid"] = 2,
				["barbed-wire fence"] = 3,
			}

			local tbl = session["zone.lair.itemsneeded"]
			if not tbl then
				async_post_page("/campground.php", { action = "telescopelow" })
				tbl = session["zone.lair.itemsneeded"] or {}
			end
			local need_item = nil
			local want_adv = nil
			for from, to in pairs(tbl) do
				if shore_tower_items[to] then
					need_item = to
					want_adv = shore_tower_items[to]
				end
			end
			if not need_item then
				critical "Don't know which shore tower item is needed."
			end
			if trips == 1 then
				do_trip(want_adv)
				did_action = have(need_item)
			elseif trips >= 2 and trips < 5 and have_item(need_item) then
				local whichtrip = {
					["Muscle"] = 1,
					["Mysticality"] = 2,
					["Moxie"] = 3,
				}
				do_trip(whichtrip[get_mainstat()])
			elseif trips < 5 then
				inform "shoring even though we might miss tower item now"
				do_trip(want_adv)
			else
				critical "Already taken 5 shore trips without getting dinghy"
			end
		elseif not have("dingy planks") then
			inform "buy dingy planks"
			set_result(buy_item("dingy planks", "m"))
			did_action = have("dingy planks")
		else
			set_result(use_item("dinghy plans"))
			did_action = have("dingy dinghy")
		end
	end

	function f.get_big_book_of_pirate_insults()
		if have("eyepatch") and have("swashbuckling pants") and have("stuffed shoulder parrot") and not have("The Big Book of Pirate Insults") then
			if meat() >= 1500 then
				inform "buy insult book and dictionary"
				wear { hat = "eyepatch", pants = "swashbuckling pants", acc3 = "stuffed shoulder parrot" }
				buy_item("The Big Book of Pirate Insults", "r")
				buy_item("abridged dictionary", "r")
				did_action = (have("The Big Book of Pirate Insults") and have("abridged dictionary"))
			else
				if challenge == "fist" then
					go("farm > sign for meat", 226, macro_noodlecannon, { ["Typographical Clutter"] = "The lower-case L" }, { "Smooth Movements", "The Sonata of Sneakiness", "Polka of Plenty" }, "Slimeling", 25)
				else
					stop "Not enough meat for insult book + dictionary."
				end
			end
		else
			script.bonus_target { "noncombat", "item" }
			go("get swashbuckling outfit", 66, macro_noodlecannon, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric" }, "Slimeling", 25, { choice_function = function(advtitle, choicenum)
				if advtitle == "Amatearrr Night" then
					if not have("stuffed shoulder parrot") then
						return "What's orange and sounds like a parrot?" -- stuffed shoulder parrot
					else
						return "What's gold and sounds like a pirate?" -- eyepatch
					end
				elseif advtitle == "The Arrrbitrator" then
					if not have("eyepatch") then
						return "Vote for Jack Robinson" -- eyepatch
					else
						return "Vote for Sergeant Hook" -- swashbuckling pants
					end
				elseif advtitle == "Barrie Me at Sea" then
					if not have("swashbuckling pants") then
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
		if not have("chewing gum on a string") then
			buy_item("chewing gum on a string", "m")
		end
		result, resulturl = use_item("chewing gum on a string")()
		did_action = get_result():contains("You acquire")
		return result, resulturl, did_action
	end

	function f.unlock_hidden_temple()
		-- spooky forest
		if have("Spooky Temple map") and have("Spooky-Gro fertilizer") and have("spooky sapling") then
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
					if not have("Spooky Temple map") then
						if not have("tree-holed coin") then
							return "Explore the stream"
						else
							return "Brave the dark thicket"
						end
					elseif not have("Spooky-Gro fertilizer") then
						return "Brave the dark thicket"
					elseif not have("spooky sapling") then
						return "Follow the old road"
					end
				elseif advtitle == "Consciousness of a Stream" then
					if not have("Spooky Temple map") and not have("tree-holed coin") then
						inform "get coin"
						return "Squeeze into the cave"
					end
				elseif advtitle == "Through Thicket and Thinnet" then
					if not have("Spooky Temple map") then
						return "Follow the coin"
					elseif not have("Spooky-Gro fertilizer") then
						inform "get fertilizer"
						return "Investigate the dense foliage"
					end
				elseif advtitle == "O Lith, Mon" then
					inform "get map"
					return "Insert coin to continue"
				elseif advtitle == "The Road Less Traveled" then
					if not have("spooky sapling") then
						return "Talk to the hunter"
					end
				elseif advtitle == "Tree's Last Stand" then
					if not have("spooky sapling") then
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
-- 			if not did_action and have("spooky sapling") and get_result():contains("Results:") then
-- 				result, resulturl = post_page("/choice.php", { pwd = get_pwd(), whichchoice = 504, option = 4 })
-- 				result, resulturl, advagain = handle_adventure_result(get_result(), resulturl, 15, nil, {})
-- 				did_action = advagain
-- 			end
		end
		return result, resulturl, did_action
	end

	function f.knob_goblin_king_with_cake(killmacro)
		if have("Knob cake") then
			inform "fight king in guard outfit"
			wear { hat = "Knob Goblin elite helm", weapon = "Knob Goblin elite polearm", pants = "Knob Goblin elite pants" }
			ensure_buffs { "Springy Fusilli", "Spirit of Garlic" }
			ensure_mp(40)
			fam "Frumious Bandersnatch"
			set_mcd(7) -- TODO: moxie-specific
			local pt, url = get_page("/cobbsknob.php", { action = "throneroom" })
			result, resulturl, advagain = handle_adventure_result(pt, url, "?", killmacro)
			did_action = advagain
		elseif have("unfrosted Knob cake") and have("Knob frosting") then
			inform "frost cake"
			set_result(cook_items("unfrosted Knob cake", "Knob frosting"))
			did_action = have("Knob cake")
		elseif have("Knob cake pan") and have("Knob batter") then
			inform "make unfrosted knob cake"
			set_result(cook_items("Knob cake pan", "Knob batter"))
			did_action = have("unfrosted Knob cake")
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
		if not have("magical mystery juice") then
			async_get_page("/guild.php", { place = "challenge" })
			buy_item("magical mystery juice", "2")
		end
		if have("magical mystery juice") then
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
			inform "get tonic water"
			if challenge ~= "fist" then
				buy_item("soda water", "m", 10)
				async_post_page("/guild.php", { action = "stillfruit", whichitem = get_itemid("soda water"), quantity = 10 })
			else
				buy_item("soda water", "m", 1)
				async_post_page("/guild.php", { action = "stillfruit", whichitem = get_itemid("soda water"), quantity = 1 })
			end
			did_action = have("tonic water")
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
		if count("star chart") >= 3 or ((challenge == "fist" or challenge == "boris") and count("star chart") >= 2) then
			if count("star") >= 8+5 and count("line") >= 7+3 then
				sparestars = count("star") - 8 - 5
				sparelines = count("line") - 7 - 3
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
			if not have("Richard's star key") then
				async_post_page("/starchart.php", { action = "makesomething", pwd = get_pwd(), numstars = "8", numlines = "7" })
			end
			if not have("star hat") then
				async_post_page("/starchart.php", { action = "makesomething", pwd = get_pwd(), numstars = "5", numlines = "3" })
			end
			if not have("star crossbow") and not have("star staff") and not have("star sword") and challenge ~= "fist" and challenge ~= "boris" then
				if count("star") >= 5 and count("line") >= 6 then
					async_post_page("/starchart.php", { action = "makesomething", pwd = get_pwd(), numstars = "5", numlines = "6" })
				elseif count("star") >= 6 and count("line") >= 5 then
					async_post_page("/starchart.php", { action = "makesomething", pwd = get_pwd(), numstars = "6", numlines = "5" })
				elseif count("star") >= 7 and count("line") >= 4 then
					async_post_page("/starchart.php", { action = "makesomething", pwd = get_pwd(), numstars = "7", numlines = "4" })
				end
			end
			if have("Richard's star key") and have("star hat") and (have("star crossbow") or have("star staff") or have("star sword") or challenge == "fist" or challenge == "boris") then
				did_action = true
			end
		else
			if trailed and trailed == "Astronomer" then
				stop("Trailing " .. trailed .. " when finishing hits")
			end
			script.bonus_target { "item" }
			go("finish hits", 83, macro_noodlecannon, {}, { "Spirit of Peppermint", "Fat Leon's Phat Loot Lyric", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Slimeling", 40)
		end
		return result, resulturl, did_action
	end

	function f.do_tavern(withfam, minmp, macrofunc)
		-- TODO: wrap in task
		if quest_text("You should head back to Bart") then
			result, resulturl = get_page("/tavern.php", { place = "barkeep" })
			did_action = have("Typical Tavern swill")
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
				if not have("goofballs") or meat() ~= m then
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
		if not buff("Super Vision") and have("Greatest American Pants") then
			wear { pants = "Greatest American Pants" }
			script.get_gap_buff("Super Vision")
		end
		if not challenge then
			maybe_ensure_buffs { "Mental A-cue-ity" }
		end
		if not have("Azazel's lollipop") then
			if count("imp air") >= 5 and have("observational glasses") then
				inform "solve mourn"
				if not challenge then
					wear { weapon = "hilarious comedy prop", offhand = "Victor, the Insult Comic Hellhound Puppet" }
					result, resulturl = post_page("/pandamonium.php", { action = "mourn", preaction = "prop" })
					result, resulturl = post_page("/pandamonium.php", { action = "mourn", preaction = "insult" })
				end
				wear { acc3 = "observational glasses" }
				result, resulturl = post_page("/pandamonium.php", { action = "mourn", preaction = "observe" })
				did_action = have("Azazel's lollipop")
			else
				local macro_laughfloor = [[
if monstername imp
]] .. macro_smash_and_graagh .. [[


]] .. macro_ppnoodlecannon() .. [[

  goto m_done
endif

]] .. macro_noodleserpent() .. [[

mark m_done

]]
				if challenge == "fist" then
					macro_laughfloor = macro_fist()
				end
				if count("imp air") < 5 then
					go("mourn, imp air: " .. count("imp air"), 242, macro_laughfloor, nil, { "Leash of Linguini", "Empathy", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling", 35)
				else
					-- TODO: buff for finding faster?
					script.bonus_target { "combat" }
					go("mourn, getting bosses", 242, macro_laughfloor, nil, { "Leash of Linguini", "Empathy", "Spirit of Garlic", "A Few Extra Pounds" }, "Rogue Program", 35)
				end
			end
		elseif not have("Azazel's unicorn") then
			if count("bus pass") >= 5 and (count("sponge cake") + count("comfy pillow") + count("booze-soaked cherry")) >= 2 and (count("gin-soaked blotter paper") + count("giant marshmallow") + count("beer-scented teddy bear")) >= 2 then
				inform "solve sven golly"
				local bognort = have("giant marshmallow") and "giant marshmallow" or "gin-soaked blotter paper"
				local stinkface = have("beer-scented teddy bear") and "beer-scented teddy bear" or "gin-soaked blotter paper"
				local flargwurm = have("booze-soaked cherry") and "booze-soaked cherry" or "sponge cake"
				local jim = have("comfy pillow") and "comfy pillow" or "sponge cake"
				async_post_page("/pandamonium.php", { action = "sven", preaction = "help" })
				async_post_page("/pandamonium.php", { action = "sven", bandmember = "Bognort", togive = get_itemid(bognort), preaction = "try" })
				async_post_page("/pandamonium.php", { action = "sven", bandmember = "Stinkface", togive = get_itemid(stinkface), preaction = "try" })
				async_post_page("/pandamonium.php", { action = "sven", bandmember = "Flargwurm", togive = get_itemid(flargwurm), preaction = "try" })
				result, resulturl = post_page("/pandamonium.php", { action = "sven", bandmember = "Jim", togive = get_itemid(jim), preaction = "try" })
				did_action = have("Azazel's unicorn")
			else
				if count("bus pass") < 5 then
				local macro_backstage = [[
]] .. macro_smash_and_graagh .. [[


]] .. macro_ppnoodlecannon()
					go("sven golly, bus passes: " .. count("bus pass"), 243, macro_backstage, nil, { "Leash of Linguini", "Empathy", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling", 35)
				else
					-- TODO: buff for finding faster?
					go("sven golly, getting items", 243, macro_noodlecannon, nil, { "Leash of Linguini", "Empathy", "Spirit of Garlic", "A Few Extra Pounds" }, "Rogue Program", 35)
				end
			end
		elseif not have("Azazel's tutu") then
			inform "solve stranger"
			async_get_page("/pandamonium.php", { action = "moan" })
			async_get_page("/pandamonium.php", { action = "moan" })
			did_action = have("Azazel's tutu")
		else
			inform "solve azazel"
			async_get_page("/pandamonium.php", { action = "temp" })
			did_action = have("steel margarita") or have("steel lasagna") or have("steel-scented air freshener")
		end
		return result, resulturl, did_action
	end

	function f.do_boss_bat(macrofunc, extra_mp)
		ignore_buffing_and_outfit = false
		local batholept = get_page("/bathole.php")
		if not batholept:match("Boss") then
			script.bonus_target { "item" }
			if have("sonar-in-a-biscuit") then
				inform "using sonar"
				use_item("sonar-in-a-biscuit")
				did_action = true
			elseif not batholept:match("Beanbat") then
				f.trade_for_clover()
				if not have("ten-leaf clover") then
					use_item("disassembled clover")
				end
				if have("ten-leaf clover") then
					if not buff("Super Structure") and have("Greatest American Pants") then
						wear { pants = "Greatest American Pants" }
						script.get_gap_buff("Super Structure")
					end
					go("clovering sonars", 31, nil, nil, { "Leash of Linguini", "Empathy", "Astral Shell" }, "Exotic Parrot", 10)
				else
					stop "No ten-leaf clover for sonars!"
				end
				did_action = (count("sonar-in-a-biscuit") == 2)
			elseif have("enchanted bean") then
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
		if not have("Degrassi Knoll shopping list") and challenge ~= "boris" and challenge ~= "zombie" and challenge ~= "jarlsberg" then
			inform "get shopping list"
			async_get_page("/guild.php", { place = "paco" })
			if have("Degrassi Knoll shopping list") then
				did_action = true
			else
				async_post_page("/guild.php", { action = "chal" })
				async_get_page("/guild.php", { place = "paco" })
				did_action = have("Degrassi Knoll shopping list")
			end
		else
			inform "build meatcar"
			if not have("meat stack") then
				async_get_page("/inventory.php", { quantity = 1, action = "makestuff", pwd = get_pwd(), whichitem = get_itemid("meat stack"), ajax = 1 })
			end
			buy_item("cog", "5")
			buy_item("empty meat tank", "5")
			buy_item("tires", "5")
			buy_item("spring", "5")
			buy_item("sprocket", "5")
			buy_item("sweet rims", "m")
			meatpaste_items("empty meat tank", "meat stack")
			meatpaste_items("spring", "sprocket")
			meatpaste_items("sprocket assembly", "cog")
			meatpaste_items("cog and sprocket assembly", "full meat tank")
			meatpaste_items("tires", "sweet rims")
			meatpaste_items("meat engine", "dope wheels")
			if not have("bitchin' meatcar") then
				critical "Failed to build bitchin' meatcar"
			end
			inform "unlock beach"
			async_get_page("/forestvillage.php", { place = "untinker" })
			async_post_page("/forestvillage.php", { action = "screwquest" })
			async_get_page("/knoll.php", { place = "smith" })
			async_get_page("/forestvillage.php", { place = "untinker" })
			local rf = async_get_page("/guild.php", { place = "paco" }) -- TODO: need the topmenu refreshed from this
			use_item("Degrassi Knoll shopping list")
			local b = get_page("/beach.php")
			did_action = b:contains("shore.php")
			result, resulturl = rf()
		end
		return result, resulturl, did_action
	end

	function f.do_crypt()
		local cyrpt = get_page("/cyrpt.php")
		if have("skeleton bone") and have("loose teeth") then
			meatpaste_items("skeleton bone", "loose teeth")
		end
		if have("evil eye") then
			use_item("evil eye")
		end
		softcore_stoppable_action("do crypt")
		local noncombattbl = {}
		if get_mainstat() == "Muscle" then
			noncombattbl["Turn Your Head and Coffin"] = "Investigate the fancy coffin"
			noncombattbl["Skull, Skull, Skull"] = "Leave the skulls alone"
			noncombattbl["Urning Your Keep"] = "Turn away"
			noncombattbl["Death Rattlin'"] = "Open the rattling one"
		elseif get_mainstat() == "Mysticality" then
			noncombattbl["Turn Your Head and Coffin"] = "Leave them all be"
			noncombattbl["Skull, Skull, Skull"] = "Leave the skulls alone"
			noncombattbl["Urning Your Keep"] = "Investigate the first urn"
			noncombattbl["Death Rattlin'"] = "Open the rattling one"
		elseif get_mainstat() == "Moxie" then
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
				if get_evilometer_data().Alcove >= 32 and have_item("Rain-Doh black box") then
					alcove_macro = macro_softcore_boris([[

if monstername modern zmobie
  use Rain-Doh black box
endif

]])
				end
				if have("Rain-Doh box full of monster") then
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
			script.bonus_target { "noncombat" }
			maybe_ensure_buffs { "Mental A-cue-ity" }
			go("do crypt cranny", 262, macro_noodlecannon, noncombattbl, { "Spirit of Garlic", "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds", "Ur-Kel's Aria of Annoyance" }, "Baby Bugged Bugbear", 35)
		elseif cyrpt:match("Defiled Niche") and (not trailed or trailed == "dirty old lihc") then
			go("do crypt niche", 263, make_cannonsniff_macro("dirty old lihc"), noncombattbl, { "Spirit of Garlic", "Butt-Rock Hair", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Rogue Program", 25, { olfact = "dirty old lihc" })
		elseif cyrpt:match("Defiled Nook") then
			script.bonus_target { "item" }
			if challenge == "boris" and not buff("Super Vision") and have("Greatest American Pants") then
				wear { pants = "Greatest American Pants" }
				script.get_gap_buff("Super Vision")
			end
			go("do crypt nook", 264, macro_noodlecannon, noncombattbl, { "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Slimeling", 25)
		else
			inform "kill bonerdagon"
			if challenge == "boris" then
				local toequip = {}
				if buffedmainstat() < 120 then
					ensure_buffs { "Go Get 'Em, Tiger!" }
				end
				if buffedmainstat() < 120 and have("Crown of the Goblin King") then
					toequip = { hat = "Crown of the Goblin King" }
				end
				wear(toequip)
				if buffedmainstat() < 120 and not buff("Starry-Eyed") then
					local gazept = post_page("/campground.php", { action = "telescopehigh" })
				end
				if buffedmainstat() >= 120 then
					f.heal_up()
					ensure_mp(50)
					local pt, url = get_page("/crypt.php", { action = "heart" })
					result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_softcore_boris_bonerdagon(), { ["The Haert of Darkness"] = "When I...  Yes?" })
				else
					stop "TODO: Fight bonerdagon in Boris"
				end
			else
				ensure_buffs { "A Few Extra Pounds", "Jalape&ntilde;o Saucesphere", "Jaba&ntilde;ero Saucesphere", "Springy Fusilli", "Spirit of Garlic", "Astral Shell", "Ghostly Shell" }
				maybe_ensure_buffs_in_fist { "A Few Extra Pounds", "Jalape&ntilde;o Saucesphere", "Jaba&ntilde;ero Saucesphere", "Astral Shell", "Ghostly Shell" }
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
			script.bonus_target { "noncombat" }
			if get_mainstat() == "Muscle" then
				if buffedmainstat() < 85 then
					ensure_buffs { "Go Get 'Em, Tiger!" }
				end
			elseif get_mainstat() == "Mysticality" then
				if buffedmainstat() < 85 then
					ensure_buffs { "Pasta Oneness", "Saucemastery" }
				end
				if buffedmainstat() < 85 then
					ensure_buffs { "Glittering Eyelashes" }
				end
			elseif get_mainstat() == "Moxie" then
				if buffedmainstat() < 85 then
					ensure_buffs { "Butt-Rock Hair" }
					maybe_ensure_buffs_in_fist { "Butt-Rock Hair" }
				end
			end
			maybe_ensure_buffs { "Mental A-cue-ity" }
			local macro = macro_noodlegeyser(4)
			if challenge == "fist" then
				macro = macro_fist()
			end
			local should_get_key = false
			-- TODO: use tobiko marble soda??
			if challenge == "boris" or challenge == "zombie" then
				if not buff("Super Structure") and have("Greatest American Pants") then
					wear { pants = "Greatest American Pants" }
					script.get_gap_buff("Super Structure")
				end
				if not buff("Super Structure") and level() < 7 then
					stop "TODO: Do bedroom in challenge path at level < 7"
				end
			end
			go("do bedroom", 108, macro, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Springy Fusilli", "Spirit of Garlic", "Jaba&ntilde;ero Saucesphere", "Jalape&ntilde;o Saucesphere" }, "Frumious Bandersnatch", 50, { choice_function = function(advtitle, choicenum)
				if choicenum == 82 then
					return "Kick it and see what happens"
				elseif choicenum == 83 then
					return "Check the bottom drawer"
				elseif choicenum == 84 then
					if have("Lord Spookyraven's spectacles") then
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
			if should_get_key and not have("Spookyraven ballroom key") then
				critical "Didn't get ballroom key when expected"
			end
		end
		return result, resulturl, did_action
	end

	function f.do_friars()
-- 		TODO: more buffs?
		local zone_stasis_macro = macro_stasis
		if challenge == "fist" then
			maybe_ensure_buffs { "Mental A-cue-ity" }
			zone_stasis_macro = macro_fist
		elseif get_mainstat() == "Mysticality" and (not have_skill("Astral Shell") or not have_skill("Tolerance of the Kitchen")) then
			maybe_ensure_buffs { "Mental A-cue-ity" }
			zone_stasis_macro = macro_noodlecannon
		end
		script.bonus_target { "noncombat", "item" }
		if fullness() + count("hellion cube") * 6 + 6 <= estimate_max_fullness() and ascensionstatus() == "Hardcore" and challenge ~= "zombie" then
			go("getting hellion cubes", 239, make_cannonsniff_macro("Hellion"), nil, { "Smooth Movements", "The Sonata of Sneakiness", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling", 20, { olfact = "Hellion" })
		elseif not have("box of birthday candles") then
			go("getting candles", 238, zone_stasis_macro, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Astral Shell", "Ghostly Shell", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "A Few Extra Pounds" }, { "Scarecrow with Boss Bat britches", "Rogue Program" }, 15)
		elseif (count("hot wing") < 3 or (meat() < 1000 and fullness() < 5)) and not have("box of birthday candles") then
			go("getting hot wings", 238, macro_noodlecannon, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "A Few Extra Pounds" }, "Slimeling even in fist", 20)
--		elseif have_reagent_pastas < 4 and not highskill_at_run and ascensionstatus() == "Hardcore" and challenge ~= "zombie" then
--			go("getting more hellion cubes", 239, macro_noodlecannon, nil, { "Leash of Linguini", "Empathy", "Butt-Rock Hair", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling", 20, { olfact = "Hellion" })
		elseif not have("dodecagram") then
			go("getting dodecagram", 239, macro_noodlecannon, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling even in fist", 20)
		elseif not have("ruby W") and (have_reagent_pastas < 8 or trailed ~= "Hellion") and ascensionstatus() == "Hardcore" then
			go("getting ruby W", 239, macro_noodlecannon, nil, { "Leash of Linguini", "Empathy", "Butt-Rock Hair", "Spirit of Garlic", "Fat Leon's Phat Loot Lyric", "A Few Extra Pounds" }, "Slimeling", 20, { olfact = "Hellion" })
		elseif not have("eldritch butterknife") then
			go("getting butterknife", 237, zone_stasis_macro, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Astral Shell", "Ghostly Shell", "Leash of Linguini", "Empathy", "Butt-Rock Hair", "A Few Extra Pounds" }, { "Scarecrow with Boss Bat britches", "Rogue Program" }, 15)
		elseif count("hot wing") < 3 then
			go("getting hot wings", 238, macro_noodlecannon, nil, { "Leash of Linguini", "Empathy", "Butt-Rock Hair", "A Few Extra Pounds" }, "Slimeling", 20)
		else
			inform "do ritual"
			async_post_page("/friars.php", { pwd = get_pwd(), action = "ritual" })
			async_post_page("/friars.php", { pwd = get_pwd(), action = "buffs", bro = "1" })
			async_get_page("/pandamonium.php")
			refresh_quest()
			did_action = not quest("Trial By Friar") and quest_text("this is Azazel in Hell")
		end
		return result, resulturl, did_action
	end

	function f.unlock_manor()
		local townright = get_page("/town_right.php")
		if townright:match("The Haunted Pantry") then
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
				async_get_page("/manor.php", { place = "stairs" }) -- breaking chairs so they reflect state
				did_action = true
			else
				if have("pool cue") and have("handful of hand chalk") and not buff("Chalky Hand") then
					use_item("handful of hand chalk") -- TODO: ensure_buffs
				end
-- 					TODO: act differently if you can't easily win with just autoattack?
				script.bonus_target { "noncombat" }
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
		-- do meatcar/beach/shore
		local dapt = get_page("/da.php")
		if dapt:contains("The Enormous Greater-Than Sign") then
			if advs() < 20 then
				stop "Fewer than 20 advs for > sign"
			elseif meat() < 1000 then
				stop "Need 1k meat for > sign"
			elseif have("plus sign") and buff("Teleportitis") then
				fam "Frumious Bandersnatch"
				ensure_buffs { "Ode to Booze" }
				stop "TODO: find oracle, then do DD to wear off teleportitis"
			else
				go("unlock dod", 226, macro_noodlecannon, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic" }, "Slimeling", 25, { choice_function = function(advtitle, choicenum)
					if advtitle == "Typographical Clutter" then
						if not have("plus sign") then
							return "The big apostrophe"
						else
							return "The upper-case Q"
						end
					end
				end })
			end
		else
			if have("dead mimic") then
				set_result(use_item("dead mimic"))
				did_action = have("pine wand") or have("ebony wand") or have("hexagonal wand") or have("aluminum wand") or have("marble wand")
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

	-- TODO: merge with unlock_hits
	function f.do_castle()
		stop "TODO: Do new castle"
		-- TODO: buff +item% more?
		script.bonus_target { "noncombat", "item" }
		go("do castle in the sky", 82, macro_noodleserpent, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Butt-Rock Hair" }, "Slimeling", 50, { choice_function = function(advtitle, choicenum)
			if advtitle == "Wheel in the Clouds in the Sky, Keep On Turning" then
				if choicenum == 9 and get_mainstat() ~= "Mysticality" then
					return "Turn the wheel counterclockwise"
				elseif choicenum == 12 then
					return "Turn the wheel counterclockwise"
				elseif choicenum == 11 then
					return "Leave the wheel alone"
				elseif choicenum == 9 and get_mainstat() == "Mysticality" then
					return "Turn the wheel clockwise"
				elseif choicenum == 10 then
					return "Turn the wheel clockwise"
				end
			end
		end})
	end

	function f.unlock_hits()
		stop "TODO: Do new hole in the sky unlock"
		result, resulturl = use_item("giant castle map")()
		if have("quantum egg") then
			inform "make rowboat"
			meatpaste_items("S.O.C.K.", "quantum egg")
			did_action = have("intragalactic rowboat")
		elseif get_result():contains("have to figure out some way to get the guard away from the door") then
			script.bonus_target { "noncombat", "item" }
			go("unlock hits", 82, macro_noodleserpent, {}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Garlic", "Butt-Rock Hair" }, "Slimeling", 40, { choice_function = function(advtitle, choicenum)
				if advtitle == "Wheel in the Clouds in the Sky, Keep On Turning" then
					if choicenum == 9 and get_mainstat() ~= "Mysticality" then
						return "Turn the wheel counterclockwise"
					elseif choicenum == 12 then
						return "Turn the wheel counterclockwise"
					elseif choicenum == 11 then
					elseif choicenum == 9 and get_mainstat() == "Mysticality" then
						return "Turn the wheel clockwise"
					elseif choicenum == 10 then
						return "Turn the wheel clockwise"
					end
				end
			end})
		end
	end

	function f.find_black_market()
		use_dancecard()
		local have_blackbird_parts = (have("broken wings") and have("sunken eyes")) or have("reassembled blackbird")
		if have("black market map") and ((challenge ~= "boris" and challenge ~= "jarlsberg") or have_blackbird_parts) then
			inform "locate black market"
			meatpaste_items("broken wings", "sunken eyes")
			fam "Reassembled Blackbird"
			set_result(use_item("black market map"))
			did_action = not have("black market map")
		else
			if have_blackbird_parts then
				script.bonus_target { "noncombat" }
			else
				script.bonus_target { "item" }
			end
			go("do black forest", 111, macro_noodleserpent, nil, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling", 45)
		end
	end

	function f.get_macguffin_diary()
		inform "shore for macguffin diary"
		if not have("forged identification documents") then
			if challenge == "fist" then
				maybe_ensure_buffs_in_fist { "Astral Shell", "Ghostly Shell", "Empathy" }
				local towear = {}
				local famt = fam "Slimeling"
				local fammpregen, famequip = famt.mpregen, famt.familiarequip
				if famequip and have(famequip) then
					towear.familiarequip = famequip
				end
				wear(towear)
				if buff("Astral Shell") and have_skill("Drunken Baby Style") and drunkenness() >= 8 then
					inform "fighting wu tang the betrayer"
					use_hottub()
					ensure_mp(50)
					local pt, url = get_page("/woods.php", { action = "fightbmguy" })
					result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_fist())
					did_action = (advagain and have("forged identification documents"))
				else
					stop "TODO: Get identification documents in fist"
				end
			else
				buy_item("forged identification documents", "l")
				if not have("forged identification documents") then
					critical "Failed to buy identification documents"
				end
			end
		end
		if have("forged identification documents") and not have("your father's MacGuffin diary") then
			result, resulturl = post_page("/shore.php", { pwd = get_pwd(), whichtrip = "3" })
		end
		if have("your father's MacGuffin diary") then
			result, resulturl = get_page("/diary.php", { whichpage = "1" })
			did_action = true
		end
	end

	function f.do_oasis_and_desert()
		if have("worm-riding hooks") and have("drum machine") then
			inform "using drum machine"
			set_result(use_item("drum machine"))
			did_action = not have("worm-riding hooks")
		elseif quest_text("got your walking shoes on") then
			go("unlock oasis", 121, macro_noodleserpent, {
				["Let's Make a Deal!"] = "Haggle for a better price",
			}, { "Spirit of Bacon Grease" }, "Mini-Hipster", 45)
			if get_result():contains("find yourself near an oasis") then
				use_hottub()
				did_action = true
			end
		elseif not buff("Ultrahydrated") then
			inform "getting ultrahydrated"
			if not have("ten-leaf clover") then
				use_item("disassembled clover")
			end
			if have("ten-leaf clover") or challenge == "fist" then
				result, resulturl, advagain = autoadventure { zoneid = 122, ignorewarnings = true }
				if buff("Ultrahydrated") or get_result():contains("You acquire an item") then
					did_action = advagain
				end
			else
				f.trade_for_clover()
				if have("ten-leaf clover") or have("disassembled clover") then
					did_action = true
				else
					stop "No clover for ultrahydrated"
				end
			end
		elseif quest_text("managed to stumble upon a hidden oasis") then
			go("find gnasir", 123, macro_noodleserpent, nil, { "Spirit of Bacon Grease" }, "Mini-Hipster", 60)
		elseif quest_text("tasked you with finding a stone rose") then
			script.bonus_target { "item" }
			if not (have("stone rose") and have("drum machine")) then
				if have("stone rose") and ascensionstatus() ~= "Hardcore" then
					pull_in_softcore("drum machine")
				end
				script.bonus_target { "item" }
				go("get stone rose + drum machine", 122, macro_noodleserpent, nil, { "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling", 60)
			elseif not have("can of black paint") then
				inform "buying can of black paint"
				buy_item("can of black paint", "l")
				did_action = have("can of black paint")
			else
				go("return stone rose", 123, macro_noodleserpent, nil, { "Spirit of Bacon Grease" }, "Mini-Hipster", 60)
			end
		elseif quest_text("that's probably long enough") then
			go("return to gnasir after waiting", 123, macro_noodleserpent, nil, { "Spirit of Bacon Grease" }, "Mini-Hipster", 60)
		elseif quest_text("find fifteen missing pages") or quest_text("fourteen to go") or quest_text("thirteen to go") then
			script.bonus_target { "item" }
			go("find missing pages", 122, macro_noodleserpent, nil, { "Spirit of Bacon Grease" }, "Mini-Hipster", 60)
		elseif quest_text("Time to take them back") then
			go("return pages to gnasir", 123, macro_noodleserpent, nil, { "Spirit of Bacon Grease" }, "Mini-Hipster", 60)
		end
	end

	function f.do_never_odd_or_even_quest()
		if not have("Talisman o' Nam") then
			if not have("pirate fledges") then
				if have("ball polish") then
					use_item("ball polish")
				end
				if have("mizzenmast mop") then
					use_item("mizzenmast mop")
				end
				if have("rigging shampoo") then
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
					-- TODO: set sail in HCNP? OK to be low on meat if we've done it already
					-- choice	O Cap'm, My Cap'm	189
					-- opt	1	Front the meat and take the wheel
					-- opt	2	Step away from the helm
					-- posting page /choice.php params: Just [("pwd","78c111d81e1e56105e9a2c33124f31f9"),("whichchoice","189"),("option","1")]
					-- got uri: /ocean.php | ?intro=1 (from /choice.php), size 2100
					-- posting page /ocean.php params: Just [("lon","22"),("lat","62")]
					-- got uri: /ocean.php |  (from /ocean.php), size 2741
					script.bonus_target { "noncombat" }
					go("do poop deck", 159, macro_noodlecannon, { ["O Cap'm, My Cap'm"] = "Step away from the helm" }, { "Butt-Rock Hair", "Smooth Movements", "The Sonata of Sneakiness", "Spirit of Bacon Grease" }, "Rogue Program", 35, { equipment = { acc3 = "pirate fledges" } })
					if get_result():contains("It's Always Swordfish") then
						did_action = true
					end
				elseif count("snakehead charrrm") >= 2 then
					inform "pasting talisman"
					meatpaste_items("snakehead charrrm", "snakehead charrrm")
					did_action = have("Talisman o' Nam")
				elseif have("gaudy key") then
					inform "using gaudy key"
					local charms = count("snakehead charrrm")
					set_result(use_item("gaudy key"))
					did_action = (count("snakehead charrrm") > charms)
				else
					if have("Rain-Doh box full of monster") then
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
			if have("Mega Gem") then
				go("fight dr awkward", 119, macro_noodleserpent, { ["Dr. Awkward"] = "War, sir, is raw!" }, { "A Few Extra Pounds", "Spirit of Garlic" }, "Knob Goblin Organ Grinder", 60, { equipment = { acc3 = "Mega Gem", acc2 = "Talisman o' Nam" } })
			elseif quest_text("wants some wet stew in return") then
				if have("wet stunt nut stew") then
					inform "getting mega gem"
					result, resulturl, advagain = autoadventure { zoneid = 50 }
					did_action = have("Mega Gem")
				elseif have("wet stew") then
					inform "cooking wet stunt nut stew"
					cook_items("wet stew", "stunt nuts")
					did_action = have("wet stunt nut stew")
				elseif not have("wet stew") and ascensionstatus() ~= "Hardcore" then
					pull_in_softcore("wet stew")
					did_action = true
				elseif have("bird rib") and have("lion oil") then
					inform "cooking wet stew"
					cook_items("bird rib", "lion oil")
					did_action = have("wet stew")
				else
					maybe_ensure_buffs { "Brother Flying Burrito's Blessing" }
					script.bonus_target { "item" }
					go("get wet stew ingredients", 100, macro_autoattack, {
						["The Only Thing About Him is the Way That He Walks"] = "Show him some moves",
						["Rapido!"] = "Steer for the cave",
						["Don't Fence Me In"] = "Jump the fence",
					}, { "Musk of the Moose", "Carlweather's Cantata of Confrontation", "Fat Leon's Phat Loot Lyric", "Heavy Petting", "Peeled Eyeballs", "Leash of Linguini", "Empathy" }, "Jumpsuited Hound Dog", 20, { equipment = { familiarequip = "sugar shield" } })
					if get_result():contains("It's A Sign!") then
						did_action = true
					end
				end
			elseif quest_text("track down this Mr. Alarm guy") and not have("stunt nuts") and not have("wet stunt nut stew") and ascensionstatus() ~= "Hardcore" then
				pull_in_softcore("stunt nuts")
				did_action = have_item("stunt nuts")
			elseif quest_text("track down this Mr. Alarm guy") and not have("wet stew") and not have("wet stunt nut stew") and ascensionstatus() ~= "Hardcore" then
				pull_in_softcore("wet stew")
				did_action = have_item("wet stew")
			elseif quest_text("track down this Mr. Alarm guy") and have("stunt nuts") then
				if have("wet stew") then
					inform "cooking wet stunt nut stew"
					cook_items("wet stew", "stunt nuts")
					did_action = have("wet stunt nut stew")
				else
					script.bonus_target { "noncombat" }
					go("track down mr. alarm", 50, macro_stasis, {
						["Mr. Alarm, I Presarm"] = "Talk to him",
					}, { "Smooth Movements", "The Sonata of Sneakiness" }, "Mini-Hipster", 15)
				end
			else
				-- WORKAROUND: doesn't appear until plains is loaded
				if not have_equipped("Talisman o' Nam") then
					print("must equip talisman")
					wear { acc3 = "Talisman o' Nam" }
					async_get_page("/plains.php")
				end
-- 				use_dancecard()
				if meat() < 500 and not (have("photograph of God") and have("hard rock candy")) and not have("&quot;I Love Me, Vol. I&quot;") then
					stop "Not enough meat for palindome"
				end
				script.bonus_target { "item" }
				if ascensionstatus() ~= "Hardcore" and have("photograph of God") and have("hard rock candy") and have("hard-boiled ostrich egg") and not have("ketchup hound") then
					pull_in_softcore("ketchup hound")
				end
				go("do palindome", 119, macro_noodleserpent, {
					["No sir, away!  A papaya war is on!"] = "Give the men a pep talk",
					["Sun at Noon, Tan Us"] = "A little while",
					["Rod Nevada, Vendor"] = "Accept (500 Meat)",
					["Do Geese See God?"] = "Buy the photograph (500 meat)",
					["A Pre-War Dresser Drawer, Pa!"] = "Ignawer the drawer",
				}, { "Smooth Movements", "The Sonata of Sneakiness", "Fat Leon's Phat Loot Lyric", "Spirit of Bacon Grease" }, "Slimeling", 40, { equipment = { acc3 = "Talisman o' Nam" } })
				if get_result():contains("Drawn Onward") and resulturl:contains("palinshelves") then
					set_result(async_post_page("/palinshelves.php", { action = "placeitems", whichitem1 = get_itemid("photograph of God"), whichitem2 = get_itemid("hard rock candy"), whichitem3 = get_itemid("ketchup hound"), whichitem4 = get_itemid("hard-boiled ostrich egg") }))
					if have("&quot;I Love Me, Vol. I&quot;") then
						use_hottub()
						did_action = true
					end
				end
			end
		end
	end

	function f.do_orc_chasm()
		local can_make_64735_scroll = (count("334 scroll") >= 2 or have("668 scroll")) and (have("64067 scroll") or (have("30669 scroll") and have("33398 scroll")))
		if have("64735 scroll") then
			inform "using scroll"
			set_result(use_item("64735 scroll"))
			did_action = have("facsimile dictionary")
		elseif quest_text("You must find your way past the Orc Chasm") then
			inform "unlock baron's valley"
			result, resulturl = post_page("/forestvillage.php", { pwd = get_pwd(), action = "untinker", whichitem = get_itemid("abridged dictionary") })
			result, resulturl = get_page("/mountains.php", { pwd = get_pwd(), orcs = 1 })
			refresh_quest()
			did_action = not quest_text("You must find your way past the Orc Chasm")
		elseif have("Wand of Nagamar") and can_make_64735_scroll then
			if f.get_photocopied_monster() ~= "rampaging adding machine" then
				inform "get adding machine from faxbot"
				f.get_faxbot_fax("rampaging adding machine", "adding_machine")
			else
				inform "fight adding machine"
				f.heal_up()
				f.ensure_mp(30)
				wear {}
				fam "Llama Lama"
				local pt, url = use_item("photocopied monster")()
				pt, url = get_page("/fight.php")
				result, resulturl, advagain = handle_adventure_result(pt, url, "?", macro_orc_chasm())
				did_action = (advagain and have("64735 scroll"))
				-- TODO: print error if unsuccessful
			end
		elseif have("lowercase N") then
			if not have("ruby W") then stop "Missing ruby W" end
			if not have("metallic A") then stop "Missing metallic A" end
			if not have("lowercase N") then stop "Missing lowercase N" end
			if not have("heavy D") then stop "Missing heavy D" end
			inform "meatpasting wand"
			meatpaste_items("ruby W", "metallic A")
			meatpaste_items("lowercase N", "heavy D")
			meatpaste_items("WA", "ND")
			did_action = have("Wand of Nagamar")
--		elseif count("334 scroll") >= 2 and have("30669 scroll") and have("33398 scroll") then
--			script.bonus_target { "item" }
--			go("doing orc chasm", 80, macro_orc_chasm, {}, { "Spirit of Bacon Grease", "Heavy Petting", "Leash of Linguini", "Empathy", "Ur-Kel's Aria of Annoyance" }, "Jumpsuited Hound Dog", 50, { equipment = { familiarequip = "sugar shield" }, olfact = "XXX pr0n" })
		else
			script.bonus_target { "item" }
			go("getting scrolls in the orc chasm", 80, macro_orc_chasm, {}, { "Spirit of Bacon Grease", "Heavy Petting", "Leash of Linguini", "Empathy", "Ur-Kel's Aria of Annoyance" }, "Jumpsuited Hound Dog", 50, { equipment = { familiarequip = "sugar shield" }, olfact = "XXX pr0n" })
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

	function f.get_faxbot_fax(target, code)
		if playername():contains("Devster") then
			stop("Devster faxbot:" .. target)
		end
		print("  photocopied:", f.get_photocopied_monster(), "getting", target, code)
		try_getting_faxbot_monster(target, code)
		try_getting_faxbot_monster(target, code)
		try_getting_faxbot_monster(target, code)
		if f.get_photocopied_monster() == target then
			did_action = true
		else
			stop("Didn't get "..target.." from faxbot")
		end
	end

	-- TODO: 1 more with bander if possible
	function f.spooky_forest_runaways()
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
			if have("sugar shield") then
				weareq = { familiarequip = "sugar shield" }
				wear(weareq)
			end
			ensure_buffs { "Heavy Petting" }
		end
-- 		print("weareq:", table_to_str(weareq))
		if buffedfamiliarweight() >= (1 + get_daily_counter("familiar.free butt runaways")) * 5 then
			-- TODO: copy-pasted, merge this
			if have("Spooky Temple map") and have("Spooky-Gro fertilizer") and have("spooky sapling") then
				inform "use spooky temple map"
				set_result(use_item("Spooky Temple map"))
				local newwoodspt = get_page("/woods.php")
				did_action = newwoodspt:contains("The Hidden Temple")
			else
				if meat() < 100 and have("Spooky Temple map") and have("Spooky-Gro fertilizer") then
					stop "Not enough meat for spooky sapling"
				end
				script.bonus_target { "noncombat" }
				go("runaways to unlock hidden temple, " .. buffedfamiliarweight() .. " lb, already done " .. get_daily_counter("familiar.free butt runaways") .. " runaways", 15, macro_spooky_forest_runaway, {}, { "Smooth Movements", "The Sonata of Sneakiness" }, "Pair of Stomping Boots", 10, { choice_function = function(advtitle, choicenum)
					if advtitle == "Arboreal Respite" then
						if not have("Spooky Temple map") then
							if not have("tree-holed coin") then
								return "Explore the stream"
							else
								return "Brave the dark thicket"
							end
						elseif not have("Spooky-Gro fertilizer") then
							return "Brave the dark thicket"
						elseif not have("spooky sapling") then
							return "Follow the old road"
						end
					elseif advtitle == "Consciousness of a Stream" then
						if not have("Spooky Temple map") and not have("tree-holed coin") then
							inform "get coin"
							return "Squeeze into the cave"
						end
					elseif advtitle == "Through Thicket and Thinnet" then
						if not have("Spooky Temple map") then
							return "Follow the coin"
						elseif not have("Spooky-Gro fertilizer") then
							inform "get fertilizer"
							return "Investigate the dense foliage"
						end
					elseif advtitle == "O Lith, Mon" then
						inform "get map"
						return "Insert coin to continue"
					elseif advtitle == "The Road Less Traveled" then
						if not have("spooky sapling") then
							return "Talk to the hunter"
						end
					elseif advtitle == "Tree's Last Stand" then
						if not have("spooky sapling") then
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
				if not did_action and have("spooky sapling") and get_result():contains("Results:") then
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

	function f.do_daily_dungeon()
		result, resulturl = get_page("/dungeon.php")
		local roomnumber, roomtitle = get_result():match("<b>Room ([0-9]*): (.-)</b>")
		roomnumber = tonumber(roomnumber)
		if not roomtitle then
			if get_result():contains("You have reached the bottom of today's Dungeon.") and not cached_stuff.completed_daily_dungeon then
				cached_stuff.completed_daily_dungeon = true
				did_action = true
				return
			else
				critical "Error doing DD, unknown room"
			end
		end
		local rooms = {}

		local function stat_test(statname, amount)
			return function()
				local stats = {
					Muscle = { f = buffedmuscle, buff = "Power Ballad of the Arrowsmith" },
					Mysticality = { f = buffedmysticality, buff = "The Magical Mojomuscular Melody" },
					Moxie = { f = buffedmoxie, buff = "The Moxious Madrigal" },
				}
				if stats[statname].f() >= amount then return true end
				ensure_buffs { stats[statname].buff }
				maybe_ensure_buffs_in_fist { stats[statname].buff }
				if stats[statname].f() >= amount then return true end
				return false, "Too low " .. statname .. " (need " .. amount .. ")"
			end
		end

		rooms["The Biggest Bathtub Ever"] = stat_test("Muscle", 31)
		rooms["Magic Shell"] = stat_test("Mysticality", 31)
		rooms["Dungeon Fever"] = stat_test("Moxie", 31)

		rooms["Yet Another Troll"] = stat_test("Muscle", 42)
		rooms["The Mystic Seal"] = stat_test("Mysticality", 42)
		rooms["Badger Badger Badger Badger"] = stat_test("Moxie", 42)

		rooms["Piledriver"] = stat_test("Muscle", 49)
		rooms["A Hairier Barrier"] = stat_test("Mysticality", 49)
		rooms["Smooth Criminal"] = stat_test("Moxie", 49)

		local function resist_test(element)
			return function()
				if get_page("/charsheet.php"):contains([[<td align=right>]]..element..[[ Protection:</td>]]) then return true end
				f.want_familiar "Exotic Parrot"
				ensure_buffs { "Astral Shell", "Leash of Linguini", "Empathy" }
				maybe_ensure_buffs_in_fist { "Astral Shell" }
				if get_page("/charsheet.php"):contains([[<td align=right>]]..element..[[ Protection:</td>]]) then return true end
				return false, "No " .. element .. " Protection"
			end
		end

		rooms["Blister in the Sun"] = resist_test("Hot")
		rooms["Did I Leave the Floor On?"] = resist_test("Hot")

		rooms["Brrrrrr."] = resist_test("Cold")
		rooms["You'll Put Your Eye Out"] = resist_test("Cold")

		rooms["Giant Creepy Floating Skull"] = resist_test("Spooky")
		rooms["The Night Gallery"] = resist_test("Spooky")

		rooms["Sewage Moat"] = resist_test("Stench")
		rooms["The Warehouse of Eternal Stench"] = resist_test("Stench")

		rooms["Seriously, I Just Read It For the Articles"] = resist_test("Sleaze")
		rooms["You Schmooze, You Lose"] = resist_test("Sleaze")

		local function choose_option(num)
			-- TODO: Do by button label, not number?
			result, resulturl = post_page("/dungeon.php", { pwd = get_pwd(), action = "Yep", option = num })
			local pt, pturl = get_page("/dungeon.php")
			did_action = (tonumber(pt:match("<b>Room [0-9]*: (.-)</b>")) ~= roomnumber)
		end

		if rooms[roomtitle] then
			local ok, msg = rooms[roomtitle]()
			if ok then
				inform("doing DD: " .. roomtitle)
				choose_option(1)
			else
				stop("TODO in DD: " .. msg)
			end
		elseif roomtitle == "Treasure!" and (roomnumber == 3 or roomnumber == 6) then
			inform("skipping DD room: " .. roomtitle)
			choose_option(2)
		elseif roomtitle == "Monster!" then
			inform "fight DD monster"
			f.heal_up()
			f.want_familiar "Stocking Mimic"
			f.wear {}
			f.ensure_mp(5)
			local pt, pturl = post_page("/dungeon.php", { pwd = get_pwd(), action = "Yep", option = num })
			local pt, url = get_page("/fight.php")
			result, resulturl, did_action = handle_adventure_result(pt, url, "?", macro_stasis())
		elseif roomtitle == "Locked Door" then
			if count("skeleton key") >= 2 then
				inform("skipping DD room: " .. roomtitle)
				choose_option(2)
			else
				if buffedmainstat() >= 52 and resist_test("Stench") then
					inform("forcing open DD door: " .. roomtitle)
					choose_option(1)
				else
					stop "TODO: Not enough skeleton keys for DD, unable to safely force door open."
				end
			end
		elseif roomtitle == "Treasure!" and roomnumber == 10 then
			local tokens = count("fat loot token")
			inform("getting fat loot token: " .. roomtitle)
			choose_option(1)
			did_action = (count("fat loot token") == tokens + 1)
		else
			critical([[TODO: Unknown DD room type: "]] .. roomtitle .. [[", room number: ]] .. tostring(roomnumber))
		end
	end

	return f
end
