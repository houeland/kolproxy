add_printer("/showplayer.php", function()
	text = text:gsub("(>View Permanent Skills</a>)(</td>)", [[%1<br>
<script type="text/javascript">
	function submit_skills() {
		var skills_text = ""
		$('tr.pskill').each(function() {
			skills_text += $(this).text() + "\n";
		});
		$('#skillchecker_skills').val(skills_text);
		$('#skillchecker_form').submit();
	}
</script>
<form method="post" action="http://alliancefromhell.com/cgi-bin/hobo/skillChecker.cgi" id="skillchecker_form" style="display: none;">
<div><textarea name="skills" rows="10" cols="50" id="skillchecker_skills"></textarea></div>
<div><input type="submit"/></div>
</form>
	<a href="javascript:submit_skills()" style="color: green;">{ Skill-checker }</a>%2]])
end)
