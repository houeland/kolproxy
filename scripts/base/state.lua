-- function get_request_state(name) return get_state("request", name) end
--function get_fight_state(name) return get_state("fight", name) end
--function get_session_state(name) return get_state("session", name) end
--function get_day_state(name) return get_state("day", name) end
--function get_ascension_state(name, value) return get_state("ascension", name) end
--function get_character_state(name) return get_state("character", name) end

-- function set_request_state(name, value) set_state("request", name, value) end
--function set_fight_state(name, value) set_state("fight", name, value) end
--function set_session_state(name, value) set_state("session", name, value) end
--function set_day_state(name, value) set_state("day", name, value) end
--function set_ascension_state(name, value) set_state("ascension", name, value) end
--function set_character_state(name, value) set_state("character", name, value) end

local function setup_state_table(statename)
	local tbl = {}
	setmetatable(tbl, { __index = function(t, k)
		-- TODO: REMOVE TEMPORARY WORKAROUNDS
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
			elseif v == [["true"]] then
				return true
			elseif v == [["false"]] then
				return false
			elseif pref == [["]] then
				if tonumber(v:sub(2, -2)) then return tonumber(v:sub(2, -2)) end
				return json_to_table("[" .. v .. "]")[1]
			elseif v == "::BOOL:true::" then
				return true
			elseif v == "::BOOL:false::" then
				return false
			elseif v == "true" then
				return true
			elseif v == "false" then
				return false
			else
				if tonumber(v) then return tonumber(v) end
				return v
			end
		end
		local v = get_state(statename, k)
		local p = parse_value(v)
		return p
	end, __newindex = function(t, k, v)
		local p = nil
		if v == nil then
			p = ""
		else
			p = tojson(v)
		end
--		print("DEBUG setting state", k, " ==> ", p)
		set_state(statename, k, p)
	end})
	return tbl
end

fight = setup_state_table("fight")
session = setup_state_table("session")
day = setup_state_table("day")
ascension = setup_state_table("ascension")
character = setup_state_table("character")


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
