local tracked_variables_f = {}

function add_tracked_variables_display(which, f)
	table.insert(tracked_variables_f, { f = f, which = which })
end

local href = add_automation_script("display-tracked-variables", function()
	local asctbl = {}
	local daytbl = {}

	table.insert(asctbl, { title = "Fortune cookie number turncounts", value = ascension["fortune cookie numbers"] })
-- Last semirare?
	table.insert(asctbl, { title = "Manor quartet song", value = ascension["zone.manor.quartet song"] })
	table.insert(asctbl, { title = "Ballroom dance card turncount", value = ascension["dance card turn"] })
	table.insert(asctbl, { title = "Number of pirate insults", value = #(ascension["zone.pirates.insults"] or {}) })
	table.insert(asctbl, { title = "Island war arena ML progress", value = string.format("Frat = %d, Hippy = %d", ascension["zone.island.frat arena flyerML"] or 0, ascension["zone.island.hippy arena flyerML"] or 0) })
-- Battlefield kills?

	for _, x in ipairs(sugar_sheet_items) do
		local v = ascension["sugar sheet." .. x .. ".fights used"]
		if v then
			table.insert(asctbl, { title = "Fights using " .. x, value = v })
		end
	end

	for _, x in ipairs(tracked_variables_f) do
		local v = x.f()
		if not v then
		elseif x.which == "ascension" then
			table.insert(asctbl, v)
		elseif x.which == "day" then
			table.insert(daytbl, v)
		end
	end

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

--	text = [[Unfortunately, there are some parts of the game status that are not possible to check, and you have to remember them. The game only tells you once when it happens, and doesn't have a page you can look at later to figure it out.<br>
--<br>
--Kolproxy tracks some of these hidden game variables, and this page lets you get a partial view of the game status all gathered in one place. (In the future this page will become more complete, and will probably also include on the same page some types of game status that we can actually be sure about, where the game server lets us check. Or it could be split into two different kinds of pages, one with raw information, and one that's helpful as a kind of checklist.)<br>
--<br>]]
	text = get_table_display_text(asctbl, "Ascension") .. "<br>" .. get_table_display_text(daytbl, "Day")
	return "Note: Work in progress<br><br>" .. text, requestpath
end)
