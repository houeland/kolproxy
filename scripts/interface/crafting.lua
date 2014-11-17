local SHClist = { "Neuromancer", "vodka stratocaster", "Mon Tiki", "teqiwila slammer", "Divine", "Gordon Bennett", "gimlet", "yellow brick road", "mandarina colada", "tangarita", "Mae West", "prussian cathouse" }
local AClist = { "pink pony", "fuzzbump", "slip 'n' slide", "ocean motion", "ducha de oro", "horizontal tango", "roll in the hay", "a little sump'm sump'm", "slap and tickle", "perpendicular hula", "rockin' wagon", "calle de miel", "tropical swill", "fruity girl swill", "blended frozen swill", "bungle in the jungle" }

function get_still_charges()
	local pt = get_page("/shop.php", { whichshop = "still" })
	local charges = tonumber(pt:match("black readout with ([0-9]*) bright green light"))
	return charges or 0
end

function get_maximum_craftable_SHCs(available_still_charges, ignore_hippy_outfit)
	local cocktailcrafting_recipes = {}
	for a, b in pairs(get_recipes_by_type("cocktail")) do
		cocktailcrafting_recipes[a] = b.ingredients
	end
	local still_recipes = {}
	for a, b in pairs(get_recipes_by_type("still")) do
		still_recipes[a] = b.base
	end
	local hippy_buyable = {}
	if have_item("filthy knitted dread sack") and have_item("filthy corduroys") and not ignore_hippy_outfit then
		for _, x in ipairs { "herbs", "grapefruit", "grapes", "lemon", "olive", "orange", "strawberry", "tomato" } do
			hippy_buyable[x] = true
		end
	end

	local best = nil
	local function score(state)
--		print("DEBUG score", #state.drinks, tojson(state.drinks))
		if #state.drinks > #best.drinks then
			best = table.copy(state)
		elseif #state.drinks == #best.drinks then
			if state.buy_hippy_fruit < best.buy_hippy_fruit then
				best = table.copy(state)
			elseif state.buy_hippy_fruit == best.buy_hippy_fruit and state.buy_soda_water < best.buy_soda_water then
				best = table.copy(state)
			end
		end
	end
	local function consume(which, state)
		if count_item(which) - state.spent[which] >= 1 then
			state.spent[which] = state.spent[which] + 1
			return true
		elseif which == "soda water" then
			state.buy_soda_water = state.buy_soda_water + 1
			return true
		elseif hippy_buyable[which] then
			state.buy_hippy_fruit = state.buy_hippy_fruit + 1
			return true
		end
		if still_recipes[which] and consume(still_recipes[which], state) then
			state.stills_left = state.stills_left - 1
			return true
		elseif cocktailcrafting_recipes[which] then
			for _, x in ipairs(cocktailcrafting_recipes[which]) do
				if not consume(x, state) then
					return false
				end
			end
			return true
		end
	end
	local function f(possibleidx, input_state)
		if input_state.stills_left < 0 or #best.drinks >= 10 then return end
		local which = SHClist[possibleidx]
		if not which then
			score(input_state)
			return
		end
--		print("DEBUG checking", which, tojson(input_state))
		local new_state = table.copy(input_state)
		for i = 0, 10 do
			f(possibleidx + 1, new_state)
			if consume(which, new_state) then
				table.insert(new_state.drinks, which)
			else
				break
			end
		end
	end
	local start_state = { stills_left = available_still_charges, drinks = {}, spent = {}, buy_soda_water = 0, buy_hippy_fruit = 0 }
	setmetatable(start_state.spent, { __index = function(tbl, key) return 0 end })
	best = table.copy(start_state)
	f(1, start_state)
	return best.drinks
end

function automate_crafting_cocktail(itemname)
	local still_recipes = {}
	for a, b in pairs(get_recipes_by_type("still")) do
		still_recipes[a] = b.base
	end
	local hippy_buyable = {}
	if have_item("filthy knitted dread sack") and have_item("filthy corduroys") then
		for _, x in ipairs { "herbs", "grapefruit", "grapes", "lemon", "olive", "orange", "strawberry", "tomato" } do
			hippy_buyable[x] = true
		end
	end
	local crafted_item_text = {}
	local function do_craft_item(name)
		if maybe_get_recipe(name, "cocktail") then
			for _, x in pairs(get_recipe(name, "cocktail").ingredients) do
				if not have_item(x) then
					do_craft_item(x)
				end
			end
			local pt = craft_item(name)()
			table.insert(crafted_item_text, pt)
		else
			if still_recipes[name] and not have_item(still_recipes[name]) then
				buy_itemname(still_recipes[name])
			end
			buy_itemname(name)
		end
	end
	do_craft_item(itemname)
	return crafted_item_text
end

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
	local function can_make(name, ignore_available)
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
		local total_possible = available + craftable + stillable + buyable
		if available > 0 and (not ignore_available or total_possible <= available) then
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
		return total_possible, steps
	end
	local function handle_recipe(name)
		local txt = ""
		for _, x in pairs(cocktailcrafting_recipes[name]) do
			txt = txt .. x .. " (" .. count_item(x) .. ")  "
		end
		local amount, steps = can_make(name, true)
		if amount > 0 then
			local stepstext = ""
			for _, x in ipairs(steps) do
				stepstext = stepstext .. "<br><small>&nbsp;&nbsp;" .. x .. "</small>"
			end
			local makelink = ""
			if amount > count_item(name) then
				makelink = string.format([[<a href="%s">[make]</a>]], href { pwd = session.pwd, makeitem = name })
			end
			return name .. " { " .. amount .. " }: " .. txt .. makelink .. stepstext
		else
			return [[<span style="color: gray;">]] .. name .. " { " .. amount .. " }: " .. txt .. [[</span>]]
		end
	end
	local crafted_item_text = {}
	if params.makeitem then
		crafted_item_text = automate_crafting_cocktail(params.makeitem)
	end
	local resptexts = {}
	if classid() == 5 or classid() == 6 or ascensionpath("Avatar of Sneaky Pete") then
		for x, name in pairs(SHClist) do
			table.insert(resptexts, handle_recipe(name))
		end
		table.insert(resptexts, "<br>")
	end
	for x, name in pairs(AClist) do
		table.insert(resptexts, handle_recipe(name))
	end
	return "Note: Work in progress, currently missing a better interface<br><br>" .. table.concat(crafted_item_text, "<br>\n") .. table.concat(resptexts, "<br>\n"), requestpath
end)

add_automation_script("buy-and-cook-fancy", function()
	local kitchen = get_page("/campground.php", { action = "inspectkitchen" })
	if kitchen:contains("E-Z Cook") and not kitchen:contains("Dramatic") then
		if not have_item("Dramatic&trade; range") then
			store_buy_item("Dramatic&trade; range", "m")
		end
		use_item("Dramatic&trade; range")
	end
	local p = {}
	for _, x in ipairs(get_allparams_keyvaluetbl()) do
		if x.key ~= "automation-script" and x.key ~= "ajax" then
			table.insert(p, x)
		end
	end
	return raw_async_submit_page("POST", "/craft.php", p)()
end)

-- TODO: make this a printer after redoing parameter handling
add_automator("/craft.php", function()
	if text:contains("need a more advanced cooking appliance") then
		local p = get_allparams_keyvaluetbl()
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
			store_buy_item("Queue Du Coq cocktailcrafting kit", "m")
		end
		use_item("Queue Du Coq cocktailcrafting kit")
	end
	local p = {}
	for _, x in ipairs(get_allparams_keyvaluetbl()) do
		if x.key ~= "automation-script" and x.key ~= "ajax" then
			table.insert(p, x)
		end
	end
	return raw_async_submit_page("POST", "/craft.php", p)()
end)

-- TODO: make this a printer after redoing parameter handling
add_automator("/craft.php", function()
	if text:contains("cocktail set is not advanced enough to make such a fancy beverage") then
		local p = get_allparams_keyvaluetbl()
		table.insert(p, { key = "automation-script", value = "buy-and-mix-fancy" })
		text = text:gsub("(cocktail set is not advanced enough to make such a fancy.-)(</td>)", function(a, b)
			return a..[[<p><a href="]]..raw_make_href("/kolproxy-automation-script", p)..[[" style="color: green">{ Buy one and try again (1000 Meat). }</a></p>]]..b
		end)
	end
end)
