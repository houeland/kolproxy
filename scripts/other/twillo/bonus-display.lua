register_setting {
	name = "show modifier estimates",
	description = "Show modifier estimates (+noncombat%, +item%, +ML. <b>Not always accurate</b>)",
	group = "charpane",
	default_level = "standard",
}

function estimate_companion_bonuses()
        local jarlcompanion = tonumber(status().jarlcompanion)
	if not jarlcompanion then return {} end
	local working_lunch = have_skill("Working Lunch") and 1 or 0
        if jarlcompanion == 1 then
		return { ["Item Drops from Monsters"] = 50 + 25 * working_lunch }
        elseif jarlcompanion == 2 then
		return { ["Combat Initiative"] = 50 + 25 * working_lunch }
        elseif jarlcompanion == 3 then
		return {}
        elseif jarlcompanion == 4 then
		return { ["Monster Level"] = 20 + 10 * working_lunch }
	else
		return {}
        end
end

function estimate_other_bonuses()
	local bonuses = {}
	add_modifier_bonuses(bonuses, { ["Monsters will be more attracted to you"] = estimate_other_combat() })
	add_modifier_bonuses(bonuses, { ["Item Drops from Monsters"] = estimate_other_item() })
	add_modifier_bonuses(bonuses, { ["Monster Level"] = estimate_other_ml() })
	add_modifier_bonuses(bonuses, { ["Combat Initiative"] = estimate_other_init() })
	add_modifier_bonuses(bonuses, { ["Meat from Monsters"] = estimate_other_meat() })
	return bonuses
end

function estimate_modifier_bonuses()
	local bonuses = {}
	add_modifier_bonuses(bonuses, estimate_equipment_bonuses())
	add_modifier_bonuses(bonuses, estimate_outfit_bonuses())
	add_modifier_bonuses(bonuses, estimate_buff_bonuses())
	add_modifier_bonuses(bonuses, estimate_companion_bonuses())
	add_modifier_bonuses(bonuses, estimate_other_bonuses())

	if bonuses["Monsters will be more attracted to you"] then
		bonuses["Monsters will be more attracted to you"] = adjust_combat(bonuses["Monsters will be more attracted to you"])
	end

	-- TODO: Separate between combat and underwater combat?
	add_modifier_bonuses(bonuses, { ["Monsters will be more attracted to you"] = estimate_underwater_combat() })

	-- TODO: Do something about initiative ML penalty here?

	return bonuses
end

add_printer("/charpane.php", function()
	if not setting_enabled("show modifier estimates") then return end

	local bonuses = estimate_modifier_bonuses()
	local ml_init_penalty = estimate_init_penalty(bonuses["Monster Level"] or 0)

	local com = bonuses["Monsters will be more attracted to you"] or 0
	local item = bonuses["Item Drops from Monsters"] or 0
	local ml = bonuses["Monster Level"] or 0
	local initial_init = bonuses["Combat Initiative"] or 0
	local adjusted_init = initial_init - ml_init_penalty
	local meat = bonuses["Meat from Monsters"] or 0

	local uncertaintystr = ""
	if not have_cached_data() then
		uncertaintystr = " ?"
	end
	print_charpane_value { normalname = "(Non)combat", compactname = "C/NC", value = string.format("%+d%%", com) .. uncertaintystr }
	print_charpane_value { normalname = "Item drops", compactname = "Item", value = string.format("%+.1f%%", floor_to_places(item, 1)) .. uncertaintystr }
	print_charpane_value { normalname = "ML", compactname = "ML", value = string.format("%+d", ml) .. uncertaintystr }
	print_charpane_value { normalname = "Initiative", compactname = "Init", value = string.format("%+d%%", adjusted_init) .. uncertaintystr, tooltip = string.format("%+d%% initiative - %d%% ML penalty = %+d%% combined", initial_init, ml_init_penalty, adjusted_init) }
	print_charpane_value { normalname = "Meat drops", compactname = "Meat", value = string.format("%+.1f%%", floor_to_places(meat, 1)) .. uncertaintystr }
end)
