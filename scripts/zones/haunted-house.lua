add_choice_text("Dark in the Attic", function()
	local tbl = {
		["Take some mimeographs"] = "Get 3 staff guides (once per dungeon)",
		["Poke around in the broken appliances"] = { getitem = "ghost trap" },
		["Turn up the boombox"] = { text = "Raise dungeon ML", good_choice = true },
		["Turn down the boombox"] = "Lower dungeon ML",
	}
	if have("silver shotgun shell") then
		tbl["Investigate the banging"] = "Kill multiple werewolves with a silver shotgun shell"
	else
		tbl["Investigate the banging"] = { text = "Need a silver shotgun shell", leave_noturn = true }
	end
	return tbl
end)

add_choice_text("Debasement", function()
	local tbl = {
		["Check out the props room"] = "Get a chain, shell, or mirror",
		["Turn up the fog machine"] = { text = "Raise dungeon ML", good_choice = true },
		["Turn down the fog machine"] = "Lower dungeon ML",
	}
	if have_equipped("plastic vampire fangs") then
		tbl["Investigate the coffins"] = "Kill multiple vampires (once per dungeon)"
	else
		tbl["Investigate the coffins"] = { text = "Need plastic vampire fangs equipped", leave_noturn = true }
	end
	return tbl
end)

add_choice_text("Prop Deportment", {
	["Examine the chainsaw"] = { getitem = "chainsaw chain" },
	["Examine the reloading bench"] = "Melt down a silver item into a shotgun shell",
	["Examine the mirror"] = { getitem = "funhouse mirror" },
})

add_choice_text("The Unliving Room", function()
	local tbl = {
		["Close the windows"] = { text = "Raise dungeon ML", good_choice = true },
		["Open the windows"] = "Lower dungeon ML",
		["Open the box"] = "Get a random sexy halloween costume",
	}
	if have("chainsaw chain") then
		tbl["Enter the dining room"] = "Kill multiple zombies with a chainsaw chain"
	else
		tbl["Enter the dining room"] = { text = "Need a chainsaw chain", leave_noturn = true }
	end
	if have("funhouse mirror") then
		tbl["Look in the closet"] = "Kill multiple skeletons with a funhouse mirror"
	else
		tbl["Look in the closet"] = { text = "Need a funhouse mirror", leave_noturn = true }
	end
	return tbl
end)
