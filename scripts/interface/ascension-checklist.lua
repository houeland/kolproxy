function ascension_checklist_get_questitem_text()
	ordered_items = {}
	local quest_items = {}
	table.insert(quest_items, { name = "map to Vanya's Castle", link = "Remember to kill Vanya's Creature [map to Vanya's Castle]" })
	for x in table.values { "Boris's key", "Jarlsberg's key", "Sneaky Pete's key", "digital key", "Richard's star key" } do
		table.insert(quest_items, { name = x, link = [[<a href="#" onclick="cook_key(this, ]]..get_itemid(x)..[[); return false;" style="color: green;">Cook ]] .. x })
	end
	for x in table.values { "Map to Safety Shelter Grimace Prime", "Dolphin King's map", "Dr. Hobo's map" } do
		table.insert(quest_items, { name = x, link = "Use " .. x })
	end
	for x in table.values(quest_items) do
		if have_item(x.name) then
			table.insert(ordered_items, [[<tr><td>]] .. x.link .. [[</td></tr>]])
		end
	end
	if not next(ordered_items) then
		return ""
	else
		return [[
<h2>Unhandled quest items</h2>
<table style="border: 1px solid black; padding: 5px; margin: 5px">
<tr><th>Item</th></tr>
<tbody>]] .. table.concat(ordered_items) .. [[
</tbody>
</table>
]]
	end
end

function ascension_checklist_get_other_tasks_text()
	local todo = {}
	if pvpfights() > 0 then
		table.insert(todo, [[
<h2>PvP fights</h2>
You have ]]..pvpfights()..[[ fights remaining today.
]])
	end
	local campgroundpt = get_page("/campground.php")
	for x in campgroundpt:gmatch("<a.-</a>") do
		if x:contains("action=garden") then
			table.insert(todo, [[
<h2>Campsite garden</h2>
Your garden contains: ]] .. x:match([[title="(.-)"]]))
		end
	end
	return table.concat(todo, "\n")
end

local cook_key_href = add_automation_script("custom-ascension-checklist-cook-key-lime", function()
	local whichitem = tonumber(params.whichitem)
	if whichitem and have_inventory_item(whichitem) then
		if not have_item("lime") then
			pull_storage_item("lime")
		end
		return cook_items(whichitem, "lime")()
	else
		critical "Invalid item."
	end
end)

local function do_retrieve_items(what)
	local items = {}
	local json = get_page("/api.php", { what = what, ["for"] = "Kolproxy by Eleron (from Lua script)", format = "json" })
	for x, y in pairs(json_to_table(json)) do
		local name = maybe_get_itemname(tonumber(x))
		if name then
			items[name] = tonumber(y)
		end
	end
	return items
end

function retrieve_all_item_locations()
	return do_retrieve_items("inventory"), do_retrieve_items("storage"), do_retrieve_items("closet")
end

local href = add_automation_script("custom-ascension-checklist", function()
	pt = [[
<!DOCTYPE html>
<html>
<head>
<title>kolproxy ascension checklist</title>
<link rel="stylesheet" type="text/css" href="http://images.kingdomofloathing.com/styles.css">
<style type="text/css">
td {
	padding: 2px 5px;
}
.extralocation { display: none }
.cantransfer { display: none }
</style>
<script type="text/javascript" src="http://images.kingdomofloathing.com/scripts/jquery-1.3.1.min.js"></script>
<script type="text/javascript">
	function cook_key_result(link, pagetext) {
		if (pagetext.match(/You acquire/)) {
			link.style.color = 'gray';
		} else {
			link.style.color = 'red';
		}
	}
	function cook_key(link, itemid) {
		]] .. cook_key_href { pwd = session.pwd, __raw__whichitem = "itemid", make_jquery = "type: 'POST', success: function(retdata) { cook_key_result(link, retdata) }" } .. [[

	}
</script></head>
<body>
]] .. ascension_checklist_get_questitem_text() .. [[
]] .. ascension_checklist_get_other_tasks_text() .. [[
<br>
(<a href="ascend.php">Back to ascending</a>)
</body></html>]]
	return pt, requestpath
end)

add_printer("/ascend.php", function()
	text = text:gsub("Are you ready to take the plunge%?", [[%0 <a href="]] .. href { pwd = session.pwd } .. [[" style="color: green">{ View pre-ascension checklist }</a>]])
end)
