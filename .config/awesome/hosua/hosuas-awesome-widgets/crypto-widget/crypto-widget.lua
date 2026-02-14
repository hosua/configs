-------------------------------------------------
-- Crypto Widget
-- Displays cryptocurrency prices from LiveCoin Watch API
-- @author hosua
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local spawn = require("awful.spawn")

local crypto_widget = {}

local config = {
	refresh_rate = 20,
	popup_bg = "#2E3440",
	popup_border_color = "#4C566A",
}

-- Global shared state (singleton pattern)
local shared_state = {
	crypto_data = {},
	update_callbacks = {},
	timer_started = false,
	widget_dir = nil,
	json = nil,
	refresh_rate = nil,
}

-- Global function to fetch crypto data (runs once for all instances)
local function fetch_crypto_data()
	if not shared_state.widget_dir or not shared_state.json then
		return
	end

	local cmd = string.format("cd %s && ./get-map.sh", shared_state.widget_dir)

	spawn.easy_async_with_shell(cmd, function(stdout, stderr, exitreason, exitcode)
		if exitcode ~= 0 or not stdout or stdout == "" then
			-- Notify all callbacks of error
			for _, callback in ipairs(shared_state.update_callbacks) do
				callback(nil, "Fetch error")
			end
			return
		end

		-- Parse JSON
		local success, data = pcall(shared_state.json.decode, stdout)
		if not success or not data then
			-- Notify all callbacks of error
			for _, callback in ipairs(shared_state.update_callbacks) do
				callback(nil, "Parse error")
			end
			return
		end

		-- Update shared data
		shared_state.crypto_data = data

		-- Notify all registered widget instances
		for _, callback in ipairs(shared_state.update_callbacks) do
			callback(shared_state.crypto_data, nil)
		end
	end)
end

local function worker(input)
	local args = input or {}

	local _config = {}
	for prop, value in pairs(config) do
		_config[prop] = args[prop] or beautiful[prop] or value
	end

	-- Initialize shared state on first widget creation
	if not shared_state.timer_started then
		-- Get the widget directory path
		shared_state.widget_dir = debug.getinfo(1, "S").source:match("^@(.+/)[^/]+$")
		-- Load JSON library from awesome config
		shared_state.json = require("json")
		shared_state.refresh_rate = _config.refresh_rate
	end

	-- Main widget text
	local crypto_text_widget = wibox.widget.textbox()

	-- Icon widget
	local crypto_icon = wibox.widget.textbox("₿ ")
	crypto_icon.font = "Terminus Bold 10"

	local widget = wibox.widget({
		{
			crypto_icon,
			crypto_text_widget,
			spacing = 4,
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
		maximum_width = 700,
		maximum_height = 500,
		offset = { y = 5 },
		widget = {},
	})

	local function format_number(num)
		if not num then
			return "N/A"
		end

		-- Format large numbers with commas
		local formatted = tostring(num)
		if num >= 1000 then
			formatted = string.format("%.2f", num)
			local k
			while true do
				formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
				if k == 0 then
					break
				end
			end
		else
			formatted = string.format("%.2f", num)
		end
		return formatted
	end

	local function format_delta(delta)
		if not delta then
			return "N/A", "#FFFFFF"
		end

		local percent = (delta - 1) * 100
		local color
		if percent > 0 then
			color = "#A3BE8C" -- green
		elseif percent < 0 then
			color = "#BF616A" -- red
		else
			color = "#D8DEE9" -- white
		end

		return string.format("%+.2f%%", percent), color
	end

	local function create_popup_content()
		local widgets = {}

		if not shared_state.crypto_data or #shared_state.crypto_data == 0 then
			local error_text = wibox.widget.textbox("No crypto data available")
			error_text.font = "Terminus 10"
			table.insert(widgets, error_text)
			widgets.layout = wibox.layout.fixed.vertical
			return widgets
		end

		-- Header
		local header = wibox.widget.textbox("<b>Cryptocurrency Prices (USD)</b>")
		header.font = "Terminus Bold 11"
		table.insert(widgets, header)

		-- Separator
		table.insert(
			widgets,
			wibox.widget({
				wibox.widget.textbox(""),
				forced_height = 8,
				widget = wibox.container.constraint,
			})
		)

		-- Table header
		local header_row = wibox.widget({
			{
				wibox.widget.textbox("<b>Coin</b>"),
				font = "Terminus 10",
				forced_width = 120,
				halign = "left",
				widget = wibox.container.place,
			},
			{
				wibox.widget.textbox("<b>Price</b>"),
				font = "Terminus 10",
				forced_width = 90,
				halign = "right",
				widget = wibox.container.place,
			},
			{
				wibox.widget.textbox("<b>1h</b>"),
				font = "Terminus 10",
				forced_width = 55,
				halign = "right",
				widget = wibox.container.place,
			},
			{
				wibox.widget.textbox("<b>24h</b>"),
				font = "Terminus 10",
				forced_width = 55,
				halign = "right",
				widget = wibox.container.place,
			},
			{
				wibox.widget.textbox("<b>7d</b>"),
				font = "Terminus 10",
				forced_width = 55,
				halign = "right",
				widget = wibox.container.place,
			},
			{
				wibox.widget.textbox("<b>30d</b>"),
				font = "Terminus 10",
				forced_width = 55,
				halign = "right",
				widget = wibox.container.place,
			},
			{
				wibox.widget.textbox("<b>90d</b>"),
				font = "Terminus 10",
				forced_width = 55,
				halign = "right",
				widget = wibox.container.place,
			},
			{
				wibox.widget.textbox("<b>1y</b>"),
				font = "Terminus 10",
				forced_width = 55,
				halign = "right",
				widget = wibox.container.place,
			},
			spacing = 6,
			layout = wibox.layout.fixed.horizontal,
		})
		table.insert(widgets, header_row)

		-- Crypto rows
		for _, coin in ipairs(shared_state.crypto_data) do
			-- Get all delta periods
			local hour_change, hour_color = format_delta(coin.delta and coin.delta.hour)
			local day_change, day_color = format_delta(coin.delta and coin.delta.day)
			local week_change, week_color = format_delta(coin.delta and coin.delta.week)
			local month_change, month_color = format_delta(coin.delta and coin.delta.month)
			local quarter_change, quarter_color = format_delta(coin.delta and coin.delta.quarter)
			local year_change, year_color = format_delta(coin.delta and coin.delta.year)

			-- Display coin as "Name (CODE)" or just "CODE" if name not available
			local coin_display = coin.name and string.format("%s (%s)", coin.name, coin.code) or coin.code
			local name_widget = wibox.widget.textbox(coin_display)
			name_widget.font = "Terminus Bold 10"

			local price_widget = wibox.widget.textbox("$" .. format_number(coin.rate))
			price_widget.font = "Terminus 10"

			-- Create widgets for all deltas
			local hour_widget = wibox.widget.textbox(hour_change)
			hour_widget.font = "Terminus 9"
			hour_widget.markup = string.format('<span foreground="%s">%s</span>', hour_color, hour_change)

			local day_widget = wibox.widget.textbox(day_change)
			day_widget.font = "Terminus 9"
			day_widget.markup = string.format('<span foreground="%s">%s</span>', day_color, day_change)

			local week_widget = wibox.widget.textbox(week_change)
			week_widget.font = "Terminus 9"
			week_widget.markup = string.format('<span foreground="%s">%s</span>', week_color, week_change)

			local month_widget = wibox.widget.textbox(month_change)
			month_widget.font = "Terminus 9"
			month_widget.markup = string.format('<span foreground="%s">%s</span>', month_color, month_change)

			local quarter_widget = wibox.widget.textbox(quarter_change)
			quarter_widget.font = "Terminus 9"
			quarter_widget.markup = string.format('<span foreground="%s">%s</span>', quarter_color, quarter_change)

			local year_widget = wibox.widget.textbox(year_change)
			year_widget.font = "Terminus 9"
			year_widget.markup = string.format('<span foreground="%s">%s</span>', year_color, year_change)

			local row = wibox.widget({
				{
					name_widget,
					forced_width = 120,
					halign = "left",
					widget = wibox.container.place,
				},
				{
					price_widget,
					forced_width = 90,
					halign = "right",
					widget = wibox.container.place,
				},
				{
					hour_widget,
					forced_width = 55,
					halign = "right",
					widget = wibox.container.place,
				},
				{
					day_widget,
					forced_width = 55,
					halign = "right",
					widget = wibox.container.place,
				},
				{
					week_widget,
					forced_width = 55,
					halign = "right",
					widget = wibox.container.place,
				},
				{
					month_widget,
					forced_width = 55,
					halign = "right",
					widget = wibox.container.place,
				},
				{
					quarter_widget,
					forced_width = 55,
					halign = "right",
					widget = wibox.container.place,
				},
				{
					year_widget,
					forced_width = 55,
					halign = "right",
					widget = wibox.container.place,
				},
				spacing = 6,
				layout = wibox.layout.fixed.horizontal,
			})
			table.insert(widgets, row)
		end

		widgets.layout = wibox.layout.fixed.vertical
		return widgets
	end

	local function update_popup()
		local content = create_popup_content()
		popup:setup({
			content,
			margins = 12,
			widget = wibox.container.margin,
		})
	end

	widget:buttons(awful.util.table.join(awful.button({}, 1, function()
		if popup.visible then
			popup.visible = false
		else
			popup:move_next_to(mouse.current_widget_geometry)
			update_popup()
			popup.visible = true
		end
	end)))

	-- Widget-specific update callback
	local function update_widget_display(data, error_msg)
		if error_msg then
			crypto_text_widget:set_text(error_msg)
			return
		end

		-- Build compact display text showing first crypto (usually BTC)
		if data and #data > 0 then
			local btc = data[1]
			local price_text = format_number(btc.rate)
			local day_change, day_color = format_delta(btc.delta and btc.delta.day)

			crypto_text_widget.markup = string.format(
				'<span foreground="#FFFFFF">$%s</span> <span foreground="%s">%s</span>',
				price_text,
				day_color,
				day_change
			)
		else
			crypto_text_widget:set_text("No data")
		end

		-- Update popup if it's visible
		if popup.visible then
			update_popup()
		end
	end

	-- Register this widget's update callback
	table.insert(shared_state.update_callbacks, update_widget_display)

	-- Start global timer only once
	if not shared_state.timer_started then
		shared_state.timer_started = true

		-- Initial fetch
		fetch_crypto_data()

		-- Set up periodic updates (global timer, runs once for all instances)
		gears.timer({
			timeout = _config.refresh_rate,
			call_now = false,
			autostart = true,
			callback = function()
				fetch_crypto_data()
			end,
		})
	else
		-- If timer already started, trigger display update with existing data
		update_widget_display(shared_state.crypto_data, nil)
	end

	return widget
end

return setmetatable(crypto_widget, {
	__call = function(_, ...)
		return worker(...)
	end,
})
