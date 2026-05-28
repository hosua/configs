-------------------------------------------------
-- Claude Usage Widget
-- Shows Claude Pro 5h and 7d usage remaining
-- Uses OAuth token from ~/.claude/.credentials.json
-- @author hosua
-------------------------------------------------

local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local string = require("string")
local math = require("math")
local os = require("os")

local claude_usage_widget = {}

local config = {
    refresh_rate = 120,
    popup_bg = "#2E3440",
    popup_border_color = "#4C566A",
    popup_auto_close = 5,
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

    local widget_dir = debug.getinfo(1, "S").source:match("^@(.+/)[^/]+$")

    -- State: utilization is 0.0–1.0 (fraction used)
    local stats = {
        h5_utilization  = 0,
        h5_reset        = 0,   -- Unix timestamp
        d7_utilization  = 0,
        d7_reset        = 0,   -- Unix timestamp
        balance         = "N/A",
        monthly_limit   = "N/A",
        credits_enabled = "unknown",
        error           = "loading",
    }

    -- ─── Helpers ──────────────────────────────────────────────────────────────

    local function remaining_pct(utilization)
        return math.max(0, math.min(100, (1 - utilization) * 100))
    end

    local function usage_color(rem_pct)
        if rem_pct > 66 then return "#FEFEFE"
        elseif rem_pct > 33 then return "#EBCB8B"
        else return "#BF616A"
        end
    end

    local function fmt_countdown(unix_ts)
        if not unix_ts or unix_ts == 0 then return "--:--:--" end
        local diff = math.max(0, unix_ts - os.time())
        local h  = math.floor(diff / 3600)
        local m  = math.floor((diff % 3600) / 60)
        local s  = math.floor(diff % 60)
        return string.format("%02d:%02d:%02d", h, m, s)
    end

    local function fmt_datetime(unix_ts)
        if not unix_ts or unix_ts == 0 then return "unknown" end
        return os.date("%a %m/%d/%Y %I:%M %p", unix_ts)
    end

    -- ─── Wibar widget ─────────────────────────────────────────────────────────

    local icon = wibox.widget({
        image = widget_dir .. "claude-icon.svg",
        resize = true,
        forced_width = 18,
        forced_height = 18,
        widget = wibox.widget.imagebox,
    })

    local icon_container = wibox.widget({ icon, top = 1, widget = wibox.container.margin })

    local function make_arc()
        return wibox.widget({
            max_value    = 100,
            value        = 100,
            thickness    = 2,
            start_angle  = 4.71238898,
            forced_height = 18,
            forced_width  = 18,
            rounded_edge = true,
            bg           = "#ffffff11",
            paddings     = 0,
            colors       = { "#FEFEFE" },
            widget       = wibox.container.arcchart,
        })
    end

    local arc_5h = make_arc()
    local arc_7d = make_arc()

    -- ─── Arc tooltips ─────────────────────────────────────────────────────────

    local function arc_tooltip_text(utilization, reset_ts, period_label)
        local used_pct = math.floor(utilization * 100)
        local rem_pct  = math.max(0, 100 - used_pct)
        local diff     = math.max(0, reset_ts - os.time())
        local time_str
        if diff < 86400 then
            local h = math.floor(diff / 3600)
            local m = math.floor((diff % 3600) / 60)
            local s = math.floor(diff % 60)
            time_str = string.format("until %02d:%02d:%02d from now", h, m, s)
        else
            local days = math.floor(diff / 86400)
            time_str = string.format("for the next %d day%s until %s",
                days, days == 1 and "" or "s",
                os.date("%a, %I:%M %p", reset_ts))
        end
        return string.format("You have used %d%% of your tokens for this %s, leaving you with %d%% %s.",
            used_pct, period_label, rem_pct, time_str)
    end

    local tt_5h = awful.tooltip({
        objects             = { arc_5h },
        bg                  = _config.popup_bg,
        border_color        = _config.popup_border_color,
        border_width        = 1,
        font                = "Terminus 9",
        mode                = "outside",
        preferred_positions = { "bottom", "top" },
    })
    arc_5h:connect_signal("mouse::enter", function()
        tt_5h.text = arc_tooltip_text(stats.h5_utilization, stats.h5_reset, "5 hour period")
    end)

    local tt_7d = awful.tooltip({
        objects             = { arc_7d },
        bg                  = _config.popup_bg,
        border_color        = _config.popup_border_color,
        border_width        = 1,
        font                = "Terminus 9",
        mode                = "outside",
        preferred_positions = { "bottom", "top" },
    })
    arc_7d:connect_signal("mouse::enter", function()
        tt_7d.text = arc_tooltip_text(stats.d7_utilization, stats.d7_reset, "week")
    end)

    local text_5h = wibox.widget.textbox()
    text_5h.font = "Terminus 9"

    local text_7d = wibox.widget.textbox()
    text_7d.font = "Terminus 9"

    local text_balance = wibox.widget.textbox()
    text_balance.font = "Terminus 9"

    local group_5h = wibox.widget({
        arc_5h, text_5h,
        spacing = 2,
        layout = wibox.layout.fixed.horizontal,
    })

    local group_7d = wibox.widget({
        arc_7d, text_7d,
        spacing = 2,
        layout = wibox.layout.fixed.horizontal,
    })

    local widget = wibox.widget({
        {
            icon_container,
            group_5h,
            group_7d,
            text_balance,
            spacing = 8,
            layout = wibox.layout.fixed.horizontal,
        },
        left = 4, right = 4,
        widget = wibox.container.margin,
    })

    -- ─── Popup ────────────────────────────────────────────────────────────────

    local popup = awful.popup({
        ontop        = true,
        visible      = false,
        shape        = gears.shape.rounded_rect,
        border_width = 1,
        border_color = _config.popup_border_color,
        bg           = _config.popup_bg,
        maximum_width = 320,
        offset       = { y = 5 },
        widget       = {},
    })

    local function make_bar()
        return wibox.widget({
            max_value        = 100,
            value            = 0,
            forced_height    = 12,
            forced_width     = 280,
            paddings         = 1,
            border_width     = 1,
            border_color     = _config.popup_border_color,
            background_color = beautiful.bg_normal or "#2E3440",
            bar_border_width = 1,
            bar_border_color = _config.popup_border_color,
            color            = "#FEFEFE",
            widget           = wibox.widget.progressbar,
        })
    end

    local bar_5h = make_bar()
    local bar_7d = make_bar()

    local reset_5h_text  = wibox.widget({ font = beautiful.font or "Terminus 10", widget = wibox.widget.textbox })
    local label_5h_text  = wibox.widget({ font = beautiful.font or "Terminus 10", widget = wibox.widget.textbox })
    local reset_7d_text  = wibox.widget({ font = beautiful.font or "Terminus 10", widget = wibox.widget.textbox })
    local label_7d_text  = wibox.widget({ font = beautiful.font or "Terminus 10", widget = wibox.widget.textbox })

    local function bold(text)
        local w = wibox.widget({ font = "Terminus Bold 10", widget = wibox.widget.textbox })
        w:set_markup("<b>" .. text .. "</b>")
        return w
    end

    local function divider()
        return wibox.widget({
            {
                forced_height = 1,
                bg = _config.popup_border_color,
                widget = wibox.container.background,
            },
            top = 5, bottom = 5,
            widget = wibox.container.margin,
        })
    end

    local function make_btn(label, callback)
        local inner = wibox.widget({
            markup = " " .. label .. " ",
            font   = "Terminus 9",
            widget = wibox.widget.textbox,
        })
        local btn = wibox.widget({
            inner,
            bg     = "#3B4252",
            shape  = gears.shape.rounded_rect,
            widget = wibox.container.background,
        })
        if callback then
            btn:buttons(awful.util.table.join(awful.button({}, 1, callback)))
        end
        return btn
    end

    -- ─── Parse fetch output ───────────────────────────────────────────────────

    local function parse_output(stdout)
        for line in stdout:gmatch("[^\r\n]+") do
            local key, value = line:match("^([%w_]+)=(.*)$")
            if key and value then
                if     key == "h5_utilization"  then stats.h5_utilization  = tonumber(value) or 0
                elseif key == "h5_reset"         then stats.h5_reset         = tonumber(value) or 0
                elseif key == "d7_utilization"  then stats.d7_utilization  = tonumber(value) or 0
                elseif key == "d7_reset"         then stats.d7_reset         = tonumber(value) or 0
                elseif key == "balance"          then stats.balance          = value
                elseif key == "monthly_limit"   then stats.monthly_limit   = value
                elseif key == "credits_enabled" then stats.credits_enabled = value
                elseif key == "error"            then stats.error            = value
                end
            end
        end
    end

    -- ─── Update wibar arcs/text ───────────────────────────────────────────────

    local function update_widget()
        local rem5 = remaining_pct(stats.h5_utilization)
        local rem7 = remaining_pct(stats.d7_utilization)

        arc_5h.value  = rem5
        arc_5h.colors = { usage_color(rem5) }
        text_5h:set_markup(string.format(" <span foreground='%s'>%d%%</span>", usage_color(rem5), math.floor(rem5)))

        arc_7d.value  = rem7
        arc_7d.colors = { usage_color(rem7) }
        text_7d:set_markup(string.format(" <span foreground='%s'>%d%%</span>", usage_color(rem7), math.floor(rem7)))

        if stats.balance ~= "N/A" then
            text_balance:set_markup(string.format(" <span foreground='#A3BE8C'>$%s</span>", stats.balance))
        else
            text_balance:set_markup("")
        end
    end

    -- ─── Popup ────────────────────────────────────────────────────────────────

    local close_popup  -- forward-declared so update_popup callbacks can reference it

    local function update_popup()
        local rem5  = remaining_pct(stats.h5_utilization)
        local rem7  = remaining_pct(stats.d7_utilization)
        local used5 = math.floor(stats.h5_utilization * 100)
        local used7 = math.floor(stats.d7_utilization * 100)

        -- 5h section
        reset_5h_text:set_markup(string.format(
            "Resets in  <span foreground='%s'><b>%s</b></span>",
            beautiful.fg_focus or "#00CCFF", fmt_countdown(stats.h5_reset)
        ))
        bar_5h.value = used5
        bar_5h.color = usage_color(rem5)
        label_5h_text:set_markup(string.format(
            "%d%% used  <span foreground='%s'>(%d%% remaining)</span>",
            used5, usage_color(rem5), math.floor(rem5)
        ))

        -- 7d section
        reset_7d_text:set_markup(string.format(
            "Resets on  <span foreground='%s'><b>%s</b></span>",
            beautiful.fg_focus or "#00CCFF", fmt_datetime(stats.d7_reset)
        ))
        bar_7d.value = used7
        bar_7d.color = usage_color(rem7)
        label_7d_text:set_markup(string.format(
            "%d%% used  <span foreground='%s'>(%d%% remaining)</span>",
            used7, usage_color(rem7), math.floor(rem7)
        ))

        -- ── Credits / billing section ─────────────────────────────────────────

        local credits_enabled = stats.credits_enabled == "true"

        local credits_left = wibox.widget({
            markup = string.format("<b>$%s</b> Usage credits", stats.balance),
            font   = beautiful.font or "Terminus 10",
            widget = wibox.widget.textbox,
        })

        local toggle_label
        local toggle_color
        if stats.credits_enabled == "unknown" then
            toggle_label = "?"
            toggle_color = "#616E88"
        elseif credits_enabled then
            toggle_label = "on"
            toggle_color = "#A3BE8C"
        else
            toggle_label = "off"
            toggle_color = "#BF616A"
        end

        local toggle_btn = make_btn(
            string.format("<span foreground='%s'>%s</span>", toggle_color, toggle_label),
            stats.credits_enabled ~= "unknown" and function()
                local new = credits_enabled and "false" or "true"
                awful.spawn.easy_async(widget_dir .. "toggle-credits.sh " .. new, function()
                    awful.spawn.easy_async(widget_dir .. "fetch-usage.sh", function(out)
                        parse_output(out)
                        update_widget()
                        if popup.visible then update_popup() end
                    end)
                end)
            end or nil
        )

        local credits_row = wibox.widget({
            credits_left, nil, toggle_btn,
            layout = wibox.layout.align.horizontal,
        })

        local adjust_btn = make_btn("Adjust Limit", function()
            awful.spawn("xdg-open https://claude.ai/settings/usage")
        end)

        local limit_left = wibox.widget({
            markup = string.format("<b>$%s</b> Monthly Limit", stats.monthly_limit),
            font   = beautiful.font or "Terminus 10",
            widget = wibox.widget.textbox,
        })

        local limit_row = wibox.widget({
            limit_left, nil, adjust_btn,
            layout = wibox.layout.align.horizontal,
        })

        local settings_btn = make_btn("Usage Settings", function()
            awful.spawn("xdg-open https://claude.ai/settings/usage")
            close_popup()
        end)

        local settings_row = wibox.widget({
            nil, nil, settings_btn,
            layout = wibox.layout.align.horizontal,
        })

        local show_credits = stats.credits_enabled ~= "unknown" or stats.balance ~= "N/A"
        local show_limit   = stats.monthly_limit ~= "N/A"

        local popup_children = {
            {
                image = "/home/hoswoo/Pictures/claude-ai-logo-darkmode.svg",
                resize = true,
                forced_height = 22,
                forced_width  = 101,
                widget = wibox.widget.imagebox,
            },
            {
                markup = " Usage &amp; Billing",
                font   = "DejaVu Sans 18",
                widget = wibox.widget.textbox,
            },
            layout = wibox.layout.fixed.horizontal,
        }

        local rows = {
            divider(),
            bold("5h Budget"),
            reset_5h_text,
            { bar_5h, top = 2, bottom = 2, widget = wibox.container.margin },
            label_5h_text,
            divider(),
            bold("7d Budget"),
            reset_7d_text,
            { bar_7d, top = 2, bottom = 2, widget = wibox.container.margin },
            label_7d_text,
        }

        if show_credits or show_limit then
            table.insert(rows, divider())
            if show_credits then table.insert(rows, credits_row) end
            if show_limit   then table.insert(rows, limit_row)   end
        end

        table.insert(rows, divider())
        table.insert(rows, settings_row)

        local col = { popup_children }
        for _, r in ipairs(rows) do table.insert(col, r) end
        col.spacing = 3
        col.layout  = wibox.layout.fixed.vertical

        popup:setup({
            col,
            margins = 10,
            widget  = wibox.container.margin,
        })
    end

    -- ─── Popup open/close ─────────────────────────────────────────────────────

    local countdown_timer  = nil
    local autoclose_timer  = nil

    close_popup = function()
        popup.visible = false
        if countdown_timer  then countdown_timer:stop();  countdown_timer  = nil end
        if autoclose_timer  then autoclose_timer:stop();  autoclose_timer  = nil end
    end

    local function open_popup()
        update_popup()
        popup:move_next_to(mouse.current_widget_geometry)
        popup.visible = true

        -- Update countdown every second while open
        countdown_timer = gears.timer({
            timeout    = 1,
            autostart  = true,
            callback   = function()
                if popup.visible then
                    reset_5h_text:set_markup(string.format(
                        "Resets in  <span foreground='%s'><b>%s</b></span>",
                        beautiful.fg_focus or "#00CCFF", fmt_countdown(stats.h5_reset)
                    ))
                else
                    close_popup()
                end
            end,
        })

        if _config.popup_auto_close > 0 then
            autoclose_timer = gears.timer({
                timeout     = _config.popup_auto_close,
                autostart   = true,
                single_shot = true,
                callback    = close_popup,
            })
        end
    end

    popup:connect_signal("button::press", function() close_popup() end)

    popup:connect_signal("mouse::enter", function()
        if autoclose_timer then autoclose_timer:stop(); autoclose_timer = nil end
    end)

    popup:connect_signal("mouse::leave", function()
        if _config.popup_auto_close > 0 and popup.visible then
            autoclose_timer = gears.timer({
                timeout     = _config.popup_auto_close,
                autostart   = true,
                single_shot = true,
                callback    = close_popup,
            })
        end
    end)

    widget:buttons(awful.util.table.join(awful.button({}, 1, function()
        if popup.visible then close_popup() else open_popup() end
    end)))

    -- ─── Data fetch ───────────────────────────────────────────────────────────

    watch(widget_dir .. "fetch-usage.sh", _config.refresh_rate, function(_, stdout)
        parse_output(stdout)
        update_widget()
        if popup.visible then update_popup() end
    end, widget)

    return widget
end

return setmetatable(claude_usage_widget, {
    __call = function(_, ...)
        return worker(...)
    end,
})
