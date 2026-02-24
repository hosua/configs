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
local gfs = require("gears.filesystem")

local crypto_widget = {}

local function code_display(code)
	return (code or ""):gsub("_", "")
end

local config = {
	refresh_rate = 20, -- ensure that API is called < 10,000 times per day to remain within API daily limit. 20 works perfectly.
	popup_bg = "#2E3440",
	popup_border_color = "#4C566A",
	main_coin = "BTC", -- The coin shown on the widget itself
	fiat = "USD", -- Your preferred currency
	codes = { "BTC", "XMR", "ETH", "LTC", "PAXG" }, -- Your curated list to show when in mode = "map"
	mode = "list", -- list or map
	coins_to_display = 100, -- how many cryptocurrencies to show in list mode, max = 100
	sort_by = "rank", -- rank, price, volume, code, name, age
	sort_order = "ascending", -- sort_by ascending or descending
}

-- Global shared state (singleton pattern)
local shared_state = {
	crypto_data = {},
	update_callbacks = {},
	timer_started = false,
	widget_dir = nil,
	json = nil,
	refresh_rate = nil,
	main_coin = nil,
	fiat = nil,
	coins_to_display = nil,
	sort_by = nil,
	sort_order = nil,
}

local function fetch_crypto_data()
	if not shared_state.widget_dir or not shared_state.json then
		return
	end

	local cmd
	if shared_state.mode == "list" then
		cmd = string.format("cd %s && FIAT=%s LIMIT=100 ./get-list.sh", shared_state.widget_dir, shared_state.fiat)
	else
		local cap = math.min(shared_state.coins_to_display or 10, 100)
		local codes_slice = {}
		for i = 1, math.min(cap, #shared_state.codes) do
			codes_slice[i] = shared_state.codes[i]
		end
		local codes_json = shared_state.json.encode(codes_slice)
		cmd = string.format(
			"cd %s && CODES='%s' FIAT=%s ./get-map.sh",
			shared_state.widget_dir,
			codes_json,
			shared_state.fiat
		)
	end

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

		shared_state.crypto_data = data

		for _, coin in ipairs(data) do
			if coin.png32 and shared_state.widget_dir then
				local cache_dir = shared_state.widget_dir .. "cache"
				local cache_path = cache_dir .. "/" .. coin.code .. ".png"
				if not gfs.file_readable(cache_path) then
					gfs.make_directories(cache_dir)
					local function shell_escape(s)
						return "'" .. (s:gsub("'", "'\\''")) .. "'"
					end
					spawn.easy_async_with_shell(
						"curl -s -o " .. shell_escape(cache_path) .. " " .. shell_escape(coin.png32),
						function() end
					)
				end
			end
		end

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

	if not shared_state.timer_started then
		shared_state.widget_dir = debug.getinfo(1, "S").source:match("^@(.+/)[^/]+$")
		shared_state.json = require("json")
		shared_state.refresh_rate = _config.refresh_rate
		shared_state.main_coin = _config.main_coin
		shared_state.fiat = _config.fiat
		shared_state.codes = _config.codes
		shared_state.mode = _config.mode
		shared_state.coins_to_display = math.min(_config.coins_to_display or 10, 100)
	end

	-- Main widget text
	local crypto_text_widget = wibox.widget.textbox()

	local coin_imagebox = wibox.widget.imagebox()
	coin_imagebox.resize = true
	coin_imagebox.forced_width = 16
	coin_imagebox.forced_height = 16
	local coin_icon_centered = wibox.container.place(coin_imagebox)
	coin_icon_centered.valign = "center"

	local widget = wibox.widget({
		{
			coin_icon_centered,
			crypto_text_widget,
			spacing = 4,
			layout = wibox.layout.fixed.horizontal,
		},
		layout = wibox.container.margin,
		left = 4,
		right = 4,
	})

	local coin_col_width = 60
	local popup_content_width = coin_col_width + 90 + (55 * 6) + (2 * 7)
	local popup = awful.popup({
		ontop = true,
		visible = false,
		shape = gears.shape.rounded_rect,
		border_width = 1,
		border_color = _config.popup_border_color,
		bg = _config.popup_bg,
		maximum_width = popup_content_width + 24,
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

	local popup_header_height = 28
	local popup_row_height = 20
	local visible_row_count = 10
	local scroll_ptr = 0

	local function create_popup_content()
		if not shared_state.crypto_data or #shared_state.crypto_data == 0 then
			local error_text = wibox.widget.textbox("No crypto data available")
			error_text.font = "Terminus 10"
			return wibox.widget({
				error_text,
				layout = wibox.layout.fixed.vertical,
			})
		end

		local header_spacer = wibox.container.constraint(wibox.widget.textbox(""), "exact", 14, 10)
		local header_row = wibox.widget({
			{
				{
					header_spacer,
					wibox.widget.textbox("<b>Coin</b>"),
					layout = wibox.layout.fixed.horizontal,
				},
				forced_width = coin_col_width,
				halign = "left",
				widget = wibox.container.place,
			},
			{
				wibox.widget.textbox(string.format("<b>Price (%s)</b>", shared_state.fiat or "USD")),
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
			spacing = 2,
			layout = wibox.layout.fixed.horizontal,
		})

		local rows = wibox.layout.fixed.vertical()
		local num_coins = math.min(shared_state.coins_to_display or 10, #shared_state.crypto_data)
		for i = 1, num_coins do
			local coin = shared_state.crypto_data[i]
			-- Get all delta periods
			local hour_change, hour_color = format_delta(coin.delta and coin.delta.hour)
			local day_change, day_color = format_delta(coin.delta and coin.delta.day)
			local week_change, week_color = format_delta(coin.delta and coin.delta.week)
			local month_change, month_color = format_delta(coin.delta and coin.delta.month)
			local quarter_change, quarter_color = format_delta(coin.delta and coin.delta.quarter)
			local year_change, year_color = format_delta(coin.delta and coin.delta.year)

			local code_show = code_display(coin.code)
			local coin_color = coin.color or "#888888"
			local color_square = wibox.container.background(
				wibox.container.constraint(wibox.widget.textbox(""), "exact", 10, 10),
				coin_color
			)
			local icon_cell
			if shared_state.widget_dir then
				local cache_path = shared_state.widget_dir .. "cache/" .. coin.code .. ".png"
				if gfs.file_readable(cache_path) then
					local row_icon = wibox.widget.imagebox(cache_path)
					row_icon.resize = true
					row_icon.forced_width = 10
					row_icon.forced_height = 10
					icon_cell = row_icon
				else
					icon_cell = color_square
				end
			else
				icon_cell = color_square
			end
			local name_widget = wibox.widget.textbox(code_show)
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
					{
						icon_cell,
						name_widget,
						spacing = 4,
						layout = wibox.layout.fixed.horizontal,
					},
					forced_width = coin_col_width,
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
				spacing = 2,
				layout = wibox.layout.fixed.horizontal,
			})
			rows:add(row)
		end

		rows:connect_signal("button::press", function(_, _, _, button)
			if button == 4 then
				if scroll_ptr > 0 then
					rows.children[scroll_ptr].visible = true
					scroll_ptr = scroll_ptr - 1
				end
			elseif button == 5 then
				if scroll_ptr < #rows.children and (#rows.children - scroll_ptr) > visible_row_count then
					scroll_ptr = scroll_ptr + 1
					rows.children[scroll_ptr].visible = false
				end
			end
		end)

		local content_height = popup_header_height + math.min(num_coins, visible_row_count) * popup_row_height
		return wibox.widget({
			{
				header_row,
				rows,
				forced_height = content_height,
				forced_width = popup_content_width,
				layout = wibox.layout.fixed.vertical,
			},
			halign = "left",
			layout = wibox.container.place,
		})
	end

	local function update_popup()
		scroll_ptr = 0
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
			coin_imagebox:set_image(nil)
			return
		end

		if data and #data > 0 then
			local main_coin_code = shared_state.main_coin

			-- Find the main coin in the data
			local main_coin = nil
			for _, coin in ipairs(data) do
				if coin.code == main_coin_code then
					main_coin = coin
					break
				end
			end

			-- Fall back to first coin if MAIN_COIN not found
			if not main_coin then
				main_coin = data[1]
			end

			if main_coin.png32 and shared_state.widget_dir then
				local cache_dir = shared_state.widget_dir .. "cache"
				local cache_path = cache_dir .. "/" .. main_coin.code .. ".png"
				if gfs.file_readable(cache_path) then
					coin_imagebox:set_image(cache_path)
				else
					gfs.make_directories(cache_dir)
					local function shell_escape(s)
						return "'" .. (s:gsub("'", "'\\''")) .. "'"
					end
					spawn.easy_async_with_shell(
						"curl -s -o " .. shell_escape(cache_path) .. " " .. shell_escape(main_coin.png32),
						function(_, __, ___, exitcode)
							if exitcode == 0 and gfs.file_readable(cache_path) then
								coin_imagebox:set_image(cache_path)
							end
						end
					)
				end
			else
				coin_imagebox:set_image(nil)
			end

			local price_text = format_number(main_coin.rate)
			local day_change, day_color = format_delta(main_coin.delta and main_coin.delta.day)

			crypto_text_widget.markup = string.format(
				'<span foreground="#FFFFFF">$%s</span> <span foreground="%s">%s</span>',
				price_text,
				day_color,
				day_change
			)
		else
			crypto_text_widget:set_text("---")
			coin_imagebox:set_image(nil)
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
