-------------------------------------------------
-- Weather Widget based on the OpenWeatherMap
-- https://openweathermap.org/
--
-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------
local awful = require("awful")
local watch = require("awful.widget.watch")
local json = require("json")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local HOME_DIR = os.getenv("HOME")
local WIDGET_DIR = HOME_DIR .. "/.config/awesome/hosua/hosuas-awesome-widgets/weather-widget"
local GET_FORECAST_CMD = [[bash -c "curl -s --show-error -X GET '%s'"]]

local SYS_LANG = os.getenv("LANG"):sub(1, 2)
if SYS_LANG == "C" or SYS_LANG == "C." then
	-- C-locale is a common fallback for simple English
	SYS_LANG = "en"
end
-- default language is ENglish
local LANG = gears.filesystem.file_readable(WIDGET_DIR .. "/" .. "locale/" .. SYS_LANG .. ".lua") and SYS_LANG or "en"
local LCLE = require("awesome-wm-widgets.weather-widget.locale." .. LANG)

local function show_warning(message)
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = LCLE.warning_title,
		text = message,
	})
end

if SYS_LANG ~= LANG then
	show_warning("Your language is not supported yet. Language set to English")
end

local weather_widget = {}
local warning_shown = false
local tooltip = awful.tooltip({
	mode = "outside",
	preferred_positions = { "bottom" },
})

local weather_popup = awful.popup({
	ontop = true,
	visible = false,
	shape = gears.shape.rounded_rect,
	border_width = 1,
	border_color = beautiful.bg_focus,
	maximum_width = 400,
	offset = { y = 5 },
	hide_on_right_click = true,
	widget = {},
})

--- Maps openWeatherMap icon name to file name w/o extension
local icon_map = {
	["01d"] = "clear-sky",
	["02d"] = "few-clouds",
	["03d"] = "scattered-clouds",
	["04d"] = "broken-clouds",
	["09d"] = "shower-rain",
	["10d"] = "rain",
	["11d"] = "thunderstorm",
	["13d"] = "snow",
	["50d"] = "mist",
	["01n"] = "clear-sky-night",
	["02n"] = "few-clouds-night",
	["03n"] = "scattered-clouds-night",
	["04n"] = "broken-clouds-night",
	["09n"] = "shower-rain-night",
	["10n"] = "rain-night",
	["11n"] = "thunderstorm-night",
	["13n"] = "snow-night",
	["50n"] = "mist-night",
}

--- Return wind direction as a string
local function to_direction(degrees)
	-- Ref: https://www.campbellsci.eu/blog/convert-wind-directions
	if degrees == nil then
		return "Unknown dir"
	end
	local directions = LCLE.directions
	return directions[math.floor((degrees % 360) / 22.5) + 1]
end

--- Convert degrees Celsius to Fahrenheit
local function celsius_to_fahrenheit(c)
	return c * 9 / 5 + 32
end

-- Convert degrees Fahrenheit to Celsius
local function fahrenheit_to_celsius(f)
	return (f - 32) * 5 / 9
end

local function gen_temperature_str(temp, fmt_str, show_other_units, units)
	local temp_str = string.format(fmt_str, temp)
	local s = temp_str .. "°" .. (units == "metric" and "C" or "F")

	if show_other_units then
		local temp_conv, units_conv
		if units == "metric" then
			temp_conv = celsius_to_fahrenheit(temp)
			units_conv = "F"
		else
			temp_conv = fahrenheit_to_celsius(temp)
			units_conv = "C"
		end

		local temp_conv_str = string.format(fmt_str, temp_conv)
		s = s .. " " .. "(" .. temp_conv_str .. "°" .. units_conv .. ")"
	end
	return s
end

local function uvi_index_color(uvi)
	local color
	if uvi >= 0 and uvi < 3 then
		color = "#A3BE8C"
	elseif uvi >= 3 and uvi < 6 then
		color = "#EBCB8B"
	elseif uvi >= 6 and uvi < 8 then
		color = "#D08770"
	elseif uvi >= 8 and uvi < 11 then
		color = "#BF616A"
	elseif uvi >= 11 then
		color = "#B48EAD"
	end

	return '<span weight="bold" foreground="' .. color .. '">' .. uvi .. "</span>"
end

local function worker(user_args)
	local args = user_args or {}

	--- Validate required parameters
	if args.coordinates == nil then
		show_warning(LCLE.parameter_warning .. "<b>coordinates</b>")
		return
	end

	local coordinates = args.coordinates
	local font_name = args.font_name or beautiful.font:gsub("%s%d+$", "")
	local units = args.units or "metric"
	local time_format_12h = args.time_format_12h
	local both_units_widget = args.both_units_widget or false
	local show_hourly_forecast = args.show_hourly_forecast
	local show_daily_forecast = args.show_daily_forecast
	local icon_pack_name = args.icons or "weather-underground-icons"
	local icons_extension = args.icons_extension or ".png"
	local timeout = args.timeout or 120
	local popup_bg = args.popup_bg or "#2e2e2e"

	local ICONS_DIR = WIDGET_DIR .. "/icons/" .. icon_pack_name .. "/"

	-- Build OpenMeteo API URL
	local hourly_params =
		"temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m"
	local daily_params = "weather_code,temperature_2m_max,temperature_2m_min,uv_index_max"
	local current_params =
		"temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m"

	-- Temperature unit conversion for OpenMeteo
	local temp_unit = units == "imperial" and "fahrenheit" or "celsius"

	local openmeteo_api = string.format(
		"https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=%s&hourly=%s&daily=%s&temperature_unit=%s&wind_speed_unit=ms&timezone=auto",
		coordinates[1],
		coordinates[2],
		current_params,
		show_hourly_forecast == false and "" or hourly_params,
		show_daily_forecast == false and "" or daily_params,
		temp_unit
	)

	weather_widget = wibox.widget({
		{
			{
				{
					{
						id = "icon",
						resize = true,
						widget = wibox.widget.imagebox,
					},
					valign = "center",
					widget = wibox.container.place,
				},
				{
					id = "txt",
					widget = wibox.widget.textbox,
				},
				layout = wibox.layout.fixed.horizontal,
			},
			layout = wibox.container.margin,
		},
		shape = function(cr, width, height)
			gears.shape.rounded_rect(cr, width, height, 4)
		end,
		widget = wibox.container.background,
		set_image = function(self, path)
			self:get_children_by_id("icon")[1].image = path
		end,
		set_text = function(self, text)
			self:get_children_by_id("txt")[1].text = text
		end,
		is_ok = function(self, is_ok)
			if is_ok then
				self:get_children_by_id("icon")[1]:set_opacity(1)
				self:get_children_by_id("icon")[1]:emit_signal("widget:redraw_needed")
			else
				self:get_children_by_id("icon")[1]:set_opacity(0.2)
				self:get_children_by_id("icon")[1]:emit_signal("widget:redraw_needed")
			end
		end,
	})

	local current_weather_widget = wibox.widget({
		{
			{
				{
					id = "icon",
					resize = true,
					forced_width = 128,
					forced_height = 128,
					widget = wibox.widget.imagebox,
				},
				align = "center",
				widget = wibox.container.place,
			},
			{
				id = "description",
				font = font_name .. " 10",
				align = "center",
				widget = wibox.widget.textbox,
			},
			forced_width = 128,
			layout = wibox.layout.align.vertical,
		},
		{
			{
				{
					id = "temp",
					font = font_name .. " 36",
					widget = wibox.widget.textbox,
				},
				{
					id = "feels_like_temp",
					align = "center",
					font = font_name .. " 9",
					widget = wibox.widget.textbox,
				},
				layout = wibox.layout.fixed.vertical,
			},
			{
				{
					id = "wind",
					font = font_name .. " 9",
					widget = wibox.widget.textbox,
				},
				{
					id = "humidity",
					font = font_name .. " 9",
					widget = wibox.widget.textbox,
				},
				{
					id = "uv",
					font = font_name .. " 9",
					widget = wibox.widget.textbox,
				},
				expand = "inside",
				layout = wibox.layout.align.vertical,
			},
			spacing = 16,
			forced_width = 150,
			layout = wibox.layout.fixed.vertical,
		},
		forced_width = 300,
		layout = wibox.layout.flex.horizontal,
		update = function(self, weather)
			self:get_children_by_id("icon")[1]
				:set_image(ICONS_DIR .. icon_map[weather.weather[1].icon] .. icons_extension)
			self:get_children_by_id("temp")[1]:set_text(gen_temperature_str(weather.temp, "%.0f", false, units))
			self:get_children_by_id("feels_like_temp")[1]
				:set_text(LCLE.feels_like .. gen_temperature_str(weather.feels_like, "%.0f", false, units))
			self:get_children_by_id("description")[1]:set_text(weather.weather[1].description)
			self:get_children_by_id("wind")[1]:set_markup(
				LCLE.wind .. "<b>" .. weather.wind_speed .. "m/s (" .. to_direction(weather.wind_deg) .. ")</b>"
			)
			self:get_children_by_id("humidity")[1]:set_markup(LCLE.humidity .. "<b>" .. weather.humidity .. "%</b>")
			self:get_children_by_id("uv")[1]:set_markup(LCLE.uv .. uvi_index_color(weather.uvi))
		end,
	})

	local daily_forecast_widget = {
		forced_width = 300,
		layout = wibox.layout.flex.horizontal,
		update = function(self, forecast, timezone_offset)
			local count = #self
			for i = 0, count do
				self[i] = nil
			end
			for i, day in ipairs(forecast) do
				if i > 5 then
					break
				end
				local day_forecast = wibox.widget({
					{
						text = os.date("%a", tonumber(day.dt) + tonumber(timezone_offset)),
						align = "center",
						font = font_name .. " 9",
						widget = wibox.widget.textbox,
					},
					{
						{
							{
								image = ICONS_DIR .. icon_map[day.weather[1].icon] .. icons_extension,
								resize = true,
								forced_width = 48,
								forced_height = 48,
								widget = wibox.widget.imagebox,
							},
							align = "center",
							layout = wibox.container.place,
						},
						{
							text = day.weather[1].description,
							font = font_name .. " 8",
							align = "center",
							forced_height = 50,
							widget = wibox.widget.textbox,
						},
						layout = wibox.layout.fixed.vertical,
					},
					{
						{
							text = gen_temperature_str(day.temp.day, "%.0f", false, units),
							align = "center",
							font = font_name .. " 9",
							widget = wibox.widget.textbox,
						},
						{
							text = gen_temperature_str(day.temp.night, "%.0f", false, units),
							align = "center",
							font = font_name .. " 9",
							widget = wibox.widget.textbox,
						},
						layout = wibox.layout.fixed.vertical,
					},
					spacing = 8,
					layout = wibox.layout.fixed.vertical,
				})
				table.insert(self, day_forecast)
			end
		end,
	}

	local hourly_forecast_graph = wibox.widget({
		step_width = 12,
		color = "#EBCB8B",
		background_color = popup_bg,
		forced_height = 100,
		forced_width = 300,
		widget = wibox.widget.graph,
		set_max_value = function(self, new_max_value)
			self.max_value = new_max_value
		end,
		set_min_value = function(self, new_min_value)
			self.min_value = new_min_value
		end,
	})
	local hourly_forecast_negative_graph = wibox.widget({
		step_width = 12,
		color = "#5E81AC",
		background_color = popup_bg,
		forced_height = 100,
		forced_width = 300,
		widget = wibox.widget.graph,
		set_max_value = function(self, new_max_value)
			self.max_value = new_max_value
		end,
		set_min_value = function(self, new_min_value)
			self.min_value = new_min_value
		end,
	})

	local hourly_forecast_widget = {
		layout = wibox.layout.fixed.vertical,
		update = function(self, hourly)
			local hours_below = {
				id = "hours",
				forced_width = 300,
				layout = wibox.layout.flex.horizontal,
			}
			local temp_below = {
				id = "temp",
				forced_width = 300,
				layout = wibox.layout.flex.horizontal,
			}

			local max_temp = -1000
			local min_temp = 1000
			local values = {}
			for i, hour in ipairs(hourly) do
				if i > 25 then
					break
				end
				values[i] = hour.temp
				if max_temp < hour.temp then
					max_temp = hour.temp
				end
				if min_temp > hour.temp then
					min_temp = hour.temp
				end
				if (i - 1) % 5 == 0 then
					table.insert(
						hours_below,
						wibox.widget({
							text = os.date(time_format_12h and "%I%p" or "%H:00", tonumber(hour.dt)),
							align = "center",
							font = font_name .. " 9",
							widget = wibox.widget.textbox,
						})
					)
					table.insert(
						temp_below,
						wibox.widget({
							markup = '<span foreground="'
								.. (tonumber(hour.temp) > 0 and "#2E3440" or "#ECEFF4")
								.. '">'
								.. string.format("%.0f", hour.temp)
								.. "°"
								.. "</span>",
							align = "center",
							font = font_name .. " 9",
							widget = wibox.widget.textbox,
						})
					)
				end
			end

			hourly_forecast_graph:set_max_value(math.max(max_temp, math.abs(min_temp)))
			hourly_forecast_graph:set_min_value(min_temp > 0 and min_temp * 0.7 or 0) -- move graph a bit up

			hourly_forecast_negative_graph:set_max_value(math.abs(min_temp))
			hourly_forecast_negative_graph:set_min_value(max_temp < 0 and math.abs(max_temp) * 0.7 or 0)

			for _, value in ipairs(values) do
				if value >= 0 then
					hourly_forecast_graph:add_value(value)
					hourly_forecast_negative_graph:add_value(0)
				else
					hourly_forecast_graph:add_value(0)
					hourly_forecast_negative_graph:add_value(math.abs(value))
				end
			end

			local count = #self
			for i = 0, count do
				self[i] = nil
			end

			-- all temperatures are positive
			if min_temp > 0 then
				table.insert(
					self,
					wibox.widget({
						{
							hourly_forecast_graph,
							reflection = { horizontal = true },
							widget = wibox.container.mirror,
						},
						{
							temp_below,
							valign = "bottom",
							widget = wibox.container.place,
						},
						id = "graph",
						layout = wibox.layout.stack,
					})
				)
				table.insert(self, hours_below)

			-- all temperatures are negative
			elseif max_temp < 0 then
				table.insert(self, hours_below)
				table.insert(
					self,
					wibox.widget({
						{
							hourly_forecast_negative_graph,
							reflection = { horizontal = true, vertical = true },
							widget = wibox.container.mirror,
						},
						{
							temp_below,
							valign = "top",
							widget = wibox.container.place,
						},
						id = "graph",
						layout = wibox.layout.stack,
					})
				)

			-- there are both negative and positive temperatures
			else
				table.insert(
					self,
					wibox.widget({
						{
							hourly_forecast_graph,
							reflection = { horizontal = true },
							widget = wibox.container.mirror,
						},
						{
							temp_below,
							valign = "bottom",
							widget = wibox.container.place,
						},
						id = "graph",
						layout = wibox.layout.stack,
					})
				)
				table.insert(
					self,
					wibox.widget({
						{
							hourly_forecast_negative_graph,
							reflection = { horizontal = true, vertical = true },
							widget = wibox.container.mirror,
						},
						{
							hours_below,
							valign = "top",
							widget = wibox.container.place,
						},
						id = "graph",
						layout = wibox.layout.stack,
					})
				)
			end
		end,
	}

	--- Map WMO weather codes to OpenWeatherMap icon codes
	-- Reference: https://www.nodc.noaa.gov/archive/arc0021/0002199/1.1/data/0-data/HTML/WMO-CODE/WMO4677.HTM
	local function wmo_to_icon(wmo_code, is_night)
		local day_night = is_night and "n" or "d"

		if wmo_code == 0 then
			return "01" .. day_night -- Clear sky
		elseif wmo_code == 1 then
			return "01" .. day_night -- Mainly clear
		elseif wmo_code == 2 then
			return "02" .. day_night -- Partly cloudy
		elseif wmo_code == 3 then
			return "03" .. day_night -- Overcast
		elseif wmo_code == 45 or wmo_code == 48 then
			return "50" .. day_night -- Fog
		elseif wmo_code >= 51 and wmo_code <= 55 then
			return "09" .. day_night -- Drizzle
		elseif wmo_code >= 56 and wmo_code <= 57 then
			return "13" .. day_night -- Freezing drizzle
		elseif wmo_code >= 61 and wmo_code <= 65 then
			return "10" .. day_night -- Rain
		elseif wmo_code >= 66 and wmo_code <= 67 then
			return "13" .. day_night -- Freezing rain
		elseif wmo_code >= 71 and wmo_code <= 75 then
			return "13" .. day_night -- Snow
		elseif wmo_code == 77 then
			return "13" .. day_night -- Snow grains
		elseif wmo_code >= 80 and wmo_code <= 82 then
			return "09" .. day_night -- Rain showers
		elseif wmo_code >= 85 and wmo_code <= 86 then
			return "13" .. day_night -- Snow showers
		elseif wmo_code >= 95 and wmo_code <= 99 then
			return "11" .. day_night -- Thunderstorm
		else
			return "01" .. day_night -- Default to clear
		end
	end

	--- Get weather description from WMO code
	local function wmo_to_description(wmo_code)
		if wmo_code == 0 then
			return "Clear sky"
		elseif wmo_code == 1 then
			return "Mainly clear"
		elseif wmo_code == 2 then
			return "Partly cloudy"
		elseif wmo_code == 3 then
			return "Overcast"
		elseif wmo_code == 45 then
			return "Fog"
		elseif wmo_code == 48 then
			return "Depositing rime fog"
		elseif wmo_code == 51 then
			return "Light drizzle"
		elseif wmo_code == 53 then
			return "Moderate drizzle"
		elseif wmo_code == 55 then
			return "Dense drizzle"
		elseif wmo_code == 56 then
			return "Light freezing drizzle"
		elseif wmo_code == 57 then
			return "Dense freezing drizzle"
		elseif wmo_code == 61 then
			return "Slight rain"
		elseif wmo_code == 63 then
			return "Moderate rain"
		elseif wmo_code == 65 then
			return "Heavy rain"
		elseif wmo_code == 66 then
			return "Light freezing rain"
		elseif wmo_code == 67 then
			return "Heavy freezing rain"
		elseif wmo_code == 71 then
			return "Slight snow"
		elseif wmo_code == 73 then
			return "Moderate snow"
		elseif wmo_code == 75 then
			return "Heavy snow"
		elseif wmo_code == 77 then
			return "Snow grains"
		elseif wmo_code == 80 then
			return "Slight rain showers"
		elseif wmo_code == 81 then
			return "Moderate rain showers"
		elseif wmo_code == 82 then
			return "Violent rain showers"
		elseif wmo_code == 85 then
			return "Slight snow showers"
		elseif wmo_code == 86 then
			return "Heavy snow showers"
		elseif wmo_code == 95 then
			return "Thunderstorm"
		elseif wmo_code == 96 then
			return "Thunderstorm with slight hail"
		elseif wmo_code == 99 then
			return "Thunderstorm with heavy hail"
		else
			return "Unknown"
		end
	end

	--- Convert ISO8601 timestamp to Unix timestamp
	local function iso8601_to_unix(iso_str)
		-- Parse ISO8601 format: "2026-02-23T14:00"
		local year, month, day, hour, min = iso_str:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
		return os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = 0 })
	end

	--- Determine if it's nighttime based on hour (simple heuristic)
	local function is_nighttime(unix_timestamp)
		local hour = tonumber(os.date("%H", unix_timestamp))
		return hour < 6 or hour >= 18
	end

	--- Transform OpenMeteo API response to OpenWeatherMap format
	local function transform_openmeteo_to_owm(openmeteo_data)
		local result = {
			current = {},
			hourly = {},
			daily = {},
			timezone_offset = openmeteo_data.utc_offset_seconds or 0,
		}

		-- Transform current weather
		if openmeteo_data.current then
			local curr = openmeteo_data.current
			local curr_timestamp = iso8601_to_unix(openmeteo_data.current.time)
			local is_night = is_nighttime(curr_timestamp)
			local icon_code = wmo_to_icon(curr.weather_code, is_night)

			result.current = {
				temp = curr.temperature_2m,
				feels_like = curr.apparent_temperature,
				humidity = curr.relative_humidity_2m,
				uvi = openmeteo_data.daily
						and openmeteo_data.daily.uv_index_max
						and openmeteo_data.daily.uv_index_max[1]
					or 0,
				wind_speed = curr.wind_speed_10m,
				wind_deg = curr.wind_direction_10m,
				weather = {
					{
						icon = icon_code,
						description = wmo_to_description(curr.weather_code),
					},
				},
			}
		end

		-- Transform hourly forecast
		if openmeteo_data.hourly then
			local hourly = openmeteo_data.hourly
			for i = 1, #hourly.time do
				local timestamp = iso8601_to_unix(hourly.time[i])
				table.insert(result.hourly, {
					dt = timestamp,
					temp = hourly.temperature_2m[i],
					feels_like = hourly.apparent_temperature and hourly.apparent_temperature[i],
					humidity = hourly.relative_humidity_2m and hourly.relative_humidity_2m[i],
				})
			end
		end

		-- Transform daily forecast
		if openmeteo_data.daily then
			local daily = openmeteo_data.daily
			for i = 1, #daily.time do
				-- Use noon (12:00) for day icon determination
				local day_timestamp = iso8601_to_unix(daily.time[i] .. "T12:00")
				local icon_code = wmo_to_icon(daily.weather_code[i], false) -- Always use day icons for daily

				table.insert(result.daily, {
					dt = day_timestamp,
					temp = {
						day = daily.temperature_2m_max[i],
						night = daily.temperature_2m_min[i],
					},
					weather = {
						{
							icon = icon_code,
							description = wmo_to_description(daily.weather_code[i]),
						},
					},
				})
			end
		end

		return result
	end

	local function update_widget(widget, stdout, stderr)
		if stderr ~= "" then
			if not warning_shown then
				if
					stderr ~= "curl: (52) Empty reply from server"
					and stderr ~= "curl: (28) Failed to connect to api.openweathermap.org port 443: Connection timed out"
					and stderr:find("^curl: %(18%) transfer closed with %d+ bytes remaining to read$") ~= nil
				then
					show_warning(stderr)
				end
				warning_shown = true
				widget:is_ok(false)
				tooltip:add_to_object(widget)

				widget:connect_signal("mouse::enter", function()
					tooltip.text = stderr
				end)
			end
			return
		end

		warning_shown = false
		tooltip:remove_from_object(widget)
		widget:is_ok(true)

		local openmeteo_data = json.decode(stdout)
		local result = transform_openmeteo_to_owm(openmeteo_data)

		widget:set_image(ICONS_DIR .. icon_map[result.current.weather[1].icon] .. icons_extension)
		widget:set_text(gen_temperature_str(result.current.temp, "%.0f", both_units_widget, units))

		current_weather_widget:update(result.current)

		local final_widget = {
			current_weather_widget,
			spacing = 16,
			layout = wibox.layout.fixed.vertical,
		}

		if show_hourly_forecast then
			hourly_forecast_widget:update(result.hourly)
			table.insert(final_widget, hourly_forecast_widget)
		end

		if show_daily_forecast then
			daily_forecast_widget:update(result.daily, result.timezone_offset)
			table.insert(final_widget, daily_forecast_widget)
		end

		weather_popup:setup({
			{
				final_widget,
				margins = 10,
				widget = wibox.container.margin,
			},
			bg = popup_bg,
			widget = wibox.container.background,
		})
	end

	weather_widget:buttons(gears.table.join(awful.button({}, 1, function()
		if weather_popup.visible then
			weather_widget:set_bg(popup_bg)
			weather_popup.visible = not weather_popup.visible
		else
			weather_widget:set_bg(beautiful.bg_focus)
			weather_popup:move_next_to(mouse.current_widget_geometry)
		end
	end)))

	watch(
		string.format(GET_FORECAST_CMD, openmeteo_api),
		timeout, -- Refresh interval
		update_widget,
		weather_widget
	)

	return weather_widget
end

return setmetatable(weather_widget, {
	__call = function(_, ...)
		return worker(...)
	end,
})
