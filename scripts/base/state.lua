local function setup_state_table(statename)
	local tbl = {}
	setmetatable(tbl, { __index = function(t, k)
		local v = get_state(statename, k)
		if v == nil or v == "" then
			return nil
		else
			return fromjson(v)
		end
	end, __newindex = function(t, k, v)
		local p = nil
		if v == nil then
			p = nil
		else
			p = tojson(v)
		end
--		print("DEBUG setting state", k, " ==> ", p)
		set_state(statename, k, p)
	end })
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

function reset_daily_counter(name, value)
	day[name] = value
end

function get_ascension_counter(name)
	return tonumber(ascension[name]) or 0
end

function increase_ascension_counter(name, amount)
	ascension[name] = get_ascension_counter(name) + (amount or 1)
end

function reset_ascension_counter(name, value)
	ascension[name] = value
end
