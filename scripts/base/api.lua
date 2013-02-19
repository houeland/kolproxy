function setup_functions()
	local cached_api_item_data = {}
	local function setup_functions_raw()
		local function_debug_output_enabled = false
		function print_debug(...)
			if function_debug_output_enabled then
				print(...)
			end
		end
		function enable_function_debug_output(newstate)
			if newstate == nil then
				newstate = true
			end
			function_debug_output_enabled = newstate
		end

		function status()
			return get_cached_function(get_status_info)
		end
		function inventory()
			return get_cached_function(get_inventory_counts)
		end
		function preload_item_api_data(name)
			local itemid = get_itemid(name)
			local v = cached_api_item_data[itemid]
			if not v then
				v = get_api_itemid_info(itemid)
				cached_api_item_data[itemid] = v
			end
			return v
		end
		function item_api_data(name)
			local v = preload_item_api_data(name)
			if type(v) ~= "table" then
				v = v()
				cached_api_item_data[get_itemid(name)] = v
			end
			return v
		end

		function buffslist()
			local tbl = {}
			for x in table.values(status().effects) do
				tbl[x[1]] = tonumber(x[2])
			end
			return tbl
		end

		function intrinsicslist()
			local tbl = {}
			for x in table.values(status().intrinsics) do
				tbl[x[1]] = "&infin;"
			end
			return tbl
		end

		function classid() return tonumber(status().class) end

		function playerid() return tonumber(status().playerid) end

		-- WARNING: Values can be out of date unless you load charpane.php. This is a KoL/CDM bug.

		function get_mainstat()
			-- WORKAROUND: Missing from API. Use correct values for known classes, otherwise guess that it's the highest one
			local cid = classid()
			if cid == 1 or cid == 2 or cid == 11 or cid == 12 then
				return "Muscle"
			elseif cid == 3 or cid == 4 then
				return "Mysticality"
			elseif cid == 5 or cid == 6 then
				return "Moxie"
			else
				local tbl = {
					{ "Muscle", rawmuscle() },
					{ "Mysticality", rawmysticality() },
					{ "Moxie", rawmoxie() },
				}
				table.sort(tbl, function(a, b) return a[2] > b[2] end)
				return tbl[1][1]
			end
		end

-- 		function level() return tonumber(status().level) end -- doesn't update when it should and was also just bugged before, KoL/CDM bug
		function level()
			-- WORKAROUND: The level/title fields in API just don't update correctly
			if basemainstat() < 4 then
				return 1
			else
				return 1 + math.floor(math.sqrt(basemainstat() - 4))
			end
		end

		function playername() return status().name end
		function ascensions_count() return tonumber(status().ascensions) end
		function current_ascension_number() return ascensions_count() + 1 end
		function daysthisrun() return tonumber(status().daysthisrun) end
		function meat() return tonumber(status().meat) end
		function maxhp() return tonumber(status().maxhp) end
		function maxmp() return tonumber(status().maxmp) end
		-- WORKAROUND: Serverside API bug, returned HP/MP can be larger than MaxHP/MaxMP
		function hp() return math.min(tonumber(status().hp), maxhp()) end
		function mp() return math.min(tonumber(status().mp), maxmp()) end
		function turnsthisrun() return tonumber(status().turnsthisrun) end
		function familiarid() return tonumber(status().familiar) end
		function familiarpicture() return status().familiarpic end
		function buffedfamiliarweight() return tonumber(status().famlevel) end
		function have_buff(name)
			if not datafile("buffs")[name] then
				print("WARNING: unknown buff", name)
			end
			return buffslist()[name] ~= nil
		end
		buff = have_buff
		function buffturns(name) return buffslist()[name] or 0 end
		function have_intrinsic(name) return intrinsicslist()[name] ~= nil end
		function adventures() return tonumber(status().adventures) end
		advs = adventures
		function buffedmuscle() return tonumber(status().muscle) end
		function buffedmysticality() return tonumber(status().mysticality) end
		function buffedmoxie() return tonumber(status().moxie) end
-- 		function basemuscle() return tonumber(status().basemuscle) end -- WORKAROUND: doesn't update correctly in API
-- 		function basemysticality() return tonumber(status().basemysticality) end -- WORKAROUND: doesn't update correctly in API
-- 		function basemoxie() return tonumber(status().basemoxie) end -- WORKAROUND: doesn't update correctly in API
		function rawmuscle() return tonumber(status().rawmuscle) end
		function rawmysticality() return tonumber(status().rawmysticality) end
		function rawmoxie() return tonumber(status().rawmoxie) end
		function locked() return status().locked end
		function basemuscle()
			return math.floor(math.sqrt(rawmuscle()))
		end
		function basemysticality()
			return math.floor(math.sqrt(rawmysticality()))
		end
		function basemoxie()
			return math.floor(math.sqrt(rawmoxie()))
		end
		function buffedmainstat()
			local stats = {
				Muscle = buffedmuscle(),
				Mysticality = buffedmysticality(),
				Moxie = buffedmoxie(),
			}
			return stats[get_mainstat()]
		end
		function basemainstat()
			local stats = {
				Muscle = basemuscle(),
				Mysticality = basemysticality(),
				Moxie = basemoxie(),
			}
			return stats[get_mainstat()]
		end
		function rawmainstat()
			local stats = {
				Muscle = rawmuscle(),
				Mysticality = rawmysticality(),
				Moxie = rawmoxie(),
			}
			return stats[get_mainstat()]
		end
		function lastadventuredata() return status().lastadv end
		function ascensionpathid() return tonumber(status().path) end
		function ascensionpathname() return status().pathname end
		function ascensionpath(check)
			-- TODO: validate
			return check == ascensionpathname()
		end
		function moonsign(check)
			if check then
				-- TODO: validate
				return check == moonsign()
			end
			return status().sign
		end
		function freedralph() return tonumber(status().freedralph) == 1 end
		function moonsign_area()
			local areas = {
				Mongoose = "Degrassi Knoll",
				Wallaby = "Degrassi Knoll",
				Vole = "Degrassi Knoll",
				Platypus = "Little Canadia",
				Opossum = "Little Canadia",
				Marmot = "Little Canadia",
				Wombat = "Gnomish Gnomad Camp",
				Blender = "Gnomish Gnomad Camp",
				Packrat = "Gnomish Gnomad Camp",
			}
			return areas[moonsign()]
		end
		function get_equipment()
			local eq = {}
			for a, b in pairs(status().equipment) do
				eq[a] = tonumber(b)
			end
			eq.fakehands = nil -- Work around API misfeature - this is not an itemid
			return eq
		end
		equipment = get_equipment
		function fullness() return tonumber(status().full) end
		function drunkenness() return tonumber(status().drunk) end
		function spleen() return tonumber(status().spleen) end
		function ascensionstatus(check)
			if check then
				if check ~= "Aftercore" and check ~= "Hardcore" and check ~= "Softcore" then
					error("Invalid ascensionstatus check: " .. tostring(check))
				end
				return check == ascensionstatus()
			end
			if tonumber(status().freedralph) == 1 then
				return "Aftercore"
			elseif tonumber(status().casual) == 1 then
				return "Aftercore"
			elseif tonumber(status().hardcore) == 1 then
				return "Hardcore"
			elseif tonumber(status().roninleft) > 0 then
				return "Softcore"
			else
				return "Aftercore"
			end
		end
--		function in_aftercore()
--			return ascensionstatus() == "Aftercore"
--		end
		function mcd() return tonumber(status().mcd) end
		function applied_scratchnsniff_stickers()
			local tbl = {}
			for a, b in pairs(status().stickers or {}) do
				tbl[a] = tonumber(b)
			end
			return tbl
		end
		function api_flag_config() return status().flag_config end
		function autoattack_is_set() return tonumber(status().flag_config.autoattack) ~= 0 end

		function substats_for_level(x)
			if x == 1 then
				return 9
			else
				local needstat = (x - 1) * (x - 1) + 4
				local needsubstat = needstat * needstat
				return needsubstat
			end
		end

		function level_progress()
			local basesubstat = substats_for_level(level())
			local nextsubstat = substats_for_level(level() + 1)
			local need = nextsubstat - basesubstat
			local have = rawmainstat() - basesubstat
-- 			print("progress", basesubstat, nextsubstat, need, have)
			return have / need, have, need
		end

		local function get_cached_equip_counts()
			return get_cached_item("cached_equip_counts", function()
				local tbl = {}
				for x in table.values(equipment()) do
					tbl[x] = (tbl[x] or 0) + 1
				end
				return tbl
			end)
		end

		function have_inventory_item(name)
			if inventory()[get_itemid(name)] then
				return true
			else
				return false
			end
		end
		have_inventory = have_inventory_item

		function have_equipped_item(name)
			return get_cached_equip_counts()[get_itemid(name)] ~= nil
		end
		have_equipped = have_equipped_item

		function count_equipped_item(name)
			return get_cached_equip_counts()[get_itemid(name)] or 0
		end
		count_equipped = count_equipped_item

		function have_item(name)
			if have_inventory_item(name) then
				return true
			else
				return have_equipped_item(name)
			end
		end
		have = have_item

		function count_inventory(name)
			return inventory()[get_itemid(name)] or 0
		end

		function count_item(name)
			return count_inventory(name) + count_equipped(name)
		end
		count = count_item

		function use_hottub()
			return async_get_page("/clan_viplounge.php", { action = "hottub" })
		end

		function get_wand_data()
			local wands = { "aluminum wand", "ebony wand", "hexagonal wand", "marble wand", "pine wand" }
			for _, x in ipairs(wands) do
				if have(x) then
					local itemid = get_itemid(x)
					local pt = get_page("/wand.php", { whichwand = itemid })
					if pt:contains("Zap an item") then
						if pt:contains(x) or pt:contains("Your wand ") or pt:contains("feels warm") or pt:contains("be careful") then
							return { name = x, itemid = itemid, heat = 1 }
						else
							return { name = x, itemid = itemid, heat = 0 }
						end
					end
				end
			end
			return nil
		end

		function clancy_level() return tonumber(status().clancy_level) end
		function clancy_instrumentid() return tonumber(status().clancy_instrument) end -- TODO: check
		function clancy_wantsattention() return status().clancy_wantsattention end

		function horde_size() return tonumber(status().horde) end

		function meatpaste_items(a, b) -- TODO move: This is a script function, not API related
			-- TODO: can this be done without requiring up-to-date status?
			if moonsign_area() == "Degrassi Knoll" and ascensionpathid() ~= 10 then
				return async_post_page("/knoll.php", { action = "combine", pwd = session.pwd, item1 = get_itemid(a), item2 = get_itemid(b), quantity = 1, ajax = 1 })
			else
				if not have("meat paste") then
					async_post_page("/craft.php", { pwd = session.pwd, action = "makepaste", qty = 1, ajax = 1, whichitem = get_itemid("meat paste") })
				end
				return async_post_page("/craft.php", { mode = "combine", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = 1, ajax = 1 })
			end
		end

		function cook_items(a, b)
			return async_post_page("/craft.php", { mode = "cook", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = 1, ajax = 1 })
		end

		function mix_items(a, b)
			return async_post_page("/craft.php", { mode = "cocktail", pwd = session.pwd, action = "craft", a = get_itemid(a), b = get_itemid(b), qty = 1, ajax = 1 })
		end

		function smith_items(a, b)
			return async_post_page("/knoll.php", { action = "smith", pwd = session.pwd, item1 = get_itemid(a), item2 = get_itemid(b), quantity = 1, ajax = 1 })
		end

		function buy_item(name, whichstore, amount)
			print_debug("  buying", name, amount or "")
			return async_get_page("/store.php", { phash = session.pwd, buying = 1, whichitem = get_itemid(name), howmany = amount or 1, whichstore = whichstore, ajax = 1, action = "buyitem" })
		end

		function equip_item(name, slot)
			local itemid = get_itemid(name)
			print_debug("  equipping", slot, maybe_get_itemname(itemid) or itemid)
			local tbl = { pwd = session.pwd, action = "equip", whichitem = itemid, ajax = 1 }
			if slot == "dualwield" then
				tbl.action = "dualwield"
			elseif slot == "offhand" then
				tbl.action = "dualwield"
				local f = get_page("/inv_equip.php", tbl)
				if equipment().offhand ~= itemid then
					tbl.action = "equip"
					tbl.slot = tostring(slot)
					return async_get_page("/inv_equip.php", tbl)
				else
					return f()
				end
			elseif slot == "acc1" then
				tbl.slot = "1"
			elseif slot == "acc2" then
				tbl.slot = "2"
			elseif slot == "acc3" then
				tbl.slot = "3"
			elseif slot == "familiarequip" then
				tbl.action = "hatrack"
				local f = async_get_page("/inv_equip.php", tbl)
				if equipment().familiarequip ~= itemid then
					tbl.action = "equip"
					tbl.slot = tostring(slot)
					return async_get_page("/inv_equip.php", tbl)
				else
					return f()
				end
			elseif slot then
				tbl.slot = tostring(slot)
			end
			return async_get_page("/inv_equip.php", tbl)
		end

		function unequip_slot(name)
			print_debug("  unequipping", name)
			return async_get_page("/inv_equip.php", { pwd = session.pwd, action = "unequip", type = name, ajax = "1" })
		end

		function set_mcd(amount) -- TODO move: This is a script function, not API-related
			if have_item("detuned radio") then
				return async_get_page("/inv_use.php", { pwd = session.pwd, whichitem = get_itemid("detuned radio"), ajax = 1, tuneradio = amount })
			elseif moonsign_area() == "Little Canadia" then
				return async_get_page("/canadia.php", { pwd = session.pwd, action = "changedial", whichlevel = amount })
			elseif moonsign_area() == "Gnomish Gnomad Camp" then
				return async_get_page("/gnomes.php", { pwd = session.pwd, action = "changedial", whichlevel = amount })
			end
		end

		function set_equipment(tbl)
-- 			print("setting equipment to", tbl)
			local eq = equipment()
			for a, b in pairs(eq) do
-- 				print("checking", b, "vs[", a, "]", tbl[a])
				if b ~= tbl[a] then
					unequip_slot(a)
-- 					print("unequipping slot", a)
				end
			end
			local eq = equipment()
			for a, b in pairs(tbl) do
				if eq[a] ~= b then
-- 					print("equipping", b, a)
					equip_item(b, a)
				end
			end
			local eq = equipment()
			local function getnamedesc(id)
				if tonumber(id) then
					local n = maybe_get_itemname(id)
					if n then
						return (n .. " (itemid:" .. tonumber(id) .. ")")
					else
						return ("itemid:" .. tonumber(id))
					end
				elseif id then
					return id
				else
					return "nil"
				end
			end
			for a, b in pairs(eq) do
				if b ~= tbl[a] then
					error("Wearing " .. tostring(a) .. ":" .. tostring(b) .. " after trying to wear " .. getnamedesc(tbl[a]))
				end
			end
			for a, b in pairs(tbl) do
				if eq[a] ~= b then
					error("Wearing " .. tostring(a) .. ":" .. tostring(eq[a]) .. " after trying to wear " .. getnamedesc(b))
				end
			end
		end

		function use_item(name, amount, noajax)
			print_debug("  using", name, amount or "")
			local ajax = (not noajax) and 1 or nil
			if amount then
				return async_get_page("/multiuse.php", { pwd = session.pwd, whichitem = get_itemid(name), ajax = ajax, quantity = amount, action = "useitem" })
			else
				return async_get_page("/inv_use.php", { pwd = session.pwd, whichitem = get_itemid(name), ajax = ajax })
			end
		end

		function use_item_noajax(name, amount)
			return use_item(name, amount, true)
		end

		function eat_item(name)
			print_debug("  eating", name)
			return async_get_page("/inv_eat.php", { pwd = session.pwd, which = 1, whichitem = get_itemid(name), ajax = 1 })
		end

		function drink_item(name)
			print_debug("  drinking", name)
			return async_get_page("/inv_booze.php", { pwd = session.pwd, whichitem = get_itemid(name), ajax = 1 })
		end

		function pull_storage_items(xs)
			local tbl = { pwd = session.pwd, action = "pull", ajax = 1 }
			for nr, name in pairs(xs) do
				tbl["howmany" .. tostring(nr)] = 1
				tbl["whichitem" .. tostring(nr)] = get_itemid(name)
			end
			-- TODO!: split up more than 11
			return async_post_page("/storage.php", tbl)
		end

		function freepull_item(name)
			return async_post_page("/storage.php", { action = "pull", pwd = session.pwd, howmany1 = 1, whichitem1 = get_itemid(name) })
		end

		function closet_item(name)
			return async_get_page("/inventory.php", { action = "closetpush", pwd = session.pwd, qty = 1, whichitem = get_itemid(name), ajax = 1 })
		end

		function uncloset_item(name)
			return async_get_page("/inventory.php", { action = "closetpull", pwd = session.pwd, qty = 1, whichitem = get_itemid(name), ajax = 1 })
		end
		
		function sell_item(name, amount)
			print_debug("  selling", name)
			return async_get_page("/sellstuff.php", { action = "sell", ajax = 1, type = "quant", ["whichitem[]"] = get_itemid(name), howmany = amount or 1, pwd = session.pwd })
		end

		function cast_skill(skill, quantity, targetid)
			local skillid = get_skillid(skill)
			targetid = targetid or playerid()
			assert(targetid and targetid ~= "")
			local tbl = { whichskill = skillid, ajax = 1, action = "Skillz", pwd = session.pwd, targetplayer = targetid, quantity = quantity }
			return async_get_page("/skills.php", tbl)
		end
		cast_skillid = cast_skill

		function switch_familiarid(id)
			return async_get_page("/familiar.php", { action = "newfam", ajax = 1, newfam = id })
		end

		function handle_adventure_result(pt, url, zoneid, macro, noncombatchoices, specialnoncombatfunction)
			if url:contains("/fight.php") then -- TODO: hmmmm? -- and url:match("ireallymeanit") then
				local advagain = nil
				if pt:contains([[>You win the fight!<!--WINWINWIN--><]]) then
					advagain = true
				elseif pt:contains([[state['fightover'] = true;]]) or true then -- HACK: doesn't get set with combat bar disabled
					if pt:contains("You lose.") then
						advagain = false
					elseif zoneid and pt:contains([[<a href="adventure.php?snarfblat=]]..zoneid..[[">Adventure Again]]) then
						advagain = true
					end
				end
				if advagain == nil then
					if macro then
						local pt, url = post_page("/fight.php", { action = "macro", macrotext = macro })
-- 						print("recurse with macro")
						return handle_adventure_result(pt, url, zoneid, nil, noncombatchoices, specialnoncombatfunction)
					else
						print("fight.php unhandled url", url)
					end
				end
-- 				print("return1 p u a", pt:len(), url, advagain)
				return pt, url, advagain
			elseif url:contains("/choice.php") then
				local advagain = nil
				local adventure_title
				local found_results = false
				for x in pt:gmatch([[<tr><td style="color: white;" align=center bgcolor=blue.-><b>([^<]*)</b></td></tr>]]) do
					if x == "Results:" then
						found_results = true
					else
						adventure_title = x
					end
				end
				adventure_title = (adventure_title or ""):gsub(" %(#[0-9]*%)$", "")
				if found_results and zoneid and pt:contains([[<a href="adventure.php?snarfblat=]]..zoneid..[[">Adventure Again]]) then
					advagain = true
					return pt, url, advagain
				end
				local choice_adventure_number = tonumber(pt:match([[<input type=hidden name=whichchoice value=([0-9]+)>]]))
		--~ 		print("choice", adventure_title, choice_adventure_number)
				local pickchoice = nil
				local optname = nil
				if specialnoncombatfunction then
					optname, pickchoice = specialnoncombatfunction(adventure_title, choice_adventure_number, pt)
				else
					optname = noncombatchoices[adventure_title]
				end
				if optname and not pickchoice then
					for nr, title in pt:gmatch([[<input type=hidden name=option value=([0-9])><input class=button type=submit value="([^>]+)">]]) do
			--~ 			print("opt", nr, title)
						if title == optname then
							pickchoice = tonumber(nr)
						end
					end
				end
				if optname and not pickchoice then
					print("Warning: option " .. tostring(optname) .. " not found for " .. tostring(adventure_title) .. ".")
				end
				if pickchoice then
					local pt, url = post_page("/choice.php", { pwd = session.pwd, whichchoice = choice_adventure_number, option = pickchoice })
-- 					print("choice ->", url)
					return handle_adventure_result(pt, url, zoneid, macro, noncombatchoices, specialnoncombatfunction)
				else
					print("choice", adventure_title, choice_adventure_number)
					for nr, title in pt:gmatch([[<input type=hidden name=option value=([0-9])><input class=button type=submit value="([^>]+)">]]) do
						print("opt", nr, title)
					end
-- 					print("return3 p u a", pt:len(), url, advagain)
					return pt, url, false
				end
			else
				local advagain = false
				if zoneid and pt:contains([[<a href="adventure.php?snarfblat=]]..zoneid..[[">Adventure Again]]) then
					advagain = true
-- 				else
-- 					print("non-fight non-choice unhandled url", url)
				end
-- 				print("return4 p u a", pt:len(), url, advagain)
				return pt, url, advagain
			end
		end

		function raw_retrieve_skills()
			if locked() then
				print("WARNING: raw_retrieve_skills() called while locked ("..tostring(locked())..")")
				return nil
			else
				print "INFO: raw_retrieve_skills() called"
			end

			if session["holiday: feast of boris"] == "yes" then
				async_get_page("/main.php")
			end

			local cs = get_page("/charsheet.php")
			local skills_text = cs:match("<p>Skills:</b>.-(<a onClick.-)</td>")
			if not skills_text then
				return nil
			end
			local skills = {}
			for s in skills_text:gmatch("<a onClick.->(.-)</a>") do
				skills[s] = true
			end
			return skills
		end

		function have_cached_data() -- TODO: check anything else that's cached?
			return get_cached_item("cached_get_player_skills", function()
				return session["cached player skills"]
			end)
		end

		function get_player_skills()
			return get_cached_item("cached_get_player_skills", function()
				-- TODO: Cache in a variable if merging Lua states
				local cached_skills = session["cached player skills"]
				local cached_skills_storedid = session["cached player skills.storedid"]
				local currentid = ascensionpathid() .. "/" .. ascensionstatus()
				if (not cached_skills or cached_skills_storedid ~= currentid) then
					if raw_submit_page then
						cached_skills = raw_retrieve_skills()
						session["cached player skills"] = cached_skills
						session["cached player skills.storedid"] = currentid
					else
						cached_skills = nil
					end
				end
				return cached_skills
			end)
		end
		function clear_cached_skills()
			session["cached player skills"] = nil
			session["cached player skills.ascensionpathid"] = nil
		end
		function have_skill(name)
			if not name or name == "" then
				error("Invalid name for have_skill: " .. tostring(name))
			end
			local skills = get_player_skills()
			if skills then
				return skills[name] ~= nil
			end
		end

		function retrieve_trailed_monster()
			local effectpt = get_page("/desc_effect.php", { whicheffect = "91635be2834f8a07c8ff9e3b47d2e43a" })
			local trailed = effectpt:match([[And by "wabbit" I mean "(.-)%."]])
			return trailed
		end

		function retrieve_raindoh_monster()
			local itempt = get_page("/desc_item.php", { whichitem = "965400716" })
			local copied = itempt:match([[with the soul of (.-) in it]])
			return copied
		end

	end

	local s_f_env = {}
	setmetatable(s_f_env, { __index = _G, __newindex = _G })
	setfenv(setup_functions_raw, s_f_env)
	setup_functions_raw()
	setmetatable(s_f_env, { __index = _G,
	__newindex = function(t, k, v)
		print("warning: s_f_env __newindex", t, k, v)
		rawset(t, k, v)
	end })
end
