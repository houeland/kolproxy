register_setting {
	name = "automate daily visits",
	description = "Automate daily visits (rumpus room, use daily items, etc.)",
	group = "automation",
	default_level = "standard",
}

register_setting {
	name = "automate daily visits/do lazy aftercore daily tasks",
	description = "Automate daily tasks in aftercore",
	group = "automation",
	default_level = "detailed",
}

register_setting {
	name = "automate daily visits/harvest garden",
	description = "Harvest garden as part of daily visits",
	group = "automation",
	default_level = "enthusiast",
}

function setup_automation_scan_page_results()
	local extracts = {
		[[<center><table><tr><td><img src="http://images.kingdomofloathing.com/itemimages/meat.gif" height=30 width=30 alt="Meat"></td><td valign=center>You gain [0-9,]+ Meat.</td></tr></table></center>]],
		[[<center><table class="item" style="float: none" rel="[^"]*"><tr><td><img src="http://images.kingdomofloathing.com/itemimages/[^"]+.gif" alt="[^"]*" title="[^"]*" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire .-</td></tr></table></center>]],
		[[{"]]..playerid()..[==[":%[[^"]*"(I found ([^"]*)!)",]==],
	}
	local ptfs = {}
	return function(x)
		if x then
			table.insert(ptfs, x)
		else
			local results = {}
			for _, pt in ipairs(ptfs) do
				if type(pt) ~= "string" then
					pt = pt()
				end
				for _, x in ipairs(extracts) do
					for m in pt:gmatch(x) do
						table.insert(results, m)
					end
				end
			end
			return results
		end
	end
end

function setup_automation_display_page_results(scan, text)
	local results = scan()
	if next(results) then
		local resulttext = ""
		for _, x in ipairs(results) do
			resulttext = resulttext .. "<center>" .. x .. "</center>"
		end
		text = add_message_to_page(text, resulttext, "Automation results:")
	end
	return text
end

function do_daily_visits()
	local extracts = {
		[[<center><table><tr><td><img src="http://images.kingdomofloathing.com/itemimages/meat.gif" height=30 width=30 alt="Meat"></td><td valign=center>You gain [0-9,]+ Meat.</td></tr></table></center>]],
		[[<center><table class="item" style="float: none" rel="[^"]*"><tr><td><img src="http://images.kingdomofloathing.com/itemimages/[^"]+.gif" alt="[^"]*" title="[^"]*" class=hand onClick='descitem%([0-9]+%)'></td><td valign=center class=effect>You acquire .-</td></tr></table></center>]],
		[[{"]]..playerid()..[==[":%[[^"]*"(I found ([^"]*)!)",]==],
	}
	local results = ""
	local tocall = {}

	local function add_result(m)
		results = results .. "<center>" .. m .. "</center>"
	end

	local function scan_results(pt)
		for _, x in ipairs(extracts) do
			for m in pt:gmatch(x) do
				add_result(m)
			end
		end
	end

	local function queue_page_result(ptf)
		table.insert(tocall, function()
			local pt, pturl = ptf()
			scan_results(pt)
		end)
	end

	local function dopage(url, params)
		queue_page_result(async_get_page(url, params))
	end

	async_get_page("/main.php")
	local campground_pt = get_page("/campground.php")

	local pwd = status().pwd

	local possible_daily_items = {
		"ball-in-a-cup",
		"burrowgrub hive",
		"cheap toaster",
		"cheap toaster",
		"cheap toaster",
		"Chester's bag of candy",
		"cursed microwave",
		"cursed pony keg",
		"Emblem of Ak'gyxoth",
		"glass gnoll eye",
		"handmade hobby horse",
		"Idol of Ak'gyxoth",
		"KoL Con Six Pack",
		"set of jacks",
		"Taco Dan's Taco Stand Flier",
		"Trivial Avocations board game",
	}
	-- TODO? neverending soda
	-- TODO? creepy voodoo doll

	local daily_items = {}
	for _, x in ipairs(possible_daily_items) do
		if have_item(x) then
			table.insert(daily_items, x)
		end
	end

	if campground_pt:contains("Humongous Buried Skull") then
		add_result([[<span style="color: darkorange">Skipped harvesting garden (<b>skulldozer ready</b>).</span>]])
	elseif setting_enabled("automate daily visits/harvest garden") then
		dopage("/campground.php", { action = "garden", pwd = pwd })
	else
		add_result("Skipped harvesting garden (can be enabled in settings).")
	end

	dopage("/clan_viplounge.php", { action = "lookingglass" })
	dopage("/clan_viplounge.php", { action = "crimbotree" })

	dopage("/volcanoisland.php", { pwd = pwd, action = "npc" })
	dopage("/volcanoisland.php", { pwd = pwd, action = "npc2" })

	dopage("/clan_rumpus.php", { preaction = "buychips", whichbag = 1 })
	dopage("/clan_rumpus.php", { preaction = "buychips", whichbag = 2 })
	dopage("/clan_rumpus.php", { preaction = "buychips", whichbag = 3 })

	dopage("/clan_viplounge.php", { action = "klaw" })
	dopage("/clan_viplounge.php", { action = "klaw" })
	dopage("/clan_viplounge.php", { action = "klaw" })

	dopage("/clan_rumpus.php", { action = "click", spot = 3, furni = 3 })
	dopage("/clan_rumpus.php", { action = "click", spot = 3, furni = 3 })
	dopage("/clan_rumpus.php", { action = "click", spot = 3, furni = 3 })

	dopage("/store.php", { whichstore = "h" })

	dopage("/clan_viplounge.php", { action = "swimmingpool" })
	dopage("/clan_viplounge.php", { preaction = "goswimming", subaction = "screwaround" })
	dopage("/choice.php", { forceoption = 0 })
	dopage("/choice.php", { whichchoice = 585, pwd = pwd, option = 1, action = "flip" })
	dopage("/choice.php", { whichchoice = 585, pwd = pwd, option = 1, action = "treasure" })
	dopage("/choice.php", { whichchoice = 585, pwd = pwd, option = 1, action = "leave" })

	if setting_enabled("automate daily visits/do lazy aftercore daily tasks") and ascensionstatus("Aftercore") then
		dopage("/campground.php", { preaction = "summonsnowcone", quantity = 3 })
		dopage("/campground.php", { preaction = "summonstickers", quantity = 3 })
		dopage("/campground.php", { preaction = "summonsugarsheets", quantity = 3 })
		-- TODO: clip art
		dopage("/campground.php", { preaction = "summonradlibs", quantity = 3 })
		dopage("/campground.php", { preaction = "summonhilariousitems" })
		dopage("/campground.php", { preaction = "summonspencersitems" })
		dopage("/campground.php", { preaction = "summonaa" })
		dopage("/campground.php", { preaction = "summonthinknerd" })
		-- TODO: librams

		queue_page_result(cast_skill("Lunch Break"))
		queue_page_result(cast_skill("Summon Crimbo Candy"))

		queue_page_result(cast_skill("Pastamastery", 16))
		queue_page_result(cast_skill("Pastamastery", 8))
		queue_page_result(cast_skill("Pastamastery", 4))
		queue_page_result(cast_skill("Pastamastery", 2))
		queue_page_result(cast_skill("Pastamastery", 1))
		queue_page_result(cast_skill("Advanced Saucecrafting", 16))
		queue_page_result(cast_skill("Advanced Saucecrafting", 8))
		queue_page_result(cast_skill("Advanced Saucecrafting", 4))
		queue_page_result(cast_skill("Advanced Saucecrafting", 2))
		queue_page_result(cast_skill("Advanced Saucecrafting", 1))
		queue_page_result(cast_skill("Advanced Cocktailcrafting", 16))
		queue_page_result(cast_skill("Advanced Cocktailcrafting", 8))
		queue_page_result(cast_skill("Advanced Cocktailcrafting", 4))
		queue_page_result(cast_skill("Advanced Cocktailcrafting", 2))
		queue_page_result(cast_skill("Advanced Cocktailcrafting", 1))
		-- TODO: use still
		queue_page_result(cast_skill("Request Sandwich"))
		queue_page_result(cast_skill("Request Sandwich"))
		queue_page_result(cast_skill("Request Sandwich"))
		queue_page_result(cast_skill("Request Sandwich"))
		queue_page_result(cast_skill("Request Sandwich"))
	end

	for _, x in ipairs(daily_items) do
		queue_page_result(use_item(x))
	end

	for _, f in ipairs(tocall) do
		f()
	end

	local clover_before = count_item("ten-leaf clover")
	if ascensionpathid() == 10 then
		get_page("/hermit.php")
	end
	if setting_enabled("automate daily visits/do lazy aftercore daily tasks") and ascensionstatus("Aftercore") then
		async_post_page("/hermit.php", { action = "trade", whichitem = get_itemid("ten-leaf clover"), quantity = 8 })
		async_post_page("/hermit.php", { action = "trade", whichitem = get_itemid("ten-leaf clover"), quantity = 4 })
		async_post_page("/hermit.php", { action = "trade", whichitem = get_itemid("ten-leaf clover"), quantity = 2 })
		post_page("/hermit.php", { action = "trade", whichitem = get_itemid("ten-leaf clover"), quantity = 1 })
	end

	if count_item("ten-leaf clover") > clover_before then
		scan_results(use_item("ten-leaf clover", count_item("ten-leaf clover") - clover_before)())
	end
	if count_item("ten-leaf clover") ~= clover_before then
		print("WARNING: unexpected result trying to pick up hermit clovers")
	end

	return results
end

add_automator("/main.php", function()
	if not setting_enabled("automate daily visits") then return end
	if locked() then return end
	local should_visit = false

	local want_tbl = {}
	table.insert(want_tbl, "visit")
	if ascensionstatus("Aftercore") then
		table.insert(want_tbl, "aftercore")
	end
	if setting_enabled("automate daily visits/harvest garden") then
		table.insert(want_tbl, "garden")
	end
	if ascensionstatus("Aftercore") and setting_enabled("automate daily visits/do lazy aftercore daily tasks") then
		table.insert(want_tbl, "aftercore")
	end
	local want_string = table.concat(want_tbl, "+")

	if day["done daily visits"] ~= want_string then
		print "INFO: doing daily visits"
		local dailythings = do_daily_visits()
		day["done daily visits"] = want_string
		text = add_message_to_page(text, dailythings, "Daily visits:")
	end
end)

-- do_aftercore_dailyvisits ref withskills = do
-- 	when withskills (do
-- 		castSkill 53 1 ref -- summon crimbo candy

-- 		castSkillMax 8103 ref -- summon brickos
-- 		castSkillMax 8100 ref -- summon candy hearts
-- 		castSkillMax 8101 ref -- summon party favors
-- 		castSkillMax 8102 ref -- summon love songs

-- 		-- use other rumpus equipment
-- 		return ())
