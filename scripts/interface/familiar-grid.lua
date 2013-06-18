fams_per_line = 2

function make_familiar_grid(favestr, pwdhash, expired_trendy_fams)
	expired_trendy_fams = expired_trendy_fams or {} -- WORKAROUND: Fave fams array from the server includes fams you can't use
	if not favestr then
		return "", {}
	end
	local extra_js = [[
<script type="text/javascript">
	function switch_fam(id) {
		$.ajax({
			type: 'GET',
			url: '/familiar.php?action=newfam&password=]]..pwdhash..[[&newfam='+id+'&ajax=1',
			cache:false,
			global:false,
			success: function() {
				top.charpane.location.href = 'charpane.php';
			}
		});
	}
</script>]]
	local fams = {}
	for pic, id in favestr:gmatch([=[%[".-","[^"]-","([^"]-)",([0-9]-)%]]=]) do -- TODO-future: redo regex?
		if not expired_trendy_fams[tonumber(id)] and tonumber(id) ~= 0 then -- CDM bug workaround: spurious id = 0 fam can be at the end of the array
			local onclickajax = "switch_fam(" .. id.. ")" -- this gets cancelled if the page is reloaded while the ajax is running, which is annoying
			local link = [[<a href="javascript:]] .. onclickajax .. [["><img style="cursor: pointer; border: solid thin white;" src="http://images.kingdomofloathing.com/itemimages/]]..pic..[[.gif" width="30" height="30"></a>]]
			fams[pic] = { link = link, id = tonumber(id), pic = pic }
		end
	end
	return extra_js, fams
end

add_printer("/charpane.php", function()
	local favestr = text:match("var FAMILIARFAVES = %[(.-)%];")
	if favestr then
		local pwdhash = text:match([[var pwdhash = "([0-9a-f]+)";]])
		local extra_js, fams = make_familiar_grid(favestr, pwdhash)
		text = text:gsub("</head>", function(x) return extra_js .. x end)
		text = text:gsub([[(<a target=mainpane href="familiar.php" class="familiarpick"><img src="http://images.kingdomofloathing.com/itemimages/)([^"]-)(.gif" width=30 height=30 )border=0(></a>)]], function(pre, fampic, y, z)
			fams[fampic] = { link = pre .. fampic .. y .. [[style="border: solid thin black"]] .. z }

			local famnames = {}
			for a, b in pairs(fams) do
				table.insert(famnames, a)
			end
			table.sort(famnames)
			local famchoosertext = ""
			local spacetimer = 1
			for _, b in ipairs(famnames) do
				famchoosertext = famchoosertext .. fams[b].link
				if spacetimer >= fams_per_line then
					famchoosertext = famchoosertext .. "<br>"
					spacetimer = 1
				else
					spacetimer = spacetimer + 1
				end
			end
			return famchoosertext
		end)
	end
end)
