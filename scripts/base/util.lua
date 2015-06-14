-- TODO: Don't load all of these
doloadfile("scripts/base/base-lua-functions.lua")
doloadfile("scripts/base/state.lua")
doloadfile("scripts/base/kolproxy-core-functions.lua")
doloadfile("scripts/base/script-functions.lua")
doloadfile("scripts/base/charpane.lua")
doloadfile("scripts/base/api.lua")
doloadfile("scripts/base/commands.lua")

local function parse_fight_vars(text)
	local monster_name = nil
	local monster_name_tag = nil
	for spantext in text:gmatch([[<span.-</span>]]) do
		if spantext:contains("monname") then
			monster_name = spantext:match([[<span [^>]*id=['"]monname['"][^>]*>(.-)</span>]]) or monster_name
			monster_name_tag = spantext:match([[<span [^>]*id=['"]monname['"][^>]*>.-</span>]]) or monster_name_tag
		end
	end
	return monster_name, monster_name_tag
end

function get_adventure_zoneid()
	return tonumber(fight.zone)
end

function adventure_zone(zone)
	return get_zoneid(zone) == get_adventure_zoneid()
end

-- TODO: redo the rest of this code
function setup_variables()
	if path == "/charpane.php" then
	elseif path == "/kolproxy-quick-charpane-normal" or path == "/kolproxy-quick-charpane-compact" then
		using_kolproxy_quick_charpane = true
		kolproxy_custom_charpane_mode = "normal"
		if path == "/kolproxy-quick-charpane-compact" then
			kolproxy_custom_charpane_mode = "compact"
		end
		path = "/charpane.php" -- TODO: hack!
	end

	if path == "/fight.php" then
		monster_name, monster_name_tag = parse_fight_vars(text)
		if not query:contains("ireallymeanit") then
			encounter_source = "other"
		elseif text:contains("hear a wolf whistle from behind you") then
			encounter_source = "Obtuse Angel"
		elseif text:contains("You bend the drops to your will, and your will is") then
			encounter_source = "Rain Man"
		elseif text:contains("You play back the recording and") then
			encounter_source = "Rain-Doh box full of monster"
		elseif text:contains("<td bgcolor=black align=center><font color=white size=1>") then
			encounter_source = "Mini-Hipster"
		elseif monster_name and monster_name:contains("Black Crayon") then
			encounter_source = "Artistic Goth Kid"
		else
			encounter_source = "adventure"
		end
	end

	for x in text:gmatch([[<tr><td style="color: white;" align=center bgcolor=blue.-><b>([^<]*)</b></td></tr>]]) do
		if x ~= "Results:" and x ~= "Adventure Again:" then
			adventure_title = x:gsub(" %(#[0-9]*%)$", "")
		end
	end
	choice_adventure_number = tonumber(text:match([[<input type=hidden name=whichchoice value=([0-9]+)>]]))
	adventure_result = text:match([[<td style="color: white;" align=center bgcolor=blue.-><b>Adventure Results:</b></td></tr><tr><td style="padding: 5px; border: 1px solid blue;"><center><table><tr><td><center><b>(.-)</b>]])
end

local function monstername_from_vars(monster_name, monster_name_tag)
	if monster_name then
		if monster_name_tag and monster_name_tag:contains([[id="monname"]]) then
			return monster_name
		else
			local name = monster_name:gsub("^[^ ]* ", "")
			return name
		end
	end
end

function get_monstername()
	return monstername_from_vars(monster_name, monster_name_tag)
end

function has_monster_modifiers()
	return ascensionpath("One Crazy Random Summer")
end

function monstername(name)
	local monster = get_monstername()
	if name == monster then
		return true
	elseif monster and has_monster_modifiers() and monster:match(name .. "$") then
		return true
	end
end

function get_raw_monstername()
	return monster_name
end

function get_monstername_from_fight_page(fight_text)
	fight_text = fight_text or get_page("/fight.php")
	local monster_name, monster_name_tag = parse_fight_vars(fight_text)
	return monstername_from_vars(monster_name, monster_name_tag)
end
