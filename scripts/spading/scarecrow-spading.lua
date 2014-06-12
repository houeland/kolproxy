-- Usage: Use a scarecrow, go to gremlins with preferably high DA and -100 ML headphones,
--        and a macro on autoattack that e.g. uses a seal tooth 25 times and then runs away,
--        then just run a bunch of turns and the scarecrow-specific text gets logged.

add_processor("/fight.php", function()
	if not familiar("Fancypants Scarecrow") then return end
	local monstername = text:match("<span id='monname'>(.-)</span>")
	local logthings = {}
	local where = 0
	while true do
		local where_fam_start, where_fam_end = text:find("<!%-%-familiarmessage%-%->.-</center>", where + 1)
		local where_damage_start, where_damage_end = text:find(">You lose [0-9,]- hit point", where + 1)
		if not where_fam_start and not where_damage_start then
			break
		elseif where_fam_start and (not where_damage_start or where_fam_start < where_damage_start) then
			where = where_fam_start
			table.insert(logthings, "  " .. text:sub(where_fam_start, where_fam_end))
		elseif where_damage_start and (not where_fam_start or where_damage_start < where_fam_start) then
			where = where_damage_start
			table.insert(logthings, "  " .. text:sub(where_damage_start, where_damage_end))
		else
			error "Something went wrong when logging scarecrow actions."
		end
	end

	local prefix = "scarecrow spading: weight[" .. buffedfamiliarweight() .. "], equipment[" .. tostring(equipment().familiarequip) .. "], monster[" .. tostring(monstername) .. "]"
	local msg = prefix .. " pageload\n"
	for x in table.values(logthings) do
		msg = msg .. "  " .. prefix .. " event: " .. x .. "\n"
	end
	msg = msg .. "\n"

	print(msg)
	local f = io.open("scarecrow-spading-log.txt", "a+")
	f:write(msg.."\n")
	f:close()
end)
