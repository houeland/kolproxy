function visit_campground_garden()
	return async_get_page("/campground.php", { action = "garden", pwd = session.pwd })
end
