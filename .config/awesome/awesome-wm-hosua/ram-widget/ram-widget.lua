local wibox = require("wibox")
local lain = require("lain")
local beautiful = require("beautiful")

local widget_dir = debug.getinfo(1, "S").source:match("^@(.+/)[^/]+$")
local ram_icon = wibox.widget.imagebox()
ram_icon:set_image(widget_dir .. "ram.svg")
ram_icon.resize = true
ram_icon.forced_width = 18
ram_icon.forced_height = 18

local ram = lain.widget.mem({
	settings = function()
		local markup = lain.util.markup
		widget:set_markup(
			markup.font(beautiful.font, string.format("%.1f/%.0fGB", mem_now.used / 1000, mem_now.total / 1000))
		)
	end,
})

-- Create horizontal layout with icon and text
local ram_widget = wibox.widget({
	wibox.container.margin(ram_icon, 0, 0, 2, 0), -- top padding of 2 to center vertically
	ram.widget,
	layout = wibox.layout.fixed.horizontal,
	spacing = 4,
})

-- Return an object with widget property to match theme usage
return { widget = ram_widget }
