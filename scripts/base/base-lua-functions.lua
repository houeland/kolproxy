pretty_print_tables = true

table_to_json = tojson
json_to_table = fromjson

if string then
	function string.contains(a, b) return not not a:find(b, 1, true) end
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

	local function deepcopy(t)
		if type(t) ~= "table" then return t end
		local mt = getmetatable(t)
		local res = {}
		for k, v in pairs(t) do
			res[k] = deepcopy(v)
		end
		setmetatable(res, mt)
		return res
	end

	table.copy = deepcopy

	function table.sum(tbl)
		local sum = 0
		for _, x in pairs(tbl) do
			sum = sum + x
		end
		return sum
	end

	function table.avg(tbl)
		local sum = 0
		local count = 0
		for _, x in pairs(tbl) do
			sum = sum + x
			count = count + 1
		end
		return sum / count
	end

	function table.map(tbl, f)
		local new_tbl = {}
		for x, y in pairs(tbl) do
			new_tbl[x] = f(y)
		end
		return new_tbl
	end

	function table.map_keys(tbl, f)
		local new_tbl = {}
		for x, y in pairs(tbl) do
			new_tbl[f(x)] = y
		end
		return new_tbl
	end
end

if math then
	function math.minmax(min, x, max)
		if x > max then
			return max
		elseif x < min then
			return min
		else
			return x
		end
	end

	function math.sign(x)
		x = tonumber(x)
		if not x then
			return 0
		elseif x < 0 then
			return -1
		else
			return 1
		end
	end
end

if debug then
	function debug.callsitedesc()
		local dgi = debug.getinfo(3)
		return dgi.short_src .. ":" .. dgi.currentline
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
	function pretty_tostring(x)
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
	tostring = pretty_tostring
end

-- TODO: remove?
local function parse_params_raw(str)
	local tbl = parse_request_param_string(str)
	if #tbl == 0 then
		return nil
	else
		return tbl
	end
end

function get_allparams_keyvaluetbl()
	return parse_params_raw(input_params)
end

function make_resubmit_href()
	return raw_make_href(requestpath, get_allparams_keyvaluetbl())
end

-- TODO: remove?
function parse_params(str)
	local rawtbl = parse_params_raw(str)
	local tbl = {}
	for x in table.values(rawtbl or {}) do
		tbl[x.key] = x.value
	end
	return tbl
end

-- TODO: put in table.XYZ
function random_choice(tbl)
	return tbl[math.random(1, #tbl)]
end

-- TODO: deprecate, use round_down string version instead for explicit length
function floor_to_places(value, places)
	return math.floor(value * math.pow(10, places)) / math.pow(10, places)
end

-- TODO: combine some of this number formatting?
function format_integer(i)
	if i >= 1000 then
		local upper = math.floor(i / 1000)
		return format_integer(upper) .. "," .. string.format("%03d", i - upper * 1000)
	else
		return i
	end
end

function round_down(value, places)
	-- TODO: handle places == 0
	-- TODO: handle places >= 10
	return string.format("%s.%0" .. places .. "d", math.floor(value), math.floor((value - math.floor(value)) * math.pow(10, places)))
end

function make_plural(v, singular, plural)
	if v == 1 then
		return string.format("%d %s", v, singular)
	else
		return string.format("%d %s", v, plural)
	end
end

function display_number_8k_2M(n)
	if n >= math.huge then
		return tostring(n)
	elseif n <= 8000 then
		if n == math.floor(n) then
			return string.format("%d", n)
		else
			return string.format("%.1f", n)
		end
	elseif n <= 2000000 then
		return string.format("%.1fk", n / 1000)
	else
		return string.format("%.1fM", n / 1000000)
	end
end

function display_number_10k_10M(n)
	if n >= math.huge then
		return tostring(n)
	elseif n < 10000 then
		return tostring(n)
	elseif n < 10000000 then
		return string.format("%dk", n / 1000)
	else
		return string.format("%dM", n / 1000000)
	end
end

function display_number_3figs(n)
	if n >= math.huge then
		return tostring(n)
	elseif n < 1000 then
		return tostring(n)
	elseif n < 9995 then
		return string.format("%.2fk", n / 1000)
	elseif n < 99950 then
		return string.format("%.1fk", n / 1000)
	elseif n < 999500 then
		return string.format("%.0fk", n / 1000)
	elseif n < 9995000 then
		return string.format("%.2fM", n / 1000000)
	elseif n < 99950000 then
		return string.format("%.1fM", n / 1000000)
	else
		return string.format("%.0fM", n / 1000000)
	end
end

function display_number_9k_90k(n)
	if n >= math.huge then
		return tostring(n)
	elseif n < 1000 then
		if n == math.floor(n) then
			return string.format("%d", n)
		else
			return string.format("%.1f", n)
		end
	elseif n < 10*1000 then
		return string.format("%.1fk", n / 1000)
	elseif n <= 1000*1000 then
		return string.format("%.0fk", n / 1000)
	elseif n <= 10*1000*1000 then
		return string.format("%.1fM", n / 1000000)
	elseif n <= 1000*1000*1000 then
		return string.format("%.0fM", n / 1000000)
	elseif n <= 10*1000*1000*1000 then
		return string.format("%.1fG", n / 1000000000)
	else
		return string.format("%.0fG", n / 1000000000)
	end
end

display_number = display_number_9k_90k

function display_signed_integer(n)
	if n < 0 then
		return "-" .. display_number(math.floor(-n + 0.5))
	else
		return "+" .. display_number(math.floor(n + 0.5))
	end
end

function display_value(v)
	if type(v) == "number" then
		return display_number(v)
	else
		return v
	end
end
