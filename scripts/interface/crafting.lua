local href
href = add_automation_script("custom-mix-drinks", function()
	local cocktailcrafting_recipes = {}
	for a, b in pairs(get_recipes_by_type("cocktail")) do
		cocktailcrafting_recipes[a] = b.ingredients
	end
	local still_recipes = {}
	for a, b in pairs(get_recipes_by_type("still")) do
		still_recipes[a] = b.base
	end
	local cached_ids = {}
	local garnishes = {
		["coconut shell"] = true,
		["little paper umbrella"] = true,
		["magical ice cubes"] = true,
	}
	local hippy_store = {
		herbs = 64,
		grapefruit = 70,
		grapes = 70,
		lemon = 70,
		olive = 70,
		orange = 70,
		strawberry = 70,
		tomato = 70,
	}
	local market_store = {
		["soda water"] = 70,
	}
	local store_price = {}
	for a, b in pairs(market_store) do store_price[a] = b end
	if have_item("filthy knitted dread sack") and have_item("filthy corduroys") then
		for a, b in pairs(hippy_store) do store_price[a] = b end
	end
	local SHC = { "Neuromancer", "vodka stratocaster", "Mon Tiki", "teqiwila slammer", "Divine", "Gordon Bennett", "gimlet", "yellow brick road", "mandarina colada", "tangarita", "Mae West", "prussian cathouse" }
	local advcock = { "pink pony", "fuzzbump", "slip 'n' slide", "ocean motion", "ducha de oro", "horizontal tango", "roll in the hay", "a little sump'm sump'm", "slap and tickle", "perpendicular hula", "rockin' wagon", "calle de miel", "tropical swill", "fruity girl swill", "blended frozen swill", "bungle in the jungle" }
	local function can_make(name)
		local available = count_item(name)
		local craftable = 0
		local craft_steps = {}
		if cocktailcrafting_recipes[name] then
			craftable = 100
			for _, x in pairs(cocktailcrafting_recipes[name]) do
				local num, partsteps = can_make(x)
				for _, y in ipairs(partsteps) do table.insert(craft_steps, y) end
				craftable = math.min(craftable, num)
			end
		end
		local stillable = 0
		local still_steps = nil
		if still_recipes[name] then
			stillable = 10
			local num, partsteps = can_make(still_recipes[name])
			still_steps = partsteps
			stillable = math.min(stillable, num)
		end
		local buyable = 0
		if store_price[name] then
			buyable = 100
		end
		local steps = {}
		if available > 0 then
			table.insert(steps, "have " .. name .. " (" .. available .. ")")
		elseif buyable > 0 then
			table.insert(steps, "buy " .. name .. " (" .. store_price[name] .. " meat)")
		elseif craftable > 0 then
			for _, y in ipairs(craft_steps) do table.insert(steps, y) end
			table.insert(steps, "mix " .. name)
		elseif stillable > 0 then
			for _, y in ipairs(still_steps) do table.insert(steps, y) end
			table.insert(steps, "still " .. still_recipes[name] .. " -> " .. name)
		end
		return available + craftable + stillable + buyable, steps
	end
	local function handle_recipe(name)
		local txt = ""
		for _, x in pairs(cocktailcrafting_recipes[name]) do
			txt = txt .. x .. " (" .. count_item(x) ..  ")  "
		end
		local amount, steps = can_make(name)
		if amount > 0 then
			local stepstext = ""
			for _, x in ipairs(steps) do
				stepstext = stepstext .. "<br><small>&nbsp;&nbsp;" .. x .. "</small>"
			end
			local makelink = string.format([[<a href="%s">[make]</a>]], href { pwd = session.pwd, makeitem = name })
			return name .. " { " .. amount .. " }: " .. txt .. makelink .. stepstext
		else
			return [[<span style="color: gray;">]] .. name .. " { " .. amount .. " }: " .. txt .. [[</span>]]
		end
	end
	local crafted_item_text = {}
	local function do_craft_item(name)
		if cocktailcrafting_recipes[name] then
			for _, x in pairs(cocktailcrafting_recipes[name]) do
				if not have_item(x) then
					do_craft_item(x)
				end
			end
			local pt = mix_items(cocktailcrafting_recipes[name][1], cocktailcrafting_recipes[name][2])()
			table.insert(crafted_item_text, pt)
		elseif still_recipes[name] then
			local pt = shop_buyitem(name, "still")()
--			table.insert(crafted_item_text, pt)
		end
	end
	if params.makeitem then
		do_craft_item(params.makeitem)
	end
	local resptexts = {}
	if classid() == 5 or classid() == 6 or ascensionpath("Avatar of Sneaky Pete") then
		for x, name in pairs(SHC) do
			table.insert(resptexts, handle_recipe(name))
		end
		table.insert(resptexts, "<br>")
	end
	for x, name in pairs(advcock) do
		table.insert(resptexts, handle_recipe(name))
	end
	return "Note: Work in progress, currently missing a better interface<br><br>" .. table.concat(crafted_item_text, "<br>\n") .. table.concat(resptexts, "<br>\n"), requestpath
end)

add_automation_script("buy-and-cook-fancy", function()
	local kitchen = get_page("/campground.php", { action = "inspectkitchen" })
	if kitchen:contains("E-Z Cook") and not kitchen:contains("Dramatic") then
		if not have_item("Dramatic&trade; range") then
			buy_item("Dramatic&trade; range", "m")
		end
		use_item("Dramatic&trade; range")
	end
	local p = {}
	for _, x in ipairs(parse_params_raw(input_params)) do
		if x.key ~= "automation-script" and x.key ~= "ajax" then
			table.insert(p, x)
		end
	end
	return raw_async_submit_page("POST", "/craft.php", p)()
end)

-- TODO: make this a printer after redoing parameter handling
add_automator("/craft.php", function()
	if text:contains("need a more advanced cooking appliance") then
		local p = parse_params_raw(input_params)
		table.insert(p, { key = "automation-script", value = "buy-and-cook-fancy" })
		text = text:gsub("(need a more advanced cooking appliance.-)(</td>)", function(a, b)
			return a..[[<p><a href="]]..raw_make_href("/kolproxy-automation-script", p)..[[" style="color: green">{ Buy one and try again (1000 Meat). }</a></p>]]..b
		end)
	end
end)

add_automation_script("buy-and-mix-fancy", function()
	local kitchen = get_page("/campground.php", { action = "inspectkitchen" })
	if kitchen:contains("My First Shaker") and not kitchen:contains("Du Coq cocktailcrafting") then
		if not have_item("Queue Du Coq cocktailcrafting kit") then
			buy_item("Queue Du Coq cocktailcrafting kit", "m")
		end
		use_item("Queue Du Coq cocktailcrafting kit")
	end
	local p = {}
	for _, x in ipairs(parse_params_raw(input_params)) do
		if x.key ~= "automation-script" and x.key ~= "ajax" then
			table.insert(p, x)
		end
	end
	return raw_async_submit_page("POST", "/craft.php", p)()
end)

-- TODO: make this a printer after redoing parameter handling
add_automator("/craft.php", function()
	if text:contains("cocktail set is not advanced enough to make such a fancy beverage") then
		local p = parse_params_raw(input_params)
		table.insert(p, { key = "automation-script", value = "buy-and-mix-fancy" })
		text = text:gsub("(cocktail set is not advanced enough to make such a fancy.-)(</td>)", function(a, b)
			return a..[[<p><a href="]]..raw_make_href("/kolproxy-automation-script", p)..[[" style="color: green">{ Buy one and try again (1000 Meat). }</a></p>]]..b
		end)
	end
end)
