------------------------------------------------------------------
-- This script adds some convenient links to the KoL wiki.      --
-- Description popup windows link the name of whatever is being --
-- described to the wiki (while also closing the popup window), --
-- and monster and adventure names also link to the wiki.       --
------------------------------------------------------------------

register_setting {
	name = "show The KoL Wiki links",
	description = "Enable item, monster, and adventure names linking to their page on The KoL Wiki.",
	group = "other",
	default_level = "enthusiast",
}

local function printer_replace(pattern, substituter)
	return function()
		if setting_enabled("show The KoL Wiki links") then
			text = text:gsub(pattern, substituter)
		end
	end
end

local function link_substitution_function(extra)
	extra = extra or ""
	return function(pre, name, post)
		return pre .. [[<a href="http://kol.coldfront.net/thekolwiki/index.php/Special:Search?search=]] .. name .. [[&go=Go" target="_blank"]] .. extra .. ">" .. name .. "</a>" .. post
	end
end

local link_substitution_close = link_substitution_function([[ onclick="window.close();"]])
local link_substitution_noclose = link_substitution_function()

-- Description popup windows, these make the name link to the wiki page with the added function of closing the popup if you click them.
add_printer("/desc_item.php", printer_replace([[(<br><b>)([^<>]-)(</b></center><p><blockquote>)]], link_substitution_close))
add_printer("/desc_familiar.php", printer_replace([[(<div id="description">%s*<font face=Arial,Helvetica><center><b>)([^<>]-)(</b><p><img)]], link_substitution_close))
add_printer("/desc_skill.php", printer_replace([[(width=30 height=30><br><font face="Arial,Helvetica"><b>)([^<>]-)(</b><p><div id="smallbits" class=small>)]], link_substitution_close))
add_printer("/desc_guardian.php", printer_replace([[(, the level %d+ )([^<>]-)(<p><blockquote><table><tr><td>)]], link_substitution_close))
add_printer("/desc_effect.php", printer_replace([[( width=30 height=30><p><b>)([^<>]-)(</b><p></center><blockquote>)]], link_substitution_close))
add_printer("/desc_outfit.php", printer_replace([[(width=50 height=50><br><b>)([^<>]-)(</b><p>Outfit Bonus:)]], link_substitution_close))
-- Non combat adventures. Needs to specify that the font color on the link should be white, or it being a link will make it black with a blue background, which is unreadable
add_printer("/choice.php", printer_replace([[(bgcolor=blue><b>)([^<>]-[^:])(</b></td>)]], link_substitution_function([[ style="color: white;"]])))
-- Monster name. Nothing fancy. Pretty sure they intentionally set it up to be as nice as possible to pattern match, what with having an extra space if there's no prefix like "a ___" or "the ___"
add_printer("/fight.php", printer_replace([[(<span id='monname'>%w*%s*)([^<>]-)(</span>)]], link_substitution_noclose))
