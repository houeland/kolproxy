local function build_spoiler(pre, value, to)
	local disable = false
	local is_good = false
	local spoiler = ""
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
				itemtext = tostring(to.getitem) .. " [" .. count_inventory(to.getitem) .. " in inventory]"
			elseif type(to.getitem) == "table" then
				local itemtbl = {}
				for _, x in ipairs(to.getitem) do
					table.insert(itemtbl, tostring(x) .. " [" .. count_inventory(tostring(x)) .. " in inventory]")
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
				itemtext = " [" .. count_inventory(to.countitem) .. " in inventory]"
			elseif type(to.countitem) == "table" then
				local itemtbl = {}
				for _, x in ipairs(to.countitem) do
					table.insert(itemtbl, count_inventory(x))
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
--~ 					newtext = "item[" .. tostring(to.getitem) .. "] meat[" .. tostring(to.getmeat) .. "]"

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
		return pre .. value .. [[" disabled="disabled" style="color: gray"><span style="color: gray">]] .. spoiler .. [[</span>]]
	else
		return pre .. value .. [[">]] .. spoiler
	end
end

local function build_spoilers_by_name(tbl)
	return text:gsub([[(<input class=button type=submit value=")([^"]-)">]], function(pre, value)
		local spoiler = tbl[value]
		return build_spoiler(pre, value, spoiler)
	end)
end

local function build_spoilers_by_number(tbl)
	return text:gsub([[(<input type=hidden name=option value=(%d+)><input class=button type=submit value=")([^"]-)">]], function(pre, option, value)
		local spoiler = tbl[tonumber(option)]
		return build_spoiler(pre, value, spoiler)
	end)
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
			-- assume array-like table
			build_spoilers = build_spoilers_by_number
		end
		text = build_spoilers(tbl)
	end
elseif choice_adventure_number ~= nil then
	print("fallback for", adventure_title, choice_adventure_number)
	local isok, spoilers = pcall(function()
		return datafile("choice spoilers")
	end)
	if isok and spoilers["choiceid:"..tostring(choice_adventure_number)] and choice_adventure_number ~= 546 then -- 546 is Vamping Out, the fallback source doesn't actually explain anything there and is just wrong
		print("got", spoilers["choiceid:"..tostring(choice_adventure_number)])
		text = text:gsub([[(<input type=hidden name=option value=)([0-9]+)(>)(<input class=button type=submit value=")([^"]-)(")(>)]], function(preopt, opt, postopt, pre, value, between, post)
			local s = spoilers["choiceid:"..tostring(choice_adventure_number)][tonumber(opt)]
			if s then
				local spoiler = [[<br><span style="color: gray;">Fallback spoiler: ( ]] .. s .. [[ )</span>]]
				return preopt .. opt .. postopt .. pre .. value .. between .. post .. spoiler
			end
		end)
	end
end

if found_function == false and adventure_title ~= nil and adventure_title ~= "Results:" then
	print("add_choice_text(\""..adventure_title.."\", { -- choice adventure number: " .. tostring(choice_adventure_number))
	for x in text:gmatch([[<input class=button type=submit value="([^"]-)">]]) do
		print([[	["]]..x..[["] = { text = "" },]])
	end
	print("})")
end

return text

end
