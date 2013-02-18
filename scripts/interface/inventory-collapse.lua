add_printer("/inventory.php", function()
	if text:contains([[function toggle(section)]]) then
		text = text:gsub([[function toggle%(section%)
%b{}]], [[%0

function toggle_kolproxy(section, title, id) {
	toggle(section)

	var whichbit = sections[section]
	var div = getObj("section" + whichbit)
	if (!div)
	  return

	var h = getObj("kolproxy_header" + id)
	var t = getObj("kolproxy_headertable" + id)
	if (div.style.display == "none") {
		h.innerHTML = title + " (collapsed)"
		t.style.opacity = 0.4;
	} else {
		h.innerHTML = title
		t.style.opacity = 1.0;
	}
}
]])
		local id = 0
		text = text:gsub([[<table  class="stuffbox"(.-)(<a class=nounder href=")javascript:toggle%('([^']-)'%)(;"><font color=white)>([^<]-)(<.-)(<div class="collapse"[^>]->)]], function(t, a, section, font, title, filler, div)
			id = id + 1
			local showtitle = title
			local style = ""
			if div:match("display: none") then
				showtitle = title .. " (collapsed)"
				style = [[ style="opacity: 0.4;"]]
			end
			return [[<table id="kolproxy_headertable]] .. id .. [[" class="stuffbox"]] .. style .. t .. a .. "javascript:toggle_kolproxy('" .. section .. "', '" .. title .. "', '" .. id .. "')" .. font .. [[ id="kolproxy_header]] .. id .. [[">]] .. showtitle .. filler .. div
		end)
	end
end)
