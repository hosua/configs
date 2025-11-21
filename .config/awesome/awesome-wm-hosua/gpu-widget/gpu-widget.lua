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
	}

	local mem_text_widget = wibox.widget.textbox()
	local temp_text_widget = wibox.widget.textbox()

	local arc_widget = wibox.widget({
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
				mem_text_widget,
				arc_widget,
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

	local update_widget = function()
		local temp_text = stats.temp or "N/A"
		local mem_text = "N/A"
		local percent = 0

		if stats.used and stats.total and stats.total > 0 then
			local used_mb = stats.used
			local total_mb = stats.total
			percent = (used_mb / total_mb) * 100
			mem_text = string.format("%.0f/%.0f MiB", used_mb, total_mb)
		end

		temp_text_widget:set_markup(string.format("GPU: %s |", temp_text))
		mem_text_widget:set_text(mem_text)
		arc_widget.value = percent
	end

	watch([[nvidia-smi -q -d MEMORY,TEMPERATURE]], _config.refresh_rate, function(_, stdout)
		if not stdout or stdout == "" then
			return
		end

		local temp_match = stdout:match("GPU Current Temp%s*:%s*(%d+)%s*C")
		local used_match = stdout:match("Used%s*:%s*(%d+)%s*MiB")
		local total_match = stdout:match("Total%s*:%s*(%d+)%s*MiB")

		if temp_match then
			stats.temp = temp_match .. "°C"
		end

		if used_match then
			stats.used = tonumber(used_match)
		end

		if total_match then
			stats.total = tonumber(total_match)
		end

		update_widget()
	end, widget)

	update_widget()

	return widget
end

return setmetatable(gpu_widget, {
	__call = function(_, ...)
		return worker(...)
	end,
})
