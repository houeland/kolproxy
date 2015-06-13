add_processor("/main.php", function()
	if text:contains("the Feast of Boris") then
		session["holiday: feast of boris"] = "yes"
		session["active feast of boris bonus fullness today"] = nil
		for tr in text:gmatch([[<tr>.-</tr>]]) do
			if tr:contains("Feast of Boris") and tr:contains("Eat, eat, eat!") then
				session["active feast of boris bonus fullness today"] = "yes"
			end
		end
	end
end)

-- inventory item annotations

local inventory_item_annotations = {}

function add_inventory_item_annotation(itemname, f)
	inventory_item_annotations[itemname] = f
end

add_printer("/inventory.php", function()
	-- TODO: make sure this triggers on all possible inventory option settings
	text = text:gsub([[(<b class="ircm">)(.-)(</b>&nbsp;<span>[^<]*</span>)]], function(pre, itemname, post)
		for checkname, f in pairs(inventory_item_annotations) do
			-- Support both inventory images turned on and off
			if itemname:contains(checkname) then
				return pre .. itemname .. post .. " " .. f(itemname)
			end
		end
	end)
end)

-- add green border to 100% runs

add_printer("/ascensionhistory.php", function()
	text = text:gsub([[(<img src="http://images.kingdomofloathing.com/itemimages/[^"]+.gif" width=30 height=30 alt="[^"]+" title="[^"]+ %(100%%%)[^"]*")(>)]], [[%1 style="border: thin solid green"%2]])
end)

-- adventure mistake warnings

add_processor("/desc_item.php", function()
	if text:contains(">Buddy Bjorn<") then
		session["Buddy Bjorn occupied"] = not text:contains(">Nobody<")
	end
end)

add_processor("/desc_item.php", function()
	if text:contains(">Crown of Thrones<") then
		session["Crown of Thrones occupied"] = not text:contains(">Nobody<")
	end
end)

add_always_adventure_warning(function()
	if have_equipped_item("Crown of Thrones") then
		estimate_item_equip_bonuses("Crown of Thrones")
		if not session["Crown of Thrones occupied"] then
			return "You might want to put a familiar in your Crown of Thrones.", "familiar in CoT"
		end
	end
end)

add_always_adventure_warning(function()
	if have_equipped_item("Buddy Bjorn") then
		estimate_item_equip_bonuses("Buddy Bjorn")
		if not session["Buddy Bjorn occupied"] then
			return "You might want to put a familiar in your Buddy Bjorn.", "familiar in Buddy Bjorn"
		end
	end
end)

add_always_adventure_warning(function()
	if drunkenness() > estimate_max_safe_drunkenness() then
		return "You might not want to adventure while this drunk.", "overdrunk"
	end
end)

add_ascension_adventure_warning(function(zoneid)
	if level() >= 13 then
		if mcd() > 0 and params.action ~= "lc_mcd" then
			return "You might want to turn off the monster-annoyer since you're already level 13+.", "turn off monster-annoyer"
		else
			return
		end
	end
	local function should_we_maximize_mcd()
		if zoneid == 34 and (mcd() == 4 or mcd() == 8) then
			return false
		end
		return true
	end
	if moonsign_area("Degrassi Knoll") then
		if not have_item("detuned radio") then
			return "You might want to buy a detuned radio.", "buy detuned radio"
		elseif mcd() == 0 then
			return "You might want to set your detuned radio.", "set detuned radio"
		elseif mcd() < 10 and should_we_maximize_mcd() then
			return "You might want to turn up your detuned radio.", "turn up detuned radio"
		end
	elseif moonsign_area("Little Canadia") and params.action ~= "lc_mcd" then
		if mcd() == 0 then
			return "You might want to set the Mind-Control Device.", "set Mind-Control Device"
		elseif mcd() < 11 and should_we_maximize_mcd() then
			return "You might want to turn up the Mind-Control Device.", "turn up Mind-Control Device"
		end
	elseif moonsign_area("Gnomish Gnomad Camp") then
		if have_unlocked_beach() then
			if mcd() == 0 then
				return "You might want to set the Annoy-o-Tron.", "set Annoy-o-Tron"
			elseif mcd() < 10 and should_we_maximize_mcd() then
				return "You might want to turn up the Annoy-o-Tron.", "turn up Annoy-o-Tron"
			end
		end
	end
end)

add_ascension_adventure_warning(function(zoneid)
	if not have_skill("Pep Talk") then return end
	if level() >= 13 and have_intrinsic("Overconfident") then
		return "You might want to turn off Overconfident since you're already level 13+.", "turn off Overconfident"
	elseif level() < 13 and not have_intrinsic("Overconfident") then
		return "You might want to turn on Overconfident to gain more stats.", "turn on Overconfident"
	end
end)

add_ascension_adventure_warning(function()
	if level() >= 13 and estimate_bonus("Monster Level") > 0 then
		return "You might want to remove your +Monster Level modifiers since you're already level 13+.", "remove +ML"
	end
end)

add_ascension_adventure_warning(function()
	if have_item("astral shirt") and not have_equipped_item("astral shirt") and level() < 13 then
		return "You might want to wear your astral shirt to gain more stats.", "wear astral shirt"
	end
end)

add_ascension_adventure_warning(function()
	if basemuscle() >= 45 and have_item("hipposkin poncho") and not have_equipped_item("hipposkin poncho") and level() < 13 then
		return "You might want to wear your hipposkin poncho to gain more stats.", "wear hipposkin poncho"
	end
end)

add_ascension_adventure_warning(function()
	if basemuscle() >= 40 and have_item("Grimacite gown") and not have_equipped_item("Grimacite gown") and level() < 13 then
		return "You might want to wear your Grimacite gown to gain more stats.", "wear Grimacite gown"
	end
end)

add_ascension_adventure_warning(function()
	if basemuscle() >= 40 and (have_item("Moonthril Cuirass") or have_item("Mint-in-box Moonthril Cuirass")) and not have_equipped_item("Moonthril Cuirass") and level() < 13 then
		return "You might want to wear your Moonthril Cuirass to gain more stats.", "wear Moonthril Cuirass"
	end
end)

add_ascension_adventure_warning(function()
	if basemuscle() >= 40 and have_item("hairshirt") and not have_equipped_item("hairshirt") and level() < 13 then
		return "You might want to wear your hairshirt to gain more stats.", "wear hairshirt"
	end
end)

add_ascension_adventure_warning(function()
	if basemysticality() >= 35 and have_inventory_item("hockey stick of furious angry rage") and level() < 13 then
		return "You might want to wear your hockey stick of furious angry rage to gain more stats.", "wear hockey stick of furious angry rage"
	end
end)

add_always_adventure_warning(function()
	if familiar("Obtuse Angel") and (ascensionstatus("Aftercore") or have_item("quake of arrows")) and not have_equipped_item("quake of arrows") then
		return "You might want to wear quake of arrows on your obtuse angel to get more copies of monsters.", "wear quake of arrows"
	end
end)

add_always_adventure_warning(function()
	if have_buff("QWOPped Up") then
		return "You are QWOPped Up and will always fumble in combat.", "adventuring while qwopped up"
	end
end)


-- add_ascension_adventure_warning(function()
-- 	if mainstat_type("Moxie") and basemoxie() >= 60 and have_inventory_item("spangly sombrero") and level() < 13 then
-- -- TODO: and not in an outfit-required place
-- 		return "You might want to wear your spangly sombrero for stats.", "wear spangly sombrero"
-- 	end
-- end)

-- add_printer("all pages", function()
-- 	text = text:gsub("</head>", [[
-- 	<style>
-- 		a:hover { opacity: 0.75; }
-- 		a[_type]:hover { opacity: 1.0; } /* combat action bar dropdowns */
-- 		input[class=button]:hover { opacity: 0.75; }
-- 	</style>
-- 	<script language=Javascript src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
-- 	<script>
-- 	jQuery(function($) {
-- 		$('a[href*=".php"]').live('click', function() {
-- 			$('img[width=100][height=100]').not($(this).find('img')).css('opacity', 0.5);
-- 		})
-- 	});
-- 	function funkit(t) {
-- 		console.log("hello", t.href)
-- 	}
-- 	</script>
-- 	%0]])
-- end)

-- add_printer("all pages", function()
-- 	text = text:gsub("</head>", [[
-- 	<script language=Javascript src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
-- 	%0]])
-- 	text = text:gsub([[href="adventure.php%?]], [[onmouseover='javascript:funkit(this)' %0]])
-- end)

--~ add_printer("/main.php", function()
--~ 	text = text:gsub("</head>", [[
--~ <script>
--~ 	$(document).ready(function() {
--~ 		$("table").effect("shake", { times: 4 }, 10);
--~ 	}
--~ </script>
--~ %0]])
--~ end)

-- add_printer("/afterlife.php", function()
-- 	if params.place == "reincarnate" and text:contains("You have unlocked the Bad Moon sign for your next run.") then
-- 		text = text:gsub([[switch%(document.ascform.whichpath.value%) {]], [[
-- if (!document.ascform.whichpath.value) { document.ascform.whichpath.value = '0'; }
-- 	%0
-- 		case 'kolproxyBM': pathimage='../itemimages/badmoon'; pathtext="<b>NOTE:</b>  You have unlocked the Bad Moon sign for your next run.  Be warned:  being born under a Bad Moon is very difficult.  It's like Hardcore, but you don't get to use any of your previous permanent skills -- just the ones you acquire on the run.  The spirits of your familiars will also not return with you, and you'll have to find them again if you want to use them during the run.  Being born under a Bad Moon will also cause you to have a lot of &quot;unlucky&quot; stuff happen to you in various places.<p>It's challenging, but it's fun, and it has its rewards, just like other challenging paths.  There is a separate set of leaderboards for Bad Moon, as well."; break;]])
-- 		text = text:gsub([[(<select name=whichpath.-)(</select>)]], [[%1<option value="kolproxyBM">Bad Moon</option>%2]])
-- 		text = text:gsub([[$%('option%[value=10%]'%).remove%(%);]], [[%0
-- 		$('option[value=kolproxyBM]').remove();
-- 		pathoptions();]])
-- 		text = text:gsub([[$%('select%[name="whichsign"%]'%).append%('<option value="10">Bad Moon</option>'%);]], [[$('select[name="whichpath"]').append('<option value="kolproxyBM">Bad Moon</option>');]])
-- 		text = text:gsub([[document.pathpic.src=]], [[
-- if (document.ascform.whichpath.value == "kolproxyBM") {
-- 		hidediv('moonsigns');
-- 		$('option[value=10]').remove();
-- 		$('select[name="whichsign"]').append('<option value=10 >Bad Moon</option>');
-- 		document.ascform.whichsign.value = "10";
-- 		moonpreview();
-- 	} else if (document.ascform.asctype.value != 0) {
-- 		showdiv('moonsigns');
-- 		$('option[value=10]').remove();
-- 		moonpreview();
-- 	}
-- 	%0]])
-- 		text = text:gsub([[if %(sign == 10%) hidediv%('path'%);]], [[]])
-- 		text = text:gsub([[else if %(lifestyle >  1 %) showdiv%('path'%);]], [[]])
-- 	end
-- end)

add_printer("/charpane.php", function()
	local ttr = tonumber(text:match("var turnsthisrun = ([0-9]+);"))
	if not ttr then return end
	if text:contains("inf_small.gif") then return end
	if not ascensionstatus("Aftercore") then return end
	local href = "http://kol.obeliks.de" .. raw_make_href("/buffbot/buff", {
		{ key = "style", value = "kol" },
-- 		{ key = "style", value = "kolproxy" },
		{ key = "target", value = playername() },
	})
	text = text:gsub([[</center></body></html>]], [[<a href="]]..href..[[" target="mainpane" style="color: green">{ Get buffs }</a>%0]])
end)


-- 	add_automator("use item", function()
-- 		if not setting_enabled("automate simple tasks") then return end
-- 		if text:match([[<input class=button type=submit value="Begin the Ritual">]]) then
-- 			text = text:gsub([[(<p>You feel your clubbing muscles begin to twitch with anticipation...<p><center><form action=inv_use.php method=post)(>)]], [[%1 name="kolproxy_summonsealform"%2]])
-- 			text = text .. [[<script>document.kolproxy_summonsealform.submit();</script>]]
-- 			-- TODO: grey out button so they don't click it as well?
-- 	-- 		local pwdhash = text:match([[<input type=hidden name=pwd value=(%x-)>]])
-- 	-- 		local whichitemstr = text:match([[<input type=hidden name=whichitem value=(%x-)>]])
-- 	-- 		text = post_page("/inv_use.php", { pwd = pwdhash, whichitem = whichitemstr, checked = "1" })
-- 		end
-- 	-- 	posting page /inv_use.php params: Just [("pwd","baf939169cd8b1b342b2536c339b8592"),("whichitem","3902"),("checked","1")]
-- 	-- 	print("\n\n\n\n")
-- 	-- 	print(text)
-- 	-- 	print("\n\n\n\n")
-- 	end)

-- if mode == "intercept" then
	-- prevent adventuring in places without enough meat: palindome, spooky forest
-- end

-- castle: inv_use.php -> quantum egg -> intragalactic



-- easter egg balloon:
-- 	got uri: /storage.php |  (from /storage.php), size 353672, params: Just [("pwd","5d6ee76c54dddac276e3e7a922ee665c"),("action","take"),("howmany1",""),("whichitem1","436")]
-- 	got uri: /lair2.php |  (from /lair2.php), size 3128, params: Just [("preaction","key"),("whichkey","436")]


-- The Sleeper Has Awakened -> equip worm-riding hooks, use drum machine, equip weap/offhand again, return page

automate_noncombat_href = add_automation_script("automate-noncombat", function()
	text, url = "Trying to automate noncombat...", requestpath
	local f = function() return text, url end
	for i = 1, 100 do
		local p = params["choice" .. i]
		if p then
			local whichchoice, option = p:match("([0-9]+)%-([0-9]+)")
--			print(params["choice" .. i], whichchoice, option)
			f = async_post_page("/choice.php", { pwd = params.pwd, whichchoice = whichchoice, option = option })
		else
			break
		end
	end
	text, url = f()
	return text, url
end)

-- vamping out

add_processor("/choice.php", function()
	if adventure_title == "Interview With You" and text:contains("A small bell chimes above the door of Isabella's as you enter.") then
		print("Vamping Out at Isabella's!")
		day["vamped out.isabella"] = "yes"
	end
end)

add_printer("/town.php", function()
	if have_item("plastic vampire fangs") then
		if day["vamped out.isabella"] == "yes" then
			text = text:gsub("</body>", [[<center style="color: gray">{ Already vamped out at Isabella's today. }</center>%0]])
		else
			text = text:gsub("</body>", [[<center style="color: green">{ Not yet vamped out at Isabella's today. }</center>%0]])
		end
	end
end)

add_choice_text("Interview With You", {
	["Visit Vlad's Boutique"] = "Get a vampire buff",
	["Visit Isabella's"] = { text = "Get big statgain", good_choice = true },
	["Visit The Masquerade"] = "Get a vampire item",
})

interview_with_you_stat_choices = {
	Muscle = { 1, 1 },
	Mysticality = { 1, 3, 1 },
	Moxie = { 1, 2, 2, 1 },
}

add_printer("/choice.php", function()
	if adventure_title ~= "Interview With You" or not text:contains("A small bell chimes above the door of Isabella's as you enter.") then return end
	local isabella_choices = interview_with_you_stat_choices
	local function make_vamp_link(goal)
		local tparams = {}
		tparams.pwd = text:match([[<input type=hidden name=pwd value='([0-9a-f]+)'>]])
		local whichchoice = text:match([[<input type=hidden name=whichchoice value=([0-9]+)>]])
		for a, b in ipairs(isabella_choices[goal]) do
			tparams[string.format("choice%d", a)] = string.format("%d-%d", whichchoice, b)
		end
		return [[<a href="]]..automate_noncombat_href(tparams)..[[" style="color: green">]] .. goal .. [[</a>]]
	end
	text = text:gsub("</form>", function(x) return x .. [[<span style="color: green">{ ]] .. make_vamp_link("Muscle") .. ", " .. make_vamp_link("Mysticality") .. ", " .. make_vamp_link("Moxie") .. [[ }</span><br>]] end)
end)

-- show banished monsters

add_automator("/fight.php", function()
	local banish_msgs = {
		"You start screaming and howling uncontrollably",
		"Blood blood blood blood BLOOOOOD",
		"get the correct volume and murderous inflection",
--		"RIP AND TEAR YOUR GUTS",
		[["RIP AND TEAR!" you shout wildly]],
		"SKULLS FOR THE SKULL THRONE",
		"stream of shouted profanities",
		"YOUR SKULL IS MIIIIINE",
		"howl grisly invocations to every god you can think of",
		"make the scariest noise you can think of",
	}
	for x in table.values(banish_msgs) do
		if text:contains(x) then
			local pt = get_page("/desc_skill.php", { whichskill = 11020, self = "true" })
			local banished = pt:match([[<blockquote.-(The following monsters.-)</blockquote>]])
			local banishmsg = ([[ <p style="color: green">]] .. tostring(banished) .. [[</p>]]):gsub("(>)([^<]*)(<br)", "%1{ %2 }%3")
			text = text:gsub("(>)([^<]*" .. x .. ".-)(<[^/i])", function(a, b, c) return a .. b .. banishmsg .. c end)
		end
	end
end)

add_automator("/fight.php", function()
	if text:contains("You howl with rage, and your zombie horde takes up the cry") then
		local pt = get_page("/desc_skill.php", { whichskill = 12020, self = "true" })
		local banished = pt:match([[<blockquote.-(The following monsters.-)<p>]])
		local banishmsg = ([[ <p style="color: green">]] .. tostring(banished) .. [[</p>]]):gsub("(>)([^<]*)(<br)", "%1{ %2 }%3")
		text = text:gsub("(>)([^<]*You howl with rage, and your zombie horde takes up the cry.-)(<[^/i])", function(a, b, c) return a .. b .. banishmsg .. c end)
	end
end)


-- Pick up filthy lucre
add_automator("/fight.php", function()
	if not setting_enabled("automate simple tasks") then return end
	local bounty1, bounty2 = text:match("%(([0-9]+) of ([0-9]+) found.%)")
	if tonumber(bounty2) and bounty1 == bounty2 and not locked() then
			local scan = setup_automation_scan_page_results()
			active_automation_assistance_scanner = scan
			pcall(function()
				async_get_page("/bhh.php")
			end)
			active_automation_assistance_scanner = nil
			text = setup_automation_display_page_results(scan, text)
		end
	end)

active_automation_assistance_scanner = nil
add_submit_page_listener(function(ptf)
	if active_automation_assistance_scanner then
		active_automation_assistance_scanner(ptf)
	end
end)

local ascension_assistance_list = {}
function add_ascension_assistance(checkf, f)
	table.insert(ascension_assistance_list, { checkf = checkf, f = f, last_checked = nil })
end

add_automator("all pages", function()
	if not setting_enabled("automate simple tasks") then return end
	local scan = setup_automation_scan_page_results()
	active_automation_assistance_scanner = scan
	for i = 1, 10 do
		local activated = false
		for _, aa in ipairs(ascension_assistance_list) do
			if aa.last_checked ~= level() and not locked() and aa.checkf() then
				activated = true
				local new_last_checked = level()
				local ok, result = pcall(aa.f)
				if ok and result then
					aa.last_checked = nil
				else
					aa.last_checked = new_last_checked
				end
			end
		end
		if not activated then break end
	end
	active_automation_assistance_scanner = nil
	text = setup_automation_display_page_results(scan, text)
end)

-- Visit council
add_ascension_assistance(function() return true end, function()
	async_get_page("/council.php")
	if level() == 8 then
		async_get_place("mclargehuge", "trappercabin")
	end
end)

-- Pick up free pulls and talk to Toot
local picked_up_free_pulls = false
add_ascension_assistance(function() return not picked_up_free_pulls end, function()
	async_post_page("/campground.php", { action = "telescopelow" })
	async_post_page("/campground.php", { action = "workshed" })
	if not have_item("Clan VIP Lounge key") then
		xx = freepull_item("Clan VIP Lounge key")
		freepull_item("cursed microwave")
		freepull_item("cursed pony keg")
	end
	if ascensionpath("Avatar of Boris") and not have_item("Boris's Helm") and not have_item("Boris's Helm (askew)") then
		freepull_item("Boris's Helm")
		freepull_item("Boris's Helm (askew)")
	end
	if ascensionpath("Avatar of Jarlsberg") and not have_item("Jarlsberg's pan") and not have_item("Jarlsberg's pan (Cosmic portal mode)") then
		freepull_item("Jarlsberg's pan")
		freepull_item("Jarlsberg's pan (Cosmic portal mode)")
	end
	picked_up_free_pulls = true
end)

local talked_to_toot = false
add_ascension_assistance(function() return not talked_to_toot and turnsthisrun() <= 10 end, function()
	async_get_page("/tutorial.php", { action = "toot" })
	use_item("letter from King Ralph XI")
	async_post_page("/galaktik.php", { action = "startquest", pwd = session.pwd })
--	if not ascensionpath("Bees Hate You") then
--		use_item("Newbiesport&trade; tent")
--	end
	if setting_enabled("break hippy stone when ascending") then
		async_post_page("/campground.php", { smashstone = "Yep.", pwd = session.pwd, confirm = "on" })
	end
	talked_to_toot = true
end)

local function add_use_item_ascension_assistance(itemname)
	add_ascension_assistance(function() return have_item(itemname) end, function()
		local c = count_item(itemname)
		use_item(itemname)()
		if count_item(itemname) < c then
			return true
		end
	end)
end

add_use_item_ascension_assistance("astral hot dog dinner")
add_use_item_ascension_assistance("astral six-pack")
add_use_item_ascension_assistance("carton of astral energy drinks")

add_use_item_ascension_assistance("telegram from Lady Spookyraven")
add_use_item_ascension_assistance("Letter for Melvign the Gnome")
add_use_item_ascension_assistance("letter to Ed the Undying")

add_use_item_ascension_assistance("evil eye")
add_use_item_ascension_assistance("desert sightseeing pamphlet")

add_ascension_assistance(function() return have_item("Knob Goblin encryption key") and have_item("Cobb's Knob map") and not ascensionpath("Bees Hate You") end, function()
	use_item("Cobb's Knob map")
end)

add_ascension_assistance(function() return have_item("Lady Spookyraven's necklace") end, function()
	get_place("manor1", "manor1_ladys")
end)

function pick_up_continuum_transfunctioner()
	async_post_page("/place.php", { whichplace = "forestvillage", action = "fv_mystic" })
	async_get_page("/choice.php", { forceoption = 0 })
	async_post_page("/choice.php", { pwd = session.pwd, whichchoice = 664, option = 1 })
	async_post_page("/choice.php", { pwd = session.pwd, whichchoice = 664, option = 1 })
	return async_post_page("/choice.php", { pwd = session.pwd, whichchoice = 664, option = 1 })
end

add_ascension_assistance(function() return level() >= 2 and not have_item("continuum transfunctioner") end, function()
	async_get_place("forestvillage", "fv_untinker_quest")
	async_post_page("/place.php", { whichplace = "forestvillage", action = "fv_untinker_quest", preaction = "screwquest" })
	async_get_place("knoll_friendly", "dk_innabox")
	async_get_place("forestvillage", "fv_untinker_quest")
	pick_up_continuum_transfunctioner()
end)

add_ascension_assistance(function() return have_item("abridged dictionary") end, function()
	-- untinker bridge
	async_post_page("/place.php", { whichplace = "forestvillage", action = "fv_untinker", pwd = session.pwd, preaction = "untinker", whichitem = get_itemid("abridged dictionary") })
end)

add_ascension_assistance(function() return level() >= 9 and have_item("64735 scroll") and have_item("dictionary") end, function()
	use_item("64735 scroll")
end)

add_use_item_ascension_assistance("hermit script")

add_ascension_assistance(function() return have_item("&quot;2 Love Me, Vol. 2&quot;") end, function()
	use_item("&quot;2 Love Me, Vol. 2&quot;")
	async_get_place("palindome", "pal_mroffice")
end)

local hermit_permit_href = add_automation_script("get-hermit-permit", function ()
	if not have_item("hermit permit") then
		store_buy_item("hermit permit", "m")
		text, url = get_page("/hermit.php")
	end
	return text, url
end)

local hermit_trinket_href = add_automation_script("get-hermit-trinket", function()
	local function get_trinket()
		if not have_item("worthless trinket") and not have_item("worthless gewgaw") and not have_item("worthless knick-knack") then
			print "  getting worthless item"
			if not have_item("chewing gum on a string") then
				store_buy_item("chewing gum on a string", "m")
			end
			local pt, pturl = use_item("chewing gum on a string")()
			if pt:contains("You acquire") then
				get_trinket()
			end
		end
	end
	get_trinket()
	text, url = get_page("/hermit.php")
	return text, url
end)

add_printer("/hermit.php", function()
	if text:contains("Hermit Permit required") then
		text = text:gsub("permits and forms.<p>", [[%0<a href="]] .. hermit_permit_href { pwd = session.pwd } .. [[" style="color: green">{ Get permit }</a><p>]])
	elseif text:contains("don't have anything worthless enough") then
		text = text:gsub("worthless enough for him to want to trade for it.<P>", [[%0<a href="]] .. hermit_trinket_href { pwd = session.pwd } .. [[" style="color: green">{ Get trinket }</a><p>]])
	end
end)

register_setting {
	name = "open chat on logon",
	description = "Automatically open modern chat in right-hand frame on login",
	group = "chat",
	default_level = "standard",
}

add_printer("/game.php", function()
	if setting_enabled("open chat on logon") then
		text = text:gsub("chatlaunch.php", "mchat.php")
	end
end)


local learn_all_boris_skills_href = add_automation_script("learn-all-boris-skills", function()
	for i = 1, 10 do
		async_post_page("/da.php", { action = "borisskill", whichtree = 1 })
		async_post_page("/da.php", { action = "borisskill", whichtree = 2 })
		async_post_page("/da.php", { action = "borisskill", whichtree = 3 })
	end
	return get_page("/da.php", { place = "gate1" })
end)

add_printer("/da.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if params.place == "gate1" and text:contains("You can learn 30 more skills") then
		text = text:gsub("You can learn 30 more skills.", [[%0</p><p><a href="]] .. learn_all_boris_skills_href { pwd = session.pwd } .. [[" style="color: green">{ Learn all Boris skills. }</a>]])
	end
end)

local learn_all_jarlsberg_skills_href = add_automation_script("learn-all-jarlsberg-skills", function()
	for _, skillid in ipairs { 14003, 14007, 14001, 14005, 14002, 14006, 14004, 14008, 14011, 14015, 14014, 14012, 14013, 14016, 14017, 14018, 14023, 14022, 14026, 14025, 14021, 14027, 14024, 14028, 14032, 14037, 14033, 14036, 14031, 14034, 14035, 14038 } do
		async_get_page("/jarlskills.php", { action = "getskill", getskid = skillid })
	end

	return get_page("/jarlskills.php")
end)

add_printer("/jarlskills.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if text:contains("You have 32 skill points to spend.") then
		text = text:gsub("You have 32 skill points to spend.", [[%0</p><p><a href="]] .. learn_all_jarlsberg_skills_href { pwd = session.pwd } .. [[" style="color: green">{ Learn all Jarlsberg skills. }</a>]])
	end
end)

-- add_interceptor("/kolproxy-async-test", function()
-- 	local tbl = {}
-- 	for i = 1, 100 do
-- 		table.insert(tbl, async_get_page("/storage.php", { which = 1, test = i }))
-- 	end
-- 	for i, f in ipairs(tbl) do
-- 		f()
-- 		print(i, "done")
-- 	end
-- 	return "Done.", requestpath
-- end)

add_itemdrop_counter("BURT", function(c)
	return "{ " .. make_plural(c, "BURT", "BURTs") .. " in inventory. }"
end)

local function do_brushfire_fight()
	if hp() < maxhp() then
		cast_skillid(3012)
		if hp() < maxhp() then
			stop "Not healed!"
		end
	end
	if not have_buff("Coldform") then
		stop "Missing coldform!"
	end
	print("fighting brushfire!")
	async_get_page("/plains.php", { action = "brushfire" })
	text, url = get_page("/fight.php")
	text, url = handle_adventure_result(text, url, "?", [[
cast throw shield
attack
attack
attack
]])
	return text, url
end

local automate_brushfire_href = add_automation_script("automate-brushfire", function()
	local stop = false
	while not stop do
		text, url = do_brushfire_fight()
		if not text:contains("5 FDKOL commendations") and not text:contains("4 FDKOL commendations") then
			stop = true
		end
	end
	return text, url
end)

-- TODO: turn into an automation script?
add_interceptor("/kolproxy-frame-page", function()
	if params.pwd ~= session.pwd then return "", requestpath end
	return [[<html style="margin: 0px; padding: 0px;"><head><script language=Javascript src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script></head><body style="margin: 0px; padding: 0px;"><iframe src="]] .. params.url .. [[" style="width: 100%; height: 100%; border: none; margin: 0px; padding: 0px;"></iframe></body></html>]], requestpath
end)

--[--[--
add_interceptor("__IGNORE__ use item: Degrassi Knoll shopping list", function()
	-- TODO: redo this entirely?
	if setting_enabled("automate simple tasks") then
				stuff = {}
				stuff["bitchin' meatcar"] = { "meat engine", "dope wheels" }
				stuff["dope wheels"] = { "tires", "sweet rims" }
				stuff["meat engine"] = { "cog and sprocket assembly", "full meat tank" }
				stuff["cog and sprocket assembly"] = { "sprocket assembly", "cog" }
				stuff["sprocket assembly"] = { "spring", "sprocket" }
				stuff["full meat tank"] = { "empty meat tank", "meat stack" }
				can_buy = {}
				if moonsign_area() == "Degrassi Knoll" then
					can_buy["tires"] = true
					can_buy["cog"] = true
					can_buy["spring"] = true
					can_buy["sprocket"] = true
					can_buy["empty meat tank"] = true
				end
				can_buy["meat stack"] = true
				function combine_tables(a, b)
					ret = {}
					for x, y in pairs(a) do table.insert(ret, y) end
					for x, y in pairs(b) do table.insert(ret, y) end
					return ret
				end
				function try_to_create(name)
					if have_item(name) then
						return { have = { name }, buy = {}, missing = {}, order = {} }
					end
					if can_buy[name] then
						return { have = {}, buy = { name }, missing = {}, order = {} }
					end
					if stuff[name] then
						local a = try_to_create(stuff[name][1])
						local b = try_to_create(stuff[name][2])
						local have = combine_tables(a.have, b.have)
						local buy = combine_tables(a.buy, b.buy)
						local missing = combine_tables(a.missing, b.missing)
						local order = combine_tables(a.order, b.order)
						table.insert(order, { stuff[name][1], stuff[name][2] })
						return { have = have, buy = buy, missing = missing, order = order }
					end
					return { have = {}, buy = {}, missing = { name }, order = {} }
				end
				meatcar = try_to_create("bitchin' meatcar")
				if next(meatcar.missing) then
					local missing_list = {}
					for a, b in pairs(meatcar.missing) do table.insert(missing_list, [[<span style="color: darkorange;">]] .. b .. [[</span>]]) end
					for a, b in pairs(meatcar.buy) do table.insert(missing_list, [[<span style="color: gray;">]] .. b .. [[</span>]]) end
					for a, b in pairs(meatcar.have) do table.insert(missing_list, [[<span style="color: green;">]] .. b .. [[</span>]]) end
					text, url = get_page("/inv_use.php", params):gsub("<blockquote>.+</blockquote>", "<blockquote>Needed items:<p><blockquote><p>" .. table.concat(missing_list, "<br>") .. "</p></blockquote></blockquote>")
				else
					for x, name in pairs(meatcar.buy) do
						if name == "meat stack" then
							async_get_page("/inventory.php", { quantity = 1, action = "makestuff", pwd = params.pwd, whichitem = get_itemid(name), ajax = 1 })
						else
							buy_item(name)
						end
					end
					for x, name in pairs(meatcar.order) do
						meatpaste_items(name[1], name[2])
					end

					async_get_page("/town_right.php", { place = "untinker" })
					async_get_page("/knoll.php", { place = "smith" })
					async_get_page("/town_right.php", { place = "untinker" })
					async_get_page("/guild.php", { place = "paco" }) -- need the topmenu refreshed from this
					text, url = get_page("/inv_use.php", params)
					async_post_page("/town_right.php", { pwd = params.pwd, action = "untinker", whichitem = get_itemid("bitchin' meatcar") })
					async_post_page("/town_right.php", { pwd = params.pwd, action = "untinker", whichitem = get_itemid("dope wheels") })

					text = "<script>parent.menupane.location.href=parent.menupane.location.href;</script>" .. text -- do in a prettier way?
				end
		return text, url
	end
end)
--]--]--

add_interceptor("use item: black market map", function()
	-- TODO: make this an automator? would hurt in bees
	-- TODO: add Bee path support?
	-- TODO: support not having a fam before?
	local famid = familiarid()
	switch_familiar("Reassembled Blackbird")
	text, url = submit_original_request()
	switch_familiar(famid)
	return text, url
end)

add_extra_always_warning("use item: photocopied monster", function()
	if autoattack_is_set() then
		return "You have autoattack enabled versus a photocopied monster.", "autoattack enabled vs photocopied monster"
	end
end)

add_always_warning("use item: spice melange", function()
	if fullness() < 3 or drunkenness() < 3 then
		return string.format("You only have %d fullness and %d drunkenness, while spice melange can remove up to 3 of each.", fullness(), drunkenness()), "using spice melange with empty organs"
	end
end)

add_automator("/manor3.php", function()
	if params.place == "chamber" and text:contains(">One of them asks you the name of the Demon you would summon.<") then
		local questlogpage = get_page("/questlog.php", { which = 3 })
		local invokedtext = questlogpage:match(">(You have invoked .-)</td>") or ""
		local demons = {
			["Ak'gyxoth"] = "(3 drinks)",
			["Tatter"] = "(pile of smoking rags)",
			["Bertrand"] = "(Mime lounge access)",
		}
		local demonorder = {}
		local demontitles = {}
		local demondescs = {
			["Lord of the Pies"] = "(3 pies)",
			["the Deadest Beat"] = "(+100% Meat)",
			["the Ancient Fishlord"] = "(5-16 HP/MP per Adventure)",
			["Duke of the Underworld"] = "(+20 Hot Damage, 5 DR)",
			["the Stankmaster"] = "(+30 Stench Damage)",
			["the Smith"] = "(80-100 hot damage each combat round)",
			["the Demonic Lord of Revenge"] = "(Existential Torment)",
			["the Pain Enjoyer"] = "(+X% Muscle, +X% Mysticality, +X% Moxie)",
		}
		for demontext in invokedtext:gmatch("&middot;(.-)<br />") do
			local name, desc = demontext:match("(.-), (.+)")
			demontitles[name] = name .. ", " .. desc
			demons[name] = demondescs[desc] or ""
			table.insert(demonorder, name)
		end
		if not demontitles["Ak'gyxoth"] then
			demontitles["Ak'gyxoth"] = "Ak'gyxoth"
			table.insert(demonorder, "Ak'gyxoth")
		end
		local demonstexttbl = {}
		for _, x in ipairs(demonorder) do
			local link = [[<a href="javascript:void($('input[name=demonname]').val(&quot;]]..x..[[&quot;))" style="color: green">]]..demontitles[x]..[[</a>]]
			table.insert(demonstexttbl, [[<tr><td>&middot;</td><td>{ ]]..link..[[ }</td><td>]]..demons[x]..[[</td></tr>]])
		end
		text = text:gsub(">One of them asks you the name of the Demon you would summon.<", function(x)
			return x .. [[br><br><span style="color: green">You know about the following demons:</span><br><table style="color: green">]]..table.concat(demonstexttbl)..[[</table><]]
		end)
	end
end)

function add_on_the_trail_warning(zone, monster)
	add_warning {
		message = "You are on the trail of another monster when you might want to sniff a " .. monster .. ".",
		type = "warning",
		zone = zone,
		check = function()
			if not have_buff("On the Trail") then return end
			return retrieve_trailed_monster() ~= monster
		end,
	}
end
