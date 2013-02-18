pretty_print_tables = true

if string then
	function string.contains(a, b) return a:find(b, 1, true) end
end

if table then
	function table.values(tbl) -- TODO: this doesn't necessarily iterate in order, but we're using it like that?!?
		local idx = nil
		local value = nil
		return function()
			idx, value = next(tbl, idx)
			return value
		end
	end

	function table.keys(tbl)
		local keys = {}
		for k, _ in pairs(tbl) do
			table.insert(keys, k)
		end
		table.sort(keys)
		return keys
	end
end

exported_raw_tostring = tostring
local raw_tostring = tostring

if pretty_print_tables then
	local type_ = type
	local stringformat_ = string.format
	local pairs_ = pairs
	local tableinsert_ = table.insert
	local next_ = next
	local tableconcat_ = table.concat
	local loop_tbl = {}
	
	local function pretty_tostring_key(x)
		if type_(x) == "string" then
			return stringformat_("%q", x)
		else
			return raw_tostring(x)
		end
	end
	local function pretty_tostring_value(x)
		if type_(x) == "table" then
			if loop_tbl[x] then
				return raw_tostring(x)
			end
			loop_tbl[x] = true
			local vals = {}
			for a, b in pairs_(x) do
				tableinsert_(vals, stringformat_("[%s] = %s", pretty_tostring_key(a), pretty_tostring_value(b)))
			end
			if next_(vals) then
				return "{ " .. tableconcat_(vals, ", ") .. " }"
			else
				return "{}"
			end
		else
			return pretty_tostring_key(x)
		end
	end
	function tostring(x)
		if type_(x) == "table" then
			loop_tbl = {}
			local vals = {}
			for a, b in pairs_(x) do
				tableinsert_(vals, stringformat_("  [%s] = %s,", pretty_tostring_key(a), pretty_tostring_value(b)))
			end
			return "{\n" .. tableconcat_(vals, "\n") .. "\n}"
		else
			return raw_tostring(x)
		end
	end
end

function encode_thing(x)
	if type(x) == "number" then return tostring(x)
	elseif type(x) == "string" then return string.format("%q", x):gsub("\\\n", "\n")
	elseif type(x) == "boolean" then
		if x == true then
			return "True"
		else
			return "False"
		end
	elseif type(x) == "table" then
		return table_to_str(x)
	else
		error("Unhandled encode_thing(" .. type(x) .. ")")
	end
end

local function decode_string(x) -- TODO-future: can this be done in a better way?
	local f = loadstring("return " .. x)
	if f then
		return f()
	else
		return nil
	end
end

local function decode_thing(x)
	local num = tonumber(x)
	if num then return num end
	if x == "True" then return true end
	if x == "False" then return false end
-- 	if x == nil then -- TODO: Hack, it's a bug when this happens
-- 		print("Error decoding string, x = nil")
-- 		return "nil"
-- 	end
	local str = x:match([[^"(.*)"$]]) -- TODO-future: redo these in some other way?
	if str then
		local s = decode_string(x)
		if s then return s end
	end
	local tblstr = x:match([[^(%[.+%])$]]) -- TODO-future: redo these in some other way?
	if tblstr then return str_to_table(tblstr) end
	local eff1, eff2, eff3 = x:match([[^%("(.-)", *([0-9]-), *"(.-)"%)$]])
	if eff1 and eff2 and eff3 then
		return { eff1, eff2, eff3 }
	end
	print("error: can't decode table value", x)
end

function table_to_str(tbl)
	local newtbl = {}
	local keys = {}
	for from, to in pairs(tbl) do
		table.insert(keys, from)
	end
	table.sort(keys)
	for from in table.values(keys) do
		local to = tbl[from]
--~ 		print("tbl["..tostring(from).."] -> "..tostring(to))
		table.insert(newtbl, string.format("(%s, %s)", encode_thing(from), encode_thing(to)))
	end
	return "["..table.concat(newtbl, ", ").."]"
end

function str_to_table(str) -- TODO: redo properly!
	local tbl = {}
-- 	print("str_to_table("..str..")")
-- 		if type(str) ~= "string" then
-- 			print("str_to_table with", type(str), str)
-- 			print(debug.traceback())
-- 		end
	for x in str:gmatch("%b()") do
-- 		print(x)
		local a, b = x:match([[^%(("[^"]*,[^"]*"), *([0-9]+)%)$]]) -- ugly hack for e.g. Go Get 'Em, Tiger!
		if not b then
			a, b = x:match([[^%((.-), *(.+)%)$]]) -- TODO-future: redo regex?
		end
-- 		print("decoding", a, "->", b)
		tbl[decode_thing(a)] = decode_thing(b)
	end
-- 	print("returning", tbl)
	return tbl
end

function parse_params_raw(str)
	local tbl = parse_request_param_string(str)
	if table.maxn(tbl) == 0 then
		return nil
	else
		return tbl
	end
end

function parse_params(str)
	local rawtbl = parse_params_raw(str)
	local tbl = {}
	for x in table.values(rawtbl or {}) do
		tbl[x.key] = x.value
	end
	return tbl
end

function random_choice(tbl)
	return tbl[math.random(1, table.maxn(tbl))]
end

function floor_to_places(value, places)
	return math.floor(value * math.pow(10, places)) / math.pow(10, places)
end

function format_integer(i)
	if i >= 1000 then
		local upper = math.floor(i / 1000)
		return format_integer(upper) .. "," .. string.format("%03d", i - upper * 1000)
	else
		return i
	end
end

function round_down(value, places)
	return string.format("%s.%0" .. places .. "d", math.floor(value), math.floor((value - math.floor(value)) * math.pow(10, places)))
end

function make_plural(v, singular, plural)
	if v == 1 then
		return string.format("%d %s", v, singular)
	else
		return string.format("%d %s", v, plural)
	end
end

function display_number(n)
	if n <= 8000 then
		return tostring(n)
	elseif n <= 2000000 then
		return string.format("%.1fk", n / 1000)
	else
		return string.format("%.1fM", n / 1000000)
	end
end

function display_value(v)
	if type(v) == "number" then
		return display_number(v)
	else
		return v
	end
end
