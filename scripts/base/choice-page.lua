local function build_spoiler(input, to)
	local disable = false
	local is_good = false
	local spoiler = ""
	
	if type(to) == "function" then
		ok, to = pcall(to)
	end
	
	if type(to) == "string" then
		spoiler = to
	elseif type(to) == "table" then
		local newtext = ""
		if to.text then
			newtext = to.text
		end
		if to.leave_noturn then
			newtext = "Leave (does not cost an adventure)"
		end
		if to.good_choice then
			is_good = true
		end
		local itemtext
		if to.getitem then
			if type(to.getitem) == "string" then
				itemtext = tostring(to.getitem) .. " [" .. count_inventory_item(to.getitem) .. " in inventory]"
			elseif type(to.getitem) == "table" then
				local itemtbl = {}
				for _, x in ipairs(to.getitem) do
					table.insert(itemtbl, tostring(x) .. " [" .. count_inventory_item(tostring(x)) .. " in inventory]")
				end
				itemtext = table.concat(itemtbl, " + ")
			end
			if newtext == "" then
				newtext = "Get " .. itemtext
			else
				newtext = newtext .. ", get " .. itemtext
			end
		end
		if to.countitem then
			if type(to.countitem) == "string" then
				itemtext = " [" .. count_inventory_item(to.countitem) .. " in inventory]"
			elseif type(to.countitem) == "table" then
				local itemtbl = {}
				for _, x in ipairs(to.countitem) do
					table.insert(itemtbl, count_inventory_item(x))
				end
				itemtext = " [" .. table.concat(itemtbl, " + ") .. " in inventory]"
			end
			newtext = newtext .. itemtext
		end
		if to.getmeat then
			if newtext == "" then
				if to.getmeat > 0 then
					newtext = "Gain " .. tostring(to.getmeat) .. " meat"
				else
					newtext = "Lose " .. tostring(-to.getmeat) .. " meat"
				end
			else
				if to.getmeat > 0 then
					newtext = newtext .. ", gain " .. tostring(to.getmeat) .. " meat"
				else
					newtext = newtext .. ", lose " .. tostring(-to.getmeat) .. " meat"
				end
			end
		end
		if to.getmeatmin and to.getmeatmax then
			if newtext == "" then
				newtext = "Gain " .. tostring(to.getmeatmin) .. "-" .. tostring(to.getmeatmax) .. " meat"
			else
				newtext = newtext .. ", gain " .. tostring(to.getmeatmin) .. "-" .. tostring(to.getmeatmax) .. " meat"
			end
		end
		if to.disabled then
			disable = true
		end
		spoiler = newtext
	end
	if spoiler ~= "" then
		if is_good then
			spoiler = "<b>" .. spoiler .. "</b>"
		end
		spoiler = "<br>" .. spoiler
	end
	if disable then
		return input:gsub(">", [[ disabled="disabled" style="color: gray">]]) .. [[<span style="color: gray">]] .. spoiler .. [[</span>]]
	else
		return input .. spoiler
	end
end

local function build_spoilers_by_name(tbl)
	return text:gsub([[<input[^>]+>]], function(input)
		local title = input:match([[value="([^>]+)"]])
		local number = tonumber(input:match([[value=([0-9]+)]]))
		local spoiler
		if title and input:contains("submit") then
			spoiler = tbl[title]
		end
		return build_spoiler(input, spoiler)
	end)
end

local function build_spoilers_by_number(tbl)
	local newtbl = {}
	for x, y in pairs(parse_choice_options(text)) do
		if tbl[y] then
			newtbl[x] = [[<span style="color: gray;">Fallback spoiler: ( ]] .. tbl[y] .. [[ )</span>]]
		end
	end
	return build_spoilers_by_name(newtbl)
end

function do_choice_page_printing(text, title, adventure_title, choice_adventure_number)

-- TODO: do with add_printer
if (title == "The Elements of Surprise . . .") then
	local function set_slot(text, slot, choose)
		local pre, choices, post = text:match("(.*)(<select name=\""..slot.."\">%s*<option value=\"\"> .. Choose an Element .. </option>%s*<option>cold</option>%s*<option>hot</option>%s*<option>sleaze</option>%s*<option>spooky</option>%s*<option>stench</option>%s*</select>)(.*)")
		if (pre ~= nil) then
			choices = choices:gsub("<option>"..choose.."</option>", "<option selected=\"selected\">"..choose.."</option>")
			text = pre .. choices .. post
		end
		return text
	end
	text = set_slot(text, "slot1", "sleaze")
	text = set_slot(text, "slot2", "spooky")
	text = set_slot(text, "slot3", "stench")
	text = set_slot(text, "slot4", "cold")
	text = set_slot(text, "slot5", "hot")
end

--print("noncombat: {"..tostring(adventure_title).."} (" .. tostring(choice_adventure_number) .. ")")

local found_function = false
local spoilers_tbl = get_noncombat_choice_spoilers((adventure_title or ""):gsub(" %(#[0-9]*%)$", ""))
if spoilers_tbl then
	for a, data in pairs(spoilers_tbl) do
		local tbl
		found_function = true
		if type(data) == "table" then
			tbl = data
		elseif type(data) == "function" then
			tbl = data()
		end
		local build_spoilers = build_spoilers_by_name
		if tbl[1] then
			print("ERROR: Building spoilers by number for", adventure_title)
			print("ERROR: This should not happen!")
			-- assume array-like table
			build_spoilers = build_spoilers_by_number
		end
		text = build_spoilers(tbl)
	end
elseif choice_adventure_number ~= nil then
--	print("fallback for", adventure_title, choice_adventure_number)
	local isok, spoilers = pcall(function()
		return datafile("choice spoilers")
	end)
	if isok and spoilers["choiceid:"..tostring(choice_adventure_number)] and choice_adventure_number ~= 546 then -- 546 is Vamping Out, the fallback source doesn't actually explain anything there and is just wrong
--		print("got", spoilers["choiceid:"..tostring(choice_adventure_number)])
		text = build_spoilers_by_number(spoilers["choiceid:"..tostring(choice_adventure_number)])
	end
end

if show_dev_info() and found_function == false and adventure_title ~= nil and adventure_title ~= "Results:" then
	print("add_choice_text(\""..adventure_title.."\", { -- choice adventure number: " .. tostring(choice_adventure_number))
	for x, y in pairs(parse_choice_options(text)) do
		print([[	["]]..x..[["] = { text = "" },]])
	end
	print("})")
end

return text

end

function parse_choice_options(pt)
	local options = {}
	for form in pt:gmatch("<form.-</form>") do
		local titles = {}
		local numbers = {}
		for input in form:gmatch("<input[^>]+>") do
			local title = input:match([[value="(.-)"]])
			local number = tonumber(input:match([[value="?([0-9]+)"?]]))
			if title and input:contains("submit") then
				table.insert(titles, title)
				local simpletitle = title:gsub(" %[.*%]$", "")
				if simpletitle ~= title then
					table.insert(titles, simpletitle)
				end
			end
			if number and input:contains("option") then
				table.insert(numbers, number)
			end
		end
		for _, title in ipairs(titles) do
			for _, number in ipairs(numbers) do
				options[title] = number
			end
		end
	end
	return options
end

add_printer("all pages", function()
	if choice_adventure_number or path == "/choice.php" then
		text = do_choice_page_printing(text, title, adventure_title, choice_adventure_number)
	end
end)
