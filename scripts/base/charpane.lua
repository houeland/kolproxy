local familiar_counters = {}
local infolines = {}
local values = {}
local fam_values = {}

function reset_charpane_values()
	familiar_counters = {}
	infolines = {}
	values = {}
	fam_values = {}
end

local charpane_line_functions = {}
function add_charpane_line(f)
	table.insert(charpane_line_functions, f)
end

function run_charpane_line_functions()
	local values = {}
	for _, f in ipairs(charpane_line_functions) do
		local lines = f()
		if not lines then
			lines = {}
		elseif lines.value or lines.compactvalue or lines.normalvalue then
			lines = { lines }
		end
		for _, x in ipairs(lines) do
			x.__charpane_line_function = true
			table.insert(values, x)
		end
	end
	return values
end

function print_charpane_value(value)
	table.insert(values, value)
end

function print_familiar_value(value)
	table.insert(fam_values, value)
end

function print_familiar_counter(compact, normal)
	if text:contains("<!-- charpane compact") or (using_kolproxy_quick_charpane and kolproxy_custom_charpane_mode == "compact") then
		table.insert(familiar_counters, compact)
	else
		table.insert(familiar_counters, normal)
	end
end

function print_charpane_infoline(compact, normal)
	if text:contains("<!-- charpane compact") or (using_kolproxy_quick_charpane and kolproxy_custom_charpane_mode == "compact") then
		table.insert(infolines, compact)
	else
		table.insert(infolines, normal)
	end
end

function print_charpane_lines(text)
	if text:contains("http://images.kingdomofloathing.com/otherimages/inf_small.gif") then return end
	--if not setting_enabled("show charpane lines") then return end

	for y in table.values(familiar_counters) do table.insert(fam_values, { value = y }) end
	for y in table.values(infolines) do table.insert(fam_values, { value = y }) end

	-- TODO: redo and merge these
	for y in table.values(fam_values) do
		local ct = y.normalvalue or y.value or "{nil}"
		if (using_kolproxy_quick_charpane and kolproxy_custom_charpane_mode == "compact") or text:contains("<!-- charpane compact") then
			ct = y.compactvalue or y.value or "{nil}"
		end

		local style = ""
		if y.color then
			style = [[ style="color: ]] .. y.color .. [["]]
		end

		if y.tooltip then
			ct = [[<span title="]] .. y.tooltip .. [["]] .. style .. ">" .. ct .. "</span>"
		else
			ct = "<span" .. style .. ">" .. ct .. "</span>"
		end

		if using_kolproxy_quick_charpane then
			text = text:gsub("(<!%-%- kolproxy charpane familiar text area %-%->)", function(one) return "<br>" .. ct .. one end)
		elseif text:contains("<!-- charpane compact") then -- compact mode
			if text:match("</table>(<!%-%- charpane compact familiar text space type%b{} weight%b{} %-%->)") then
				text = text:gsub("(<!%-%- charpane compact familiar text space type%b{} weight%b{} %-%->)", function(one) return ct .. one end)
			else
				text = text:gsub("(<!%-%- charpane compact familiar text space type%b{} weight%b{} %-%->)", function(one) return "<br>" .. ct .. one end)
			end
		else
			text = text:gsub("(<!%-%- charpane normal familiar text space type%b{} weight%b{} %-%->)", function(one) return [[<tr><td colspan="2"><center><font size="2">]] .. ct .. "</font></center></td></tr>" .. one end)
		end
	end

	if using_kolproxy_quick_charpane then
		for y in table.values(values) do
			local name = y.normalname or y.name or "{nil}"
			local value = y.normalvalue or y.value or "{nil}"
			if kolproxy_custom_charpane_mode == "compact" then
				name = y.compactname or y.name or "{nil}"
				value = y.compactvalue or y.value or "{nil}"
			end
			local ct_pre = name
			local ct_value = "<b>" .. value .. "</b>"
			local style = ""
			if y.color then
				style = [[ style="color: ]] .. y.color .. [["]]
			end
			if y.link then
				ct_pre = [[<a target="mainpane" href="]] .. y.link .. [["]] .. style .. [[>]] .. name .. [[</a>]]
				if not y.link_name_only then
					ct_value = [[<a target="mainpane" href="]] .. y.link .. [["]] .. style .. [[><b>]] .. value .. [[</b></a>]]
				end
			end
			if kolproxy_custom_charpane_mode == "compact" then
				if not y.__charpane_line_function then
					local ct = ct_pre .. ": " .. ct_value
					if y["tooltip"] then
						ct = [[<span title="]] .. y["tooltip"] .. [["]] .. style .. ">" .. ct .. "</span>"
					else
						ct = "<span" .. style .. ">" .. ct .. "</span>"
					end
					text = text:gsub("(<!%-%- kolproxy charpane text area %-%->)", function(one) return "<br>" .. ct .. one end)
				end
			else
				local tr = [[<tr]] .. style .. [[><td align=right>]] .. ct_pre .. [[:</td><td>]] .. ct_value .. [[</td></tr>]]
				if y["tooltip"] then
					tr = [[<tr title="]] .. y["tooltip"] .. [["]] .. style .. [[><td align=right>]] .. ct_pre .. [[:</td><td>]] .. ct_value .. [[</td></tr>]]
				end
				if not text:contains("kolproxy value printing area") then
					text = text:gsub("(<!%-%- kolproxy charpane text area %-%->)", function(one) return one .. [[
<font size="2">
<table align="center">
<!-- kolproxy value printing area -->
</table>
</font>
]] end)
				end
				text = text:gsub("(<!%-%- kolproxy value printing area %-%->)", function(one) return tr .. one end)
			end
		end
	elseif text:contains("<!-- charpane compact") then -- compact mode
		for x,y in pairs(values) do
			local name = y.compactname or y.name or "{nil}"
			local value = y.compactvalue or y.value or "{nil}"
			local ct = "<td align=right>" .. name .. ":</td><td align=left><b>" .. value .. "</b></td>"
			local style = ""
			if y["color"] then
				style = [[ style="color: ]] .. y["color"] .. [["]]
			end
			if y.link then
				ct = [[<td align=right><a target="mainpane" href="]] .. y["link"] .. [["]] .. style .. [[>]] .. name .. [[</a>:</td><td align=left><a target="mainpane" href="]] .. y["link"] .. [["]] .. style .. [[><b>]] .. value .. [[</b></a></td>]]
			end
			if y["tooltip"] then
				ct = "<tr title=\"" .. y["tooltip"] .. "\"" .. style .. ">" .. ct .. "</tr>"
			else
				ct = "<tr" .. style .. ">" .. ct .. "</tr>"
			end
			text = text:gsub("(<!%-%- charpane compact text space %-%->)", function(one) return ct .. one end)
		end
	else -- normal mode
		for x, y in pairs(values) do
			local name = y.normalname or y.name or "{nil}"
			local value = y.normalvalue or y.value or "{nil}"
			local nt = [[<font size="2">]] .. name .. ": <b>" .. value .. "</b></font>"
			local style = ""
			if y.color then
				style = [[ style="color: ]] .. y.color .. [["]]
			end
			if y.link then
				nt = [[<font size="2"><a target="mainpane" href="]] .. y.link .. [["]] .. style .. [[>]] .. name .. [[: <b>]] .. value .. [[</b></a></font>]]
			end
			if y.tooltip then
				nt = [[<span title="]] .. y.tooltip .. [["]] .. style .. ">" .. nt .. "</span>"
			else
				nt = "<span" .. style .. ">" .. nt .. "</span>"
			end
			text = text:gsub("(<!%-%- charpane normal text space %-%->)", function(one) return nt .. "<br>" .. one end)
		end
	end
	return text
end
