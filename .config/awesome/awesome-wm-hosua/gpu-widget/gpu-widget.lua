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

local gpu_widget = {}

local config = {
	refresh_rate = 1,
}

local function worker(input)
	local args = input or {}
	local _config = gears.table.join({}, config, args)

	local stats = {
		temp = nil,
		used = nil,
		total = nil,
		power = nil,
		power_limit = nil,
	}

	local mem_text_widget = wibox.widget.textbox()
	local temp_text_widget = wibox.widget.textbox()
	local power_text_widget = wibox.widget.textbox()

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

	local widget = wibox.widget({
		{
			temp_text_widget,
			{
				power_text_widget,
				power_arc_widget,
				wibox.widget.textbox(" |"),
				spacing = 4,
				layout = wibox.layout.fixed.horizontal,
			},
			{
				mem_text_widget,
				mem_arc_widget,
				spacing = 4,
				layout = wibox.layout.fixed.horizontal,
			},
			spacing = 8,
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
		border_color = beautiful.bg_focus or beautiful.bg_normal,
		maximum_width = 600,
		maximum_height = 500,
		offset = { y = 5 },
		widget = {},
	})

	local function format_nvidia_smi_output(stdout, temp_value)
		local widgets = {}
		local gpu_data_line = nil

		for line in stdout:gmatch("[^\r\n]+") do
			line = line:gsub("^%s+", ""):gsub("%s+$", "")

			if line:match("^%+%-+%+") or line:match("^|%-%-") or line == "" then
			elseif line:match("^|%s+%d+%%") then
				gpu_data_line = line
				break
			end
		end

		if gpu_data_line then
			local power_match = gpu_data_line:match("(%d+W%s*/%s*%d+W)")
			local mem_match = gpu_data_line:match("(%d+MiB%s*/%s*%d+MiB)")

			if power_match and mem_match then
				local power = tostring(power_match):gsub("%s+", " ")
				local mem = tostring(mem_match):gsub("%s+", " ")
				local temp_text = temp_value or "N/A"

				local info_widget = wibox.widget.textbox()
				info_widget:set_markup(string.format("<b>Temperature:</b> %s    <b>Power:</b> %s    <b>Memory:</b> %s", temp_text, power, mem))
				info_widget.font = "Terminus 10"
				table.insert(widgets, info_widget)
			end
		end

		return widgets
	end

	local function create_process_table(processes)
		local header_pid = wibox.widget.textbox("<b>PID</b>")
		header_pid.font = "Terminus 10"
		local header_name = wibox.widget.textbox("<b>Process Name</b>")
		header_name.font = "Terminus 10"
		local header_mem = wibox.widget.textbox("<b>Mem Used</b>")
		header_mem.font = "Terminus 10"

		local header_row = wibox.widget({
			{
				header_pid,
				forced_width = 80,
				halign = "left",
				widget = wibox.container.place,
			},
			{
				header_name,
				forced_width = 100,
				halign = "left",
				widget = wibox.container.place,
			},
			{
				header_mem,
				forced_width = 100,
				halign = "right",
				widget = wibox.container.place,
			},
			spacing = 2,
			layout = wibox.layout.fixed.horizontal,
		})

		local process_rows = { header_row }

		for _, process in ipairs(processes) do
			local pid, name, mem = process:match("([^,]+),([^,]+),([^,]+)")
			if pid and name and mem then
				pid = pid:gsub("^%s+", ""):gsub("%s+$", "")
				name = name:gsub("^%s+", ""):gsub("%s+$", "")
				mem = mem:gsub("^%s+", ""):gsub("%s+$", "")

				local pid_widget = wibox.widget.textbox(pid)
				pid_widget.font = "Terminus 9"

				local name_widget = wibox.widget.textbox(name)
				name_widget.font = "Terminus 9"

				local mem_padded = string.format("%12s", mem)
				local mem_widget = wibox.widget.textbox(mem_padded)
				mem_widget.font = "Terminus 9"

				local row = wibox.widget({
					{
						pid_widget,
						forced_width = 80,
						halign = "left",
						widget = wibox.container.place,
					},
					{
						name_widget,
						forced_width = 100,
						halign = "left",
						widget = wibox.container.place,
					},
					{
						mem_widget,
						forced_width = 100,
						halign = "right",
						widget = wibox.container.place,
					},
					spacing = 2,
					layout = wibox.layout.fixed.horizontal,
				})
				table.insert(process_rows, row)
			end
		end

		return process_rows
	end

	local function update_popup()
		spawn.easy_async("nvidia-smi", function(stdout, stderr, exitreason, exitcode)
			if exitcode == 0 and stdout then
				local widgets = format_nvidia_smi_output(stdout, stats.temp)
				local layout_table = {}
				layout_table.layout = wibox.layout.fixed.vertical
				for _, widget_item in ipairs(widgets) do
					table.insert(layout_table, widget_item)
				end

				local separator = wibox.widget({
					wibox.widget.textbox(""),
					forced_height = 10,
					widget = wibox.container.constraint,
				})
				table.insert(layout_table, separator)

				local process_cmd =
					'nvidia-smi -q | awk \'/Process ID/ { pid=$NF } /Name/ { sub(/^.*: /, ""); name=$0 } /Used GPU Memory/ { sub(/^.*: /, ""); mem=$0; split(mem, a, " "); mem_num=a[1]; print pid "," name "," mem "," mem_num }\' | sort -t, -k4,4nr | cut -d, -f1-3 | head -10'

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
								for _, row in ipairs(process_rows) do
									table.insert(layout_table, row)
								end
							end
						end

						popup:setup({
							layout_table,
							margins = 8,
							widget = wibox.container.margin,
						})
					end
				)
			else
				local error_widget = wibox.widget.textbox()
				error_widget:set_markup("<b>Error:</b> Could not get GPU information")
				error_widget.font = "Terminus 9"
				popup:setup({
					{
						error_widget,
						layout = wibox.layout.fixed.vertical,
					},
					margins = 8,
					widget = wibox.container.margin,
				})
			end
		end)
	end

	local popup_timer = gears.timer({
		timeout = 1,
		autostart = false,
	})

	popup_timer:connect_signal("timeout", function()
		if popup.visible then
			update_popup()
		else
			popup_timer:stop()
		end
	end)

	popup:connect_signal("property::visible", function()
		if not popup.visible then
			popup_timer:stop()
		end
	end)

	widget:buttons(awful.util.table.join(awful.button({}, 1, function()
		if popup.visible then
			popup.visible = false
			popup_timer:stop()
		else
			popup:move_next_to(mouse.current_widget_geometry)
			popup.visible = true
			popup_timer:start()
			popup_timer:emit_signal("timeout")
		end
	end)))

	local update_widget = function()
		local temp_text = stats.temp or "N/A"
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
			mem_text = string.format("%.0f/%.0f MiB", used_mb, total_mb)
		end

		temp_text_widget:set_markup(string.format("GPU: %s |", temp_text))
		power_text_widget:set_text(power_text)
		mem_text_widget:set_text(mem_text)
		mem_arc_widget.value = mem_percent
		power_arc_widget.value = power_percent
	end

	watch(
		[[nvidia-smi --query-gpu=memory.used,memory.free,temperature.gpu,power.draw,power.limit --format=csv,noheader,nounits]],
		_config.refresh_rate,
		function(_, stdout)
			if not stdout or stdout == "" then
				return
			end

			local used_str, free_str, temp_str, power_str, power_limit_str =
				stdout:match("([%d%.]+),%s*([%d%.]+),%s*([%d%.]+),%s*([%d%.]+),%s*([%d%.]+)")

			if temp_str then
				stats.temp = string.format("%.0f°C", tonumber(temp_str))
			end

			if used_str then
				stats.used = tonumber(used_str)
			end

			if free_str and stats.used then
				stats.total = stats.used + tonumber(free_str)
			end

			if power_str then
				stats.power = tonumber(power_str)
			end

			if power_limit_str then
				stats.power_limit = tonumber(power_limit_str)
			end

			update_widget()
		end,
		widget
	)

	update_widget()

	return widget
end

return setmetatable(gpu_widget, {
	__call = function(_, ...)
		return worker(...)
	end,
})
