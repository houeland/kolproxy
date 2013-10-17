--~ function get_request_state(name) return get_state("request", name) end
function get_fight_state(name) return get_state("fight", name) end
function get_session_state(name) return get_state("session", name) end
function get_day_state(name) return get_state("day", name) end
function get_ascension_state(name, value) return get_state("ascension", name) end
function get_character_state(name) return get_state("character", name) end

--~ function set_request_state(name, value) set_state("request", name, value) end
function set_fight_state(name, value) set_state("fight", name, value) end
function set_session_state(name, value) set_state("session", name, value) end
function set_day_state(name, value) set_state("day", name, value) end
function set_ascension_state(name, value) set_state("ascension", name, value) end
function set_character_state(name, value) error("No set_character_state from Lua") end



local function setup_state_table(getf, setf)
	local tbl = {}
	setmetatable(tbl, { __index = function(t, k)
		local function parse_value(v)
			if v == "" then return nil end
			local pref = v:sub(1, 1)
			if pref == "{" then
				return json_to_table(v)
			elseif pref == "[" then
				local pref2 = v:sub(2, 2)
				if pref2 == "(" then
					return str_to_table(v)
				else
					return json_to_table(v)
				end
			elseif v == "::BOOL:true::" then
				return true
			elseif v == "::BOOL:false::" then
				return false
			else
				return v
			end
		end
		local v = getf(k)
		local p = parse_value(v)
		return p
	end, __newindex = function(t, k, v)
		local p = nil
		if v == nil then
			p = ""
		elseif type(v) == "table" then
			p = table_to_str(v)
--			p = table_to_json(v)
		elseif type(v) == "number" then
			p = tostring(v)
		elseif type(v) == "string" then
			p = v
		elseif type(v) == "boolean" then
			p = "::BOOL:" .. tostring(v) .. "::"
		else
			error("Unknown value " .. tostring(v) .. " of type " .. type(v))
		end
		setf(k, p)
	end})
	return tbl
end

fight = setup_state_table(get_fight_state, set_fight_state)
session = setup_state_table(get_session_state, set_session_state)
day = setup_state_table(get_day_state, set_day_state)
ascension = setup_state_table(get_ascension_state, set_ascension_state)
character = setup_state_table(get_character_state, set_character_state)


function get_daily_counter(name)
	return tonumber(day[name]) or 0
end

function increase_daily_counter(name, amount)
	day[name] = get_daily_counter(name) + (amount or 1)
end

function reset_daily_counter(name)
	day[name] = nil
end

function get_ascension_counter(name)
	return tonumber(ascension[name]) or 0
end

function increase_ascension_counter(name, amount)
	ascension[name] = get_ascension_counter(name) + (amount or 1)
end

function reset_ascension_counter(name)
	ascension[name] = nil
end
