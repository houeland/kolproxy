local href = add_automation_script("display-tracked-variables", function()
	local asctbl = {}
	local daytbl = {}

	table.insert(asctbl, { title = "Fortune cookie number turncounts", value = ascension["fortune cookie numbers"] })
-- Last semirare?
	table.insert(asctbl, { title = "Manor quartet song", value = ascension["zone.manor.quartet song"] })
	table.insert(asctbl, { title = "Ballroom dance card turncount", value = ascension["dance card turn"] })
	table.insert(asctbl, { title = "Number of pirate insults", value = table.maxn(ascension["zone.pirates.insults"] or {}) })
	table.insert(asctbl, { title = "Island war arena ML progress", value = string.format("Frat = %d, Hippy = %d", ascension["zone.island.frat arena flyerML"] or 0, ascension["zone.island.hippy arena flyerML"] or 0) })
-- Battlefield kills?

	for _, x in ipairs(sugar_sheet_items) do
		local v = ascension["sugar sheet." .. x .. ".fights used"]
		if v then
			table.insert(asctbl, { title = "Fights using " .. x, value = v })
		end
	end

	table.insert(daytbl, { title = "Nanorhino banished monster", value = day["nanorhino banished monster"] })
-- Familiar item drops?

	local function get_table_display_text(tbl, title)
		local lines = {}
		table.insert(lines, "<table>")
		for _, x in ipairs(tbl) do
			local value = [[<i>&lt;none&gt;</i>]]
			if x.value then
				if type(x.value) == "table" then
					value = "<tt>" .. table_to_json(x.value) .. "</tt>"
				else
					value = "<tt>" .. x.value .. "</tt>"
				end
			end
			table.insert(lines, string.format([[<tr><td>%s:</td><td>%s</td></tr>]], x.title, value))
		end
		table.insert(lines, "</table>")
		return make_kol_html_frame(table.concat(lines, "\n"), title)
	end

	text = [[Unfortunately, there are some parts of the game status that are not possible to check, and you have to remember them. The game only tells you once when it happens, and doesn't have a page you can look at later to figure it out.<br>
<br>
Kolproxy tracks some of these hidden game variables, and this page lets you get a partial view of the game status all gathered in one place. (In the future this page will become more complete, and will probably also include on the same page some types of game status that we can actually be sure about, where the game server lets us check. Or it could be split into two different kinds of pages, one with raw information, and one that's helpful as a kind of checklist.)<br>
<br>]] .. get_table_display_text(asctbl, "Ascension") .. "<br>" .. get_table_display_text(daytbl, "Day")
	return "Note: Work in progress, currently missing an interface<br><br>" .. text, requestpath
end)
