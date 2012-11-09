--~ add_printer("/campground.php", function()
--~ 	text = string.gsub(text, [[(<input type=submit class=button value="Look Low")(>)]], [[
--~ 	<script type="text/javascript">
--~ 		function play_nemesis_music() {
--~ 			var div = document.createElement('div');
--~ 			div.innerHTML = '<iframe style="visibility: hidden;" src="http://www.youtube.com/v/hrML6s1wNHk?autoplay=1&start=9">';
--~ 			top.menupane.document.getElementsByTagName("body")[0].appendChild(div);
--~ 		}
--~ 	</script>
--~ 	%1 onclick="javascript:play_nemesis_music()"%2]])
--~ end)

--~ add_printer("/topmenu.php", function()
--~ 	text = string.gsub(text, "</head>", [[
--~ <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"></script>
--~ 	%0]])
--~ 	text = string.gsub(text, "</body>", [[
--~ 	<div id="nemesis_video"></div>
--~ <script type="text/javascript">
--~     swfobject.embedSWF("http://www.youtube.com/v/hrML6s1wNHk?enablejsapi=1&start=9", "nemesis_video", "400", "200", "8", null, null, { allowScriptAccess: "always" }, null);
--~ 	function play_nemesis_music() {
--~ 		var nv = document.getElementById("nemesis_video")
--~ 		nv.playVideo()
--~ 	}
--~ 	function rewind_nemesis_music() {
--~ 	}
--~ 	function onYTPStateChange(newstate) {
--~ 		if (newstate == 0) {
--~ 			alert("newstate:" + newstate);
--~ 		}
--~ 	}
--~ 	function onYouTubePlayerReady() {
--~ 		var nv = document.getElementById("nemesis_video")
--~ 		nv.addEventListener("onStateChange", "onYTPStateChange")
--~ 		nv.playVideo()
--~ 		nv.pauseVideo()
--~ 	}
--~ </script>
--~ 	%0]])
--~ end)

add_printer("/choice.php", function()
	if adventure_title == "Flying In Circles" then
		text = string.gsub(text, [[(<input class=button type=submit value="Continue")(>)]], [[
	<script type="text/javascript">
		function play_nemesis_music() {
			var div = document.createElement('div');
			div.innerHTML = '<iframe style="visibility: hidden;" src="http://www.youtube.com/v/hrML6s1wNHk?autoplay=1&start=9">';
			top.menupane.document.getElementsByTagName("body")[0].appendChild(div);
		}
	</script>
	%1 onclick="javascript:play_nemesis_music()"%2]])
	end
end)
