local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")

local onepassword_widget = {}

local config = {
    popup_bg = "#2E3440",
    popup_border_color = "#4C566A",
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

    -- ── Icons ─────────────────────────────────────────────────────────────────
    local main_icon = wibox.widget({
        image = "/usr/share/icons/hicolor/32x32/apps/1password.png",
        resize = true,
        forced_width = 18,
        forced_height = 18,
        widget = wibox.widget.imagebox,
    })

    local icon_container = wibox.widget({
        main_icon,
        top = 1,
        widget = wibox.container.margin,
    })

    -- ── Wibar layout ──────────────────────────────────────────────────────────
    local widget = wibox.widget({
        {
            icon_container,
            layout = wibox.layout.fixed.horizontal,
        },
        left = 4,
        right = 4,
        widget = wibox.container.margin,
    })

    -- ── Client tracking ───────────────────────────────────────────────────────
    client.connect_signal("manage", function(c)
        if c.class == "1Password" then
            gears.timer.start_new(0.05, function()
                local geo = c:geometry()
                -- Quick Access is a small overlay — leave it completely alone
                if geo.height < 300 then return false end
                c.floating = true
                c.sticky = true
                c.ontop = true
                local target_screen = mouse.screen or awful.screen.focused()
                local screen_geo = target_screen.geometry
                local width = screen_geo.width * 0.8
                local height = screen_geo.height * 0.8
                c:geometry({
                    width = width,
                    height = height,
                    x = screen_geo.x + (screen_geo.width - width) / 2,
                    y = screen_geo.y + (screen_geo.height - height) / 2,
                })
                c:raise()
                client.focus = c
                return false
            end)
        end
    end)

    -- ── Right-click context menu ───────────────────────────────────────────────
    local ctx_menu = nil

    local function close_ctx_menu()
        if ctx_menu then
            ctx_menu.visible = false
            ctx_menu = nil
        end
    end

    local function make_item(label, callback)
        local bg_n = _config.popup_bg
        local item = wibox.widget({
            {
                {
                    text = label,
                    font = beautiful.font or "Terminus 10",
                    widget = wibox.widget.textbox,
                },
                left = 12, right = 20, top = 5, bottom = 5,
                widget = wibox.container.margin,
            },
            bg = bg_n,
            fg = "#FEFEFE",
            widget = wibox.container.background,
        })
        item:connect_signal("mouse::enter", function() item.bg = "#3B4252" end)
        item:connect_signal("mouse::leave", function() item.bg = bg_n end)
        item:connect_signal("button::press", function(_, _, _, btn)
            if btn == 1 and callback then
                close_ctx_menu()
                callback()
            end
        end)
        return item
    end

    local function make_separator()
        return wibox.widget({
            {
                {
                    forced_height = 1,
                    bg = "#4C566A",
                    widget = wibox.container.background,
                },
                left = 8, right = 8,
                widget = wibox.container.margin,
            },
            top = 3, bottom = 3,
            widget = wibox.container.margin,
        })
    end

    local function show_ctx_menu()
        if ctx_menu then close_ctx_menu(); return end

        local layout = wibox.layout.fixed.vertical()
        layout:add(make_item("Open 1Password",    function() awful.spawn("1password --toggle") end))
        layout:add(make_item("Open Quick Access", function() awful.spawn("1password --quick-access") end))
        layout:add(make_separator())
        layout:add(make_item("Lock",     function() awful.spawn("1password --lock") end))
        layout:add(make_item("Settings", function() awful.spawn("1password onepassword://settings") end))
        layout:add(make_item("Quit",     function() awful.spawn.with_shell("pkill -f '1password$'") end))

        ctx_menu = awful.popup({
            ontop = true,
            visible = true,
            shape = gears.shape.rounded_rect,
            border_width = 1,
            border_color = _config.popup_border_color,
            bg = _config.popup_bg,
            minimum_width = 170,
            offset = { y = 5 },
            widget = wibox.widget({
                layout,
                top = 4, bottom = 4,
                widget = wibox.container.margin,
            }),
        })
        ctx_menu:move_next_to(mouse.current_widget_geometry)
    end

    -- ── Tooltip ───────────────────────────────────────────────────────────────
    awful.tooltip({
        objects = { widget },
        text = "Open 1Password",
        delay_show = 0.5,
    })

    -- ── Button bindings ───────────────────────────────────────────────────────
    widget:buttons(awful.util.table.join(
        awful.button({}, 1, function()
            awful.spawn("1password --toggle")
        end),
        awful.button({}, 2, function()
            awful.spawn("1password --lock")
        end),
        awful.button({}, 3, show_ctx_menu)
    ))

    return widget
end

return setmetatable(onepassword_widget, {
    __call = function(_, ...)
        return worker(...)
    end,
})
