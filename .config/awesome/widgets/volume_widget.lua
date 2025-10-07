-- volume_widget.lua
local awful = require("awful")
local wibox = require("wibox")

-- Create the volume widget
local volume_widget = wibox.widget {
    {
        id = "icon",
        widget = wibox.widget.textbox,
        text = "🔊"
    },
    {
        id = "volume_level",
        widget = wibox.widget.textbox,
        text = "0%"
    },
    layout = wibox.layout.fixed.horizontal
}

-- Function to update the widget
local function update_volume()
    awful.spawn.easy_async_with_shell(
        "amixer get Master | grep -o -m 1 '[0-9]*%' | tr -d '%'",
        function(stdout)
            local volume = tonumber(stdout) or 0
            volume_widget:get_children_by_id("volume_level")[1].text = volume .. "%"
            if volume == 0 then
                volume_widget:get_children_by_id("icon")[1].text = "🔇"
            elseif volume < 50 then
                volume_widget:get_children_by_id("icon")[1].text = "🔈"
            else
                volume_widget:get_children_by_id("icon")[1].text = "🔊"
            end
        end
    )
end

-- Update every 5 seconds
local timer = require("gears.timer")
timer {
    timeout = 5,
    autostart = true,
    callback = update_volume
}

-- Initial update
update_volume()

return volume_widget

