local wibox = require("wibox")
local awful = require("awful")
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

-- Track the monitor client window
local monitor_client = nil

-- Add click functionality to toggle system monitor in floating magnified window
ram_widget:buttons(awful.util.table.join(
	awful.button({}, 1, function()
		-- Check if monitor window is already open
		if monitor_client and monitor_client.valid then
			-- Close the existing monitor window
			monitor_client:kill()
			monitor_client = nil
		else
			-- Use shell command to find first available monitor (btop > htop > top)
			local check_cmd = "command -v btop >/dev/null && echo btop || (command -v htop >/dev/null && echo htop || echo top)"
			awful.spawn.easy_async_with_shell(check_cmd, function(stdout)
				local monitor_cmd = stdout:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n", "")
				local target_screen = mouse.screen

				-- Launch terminal with monitor as floating window
				awful.spawn(awful.util.terminal .. " -o confirm_os_window_close=0 -e " .. monitor_cmd, {
					floating = true,
					screen = target_screen,
					callback = function(c)
						c.floating = true
						c.ontop = true
						c.screen = target_screen

						-- Apply magnification by scaling and centering the window
						local screen_geo = target_screen.geometry
						local width = screen_geo.width * 0.6
						local height = screen_geo.height * 0.6

						c:geometry({
							width = width,
							height = height,
							x = screen_geo.x + (screen_geo.width - width) / 2,
							y = screen_geo.y + (screen_geo.height - height) / 2
						})

						c:raise()
						client.focus = c
						monitor_client = c

						-- Clean up when window is closed
						c:connect_signal("unmanage", function()
							monitor_client = nil
						end)
					end
				})
			end)
		end
	end)
))

return { widget = ram_widget }
