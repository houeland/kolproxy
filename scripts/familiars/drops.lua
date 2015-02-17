local drop_familiars = {
	babyworm = {
		counter_name = "sandworm",
		message = "A few minutes later, he belches some murky fluid back into the bottle and hands it to you.",
		short_item_name = "agua",
		plural = true,
	},
	badger = {
		message = "You pick it up because, hey, free mushroom.",
		short_item_name = "mushroom",
	},
	groose = {
		counter_name = "bloovian groose",
		message = "produces a small glob of grease",
		short_item_name = "grease",
		plural = true,
	},
	kloop = {
		message = "drops at your feet a small leatherbound book",
		short_item_name = "folio",
	},
	lilxeno = {
		counter_name = "lil xenomorph",
		message = "Your curiosity overcomes your gag reflex and you pick up the device",
		short_item_name = "transponders",
		plural = true,
	},
	llama = {
		message = "This gong will enable you to see things from a different perspective.",
		short_item_name = "gong",
	},
	pictsie = {
		counter_name = "pixie",
		message = "He tosses you a bottle of absinthe.",
		short_item_name = "absinthe",
		plural = true,
	},
	tronguy = {
		counter_name = "rogue program",
		message = "&quot;Please accept this token of my devotion to my user,&quot; and hands you an actual, literal token.",
		short_item_name = "tokens",
		plural = true,
	},
	uc = {
		counter_name = "unconscious collective",
		message = "dream stuff",
		short_item_name = "jar",
	},
	grimbrother = {
		message = "finishes an illustrated manuscript with a final flourish",
		short_item_name = "tale",
	},
	fistturkey = {
		message = "bottle of booze",
		short_item_name = "bottle",
	},
	galgrill = {
		message = "little pile of hot ashes falls out of the bottom",
		short_item_name = "ashes",
		plural = true,
	},
	goldmonkey = {
		message = "dislodging some golden dandruff",
		short_item_name = "gold",
	},
}

local function counter_name(familiar, info)
	local name = info.counter_name or familiar
	return "familiar." .. name .. "." .. info.short_item_name
end

add_printer("/charpane.php", function()
	local familiar = familiarpicture()
	local info = drop_familiars[familiar]
	if not info then return end

	local item = get_daily_counter(counter_name(familiar, info))

	local compact = item .. " / " .. 5
	local normal = compact .. " " .. info.short_item_name
	if not info.plural then
		normal = normal .. "s"
	end

	print_familiar_counter(compact, normal)
end)

for familiar, info in pairs(drop_familiars) do
	local counter_name = counter_name(familiar, info)
	add_processor("familiar message: " .. familiar, function()
		if text:contains(info.message) then
			increase_daily_counter(counter_name)
		end
	end)
	add_tracked_variables_display("day", function()
		return { title = "Familiar drops (" .. familiar .. ")", value = get_daily_counter(counter_name) .. " / 5 " .. info.short_item_name }
	end)
	track_familiar_info(familiar, function()
		return {
			count = get_daily_counter(counter_name),
			max = 5,
			info = info.short_item_name,
			type = "counter"
		}
	end)
end
