function setup_functions()
	local cached_api_item_data = {}
	local function setup_functions_raw()
		local function_debug_output_enabled = false
		local debug_infoline = function() end
		function print_debug(...)
			if function_debug_output_enabled then
				debug_infoline(...)
			end
		end
		function enable_function_debug_output(newstate, f)
			if newstate == nil then
				newstate = true
			end
			function_debug_output_enabled = newstate
			debug_infoline = f
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
			for _, x in pairs(status().effects) do
				tbl[x[1]] = tonumber(x[2])
			end
			return tbl
		end

		function intrinsicslist()
			local tbl = {}
			for _, x in pairs(status().intrinsics) do
				tbl[x[1]] = "&infin;"
			end
			return tbl
		end

		local player_classid_names = {
			"Seal Clubber", -- 1
			"Turtle Tamer", -- 2
			"Pastamancer", -- 3
			"Sauceror", -- 4
			"Disco Bandit", -- 5
			"Accordion Thief", -- 6
			nil, nil, nil, nil, -- 7, 8, 9, 10
			"Avatar of Boris", -- 11
			"Zombie Master", -- 12
			nil, -- 13
			"Avatar of Jarlsberg", -- 14
			"Avatar of Sneaky Pete", -- 15
			nil, -- 16
			"Ed", -- 17
		}
		function classid() return tonumber(status().class) end
		function maybe_playerclassname()
			return player_classid_names[classid()]
		end
		function playerclass(check)
			for i = 1, 100 do
				if check == player_classid_names[i] then
					return classid() == i
				end
			end
			error("Unknown playerclass: " .. tostring(check))
		end

		function playerid() return tonumber(status().playerid) end

		-- WARNING: Values can be out of date unless you load charpane.php. This is a KoL/CDM bug.

		function get_mainstat_type()
			-- WORKAROUND: Missing from API. Use correct values for known classes, otherwise guess that it's the highest one
			local cid = classid()
			if cid == 1 or cid == 2 or cid == 11 or cid == 12 then
				return "Muscle"
			elseif cid == 3 or cid == 4 or cid == 14 or cid == 17 then
				return "Mysticality"
			elseif cid == 5 or cid == 6 or cid == 15 then
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

		function mainstat_type(which)
			return get_mainstat_type() == which
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
		function turnsplayed() return tonumber(status().turnsplayed) end
		function familiarid() return tonumber(status().familiar) end
		function familiarpicture() return status().familiarpic end
		function familiar(name)
			return familiarid() == get_familiarid(name)
		end
		function buffedfamiliarweight() return tonumber(status().famlevel) end
		function have_buff(name)
			if not datafile("buffs")[name] then
				print("WARNING: unknown buff", name)
			end
			return buffslist()[name] ~= nil
		end
		function buff(...)
			print("WARNING: buff() is deprecated, use have_buff()")
			return have_buff(...)
		end
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
		function locked()
			if status().locked == "cancelable-choice" then
				return false
			else
				return status().locked
			end
		end
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
			return stats[get_mainstat_type()]
		end
		function basemainstat()
			local stats = {
				Muscle = basemuscle(),
				Mysticality = basemysticality(),
				Moxie = basemoxie(),
			}
			return stats[get_mainstat_type()]
		end
		function rawmainstat()
			local stats = {
				Muscle = rawmuscle(),
				Mysticality = rawmysticality(),
				Moxie = rawmoxie(),
			}
			return stats[get_mainstat_type()]
		end
		function lastadventuredata() return status().lastadv end
		function lastadventurezoneid()
			local lastadv = lastadventuredata()
			if lastadv and lastadv.link then
				return tonumber(lastadv.link:match("^adventure%.php%?snarfblat=([0-9]+)$"))
			end
		end
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
		function finished_mainquest()
			-- TODO: Should be defeated NS, not freed ralph
			if ascensionpath("Actually Ed the Undying") then
				return have_item(7965) -- Holy MacGuffin in Ed
			else
				return tonumber(status().freedralph) == 1
			end
		end
		function moonsign_area(name)
			if name then
				-- TODO: validate
				return moonsign_area() == name
			end
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
		function equipment()
			-- TODO: Whitelist equipment slots? CDM occasionally adds non-items here.
			local eq = {}
			for a, b in pairs(status().equipment) do
				eq[a] = tonumber(b)
				if eq[a] == 0 then
					eq[a] = nil -- Assume this is another unknown API misfeature. Tell CDM to stop doing this!
				end
			end
			eq.fakehands = nil -- Work around API misfeatures - these are not itemids
			eq.cardsleeve = nil
			return eq
		end
		function fullness() return tonumber(status().full) end
		function drunkenness() return tonumber(status().drunk) end
		function spleen() return tonumber(status().spleen) end
		function ascensionstatus(check)
			-- TODO: remove or change values
			if check then
				if check ~= "Aftercore" and check ~= "Hardcore" and check ~= "Softcore" and check ~= "Casual" then
					error("Invalid ascensionstatus check: " .. tostring(check))
				end
				return check == ascensionstatus()
			end
			if finished_mainquest() and not ascensionpath("Actually Ed the Undying") then
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
		function have_mall_access() return ascensionstatus("Aftercore") end
		function have_storage_access() return ascensionstatus("Aftercore") end
		function mcd() return tonumber(status().mcd) end
		function maxmcd()
			if moonsign_area("Little Canadia") then
				return 11
			else
				return 10
			end
		end
		function applied_scratchnsniff_stickers()
			local tbl = {}
			for a, b in pairs(status().stickers or {}) do
				tbl[a] = tonumber(b)
			end
			return tbl
		end
		function api_flag_config() return status().flag_config end
		function autoattack_is_set() return tonumber(status().flag_config.autoattack) ~= 0 end
		function pastathrallid() return tonumber(status().pastathrall) or 0 end
		function pastathralllevel() return tonumber(status().pastathralllevel) or 0 end
		function fury() return tonumber(status().fury) or 0 end
		function soulsauce() return tonumber(status().soulsauce) or 0 end
		function pvpfights() return tonumber(status().pvpfights) or 0 end

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
		function have_inventory(...)
			print("WARNING: have_inventory() is deprecated, use have_inventory_item()")
			return have_inventory_item(...)
		end

		function have_equipped_item(name)
			return get_cached_equip_counts()[get_itemid(name)] ~= nil
		end
		function have_equipped(...)
			print("WARNING: have_equipped() is deprecated, use have_equipped_item()")
			return have_equipped_item(...)
		end

		function count_equipped_item(name)
			return get_cached_equip_counts()[get_itemid(name)] or 0
		end
		function count_equipped(...)
			print("WARNING: count_equipped() is deprecated, use count_equipped_item()")
			return count_equipped_item(...)
		end

		function have_item(name)
			if have_inventory_item(name) then
				return true
			else
				return have_equipped_item(name)
			end
		end
		function have(...)
			print("WARNING: have() is deprecated, use have_item()")
			return have_item(...)
		end

		function count_inventory_item(name)
			return inventory()[get_itemid(name)] or 0
		end
		function count_inventory(...)
			print("WARNING: count_inventory() is deprecated, use count_inventory_item()")
			return count_inventory_item(...)
		end

		function count_item(name)
			return count_inventory_item(name) + count_equipped_item(name)
		end
		function count(...)
			print("WARNING: count() is deprecated, use count_item()")
			return count_item(...)
		end

		function clancy_level() return tonumber(status().clancy_level) end
		function clancy_instrumentid() return tonumber(status().clancy_instrument) end -- TODO: check
		function clancy_wantsattention() return status().clancy_wantsattention end

		function horde_size() return tonumber(status().horde) end
		function petelove() return tonumber(status().petelove) or 0 end -- Not automatically up-to-date
		function petehate() return tonumber(status().petehate) or 0 end

		function heavyrains_thunder() return tonumber(status().thunder) end
		function heavyrains_rain() return tonumber(status().rain) end
		function heavyrains_lightning() return tonumber(status().lightning) end

		function raw_retrieve_skills()
			if locked() then
				--print("WARNING: raw_retrieve_skills() called while locked ("..tostring(locked())..")")
				return nil
			else
				--print "INFO: raw_retrieve_skills() called"
			end

			if session["holiday: feast of boris"] == "yes" then
				async_get_page("/main.php")
			end

			local cs = get_page("/charsheet.php")
			local skills_text = cs:match("<p>Skills:</b>.-(<a onClick.-)</td>")
			if not skills_text then
				--print "WARNING: raw_retrieve_skills() with invalid page"
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
				return session["cached player skills.ascensionpathid"]
			end)
		end

		function state_identifier()
			return current_ascension_number() .. "/" .. ascensionpathid() .. "/" .. ascensionstatus()
		end

		function get_player_skills()
			return get_cached_item("cached_get_player_skills", function()
				local cached_skills = session["cached player skills"]
				local cached_skills_storedid = session["cached player skills.storedid"]
				if cached_skills_storedid ~= state_identifier() then
					if kolproxycore_async_submit_page and not cannot_set_state and not locked() then
						local skills = raw_retrieve_skills()
						if skills then
							cached_skills = skills
							session["cached player skills"] = skills
							session["cached player skills.storedid"] = state_identifier()
						end
					end
				end
				return cached_skills
			end)
		end
		function clear_cached_skills()
			session["cached player skills.storedid"] = nil
		end
		function have_skill(name)
			if not name or name == "" then
				error("Invalid name for have_skill: " .. tostring(name))
			end
			local skills = get_player_skills()
			local result
			if skills then
				result = skills[name] ~= nil
				if name == "Torso Awaregness" and not result then
					-- Hack to implement Best Dressed to count as Torso the way the game does
					result = skills["Best Dressed"] ~= nil
				end
			end
			return result
		end
	end

	local s_f_env = {}
--	s_f_env._G = s_f_env
	s_f_env._G_envname = "api s_f_env"
	setmetatable(s_f_env, { __index = _G, __newindex = _G })
	setfenv(setup_functions_raw, s_f_env)
	setup_functions_raw()
	setmetatable(s_f_env, { __index = _G,
	__newindex = function(t, k, v)
		print("warning: s_f_env __newindex", t, k, v)
		rawset(t, k, v)
	end })
end
