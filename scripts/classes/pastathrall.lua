local thralls = {
	[1] = { name = "Vampieroghi", effect = "+HP" },
	[2] = { name = "Vermincelli", effect = "+MP" },
	[3] = { name = "Angel Hair Wisp", effect = "+init%" },
	[4] = { name = "Elbow Macaroni", effect = "mus=mys" },
	[5] = { name = "Penne Dreadful", effect = "mox=mys" },
	[6] = { name = "Lasagmbie", effect = "+meat%" },
	[7] = { name = "Spice Ghost", effect = "+item%" },
	[8] = { name = "Spaghetti Elemental", effect = "+stat" },
}

function maybe_get_pastathrall_name(thrallid)
	return (thralls[thrallid] or {}).name
end

function maybe_get_pastathrall_effect(thrallid)
	return (thralls[thrallid] or {}).effect
end

function describe_pastathrall(thrallid)
	if thralls[thrallid] then
		return string.format([[Lvl. %d %s <span style="white-space: nowrap">(%s)</span>]], pastathralllevel(), maybe_get_pastathrall_name(thrallid) or "?", maybe_get_pastathrall_effect(thrallid) or "?")
	else
		return string.format("Lvl. %d {thrallid:%d???}", pastathralllevel(), thrallid)
	end
end
