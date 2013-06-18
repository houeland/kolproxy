register_setting {
	name = "show extra notices/check florist friar",
	description = "Show florist friar notice if re-adventuring without plants",
	group = "warnings",
	default_level = "detailed",
	parent = "enable adventure warnings",
}

local have_friar = nil
local checked_zones = {}

-- TODO: redo with add_warning?
add_interceptor("/adventure.php", function()
	if not setting_enabled("enable adventure warnings") then return end
	if not setting_enabled("show extra notices") then return end
	if not setting_enabled("show extra notices/check florist friar") then return end
	local pt
	if have_friar == false then
		return
	elseif have_friar == nil then
		pt = get_page("/forestvillage.php", { action = "floristfriar" })
		if pt:contains("The Florist Friar's Cottage") then
			have_friar = true
		elseif pt:contains("Forest Village") then
			have_friar = false
			return
		end
	end
	local lastadv = lastadventuredata()
	if tonumber(params.snarfblat) == tonumber(lastadv.id) and tonumber(lastadv.id) then
		if checked_zones[tonumber(lastadv.id)] then return end
		local noplants = 0
		if not pt then
			pt = get_page("/forestvillage.php", { action = "floristfriar" })
		end
		for x in pt:gmatch([[title="No Plant"]]) do
			noplants = noplants + 1
		end
		print("INFO: checking friar for plants")
		if noplants == 3 then
			--print("INFO:   no plants!")
			return intercept_warning { message = "The Florist Friar has not planted anything here yet.", id = "no florist plants, zoneid " .. tonumber(lastadv.id), customdisablecolor = "rgb(51, 153, 51)", customwarningprefix = "Notice: ", customaction = string.format([[<a href="%s">%s</a>]], make_href("/forestvillage.php", { action = "floristfriar" }), "Visit Florist Friar.") }
		else
			checked_zones[tonumber(lastadv.id)] = true
			--print("INFO:   have some plants", 3 - noplants)
		end
	end
end)
