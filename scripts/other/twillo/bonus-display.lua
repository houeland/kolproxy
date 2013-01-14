register_setting {
	name = "show modifier estimates",
	description = "Show modifier estimates (+noncombat%, +item%, +ML. <b>Not always accurate</b>)",
	group = "charpane",
	default_level = "standard",
}

add_printer("/charpane.php", function()
	if not setting_enabled("show modifier estimates") then return end

	local eq_bonuses = get_equipment_bonuses()
	local outfit_bonuses = get_outfit_bonuses()
	local buff_bonuses = get_buff_bonuses()

	local com = estimate_other_com() + eq_bonuses.combat + outfit_bonuses.combat + buff_bonuses.combat
	com = adjust_com(com)
	local item = estimate_other_item() + eq_bonuses.item + outfit_bonuses.item + buff_bonuses.item
	local ml = estimate_other_ml() + eq_bonuses.ml + outfit_bonuses.ml + buff_bonuses.ml
	local init = estimate_other_init() + eq_bonuses.initiative + outfit_bonuses.initiative + buff_bonuses.initiative
	local ml_init_penalty = -estimate_init_penalty(ml)
	local total_init = init + ml_init_penalty
	local meat = estimate_other_meat() + eq_bonuses.meat + outfit_bonuses.meat + buff_bonuses.meat
	
	local uncertaintystr = ""
	if not have_cached_data() then
		uncertaintystr = " ?"
	end
	print_charpane_value { normalname = "(Non)combat", compactname = "C/NC", value = string.format("%+d%%", com) .. uncertaintystr }
	print_charpane_value { normalname = "Item drops", compactname = "Item", value = string.format("%+.1f%%", floor_to_places(item, 1)) .. uncertaintystr }
	print_charpane_value { normalname = "ML", compactname = "ML", value = string.format("%+d", ml) .. uncertaintystr }
	print_charpane_value { normalname = "Initiative", compactname = "Init", value = string.format("%+d%%", init) .. uncertaintystr, tooltip = string.format("%+d%% initiative - %d%% ML penalty = %+d%% combined", total_init, ml_init_penalty, init) }
	print_charpane_value { normalname = "Meat drops", compactname = "Meat", value = string.format("%+.1f%%", floor_to_places(meat, 1)) .. uncertaintystr }
end)
