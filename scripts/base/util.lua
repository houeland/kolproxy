-- TODO: Don't load all of these
dofile("scripts/base/base-lua-functions.lua")
dofile("scripts/base/state.lua")
dofile("scripts/base/kolproxy-core-functions.lua")
dofile("scripts/base/script-functions.lua")
dofile("scripts/base/charpane.lua")
dofile("scripts/base/api.lua")
dofile("scripts/base/commands.lua")


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
		monster_name = nil
		monster_name_tag = nil
		for spantext in text:gmatch([[<span.-</span>]]) do
			if spantext:contains("monname") then
				monster_name = spantext:match([[<span [^>]*id=['"]monname['"][^>]*>(.-)</span>]]) or monster_name
				monster_name_tag = spantext:match([[<span [^>]*id=['"]monname['"][^>]*>.-</span>]]) or monster_name_tag
			end
		end
		adventure_zone = tonumber(fight.zone)
		if not query:contains("ireallymeanit") then
			encounter_source = "other"
		elseif text:contains("hear a wolf whistle from behind you") then
			encounter_source = "Obtuse Angel"
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

function monstername(name)
	if name then
		return name == monstername()
	end
	if monster_name then
		if monster_name_tag and monster_name_tag:contains([[id="monname"]]) then
			return monster_name
		else
			return monster_name:gsub("^[^ ]* ", "")
		end
	end
end
