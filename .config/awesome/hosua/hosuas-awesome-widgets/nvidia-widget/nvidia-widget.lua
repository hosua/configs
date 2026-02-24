-------------------------------------------------
-- Nvidia GPU Widget
-- Only works with Nvidia GPUs, sorry. I don't have an AMD GPU
-- @author hosua
-- @copyright 2025 hosua (I'm just kidding, feel free to do whatever you want with it)
-------------------------------------------------

local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local spawn = require("awful.spawn")
local nvidia_widget = {}

local config = {
	refresh_rate = 1,
	popup_bg = "#2E3440",
	popup_border_color = "#4C566A",
	show_icon = true,
	show_temp = true,
	show_power = true,
	show_vram = true,
	show_arc = true,
}

local function worker(input)
	local args = input or {}

	local _config = {}
	for prop, value in pairs(config) do
		if args[prop] ~= nil then
			_config[prop] = args[prop]
		elseif beautiful[prop] ~= nil then
			_config[prop] = beautiful[prop]
		else
			_config[prop] = value
		end
	end

	local stats = {
		temp = nil,
		temp_raw = nil,
		used = nil,
		total = nil,
		power = nil,
		power_limit = nil,
		gpu_name = nil,
		driver_version = nil,
	}

	local mem_text_widget = wibox.widget.textbox()
	local temp_text_widget = wibox.widget.textbox()
	local power_text_widget = wibox.widget.textbox()

	local widget_dir = debug.getinfo(1, "S").source:match("^@(.+/)[^/]+$")
	local gpu_icon = wibox.widget.imagebox()
	gpu_icon:set_image(widget_dir .. "gpu.svg")
	gpu_icon.resize = true
	gpu_icon.forced_width = 18
	gpu_icon.forced_height = 18
	gpu_icon.spacing = 2

	local gpu_icon_container = wibox.widget({
		gpu_icon,
		top = 1,
		widget = wibox.container.margin,
	})

	local mem_arc_widget = wibox.widget({
		max_value = 100,
		thickness = 2,
		start_angle = 4.71238898,
		forced_height = 18,
		forced_width = 18,
		rounded_edge = true,
		bg = "#ffffff11",
		paddings = 0,
		colors = { beautiful.fg_normal or "#FEFEFE" },
		widget = wibox.container.arcchart,
	})

	local power_arc_widget = wibox.widget({
		max_value = 100,
		thickness = 2,
		start_angle = 4.71238898,
		forced_height = 18,
		forced_width = 18,
		rounded_edge = true,
		bg = "#ffffff11",
		paddings = 0,
		colors = { beautiful.fg_normal or "#FEFEFE" },
		widget = wibox.container.arcchart,
	})

	local function build_widget_layout()
		local left_items = {}
		local has_data_segment = false

		if _config.show_icon then
			table.insert(left_items, gpu_icon_container)
		end

		if _config.show_temp then
			if has_data_segment then
				table.insert(left_items, wibox.widget.textbox(" |"))
			end
			table.insert(left_items, temp_text_widget)
			has_data_segment = true
		end

		if _config.show_power then
			if has_data_segment then
				table.insert(left_items, wibox.widget.textbox(" |"))
			end
			if _config.show_arc then
				table.insert(left_items, {
					power_arc_widget,
					power_text_widget,
					spacing = 4,
					layout = wibox.layout.fixed.horizontal,
				})
			else
				table.insert(left_items, power_text_widget)
			end
			has_data_segment = true
		end

		local left_layout = nil
		if #left_items > 0 then
			local t = {}
			for _, item in ipairs(left_items) do
				table.insert(t, item)
			end
			t.spacing = 8
			t.layout = wibox.layout.fixed.horizontal
			left_layout = wibox.widget(t)
		end

		local right_layout = nil
		if _config.show_vram then
			if _config.show_arc then
				right_layout = wibox.widget({
					{
						mem_arc_widget,
						mem_text_widget,
						spacing = 4,
						layout = wibox.layout.fixed.horizontal,
					},
					left = 8,
					widget = wibox.container.margin,
				})
			else
				right_layout = wibox.widget({
					mem_text_widget,
					left = 8,
					widget = wibox.container.margin,
				})
			end
		end

		local align_layout = wibox.widget({
			left_layout,
			nil,
			right_layout,
			layout = wibox.layout.align.horizontal,
		})

		return wibox.widget({
			align_layout,
			layout = wibox.container.margin,
			left = 4,
			right = 4,
		})
	end

	local widget = build_widget_layout()

	local popup = awful.popup({
		ontop = true,
		visible = false,
		shape = gears.shape.rounded_rect,
		border_width = 1,
		border_color = _config.popup_border_color,
		bg = _config.popup_bg,
		maximum_width = 600,
		maximum_height = 500,
		offset = { y = 5 },
		widget = {},
	})

	local function format_temp(celsius)
		if not celsius then
			return "N/A"
		end
		local fahrenheit = (celsius * 9 / 5) + 32
		return string.format("%.0f°C (%.0f°F)", celsius, fahrenheit)
	end

	local function create_popup_content()
		local gpu_name_text = stats.gpu_name or "N/A"
		local driver_version_text = stats.driver_version or "N/A"

		local power = "N/A"
		local power_percent = 0
		if stats.power and stats.power_limit and stats.power_limit > 0 then
			power = string.format("%.0f/%.0fW", stats.power, stats.power_limit)
			power_percent = (stats.power / stats.power_limit) * 100
		end

		local mem_display = "N/A"
		local mem_percent = 0
		if stats.used and stats.total and stats.total > 0 then
			mem_display = string.format("%.0f/%.0fMiB", stats.used, stats.total)
			mem_percent = (stats.used / stats.total) * 100
		end

		local temp_text = format_temp(stats.temp_raw)

		local temp_line = wibox.widget.textbox()
		temp_line:set_markup(string.format("<b>Temp</b> %s", temp_text))
		temp_line.font = "Terminus 10"

		local popup_power_arc = wibox.widget({
			max_value = 100,
			thickness = 2,
			start_angle = 4.71238898,
			forced_height = 14,
			forced_width = 14,
			rounded_edge = true,
			bg = "#ffffff11",
			paddings = 0,
			colors = { beautiful.fg_normal or "#FEFEFE" },
			widget = wibox.container.arcchart,
		})
		popup_power_arc.value = power_percent
		local power_value_text = wibox.widget.textbox(power)
		power_value_text.font = "Terminus 10"
		local power_label = wibox.widget.textbox()
		power_label:set_markup("<b>Power</b>")
		power_label.font = "Terminus 10"
		local power_line = wibox.widget({
			power_label,
			popup_power_arc,
			power_value_text,
			spacing = 4,
			layout = wibox.layout.fixed.horizontal,
		})

		local gpu_line = wibox.widget.textbox()
		gpu_line:set_markup(gpu_name_text)
		gpu_line.font = "Terminus 10"

		local driver_line = wibox.widget.textbox()
		driver_line:set_markup(string.format("<b>Driver</b> %s", driver_version_text))
		driver_line.font = "Terminus 10"
		local driver_line_placed = wibox.widget({
			driver_line,
			halign = "right",
			widget = wibox.container.place,
		})

		local gpu_line_placed = wibox.widget({
			gpu_line,
			halign = "center",
			widget = wibox.container.place,
		})

		local first_row = wibox.widget({
			driver_line_placed,
			gpu_line_placed,
			temp_line,
			layout = wibox.layout.align.horizontal,
		})

		local popup_mem_arc = wibox.widget({
			max_value = 100,
			thickness = 2,
			start_angle = 4.71238898,
			forced_height = 14,
			forced_width = 14,
			rounded_edge = true,
			bg = "#ffffff11",
			paddings = 0,
			colors = { beautiful.fg_normal or "#FEFEFE" },
			widget = wibox.container.arcchart,
		})
		popup_mem_arc.value = mem_percent
		local memory_label = wibox.widget.textbox()
		memory_label:set_markup("<b>VRAM</b>")
		memory_label.font = "Terminus 10"
		local memory_value_text = wibox.widget.textbox(mem_display)
		memory_value_text.font = "Terminus 10"
		local memory_line = wibox.widget({
			memory_label,
			popup_mem_arc,
			memory_value_text,
			spacing = 4,
			layout = wibox.layout.fixed.horizontal,
		})

		local second_row = wibox.widget({
			memory_line,
			nil,
			power_line,
			layout = wibox.layout.align.horizontal,
		})

		return wibox.widget({
			first_row,
			second_row,
			spacing = 6,
			layout = wibox.layout.fixed.vertical,
		})
	end

	local COL_PID = 72
	local COL_VRAM = 100
	local ROW_SPACING = 2
	local COL_NAME = 306
	local POPUP_CONTENT_WIDTH = COL_PID + COL_NAME + COL_VRAM + (2 * ROW_SPACING)

	local function make_table_row(pid_widget, name_widget, mem_widget)
		return wibox.widget({
			{
				pid_widget,
				forced_width = COL_PID,
				halign = "left",
				widget = wibox.container.place,
			},
			{
				name_widget,
				forced_width = COL_NAME,
				halign = "left",
				widget = wibox.container.place,
			},
			{
				mem_widget,
				forced_width = COL_VRAM,
				halign = "right",
				widget = wibox.container.place,
			},
			spacing = ROW_SPACING,
			layout = wibox.layout.fixed.horizontal,
		})
	end

	local function create_process_table(processes)
		local header_pid = wibox.widget.textbox("<b>PID</b>")
		header_pid.font = "Terminus 10"
		header_pid.wrap = "off"
		local header_name = wibox.widget.textbox("<b>Process Name</b>")
		header_name.font = "Terminus 10"
		header_name.wrap = "off"
		local header_mem = wibox.widget.textbox("<b>VRAM Used</b>")
		header_mem.font = "Terminus 10"
		header_mem.wrap = "off"

		local header_row = make_table_row(header_pid, header_name, header_mem)
		local process_rows = { header_row }

		for _, process in ipairs(processes) do
			local parts = {}
			for part in process:gmatch("([^|]+)") do
				table.insert(parts, part)
			end
			if #parts >= 3 then
				local pid = parts[1]
				local mem = parts[#parts]
				local name = table.concat(parts, "|", 2, #parts - 1)
				pid = pid:gsub("^%s+", ""):gsub("%s+$", "")
				name = name:gsub("^%s+", ""):gsub("%s+$", "")
				mem = mem:gsub("^%s+", ""):gsub("%s+$", "")

				local full_name = name
				local is_truncated = false
				if #name > 64 then
					name = name:sub(1, 61) .. "..."
					is_truncated = true
				end

				local pid_widget = wibox.widget.textbox(pid)
				pid_widget.font = "Terminus 9"
				pid_widget.wrap = "off"

				local name_widget = wibox.widget.textbox(name)
				name_widget.font = "Terminus 9"
				name_widget.wrap = "off"
				name_widget.ellipsize = "end"

				local mem_widget = wibox.widget.textbox(mem)
				mem_widget.font = "Terminus 9"
				mem_widget.wrap = "off"

				local name_container = wibox.widget({
					{
						name_widget,
						forced_width = COL_NAME,
						halign = "left",
						widget = wibox.container.place,
					},
					bg = "#00000000",
					widget = wibox.container.background,
				})

				local row = make_table_row(pid_widget, name_container, mem_widget)

				if is_truncated then
					local tooltip_textbox = wibox.widget.textbox(full_name)
					tooltip_textbox.font = "Terminus 9"
					tooltip_textbox.wrap = "char"

					local tooltip_width = 400

					local tooltip_widget = wibox.widget({
						{
							tooltip_textbox,
							margins = 8,
							widget = wibox.container.margin,
						},
						forced_width = tooltip_width,
						widget = wibox.container.constraint,
					})

					local tooltip = awful.popup({
						ontop = true,
						visible = false,
						shape = gears.shape.rounded_rect,
						border_width = 1,
						border_color = _config.popup_border_color,
						bg = _config.popup_bg,
						fg = beautiful.fg_normal or "#D8DEE9",
						maximum_width = tooltip_width,
						offset = { y = 5 },
						widget = tooltip_widget,
					})

					name_container:connect_signal("mouse::enter", function()
						tooltip:move_next_to(mouse.current_widget_geometry)
						tooltip.visible = true
					end)

					name_container:connect_signal("mouse::leave", function()
						tooltip.visible = false
					end)
				end
				table.insert(process_rows, row)
			end
		end

		return process_rows
	end

	local function update_popup()
		local layout_table = {}
		layout_table.layout = wibox.layout.fixed.vertical
		table.insert(layout_table, create_popup_content())
		table.insert(
			layout_table,
			wibox.widget({
				wibox.widget.textbox(""),
				forced_height = 10,
				widget = wibox.container.constraint,
			})
		)

		local process_cmd = [[
			nvidia-smi -q | awk '
				BEGIN { OFS="|" }
				/Process ID/ { pid=$NF }
				/Name/ { sub(/^.*: /, ""); name=$0 }
				/Used GPU Memory/ {
					sub(/^.*: /, "");
					mem=$0;
					split(mem, a, " ");
					mem_num=a[1];
					print pid, name, mem, mem_num
				}
			' | sort -t'|' -k4,4nr | awk -F'|' '{print $1 "|" $2 "|" $3}' | head -10
		]]

		spawn.easy_async_with_shell(
			process_cmd,
			function(process_stdout, process_stderr, process_exitreason, process_exitcode)
				if process_exitcode == 0 and process_stdout and process_stdout ~= "" then
					local processes = {}
					for line in process_stdout:gmatch("[^\r\n]+") do
						line = line:gsub("^%s+", ""):gsub("%s+$", "")
						if line and line ~= "" then
							table.insert(processes, line)
						end
					end

					if #processes > 0 then
						local process_rows = create_process_table(processes)
						local table_container = wibox.widget({
							spacing = 2,
							layout = wibox.layout.fixed.vertical,
						})
						for _, row in ipairs(process_rows) do
							table_container:add(row)
						end
						local full_width_table = wibox.widget({
							table_container,
							forced_width = POPUP_CONTENT_WIDTH,
							halign = "left",
							widget = wibox.container.place,
						})
						table.insert(layout_table, full_width_table)
					end
				end

				popup:setup({
					layout_table,
					margins = 8,
					widget = wibox.container.margin,
				})
			end
		)
	end

	widget:buttons(awful.util.table.join(awful.button({}, 1, function()
		if popup.visible then
			popup.visible = false
		else
			popup:move_next_to(mouse.current_widget_geometry)
			popup.visible = true
			update_popup()
		end
	end)))

	local update_widget = function()
		local temp_text = "N/A"
		if stats.temp_raw then
			temp_text = string.format("%.0f°C", stats.temp_raw)
		end
		local power_text = "N/A"
		local mem_text = "N/A"
		local mem_percent = 0
		local power_percent = 0

		if stats.power and stats.power_limit and stats.power_limit > 0 then
			power_percent = (stats.power / stats.power_limit) * 100
			power_text = string.format("%.0f/%.0fW", stats.power, stats.power_limit)
		end

		if stats.used and stats.total and stats.total > 0 then
			local used_mb = stats.used
			local total_mb = stats.total
			mem_percent = (used_mb / total_mb) * 100
			mem_text = string.format("%.0f/%.0fMiB", used_mb, total_mb)
		end

		if _config.show_temp then
			temp_text_widget:set_markup(temp_text)
		end
		if _config.show_power then
			power_text_widget:set_text(power_text)
			power_arc_widget.value = power_percent
		end
		if _config.show_vram then
			mem_text_widget:set_text(mem_text)
			mem_arc_widget.value = mem_percent
		end
	end

	watch(
		[[nvidia-smi --query-gpu=gpu_name,driver_version,memory.used,memory.total,temperature.gpu,power.draw,power.limit --format=csv,noheader,nounits]],
		_config.refresh_rate,
		function(_, stdout)
			if not stdout or stdout == "" then
				return
			end

			local gpu_name_str, driver_version_str, used_str, total_str, temp_str, power_str, power_limit_str =
				stdout:match("([^,]+),%s*([^,]+),%s*([%d%.]+),%s*([%d%.]+),%s*([%d%.]+),%s*([%d%.]+),%s*([%d%.]+)")

			if gpu_name_str then
				stats.gpu_name = gpu_name_str:gsub("^%s+", ""):gsub("%s+$", "")
			end

			if driver_version_str then
				stats.driver_version = driver_version_str:gsub("^%s+", ""):gsub("%s+$", "")
			end

			if temp_str then
				stats.temp_raw = tonumber(temp_str)
			end

			if used_str then
				stats.used = tonumber(used_str)
			end

			if total_str then
				stats.total = tonumber(total_str)
			end

			if power_str then
				stats.power = tonumber(power_str)
			end

			if power_limit_str then
				stats.power_limit = tonumber(power_limit_str)
			end

			update_widget()
			if popup.visible then
				update_popup()
			end
		end,
		widget
	)

	update_widget()

	return widget
end

return setmetatable(nvidia_widget, {
	__call = function(_, ...)
		return worker(...)
	end,
})
