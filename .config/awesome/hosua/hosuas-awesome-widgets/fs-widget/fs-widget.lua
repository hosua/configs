local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")

local storage_bar_widget = {}

--- Table with widget configuration, consists of three sections:
---  - general - general configuration
---  - widget - configuration of the widget displayed on the wibar
---  - popup - configuration of the popup
local config = {}

-- general
config.mounts = { "/" }
config.refresh_rate = 60
config.show_storage_bar = true

-- wibar widget
config.widget_width = 40
config.widget_bar_color = "#aaaaaa"
config.widget_onclick_bg = "#ff0000"
config.widget_border_color = "#535d6c66"
config.widget_background_color = "#22222233"

-- popup
config.popup_bg = "#22222233"
config.popup_border_width = 1
config.popup_border_color = "#535d6c66"
config.popup_bar_color = "#aaaaaa"
config.popup_bar_background_color = "#22222233"
config.popup_bar_border_color = "#535d6c66"

local function worker(user_args)
	local args = user_args or {}

	local _config = {}
	for prop, value in pairs(config) do
		if args[prop] ~= nil then
			_config[prop] = args[prop]
		else
			_config[prop] = beautiful[prop] or value
		end
	end

	local widget_dir = debug.getinfo(1, "S").source:match("^@(.+/)[^/]+$")
	if widget_dir then
		widget_dir = widget_dir:gsub("^~", os.getenv("HOME"))
	end

	if _config.show_storage_bar then
		storage_bar_widget = wibox.widget({
			{
				id = "progressbar",
				color = _config.widget_bar_color,
				max_value = 100,
				forced_height = 20,
				forced_width = _config.widget_width,
				paddings = 2,
				margins = 4,
				border_width = 1,
				border_radius = 2,
				border_color = _config.widget_border_color,
				background_color = _config.widget_background_color,
				widget = wibox.widget.progressbar,
			},
			shape = function(cr, width, height)
				gears.shape.rounded_rect(cr, width, height, 4)
			end,
			widget = wibox.container.background,
			set_value = function(self, new_value)
				self:get_children_by_id("progressbar")[1].value = new_value
			end,
		})
	else
		local icon = wibox.widget.imagebox(widget_dir and (widget_dir .. "files.svg") or nil)
		-- icon.forced_width = 18
		-- icon.forced_height = 18
		storage_bar_widget = wibox.widget({
			wibox.container.place(icon, nil, "center"),
			widget = wibox.container.background,
			set_value = function() end,
		})
	end

	local disk_rows = {
		{ widget = wibox.widget.textbox },
		spacing = 4,
		layout = wibox.layout.fixed.vertical,
	}

	local disk_header = wibox.widget({
		{
			markup = "<b>Mount</b>",
			forced_width = 150,
			align = "left",
			widget = wibox.widget.textbox,
		},
		{
			markup = "<b>Used</b>",
			align = "left",
			widget = wibox.widget.textbox,
		},
		layout = wibox.layout.ratio.horizontal,
	})
	disk_header:ajust_ratio(2, 0.3, 0.7)

	local function spawn_ncdu(mount_path)
		local target_screen = mouse.screen
		local path_escaped = mount_path:gsub("\\", "\\\\"):gsub('"', '\\"')
		local cmd = awful.util.terminal .. ' -o confirm_os_window_close=0 -e sh -c "ncdu \\"' .. path_escaped .. '\\""'
		awful.spawn(cmd, {
			floating = true,
			screen = target_screen,
			callback = function(c)
				c.floating = true
				c.ontop = true
				c.screen = target_screen
				local screen_geo = target_screen.geometry
				local width = screen_geo.width * 0.6
				local height = screen_geo.height * 0.6
				c:geometry({
					width = width,
					height = height,
					x = screen_geo.x + (screen_geo.width - width) / 2,
					y = screen_geo.y + (screen_geo.height - height) / 2,
				})
				c:raise()
				client.focus = c
			end,
		})
	end

	local popup = awful.popup({
		bg = _config.popup_bg,
		fg = "#D8DEE9",
		ontop = true,
		visible = false,
		shape = gears.shape.rounded_rect,
		border_width = _config.popup_border_width,
		border_color = _config.popup_border_color,
		maximum_width = 400,
		offset = { y = 5 },
		widget = {},
	})

	storage_bar_widget:buttons(awful.util.table.join(awful.button({}, 1, function()
		if popup.visible then
			popup.visible = not popup.visible
			storage_bar_widget:set_bg("#00000000")
		else
			storage_bar_widget:set_bg(_config.widget_background_color)
			popup:move_next_to(mouse.current_widget_geometry)
		end
	end)))

	local disks = {}
	watch([[bash -c "df | tail -n +2"]], _config.refresh_rate, function(widget, stdout)
		for line in stdout:gmatch("[^\r\n$]+") do
			local filesystem, size, used, avail, perc, mount =
				line:match("([%p%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d%w]+)%s+([%d]+)%%%s+([%p%w]+)")

			disks[mount] = {}
			disks[mount].filesystem = filesystem
			disks[mount].size = size
			disks[mount].used = used
			disks[mount].avail = avail
			disks[mount].perc = perc
			disks[mount].mount = mount

			if disks[mount].mount == _config.mounts[1] then
				widget:set_value(tonumber(disks[mount].perc))
			end
		end

		for k, v in ipairs(_config.mounts) do
			local mount_path = disks[v].mount
			local mount_text = wibox.widget.textbox(disks[v].mount)
			mount_text.forced_width = 150
			local mount_btn = wibox.container.background(mount_text)
			local hover_bg = _config.popup_bar_border_color or "#535d6c99"
			mount_btn:connect_signal("mouse::enter", function()
				mount_btn:set_bg(hover_bg)
			end)
			mount_btn:connect_signal("mouse::leave", function()
				mount_btn:set_bg("#00000000")
			end)
			mount_btn:buttons(awful.util.table.join(awful.button({}, 1, function()
				spawn_ncdu(mount_path)
			end)))
			local row =
				wibox.widget({
					mount_btn,
					{
						color = _config.popup_bar_color,
						max_value = 100,
						value = tonumber(disks[v].perc),
						forced_height = 20,
						paddings = 1,
						margins = 4,
						border_width = 1,
						border_color = _config.popup_bar_border_color,
						background_color = _config.popup_bar_background_color,
						bar_border_width = 1,
						bar_border_color = _config.popup_bar_border_color,
						widget = wibox.widget.progressbar,
					},
					{
						text = math.floor(disks[v].used / 1024 / 1024) .. "/" .. math.floor(
							disks[v].size / 1024 / 1024
						) .. "GiB(" .. math.floor(disks[v].perc) .. "%)",
						widget = wibox.widget.textbox,
					},
					layout = wibox.layout.ratio.horizontal,
				})
			row:ajust_ratio(2, 0.3, 0.3, 0.4)

			disk_rows[k] = row
		end
		popup:setup({
			{
				disk_header,
				disk_rows,
				layout = wibox.layout.fixed.vertical,
			},
			margins = 8,
			widget = wibox.container.margin,
		})
	end, storage_bar_widget)

	return storage_bar_widget
end

return setmetatable(storage_bar_widget, {
	__call = function(_, ...)
		return worker(...)
	end,
})
