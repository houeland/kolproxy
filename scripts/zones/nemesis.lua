add_processor("/desc_item.php", function()
	name, left, right, word = text:match([[<b>(a [a-z]- paper strip)</b>.-title="A ([a-z-]-) tear".-title="A ([a-z-]-) tear".-<font size=%+1><b>([A-Z]-)</b></font>]])
	if name and left and right and word then
		local tbl = session["zone.cave.paper strips"] or {}
		tbl[name] = { left = left, right = right, word = word }
		session["zone.cave.paper strips"] = tbl
	end
end)

function check_nemesis_paper_strips()
	async_get_page("/desc_item.php", { whichitem = "776620628" })
	async_get_page("/desc_item.php", { whichitem = "298163869" })
	async_get_page("/desc_item.php", { whichitem = "564255755" })
	async_get_page("/desc_item.php", { whichitem = "411336587" })
	async_get_page("/desc_item.php", { whichitem = "626990413" })
	async_get_page("/desc_item.php", { whichitem = "647825911" })
	async_get_page("/desc_item.php", { whichitem = "153915446" })
	get_page("/desc_item.php", { whichitem = "148513878" })
end

function determine_nemesis_paper_strips_password()
	local tbl = session["zone.cave.paper strips"] or {}
	local right_sides = {}
	local left_sides = {}
	local count = 0
	local solution = nil
	for a,b in pairs(tbl) do
		right_sides[b.right] = a
		left_sides[b.left] = a
		count = count + 1
	end
	if count == 8 then
		where = nil
		for a, b in pairs(left_sides) do
			if right_sides[a] == nil then
				where = b
			end
		end
		solution = ""
		while where do
			solution = solution .. tbl[where].word
			where = left_sides[tbl[where].right]
		end
	end
	return count, solution
end

add_automator("/cave.php", function()
	if params.action == "door4" then
		check_nemesis_paper_strips()
	end
end)

add_printer("/cave.php", function()
	function select_item(name)
		if text:match(name) then
			text = text:gsub("(<option value='[0-9]-' descid='[0-9]-')(>"..name.." %([0-9]-%)</option>)", "%1 selected=\"selected\"%2")
		else
			text = text:gsub("(%-select an item%-)", "%1 { need: " .. name .. " }")
		end
	end

	local item_table = {
		["depicts an angry-looking man holding a spear and shield"] = "viking helmet", -- muscle
		["depicts a man fighting a crowd of little tiny people."] = "stalk of asparagus", -- mysticality
		["depicts a pair of hands with little lines radiating off of them."] = "dirty hobo gloves", -- moxie
		["with little round things pouring out of it"] = "insanely spicy bean burrito", -- muscle
		["small round glowing thing"] = "insanely spicy enchanted bean burrito", -- mysticality
		["little wiggly lines coming off of them"] = "insanely spicy jumping bean burrito", -- moxie
		["coiled snake with the head of a clown"] = "clown whip", -- seal clubber
		["large circle with a jeering clown head"] = "clownskin buckler", -- turtle tamer
		["long wavy horizontal lines"] = "boring spaghetti", -- pastamancer
		["a wobbly blob"] = "tomato juice of powerful power", -- sauceror
	}
	for a, b in pairs(item_table) do
		if text:contains(a) then
			select_item(b)
		end
	end

	if text:match("a group of small squares, and a large circle") then -- disco bandit
		text = text:gsub("is in the wall next to the engraving.", [[%0<br><span style="color: green">{ Need advanced cocktailcrafting drink. }</span>]])
	end
	if text:match("wobbly shapes that sort of look like cutlets of meat") then -- accordion thief
		text = text:gsub("Unexpectedly, you can't find any hole in the wall this time. Hmm.", [[%0<br><span style="color: green">{ Need Polka of Plenty buff. }</span>]])
	end

	if text:match("SPEAK THE PASSWORD TO ENTER") then
		local count, solution = determine_nemesis_paper_strips_password()
		if solution then
			text = text:gsub([[(<input type="text" name="say" size="30")( />)]], [[%1 value="]]..solution..[["%2]])
		end
		text = text:gsub("This could be an excellent opportunity to voice your opinion on any grievances you might have.</p>", "%0<p>" .. count .. " / 8 strips found.</p>")
	end
end)

-- Turtle Tamer

add_processor("/fight.php", function()
	if monstername("guard turtle") then
		if text:match("<img id='monpic' .-frenchturtle.gif.->") then
			fight["guard turtle.type"] = "French"
		end
	end
end)

-- Disco Bandit

add_processor("/fight.php", function()
	dancers = {
		["breakdancing raver"] = "spinning his legs",
		["pop-and-lock raver"] = "spastic and jerky",
		["running man"] = "running anywhere",
	}
	if dancers[get_monstername()] then
		if not fight["nemesis.dancer"] then
			fight["nemesis.dancer"] = "yes"
		end
		if text:contains(dancers[get_monstername()]) then
			fight["nemesis.dancer.special move"] = "yes"
		else
			fight["nemesis.dancer.special move"] = nil
		end
		if text:contains("You lazily wave your hands around for a moment.") then
			fight["nemesis.dancer"] = "learned"
		end
	end
end)

-- Volcano

--~ 	add_processor("/volcanomaze.php", function()
--~ 	--~ 	set_ascension_state("zone.volcano.maze states", table_to_str({}))
--~ 		platforms = {}
--~ 		goal = nil
--~ 		you = nil

--~ 		tbl = get_ascension_state("zone.volcano.maze states")
--~ 		if (tbl == "") then tbl = {} else tbl = str_to_table(tbl) end

--~ 		squares = get_session_state("zone.volcano.maze squares")
--~ 		if (squares == "") then squares = {} else squares = str_to_table(squares) end

--~ 		for square, pos in string.gmatch(text, [[<div id="sq([0-9]+)" class="[^"]-" rel="([0-9,]+)">]]) do
--~ 			squares[tonumber(square)] = pos
--~ 		end

--~ 		set_session_state("zone.volcano.maze squares", table_to_str(squares))

--~ 	--~ 	print("volcano text", text)
--~ 		if text:contains("A Volcanic Cave") then
--~ 			for pos, object in text:gmatch([[<a href="%?move=[0-9]+,[0-9]+" title="%(([0-9,]+) %- ([^)]-)%)">]]) do
--~ 				if object == "Platform" then
--~ 					table.insert(platforms, pos)
--~ 				elseif object == "You" then
--~ 					you = pos
--~ 				elseif object == "Goal" then
--~ 					goal = pos
--~ 					table.insert(platforms, pos)
--~ 				end
--~ 			end
--~ 		else
--~ 			you = text:match([["pos":"([0-9,]+)"]])
--~ 			showstr = text:match([["show":(%b[])]])
--~ 			if showstr then
--~ 				for s in showstr:gmatch([[([0-9]+)]]) do
--~ 					pos = squares[tonumber(s)]
--~ 					table.insert(platforms, pos)
--~ 				end
--~ 			end
--~ 		end

--~ 	--~ 	print("this one is", printstr(platforms), goal, you)
--~ 		platformstr = table_to_str(platforms)
--~ 		isnew = true
--~ 		for x,y in pairs(tbl) do
--~ 			if str_to_table(y).platforms == platformstr then
--~ 				isnew = false
--~ 			end
--~ 		end
--~ 		if isnew and you then
--~ 			table.insert(tbl, table_to_str({ you = you, platforms = platformstr }))
--~ 			set_ascension_state("zone.volcano.maze states", table_to_str(tbl))
--~ 		end
--~ 	end)

local volcano_solutions = {}

volcano_solutions[1] = [[
7, 12
8, 12
9, 11
8, 11
9, 10
10, 9
10, 8
9, 7
10, 6
10, 5
10, 4
11, 3
10, 2
9, 1
8, 0
9, 0
10, 1
11, 0
12, 1
12, 2
12, 3
12, 4
12, 5
11, 6
12, 7
12, 8
12, 9
12, 10
12, 11
11, 12
10, 12
11, 11
10, 10
9, 9
8, 9
7, 10
6, 10
5, 9
4, 10
3, 9
3, 8
3, 7
2, 6
1, 6
0, 5
1, 4
2, 3
2, 4
1, 3
0, 3
1, 2
1, 1
2, 0
3, 1
4, 1
5, 2
6, 2
7, 2
8, 3
7, 3
6, 3
7, 4
6, 5
]]

volcano_solutions[2] = [[
5, 12
4, 12
3, 11
4, 11
3, 10
2, 9
2, 8
3, 7
2, 6
2, 5
2, 4
1, 3
2, 2
3, 1
4, 0
3, 0
2, 0
1, 0
0, 1
0, 2
0, 3
0, 4
0, 5
1, 6
0, 7
0, 8
0, 9
0, 10
0, 11
1, 12
2, 12
1, 11
2, 10
3, 9
4, 9
5, 10
6, 10
7, 9
8, 10
9, 9
9, 8
9, 7
10, 6
11, 6
12, 5
11, 4
10, 3
10, 4
11, 3
12, 3
11, 2
11, 1
10, 0
9, 1
8, 1
7, 2
6, 2
5, 2
4, 3
5, 3
6, 3
5, 4
6, 5
]]

volcano_solutions[3] = [[
7, 12
8, 11
9, 11
10, 11
9, 10
9, 9
8, 10
7, 9
6, 10
5, 10
4, 10
3, 11
2, 10
1, 11
0, 10
1, 9
2, 9
1, 8
0, 7
0, 6
1, 5
0, 4
0, 3
1, 2
2, 1
3, 0
4, 0
5, 1
6, 0
7, 0
8, 1
9, 1
10, 2
11, 3
10, 4
9, 5
8, 6
8, 7
7, 7
]]

volcano_solutions[4] = [[
5, 12
4, 11
3, 11
2, 11
3, 10
3, 9
4, 10
5, 9
6, 10
7, 10
8, 10
9, 11
10, 10
11, 11
12, 10
11, 9
10, 9
11, 8
12, 7
12, 6
11, 5
12, 4
11, 3
11, 2
10, 1
9, 0
8, 0
7, 1
6, 0
5, 0
4, 1
3, 1
2, 2
1, 3
2, 4
3, 5
3, 6
4, 7
5, 7
]]

volcano_solutions[5] = [[
7, 12
8, 12
9, 11
10, 11
11, 10
11, 9
11, 8
12, 7
12, 6
11, 5
11, 4
11, 3
10, 2
9, 1
8, 1
7, 0
6, 0
5, 1
4, 1
3, 0
2, 0
1, 1
1, 2
0, 3
0, 4
1, 5
2, 4
3, 3
4, 3
5, 3
6, 2
7, 2
8, 3
9, 4
9, 5
9, 6
10, 7
9, 7
8, 6
8, 7
7, 8
6, 8
5, 8
4, 7
5, 6
]]

volcano_solutions[6] = [[
5, 12
4, 12
3, 11
2, 11
1, 10
1, 9
1, 8
0, 7
0, 6
1, 5
1, 4
1, 3
2, 2
3, 1
4, 1
5, 0
6, 0
7, 1
8, 1
9, 0
10, 0
11, 1
11, 2
12, 3
12, 4
11, 5
10, 4
9, 3
8, 3
7, 3
6, 2
5, 2
4, 3
3, 4
3, 5
3, 6
2, 7
3, 7
4, 6
4, 7
5, 8
6, 8
7, 8
8, 7
7, 6
]]


function automate_volcanomaze()
	text, url = "Solving volcano puzzle", requestpath
	volcano = get_page("/volcanomaze.php")
	platforms = {}
	for pos, object in volcano:gmatch([[<a href="%?move=[0-9]+,[0-9]+" title="%(([0-9,]+) %- ([^)]-)%)">]]) do
		if object == "Platform" then
			platforms[pos] = true
		elseif object == "You" then
			you = pos
		elseif object == "Goal" then
			platforms[pos] = true
		end
	end
	if you == "6,12" then
		text = "Trying to solve volcano maze"
		solution = nil
		if platforms["5,12"] and platforms["7,12"] then
			if platforms["0,0"] then
				text = "use solution 1"
				solution = volcano_solutions[1]
			else
				text = "use solution 2"
				solution = volcano_solutions[2]
			end
		elseif platforms["5,12"] then
			if platforms["6,11"] then
				text = "use solution 4"
				solution = volcano_solutions[4]
			else
				text = "use solution 6"
				solution = volcano_solutions[6]
			end
		elseif platforms["7,12"] then
			if platforms["6,11"] then
				text = "use solution 3"
				solution = volcano_solutions[3]
			else
				text = "use solution 5"
				solution = volcano_solutions[5]
			end
		else
			error "Unknown platform layout!"
		end
		if solution then
			for x, y in solution:gmatch("([0-9]+), ([0-9]+)") do
				async_get_page("/volcanomaze.php", { move = x .. "," .. y, ajax = "1" })
				print("move", x, y)
			end
			text, url = get_page("/volcanomaze.php")
			-- Redirect to volcanomaze.php for further move() commands, not kolproxy-automation-script.
			-- TODO: Let Lua scripts specify redirect headers?
			text = text:gsub("</head>", [[<meta http-equiv="refresh" content="0; url=volcanomaze.php">%0]])
		else
			error "No solution found!"
		end
	else
		text = "Swim back to shore first to enable solving"
	end
	return text, url
end

local href = add_automation_script("automate-volcanomaze", automate_volcanomaze)

add_printer("/volcanomaze.php", function()
	text = text:gsub([[value="Swim Back to Shore".->]], [[%0<br><a href="]].. href { pwd = session.pwd } ..[[" style="color: green">{ solve }</a>]])
end)

add_printer("/fight.php", function()
	if text:contains("In your ears! Earworms! He's given you <i>EARWORMS!</i>") then
		link = make_href("/fight.php", { action = "skill", whichskill = 6025, pwd = session.pwd })
		text = text:gsub("He's given you <i>EARWORMS!</i>", [[%0 <a href="]]..link..[[" style="color: green">{ Sing something worse! }</a>]])
	end
end)
