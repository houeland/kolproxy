-- TODO: display this somewhere?

add_processor("/fight.php", function()
	if text:contains("launch a blast of white hot atomic energy") then
		day["nanorhino banished monster"] = monstername()
	end
end)
