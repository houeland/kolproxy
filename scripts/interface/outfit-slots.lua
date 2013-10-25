local function load_slots()
	local slots = ascension["interface.outfit slots"] or {}
	slots.outfits = slots.outfits or { {}, {}, {}, {}, {} }
	slots.familiars = slots.familiars or { 0, 0, 0, 0, 0 }
	-- >>> TODO: TEMPORARY WORKAROUND >>> --
	for i = 1, 5 do
		slots.familiars[i] = slots.familiars[i] or 0
	end
	-- <<< TODO: TEMPORARY WORKAROUND <<< --
	slots.selected = slots.selected or 1
	return slots
end

function switch_outfit_slot(slot)
	local slots = load_slots()
	slots.outfits[slots.selected] = equipment()
	slots.familiars[slots.selected] = familiarid()
	if equipment().familiarequip and (slots.familiars[slots.selected] or 0) ~= (slots.familiars[slot] or 0) then
		local famname = maybe_get_familiarname(familiarid())
		local famequip = famname and datafile("familiars")[famname].familiarequip
		if famequip and maybe_get_itemname(equipment().familiarequip) == famequip then
		else
			unequip_slot("familiarequip")
		end
	end
	slots.selected = slot
	pcall(switch_familiarid, slots.familiars[slots.selected] or 0)
	pcall(set_equipment, slots.outfits[slots.selected] or {})
	ascension["interface.outfit slots"] = slots
end

switch_outfit_slot_href = add_automation_script("custom-outfit-slot", function()
	local slot = tonumber(params.slot)
	if load_slots().outfits[slot] then
		switch_outfit_slot(slot)
		return "Done.", requestpath
	end
	return "Failed.", requestpath
end)

function get_outfit_slots_script()
	return [[
<script type="text/javascript">
	function switch_outfit_slot(slot) {
		$.ajax({
			type: 'GET',
			url: '/kolproxy-automation-script?automation-script=custom-outfit-slot&pwd=]]..session.pwd..[[&slot=' + slot,
			cache: false,
			global: false,
			success: function() {
				top.charpane.location.href = 'charpane.php';
			}
		});
	}
</script>
]]
end

function get_outfit_slots_line()
	local links = {}
	local slots = load_slots()
	for a, _ in ipairs(slots.outfits) do
		if a == slots.selected then
			table.insert(links, string.format([[<a href="javascript:switch_outfit_slot(%d)" style="color: black">[%d]</a>]], a, a))
		else
			table.insert(links, string.format([[<a href="javascript:switch_outfit_slot(%d)" style="color: gray">[%d]</a>]], a, a))
		end
	end
	return table.concat(links, " ")
end
