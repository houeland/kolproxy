function lightsout() return (-tonumber(status().turnsplayed)) % 37 end 


liz_quest = {
	{
		marker = "You carefully tiptoe through the room to look out the window.", 
		counter = 1, 
		description =  "store room (window)"
	},	
	{
		marker = "You approach an overflowing hamper of white sheets and towels with curious red-brown stains on them.", 
		counter = 2, 
		description =  "laundry room (stain)"
	},	
	{
		marker = "You peer into the bathtub.",  
		counter = 3, 
		description =  "bath room (tub)"
	},	
	{
		marker = "You fumble your way to the pantry and open the door.", 
		counter = 4, 
		description = "kitchen (snack)"  
	},	
	{
		marker = "You try to remember the signs you saw before the lights went out, and feel your way to the children's section.", 
		counter = 5, 
		description =  "library (children's book)"
	},	
	{
		marker = "You close your eyes, hold up your hands as if you had an invisible partner, and begin to box-step your way across the dance floor.", 
		counter = 6, 
		description =  "ball room (dance with yourself)"
	},	
	{
		marker = "xxxxx????xxxx", 
		counter = 7, 
		description =  "gallery (tormented souls), FIGHT"
	}
}



steve_quest = {
	{
		marker = "You reach out your left hand and fumble about.", 
		counter = 1, 
		description =  "Bedroom (left nightstand)"
	},	
	{
		marker = "Surprisingly, the contents of the box are pretty mundane", 
		counter = 2, 
		description =  "Nursery (stuffed animals)"
	},	
	{
		marker = "You brush away the moss to reveal an engraved portrait of Crumbles", 
		counter = 3, 
		description = "Conservatory (graves, Crumbles)"  
	},	
	
	{
		marker = "Why are they here and not in the wine cellar?", 
		counter = 4, 
		description =  "Billiards (taxidermy)"
	},	
	
	{
		marker = "It is, of course, Stephen's handwriting, though identifiably more mature than in the child's diary you found earlier.", 
		counter = 5, 
		description =  "Wine (pinot noir)"
	},	
	
	{
		marker = "It turns out to be a blackened and slightly melted chain dog-collar.", 
		counter = 6, 
		description =  "Boiler (barrel)"
	},	
	
	{
		marker = "xxxx????xxxx", 
		counter = 7, 
		description =  "Laboratory (weird machine), FIGHT"
	}
}



function check_lightsout_questlog()
	---if !session["checked lights out completion"]
	ql = get_page("/quest.php", {which=2})
	if ql:contains("Like Father Like Daughter") then
		ascension["liz quest"] = 7
	end

	if ql:contains("Like Mother Like Son") then
		ascension["steve quest"] = 7
	end

	print("Checked questlog for lightsout info")

end


function check_lightsout_progress()
	local liz = 0
	local steve = 0

	for _, obj in  ipairs(liz_quest) do
		if text:contains(obj.marker) then
			liz = obj.counter
		end
	end
	if liz > tonumber(ascension["liz quest"] or 0) then
		print("Updating liz quest to " .. liz)
		ascension["liz quest"] = liz 
	end

	for _, obj in  ipairs(steve_quest) do
		if text:contains(obj.marker) then
			steve = obj.counter
		end
	end
	if steve > tonumber(ascension["steve quest"] or 0) then
		print("Updating steve quest to " .. steve)
		ascension["steve quest"] = steve
	end
end

function get_lightsout_info()
	local turn = turnsthisrun()
	local lastturn = tonumber((ascension["last lights out"] or {}).turn)
	local lastencounter = (ascension["last lights out"] or {}).encounter
	local liznumber = ascension["liz quest"] or 0
	local stevenumber = ascension["steve quest"] or 0
	local counter = lightsout()
	if lastturn == turn and counter == 0 then
		counter = 37
	end
	return counter, lastencounter, liznumber, stevenumber
end

add_processor("/choice.php", function()
	if (adventure_title and adventure_title:contains("Lights Out in the")) or (adventure_result and adventure_result:contains("Lights Out in the")) then
		print("Lights Out!")
		ascension["last lights out"] = {encounter = adventure_title, turn = turnsthisrun()}
		check_lightsout_progress()
	end

end)

add_processor("/fight.php", function()
	if monstername("Ghost of Elizabeth Spookyraven") and text:contains("<!--WINWINWIN-->") then
		ascension["liz quest"] = 7
	end
	if monstername("Stephen Spookyraven") and text:contains("<!--WINWINWIN-->") then
		ascension["steve quest"] = 7
	end
end)


add_charpane_line(function()
	normalname  = "Lights Out"
	compactname = "Lights Out"
	value, lastencounter, liznumber, stevenumber = get_lightsout_info()
	
	tooltip = "L/S progress: " .. liznumber .. "/" .. stevenumber
	if value == 0 then
		color = "green"
	else
		color = "black"
	end
	lines = {}
	table.insert(lines, { normalname = normalname, compactname = compactname, value = value, tooltip = tooltip, color = color })
	if value==0 and lastencounter then
		if stevenumber < 7 then
			table.insert(lines, { name = "Steve", value = steve_quest[stevenumber+1].description })
		end
		if liznumber < 7 then
			table.insert(lines, { name = "Liz", value = liz_quest[liznumber+1].description })
		end
		
	end
	return lines
end )



add_always_adventure_warning(function()
	counter, lastencounter, liznumber, stevenumber = get_lightsout_info()
	if counter == 0 and (not session["checked lights out quest"]) then
		check_lightsout_questlog()
		session["checked lights out quest"] = true
	end

	if counter == 0 and (liznumber<7 or stevenumber <7 ) then
		local msg = "Next turn could be Lights Out!"
		if lastencounter then
			msg = msg .. "\n<br>(Last one was " .. lastencounter .. ".)"
		end

		liz_hints = "\n<br/> &nbsp; &nbsp; <b>Elizabeth: </b>"
		for _, obj in ipairs(liz_quest) do
			if obj.counter <= liznumber then
				liz_hints = liz_hints .. "<i>" .. obj.description .. ";</i> "
			elseif obj.counter == liznumber + 1 then
				liz_hints = liz_hints .. "<span style='color: green'>" .. obj.description .. ";</span> "
			else
				liz_hints = liz_hints .. obj.description .. "; "
			end
		end

		steve_hints = "\n<br/> &nbsp; &nbsp; <b>Steven: </b>"
		for _, obj in ipairs(steve_quest) do
			if obj.counter <= stevenumber then
				steve_hints = steve_hints .. "<i>" .. obj.description .. ";</i> "
			elseif obj.counter == stevenumber + 1 then
				steve_hints = steve_hints .. "<span style='color: green'>" .. obj.description .. ";</span> "
			else
				steve_hints = steve_hints .. obj.description .. "; "
			end
		end

		msg = msg .. "\n<br/><small>" .. steve_hints .. liz_hints .. "</small>"

		return msg, "lightsout-" .. turnsthisrun(), "Disable the warning for turn " .. (turnsthisrun() + 1) .. " and adventure", "teal", "Lights Out warning: "
	end
end)