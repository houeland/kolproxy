register_setting {
	name = "automate daily visits",
	description = "Automate daily visits (rumpus room, etc.)",
	group = "automation",
	default_level = "standard",
}

register_setting {
	name = "automate daily visits/harvest garden",
	description = "Harvest garden as part of daily visits",
	group = "automation",
	default_level = "enthusiast",
}

register_setting {
	name = "automate daily visits/use bookshelf skills in aftercore",
	description = "Use bookshelf skills in aftercore as part of daily visits (not implemented yet)",
	group = "automation",
	default_level = "enthusiast",
}

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
			local m = pt:match(x)
			if m then
				add_result(m)
			end
		end
	end

	local function dopage(url, params)
		local ptf = async_get_page(url, params)
		table.insert(tocall, function()
			local pt, pturl = ptf()
			scan_results(pt)
		end)
	end

	async_get_page("/main.php")
	async_get_page("/campground.php")

	local pwd = status().pwd

	if setting_enabled("automate daily visits/harvest garden") then
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

	local itemname = "Taco Dan's Taco Stand Flier"
	if have(itemname) then
		dopage("/inv_use.php", { pwd = pwd, whichitem = get_itemid(itemname), ajax = 1 })
	end

	for f in table.values(tocall) do
		f()
	end

	if ascensionpathid() == 10 then
		local clover_before = count_item("ten-leaf clover")
		get_page("/hermit.php")
		if count_item("ten-leaf clover") > clover_before then
			scan_results(use_item("ten-leaf clover")())
		end
	end

	return results
end

add_automator("/main.php", function()
	if setting_enabled("automate daily visits") and not day["done daily visits"] and not locked() then
		print "player login daily visits!"
		local dailythings = do_daily_visits()
		day["done daily visits"] = "yes"
		text = add_message_to_page(text, dailythings, "Daily visits:")
	end
end)

-- do_aftercore_dailyvisits ref withskills = do
-- 	when withskills (do
-- 		castSkill 8000 3 ref -- Summon snowcones
-- 		castSkill 8001 3 ref -- Summon stickers
-- 		castSkill 8002 3 ref -- Summon sugar sheets

-- 		castSkill 8200 1 ref -- summon hilarious objects
-- 		castSkill 8201 1 ref -- summon tasteful gifts

-- 		castSkill 4006 3 ref -- Advanced Saucecrafting
-- 		castSkill 4006 3 ref
-- 		castSkill 4006 2 ref

-- 		castSkill 5014 3 ref -- Advanced Cocktailcrafting
-- 		castSkill 5014 2 ref

-- 		castSkill 3006 3 ref -- Pastamastery
-- 		castSkill 3006 2 ref

-- 		castSkill 53 1 ref -- sumon crimbo candy

-- 		castSkillMax 8103 ref -- summon brickos
-- 		castSkillMax 8100 ref -- summon candy hearts
-- 		castSkillMax 8101 ref -- summon party favors
-- 		castSkillMax 8102 ref -- summon love songs

-- 		useItem 3393 ref -- oscus's soda
-- 		useItem 3629 ref -- burrowgrub
-- 		-- trade with hermit
-- 		-- use other rumpus equipment
-- 		-- 	use still
-- 		return ())

-- 	useItem 3261 ref -- chester's bag of candy
-- 	useItem 637 ref -- cheap toaster
-- 	useItem 637 ref -- cheap toaster
-- 	useItem 637 ref -- cheap toaster
-- 	useItem 3731 ref -- glass gnoll eye
