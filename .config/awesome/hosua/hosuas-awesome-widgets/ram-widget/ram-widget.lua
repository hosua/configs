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
local monitor_tag = nil

-- Add click functionality to toggle system monitor in magnify mode
ram_widget:buttons(awful.util.table.join(
	awful.button({}, 1, function()
		-- Check if monitor window is already open
		if monitor_client and monitor_client.valid then
			-- Close the existing monitor window
			monitor_client:kill()
			monitor_client = nil
			-- Restore previous layout if we stored it
			if monitor_tag then
				monitor_tag = nil
			end
		else
			-- Use shell command to find first available monitor (btop > htop > top)
			local check_cmd = "command -v btop >/dev/null && echo btop || (command -v htop >/dev/null && echo htop || echo top)"
			awful.spawn.easy_async_with_shell(check_cmd, function(stdout)
				local monitor_cmd = stdout:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n", "")

				-- Store current tag
				monitor_tag = awful.screen.focused().selected_tag

				-- Launch terminal with monitor (disable close confirmation for kitty)
				awful.spawn(awful.util.terminal .. " -o confirm_os_window_close=0 -e " .. monitor_cmd, {
					tag = monitor_tag,
					placement = awful.placement.centered,
				})

				-- Set layout to magnifier for the current tag
				awful.layout.set(awful.layout.suit.magnifier, monitor_tag)

				-- Capture the client when it's created
				local manage_handler
				manage_handler = function(c)
					-- Check if this is our monitor window by matching the command
					if c.pid then
						awful.spawn.easy_async_with_shell(
							string.format("ps -p %d -o command= | grep -E 'btop|htop|top'", c.pid),
							function(ps_stdout)
								if ps_stdout and ps_stdout ~= "" then
									monitor_client = c
									-- Disconnect this handler once we've found our client
									client.disconnect_signal("manage", manage_handler)

									-- Clean up when window is closed
									c:connect_signal("unmanage", function()
										monitor_client = nil
										monitor_tag = nil
									end)
								end
							end
						)
					end
				end
				client.connect_signal("manage", manage_handler)
			end)
		end
	end)
))

return { widget = ram_widget }
