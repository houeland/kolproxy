register_setting {
	name = "show extra notices/show lightsout warning",
	description = "Add warning and countdown for Lights Out adventures",
	group = "warnings",
	default_level = "detailed",
	parent = "enable adventure warnings",
	update_charpane = true,
}

-- TODO: remove
local function lightsout_enabled()
	return (setting_enabled("enable adventure warnings") and setting_enabled("show extra notices") and setting_enabled("show extra notices/show lightsout warning"))
end

-- TODO: zone names instead of ids
local liz_quest = {
	{
		marker = "You carefully tiptoe through the room to look out the window.",
		description = "Store room (window)",
		zone = "398"
	},
	{
		marker = "You approach an overflowing hamper of white sheets and towels with curious red-brown stains on them.",
		description = "Laundry room (stain)",
		zone = "400"
	},
	{
		marker = "You peer into the bathtub.",
		description = "Bathroom (tub)",
		zone = "392"
	},
	{
		marker = "You fumble your way to the pantry and open the door.",
		description = "Kitchen (snack)",
		zone = "388"
	},
	{
		marker = "You try to remember the signs you saw before the lights went out, and feel your way to the children's section.",
		description = "Library (children's book)",
		zone = "390"
	},
	{
		marker = "You close your eyes, hold up your hands as if you had an invisible partner, and begin to box-step your way across the dance floor.",
		description = "Ballroom (dance with yourself)",
		zone = "395"
	},
	{
		marker = nil,
		description = "Gallery (tormented souls), FIGHT",
		zone = "394"
	}
}

local steve_quest = {
	{
		marker = "You reach out your left hand and fumble about.",
		description = "Bedroom (left nightstand)",
		zone = "393"
	},
	{
		marker = "Surprisingly, the contents of the box are pretty mundane",
		description = "Nursery (stuffed animals)",
		zone = "397"
	},
	{
		marker = "You brush away the moss to reveal an engraved portrait of Crumbles",
		description = "Conservatory (graves, Crumbles)",
		zone = "389"
	},
	{
		marker = "Why are they here and not in the wine cellar?",
		description = "Billiards (taxidermy)",
		zone = "391"
	},
	{
		marker = "It is, of course, Stephen's handwriting, though identifiably more mature than in the child's diary you found earlier.",
		description = "Wine (pinot noir)",
		zone = "401"
	},
	{
		marker = "It turns out to be a blackened and slightly melted chain dog-collar.",
		description = "Boiler (barrel)",
		zone = "399"
	},
	{
		marker = nil,
		description = "Laboratory (weird machine), FIGHT",
		zone = "396"
	}
}

local function check_lightsout_questlog()
	---if !session["checked lights out completion"]
	local ql = get_page("/questlog.php", { which = 2 })
	if ql:contains("Like Father Like Daughter") then
		ascension["liz quest"] = 7
	end

	if ql:contains("Like Mother Like Son") then
		ascension["steve quest"] = 7
	end

	print("DEBUG: Checked questlog for lightsout info")

end

local function check_lightsout_progress()
	local liz = 0
	local steve = 0

	for ctr, obj in ipairs(liz_quest) do
		if obj.marker and text:contains(obj.marker) then
			liz = ctr
		end
	end
	if liz > tonumber(ascension["liz quest"] or 0) then
		print("DEBUG: Updating liz quest to " .. liz)
		ascension["liz quest"] = liz
	end

	for ctr, obj in ipairs(steve_quest) do
		if obj.marker and text:contains(obj.marker) then
			steve = ctr
		end
	end
	if steve > tonumber(ascension["steve quest"] or 0) then
		print("Updating steve quest to " .. steve)
		ascension["steve quest"] = steve
	end
end

-- TODO: remove lastencounter
function get_lightsout_info()
	local turn = turnsthisrun()
	local lastturn = tonumber((ascension["last lights out"] or {}).turn)
	local lastencounter = (ascension["last lights out"] or {}).encounter
	local liznumber = ascension["liz quest"] or 0
	local stevenumber = ascension["steve quest"] or 0
	local function lightsout_turns_remaining()
		local played = turnsplayed() or 0
		return (37 - played % 37) % 37
	end
	local counter = lightsout_turns_remaining()
	if lastturn == turn and counter == 0 then
		counter = 37
	end
	return counter, lastencounter, liznumber, stevenumber
end

add_processor("/choice.php", function()
	if (adventure_title and adventure_title:contains("Lights Out in the")) or (adventure_result and adventure_result:contains("Lights Out in the")) then
		print("DEBUG: Lights Out!")
		ascension["last lights out"] = { encounter = adventure_title, turn = turnsthisrun() }
		check_lightsout_progress()
	end
end)

add_processor("won fight: ghost of Elizabeth Spookyraven", function()
	ascension["liz quest"] = 7
end)

add_processor("won fight: Stephen Spookyraven", function()
	ascension["steve quest"] = 7
end)

add_counter_effect(function()
	if not lightsout_enabled() then return end
	local value, lastencounter, liznumber, stevenumber = get_lightsout_info()

	return { title = "Lights Out", duration = value, imgname = "lightning", group = "effect" }
end)

add_charpane_line(function()
	if setting_enabled("display counters as effects") then return end
	if not lightsout_enabled() then return end
	local value, lastencounter, liznumber, stevenumber = get_lightsout_info()

	local tooltip = "Liz: " .. liznumber .. "; Steve: " .. stevenumber
	local color = (value == 0) and "green" or "black"
	local lines = {}
	table.insert(lines, { name = "Lights Out", value = value, tooltip = tooltip, color = color })
	local function make_zone_link(step)
		return string.format([[<a target="mainpane" href="adventure.php?snarfblat=%s">%s</a>]], step.zone, step.description)
	end
	if value == 0 then
		if stevenumber < 7 then
			table.insert(lines, { name = "Steve", value = make_zone_link(steve_quest[stevenumber + 1]) })
		end
		if liznumber < 7 then
			table.insert(lines, { name = "Liz", value = make_zone_link(liz_quest[liznumber + 1]) })
		end
	end
	return lines
end)

add_always_adventure_warning(function()
	if not lightsout_enabled() then return end
	local counter, lastencounter, liznumber, stevenumber = get_lightsout_info()
	if not session["checked lights out quest"] and (liznumber < 7 or stevenumber < 7) then
		check_lightsout_questlog()
		session["checked lights out quest"] = true
	end

	if counter == 0 and (liznumber < 7 or stevenumber < 7) then
		return "Next turn could be Lights Out!", "Lights Out warning: "
	end
end)
