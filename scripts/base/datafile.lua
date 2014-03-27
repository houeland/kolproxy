-- TODO: Workaround hack
if string then
        function string.contains(a, b) return not not a:find(b, 1, true) end
end

local function load_datafile(datafilename)
	local fobj = io.open("cache/data/" .. datafilename:gsub(" ", "-") .. ".json")
	if not fobj then
		error("Couldn't load datafile: " .. tostring(datafilename))
	end
	local str = fobj:read("*a")
	fobj:close()
	local data = fromjson(str)
	return data
end
local datafile_cache = {}
function datafile(name)
	if not datafile_cache[name] then
		datafile_cache[name] = load_datafile(name)
	end
	return datafile_cache[name]
end

local itemid_name_lookup = {}
local skillid_name_lookup = {}
local monster_image_lookup = {}
local monster_name_lookup = {}
local familiarid_name_lookup = {}
local zoneid_name_lookup = {}
function reset_datafile_cache()
	local function make_name_lookup(datafilename, field)
		local tbl = {}
		for x, y in pairs(datafile(datafilename)) do
			if y[field] then
				tbl[y[field]] = x
			end
		end
		return tbl
	end
	datafile_cache = {}
	itemid_name_lookup = make_name_lookup("items", "id")
	skillid_name_lookup = make_name_lookup("skills", "skillid")
	familiarid_name_lookup = make_name_lookup("familiars", "famid")
	zoneid_name_lookup = make_name_lookup("zones", "zoneid")
	datafile("outfits")
	datafile("semirares")
	monster_name_lookup = {}
	for monstername, monster in pairs(datafile("monsters")) do
		if monster.image then
			monster_image_lookup[monster.image] = monstername
		elseif monstername:lower():contains("ed the undying") then
			local form = tonumber(monstername:match("%(([0-9])%)"))
			monster_image_lookup["ed"..tostring(form)..".gif"] = monstername
		end
		monster_name_lookup[monstername:lower()] = monstername
	end
end
reset_datafile_cache()

local function get_item_data_by_name(name)
	return datafile("items")[name]
end

local function get_item_data_by_id(id)
	local name = itemid_name_lookup[id]
	if name then
		return get_item_data_by_name(name)
	end
end

function maybe_get_itemid(name)
	if name == nil then
		return nil
	end

	local t = type(name)
	if t == "number" then
		return name
	elseif t ~= "string" then
		error("Invalid itemid type: " .. t)
	end

	return (get_item_data_by_name(name) or {}).id
end

function get_itemid(name)
	local id = maybe_get_itemid(name)
	if not id then
		error("No itemid found for: " .. tostring(name))
	end
	return id
end

function get_skillid(name)
	if name == nil then
		return nil
	end

	local t = type(name)
	if t == "number" then
		return name
	elseif t ~= "string" then
		error("Invalid itemid type: " .. t)
	end

	local skill = datafile("skills")[name]
	if not skill then
		error("No skillid found for: " .. tostring(name))
	end
	return skill.skillid
end

function maybe_get_itemname(item)
	local id = maybe_get_itemid(item)
	return itemid_name_lookup[id]
end

function maybe_get_skillname(skill_id)
	return skillid_name_lookup[skill_id]
end

function get_itemname(item)
	local name = maybe_get_itemname(item)
	if not name then
		error("No item name found for: " .. tostring(item))
	end
	return name
end

function maybe_get_itemdata(name)
	local id = get_itemid(name)
	return get_item_data_by_id(id)
end

function get_itemdata(name)
	local data = maybe_get_itemdata(name)
	if not data then
		error("No item data found for: " .. tostring(name))
	end
	return data
end

function maybe_get_monsterdata(name, image)
	local realname = nil
	if image then
		realname = monster_image_lookup[image]
	elseif name then
		realname = monster_name_lookup[name:lower()]
	end
	return datafile("monsters")[realname]
end

function maybe_get_familiarid(name)
	if name == nil then
		return nil
	end

	local t = type(name)
	if t == "number" then
		return name
	elseif t ~= "string" then
		error("Invalid familiarid type: " .. t)
	end
	return (datafile("familiars")[name] or {}).famid
end

function get_familiarid(name)
	local id = maybe_get_familiarid(name)
	if not id then
		error("No familiarid found for: " .. tostring(name))
	end
	return id
end

function maybe_get_familiarname(fam)
	local id = maybe_get_familiarid(fam)
	return familiarid_name_lookup[id]
end

function get_familiarname(id)
	local name = maybe_get_familiarname(id)
	if not name then
		error("No familiarname found for: " .. tostring(id))
	end
	return name
end

function get_recipe(item)
	local name = get_itemname(item)
	local recipes = datafile("recipes")[name]
	if not recipes then
		error("No recipe found for: " .. tostring(item))
	end
	if not recipes[1] or recipes[2] then
		error("No unique recipe for: " .. tostring(item))
	end
	return recipes[1]
end

function get_recipes_by_type(typename)
	local recipes = {}
	local ambiguous = {}
	for name, rs in pairs(datafile("recipes")) do
		for _, r in ipairs(rs) do
			if not typename or r.type == typename then
				if recipes[name] then
					ambiguous[name] = true
				else
					recipes[name] = r
				end
			end
		end
	end
	for a, _ in pairs(ambiguous) do
		recipes[a] = nil
	end
	return recipes
end

function get_semirare_encounters()
	return datafile("semirares")
end

function load_buff_extension_info()
	local skills = load_datafile("skills")
	local buff_recast_skills = load_datafile("buff-recast-skills")
	local info = {}
	for x, y in pairs(buff_recast_skills) do
		info[x] = { skillname = y, skillid = skills[y].skillid, mpcost = skills[y].mpcost }
		if ascensionpath("Zombie Slayer") then
			info[x].zombiecost = info[x].mpcost
			info[x].mpcost = 0
		end
	end
	return info
end

function get_zoneid(name)
       	if type(name) == "number" then
                return name
	end

	local zoneid = (datafile("zones")[name] or {}).zoneid
	if not zoneid then
		error("Unknown zone: " .. tostring(name))
	end
	return zoneid
end

function maybe_get_zonename(zone)
	local id = get_zoneid(zone)
	return zoneid_name_lookup[id]
end
