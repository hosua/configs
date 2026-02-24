-------------------------------------------------
-- CPU Widget
-- Shows CPU usage with individual core details in popup
-- @author hosua
-------------------------------------------------

local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local math = require("math")
local string = require("string")

local cpu_widget = {}

local config = {
	refresh_rate = 1,
	popup_bg = "#2E3440",
	popup_border_color = "#4C566A",
	cores_per_row = 3, -- 3-column layout for compact display
}

local function worker(input)
	local args = input or {}

	local _config = {}
	for prop, value in pairs(config) do
		_config[prop] = args[prop] or beautiful[prop] or value
	end

	local widget_dir = debug.getinfo(1, "S").source:match("^@(.+/)[^/]+$")
	local cpu_icon = wibox.widget.imagebox()
	cpu_icon:set_image(widget_dir .. "cpu.svg")
	cpu_icon.resize = true
	cpu_icon.forced_width = 18
	cpu_icon.forced_height = 18

	local cpu_icon_container = wibox.widget({
		cpu_icon,
		top = 1,
		widget = wibox.container.margin,
	})

	local cpu_text = wibox.widget.textbox()
	cpu_text.font = beautiful.font or "Terminus 10"

	local cpu_arc = wibox.widget({
		max_value = 100,
		value = 0,
		thickness = 2,
		start_angle = 4.71238898,
		forced_height = 18,
		forced_width = 18,
		rounded_edge = true,
		bg = "#ffffff11",
		paddings = 0,
		colors = { beautiful.fg_normal or "#D8DEE9" },
		widget = wibox.container.arcchart,
	})

	local widget = wibox.widget({
		{
			cpu_icon_container,
			-- cpu_arc,
			spacing = 2,
			cpu_text,
			layout = wibox.layout.fixed.horizontal,
		},
		layout = wibox.container.margin,
		left = 4,
		right = 4,
	})

	local popup = awful.popup({
		ontop = true,
		visible = false,
		shape = gears.shape.rounded_rect,
		border_width = 1,
		border_color = _config.popup_border_color,
		bg = _config.popup_bg,
		maximum_width = 400,
		maximum_height = 500,
		offset = { y = 5 },
		widget = {},
	})

	local core_widgets = {}
	local rows_container = wibox.layout.fixed.vertical()
	rows_container.spacing = 4 -- Spacing between rows

	local cpu_name_text = wibox.widget.textbox()
	cpu_name_text.font = beautiful.font or "Terminus 10"
	cpu_name_text:set_markup("Loading...")

	local all_text = wibox.widget.textbox()
	all_text.font = beautiful.font or "Terminus 10"
	all_text.forced_width = 80

	local all_progress = wibox.widget({
		max_value = 100,
		value = 0,
		forced_height = 18,
		paddings = 1,
		margins = 0,
		border_width = 1,
		border_color = beautiful.bg_focus or "#4C566A",
		background_color = beautiful.bg_normal or "#2E3440",
		bar_border_width = 1,
		bar_border_color = beautiful.bg_focus or "#4C566A",
		color = "linear:100,0:0,0:0,#5E81AC:0.3,#BF616A:0.6," .. (beautiful.fg_normal or "#D8DEE9"),
		widget = wibox.widget.progressbar,
	})

	local all_row = wibox.widget({
		all_text,
		all_progress,
		spacing = 0,
		layout = wibox.layout.fixed.horizontal,
	})

	local function get_cpu_name()
		awful.spawn.easy_async(
			{ awful.util.shell, "-c", [[grep -m 1 "model name" /proc/cpuinfo | cut -d ':' -f 2 | sed 's/^ *//']] },
			function(stdout)
				if stdout and stdout ~= "" then
					local cpu_name = stdout:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n", "")
					if cpu_name ~= "" then
						cpu_name_text:set_markup("<b>" .. cpu_name .. "</b>")
					end
				end
			end
		)
	end

	local function create_core_widget(core_id)
		local core_text = wibox.widget.textbox()
		core_text.font = beautiful.font or "Terminus 10"
		core_text.forced_width = 80

		local core_arc = wibox.widget({
			max_value = 100,
			value = 0,
			thickness = 2,
			start_angle = 4.71238898,
			forced_height = 18,
			forced_width = 18,
			rounded_edge = true,
			bg = "#ffffff11",
			paddings = 0,
			colors = { beautiful.fg_normal or "#D8DEE9" },
			widget = wibox.container.arcchart,
		})

		local core_row = wibox.widget({
			core_text,
			core_arc,
			spacing = 0,
			layout = wibox.layout.fixed.horizontal,
		})

		return {
			text = core_text,
			arc = core_arc,
			row = core_row,
		}
	end

	local function update_popup(core_usages, overall_usage)
		if not core_usages or type(core_usages) ~= "table" then
			return
		end

		local sorted_cores = {}
		for core_id, _ in pairs(core_usages) do
			table.insert(sorted_cores, core_id)
		end
		table.sort(sorted_cores)

		local num_cores = #sorted_cores
		local num_rows = math.ceil(num_cores / _config.cores_per_row)

		-- Update overall CPU usage
		local usage_value = overall_usage or 0
		all_text:set_markup(string.format("CPU: %.2f%%", usage_value))
		all_progress.value = usage_value
		all_progress.forced_width = 280 -- Fixed width for 3 columns

		-- Clear and rebuild rows
		rows_container:reset()

		-- Create rows (each row has 3 cores)
		for row_idx = 0, num_rows - 1 do
			local row_layout = wibox.layout.fixed.horizontal()
			row_layout.spacing = 8

			for col_idx = 0, _config.cores_per_row - 1 do
				local core_idx = row_idx * _config.cores_per_row + col_idx + 1
				if core_idx <= num_cores then
					local core_id = sorted_cores[core_idx]

					-- Create or get cached core widget
					if not core_widgets[core_id] then
						core_widgets[core_id] = create_core_widget(core_id)
					end

					-- Update core usage
					local usage = core_usages[core_id] or 0
					core_widgets[core_id].text:set_markup(string.format("C%d: %.2f%%", core_id, usage))
					core_widgets[core_id].arc.value = usage

					row_layout:add(core_widgets[core_id].row)
				end
			end

			rows_container:add(row_layout)
		end

		-- Build main layout
		local main_layout = wibox.layout.fixed.vertical()
		main_layout:add(cpu_name_text)
		main_layout:add(all_row)
		main_layout:add(rows_container)

		popup:setup({
			main_layout,
			margins = 8,
			widget = wibox.container.margin,
		})
	end

	local function update_widget(overall_usage, core_usages)
		local usage = overall_usage or 0
		cpu_text:set_markup(string.format(" %.2f%%", usage))
		cpu_arc.value = usage

		if popup.visible then
			update_popup(core_usages, overall_usage)
		end
	end

	-- Toggle popup on click
	widget:buttons(awful.util.table.join(awful.button({}, 1, function()
		if popup.visible then
			popup.visible = false
		else
			popup:move_next_to(mouse.current_widget_geometry)
			popup.visible = true
			update_popup(core_usages, overall_usage)
		end
	end)))

	local mpstat_cmd = { awful.util.shell, "-c", [[mpstat -P ALL 1 1 2>&1 | awk 'NR > 3 {print $2, $NF}']] }

	local core_usages = {}
	local overall_usage = 0

	watch(mpstat_cmd, _config.refresh_rate, function(_, stdout)
		if not stdout or stdout == "" then
			return
		end

		local overall_idle = nil
		local new_core_usages = {}

		for line in stdout:gmatch("[^\r\n]+") do
			line = line:gsub("^%s+", ""):gsub("%s+$", "")
			if line == "" then
				goto continue
			end

			local fields = {}
			for field in line:gmatch("%S+") do
				table.insert(fields, field)
			end

			if #fields >= 2 then
				local cpu_id = fields[1]
				local idle = tonumber(fields[2])

				if idle then
					if cpu_id == "all" then
						overall_idle = idle
					else
						local core_id = tonumber(cpu_id)
						if core_id then
							local usage = 100 - idle
							usage = math.min(100, math.max(0, usage))
							new_core_usages[core_id] = usage
						end
					end
				end
			end

			::continue::
		end

		core_usages = new_core_usages

		if overall_idle then
			overall_usage = 100 - overall_idle
			overall_usage = math.min(100, math.max(0, overall_usage))
			update_widget(overall_usage, core_usages)
		end
	end, widget)

	get_cpu_name()

	return widget
end

return setmetatable(cpu_widget, {
	__call = function(_, ...)
		return worker(...)
	end,
})
