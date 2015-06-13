local quarters_junk = { "green clay bead", "purple clay bead", "pink clay bead", "communications windchimes" }

local quarters_all = {
	"bullet-proof corduroys",
	"communications windchimes",
	"didgeridooka",
	"fire poi",
	"flowing hippy skirt",
	"Gaia beads",
	"green clay bead",
	"hippy medical kit",
	"hippy protest button",
	"lead pipe",
	"Lockenstock&trade; sandals",
	"pink clay bead",
	"purple clay bead",
	"reinforced beaded headband",
	"round green sunglasses",
	"round purple sunglasses",
	"wicker shield",
}

local dimes_junk = { "white class ring", "blue class ring", "red class ring", "PADL Phone" }

local dimes_all = {
	"beer bong",
	"beer helmet",
	"bejeweled pledge pin",
	"blue class ring",
	"bottle opener belt buckle",
	"distressed denim pants",
	"Elmley shades",
	"energy drink IV",
	"giant foam finger",
	"keg shield",
	"kick-ass kicks",
	"PADL Phone",
	"perforated battle paddle",
	"red class ring",
	"war tongs",
	"white class ring",
}

function turn_in_war_items(campid, what)
	local itemlists = {
		junk1 = dimes_junk,
		all1 = dimes_all,
		junk2 = quarters_junk,
		all2 = quarters_all,
	}
	local turnins = {}
	for _, x in ipairs(itemlists[what..campid]) do
		if have_item(x) then
			table.insert(turnins, { whichitem = get_itemid(x), quantity = count_item(x) })
		end
	end
	for _, x in ipairs(turnins) do
		async_get_page("/bigisland.php", { action = "turnin", pwd = session.pwd, whichcamp = campid, whichitem = x.whichitem, quantity = x.quantity })
	end
	return get_page("/bigisland.php", { place = "camp", whichcamp = campid })
end

local turn_in_war_items_href = add_automation_script("turn-in-war-items", function()
	return turn_in_war_items(params.campid, params.what)
end)

add_printer("/bigisland.php", function()
	if not setting_enabled("automate simple tasks") then return end
	if params.place == "camp" and text:contains([[value="turnin"]]) then
		local junk_href = turn_in_war_items_href { pwd = session.pwd, campid = tonumber(params.whichcamp), what = "junk" }
		local all_href = turn_in_war_items_href { pwd = session.pwd, campid = tonumber(params.whichcamp), what = "all" }
		text = text:gsub([["Turn it in"></form>]], [[%0<p><a href="]] .. junk_href .. [[" style="color: green">{ Turn in junk }</a><a href="]] .. all_href .. [[" style="color: green">{ Turn in all }</a></p>]])
	end
end)

--[[
-- add this?
add_automator("/fight.php", function()
 if ascension automation assistance
  if won battlefield fight
   turn in junk
end)
--]]
