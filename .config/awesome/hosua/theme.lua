--[[
     hosua's Awesome WM theme
     github.com/hosua
--]]

local gears = require("gears")
local lain = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful.xresources").apply_dpi
local calendar_widget = require("awesome-wm-widgets.calendar-widget.calendar")
local fs_widget = require("awesome-wm-widgets.fs-widget.fs-widget")
local volume_widget = require("awesome-wm-widgets.volume-widget.volume")
local pacman_widget = require("awesome-wm-widgets.pacman-widget.pacman")
local ram_widget = require("hosua.hosuas-awesome-widgets.ram-widget.ram-widget")

local nvidia_widget = require("hosua.hosuas-awesome-widgets.nvidia-widget.nvidia-widget")
local cpu_widget = require("hosua.hosuas-awesome-widgets.cpu-widget.cpu-widget")

local mysystray = wibox.widget.systray({ opacity = 0 }) -- why the fuck doesn't opacity work?
_G.mysystray = mysystray

local math, string, os = math, string, os
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

-- the mounts to show in the fs widget
local fs_mounts = { "/", "/mnt/DISK1", "/mnt/DISK2", "/mnt/DISK3", "/mnt/DISK4" }

local opacity = {
	lo = "10",
	lo_med = "30",
	med = "55",
	hi = "A0",
	very_hi = "CC",
}

local color = {
	primary = "#27374D",
	secondary = "#526D82",
	focus = "#2F435E",
	dark_gray = "#2f2f2f",
	extra1 = "#9DB2BF",
	extra2 = "#DDE6ED",
	text_light = "#EAEFEF",
	text_dark = "#333446",
	text_focus = "#00CCFF",
	popup = "#2E3440",
}

local color_wibox = {
	primary = color.primary .. opacity.lo,
	secondary = color.secondary .. opacity.lo_med,
}

local theme = {}
theme.dir = os.getenv("HOME") .. "/.config/awesome/hosua"

theme.font = "Terminus 10"
theme.fg_normal = "#FEFEFE"
theme.fg_focus = color.text_focus
theme.fg_urgent = "#C83F11"
theme.bg_normal = color.dark_gray .. opacity.lo
theme.bg_focus = color.primary .. opacity.lo
theme.bg_urgent = color.primary .. opacity.lo
theme.taglist_fg_focus = color.text_focus
theme.tasklist_bg_normal = color.dark_gray .. opacity.lo
theme.tasklist_bg_focus = color.primary .. opacity.med
theme.tasklist_fg_focus = color.text_focus
theme.border_width = dpi(1)
theme.border_normal = color.primary .. opacity.med
theme.border_focus = "#6F6F6F"
theme.border_marked = "#CC9393"
theme.titlebar_bg_focus = color.primary .. opacity.hi
theme.titlebar_bg_normal = color.dark_gray .. opacity.hi
theme.titlebar_fg_focus = theme.fg_focus
theme.menu_height = dpi(32)
theme.menu_width = dpi(140)
theme.menu_submenu_icon = theme.dir .. "/icons/submenu.png"
theme.awesome_icon = theme.dir .. "/icons/awesome.png"
theme.taglist_squares_sel = theme.dir .. "/icons/square_sel.png"
theme.taglist_squares_unsel = theme.dir .. "/icons/square_unsel.png"
theme.layout_tile = theme.dir .. "/icons/tile.png"
theme.layout_tileleft = theme.dir .. "/icons/tileleft.png"
theme.layout_tilebottom = theme.dir .. "/icons/tilebottom.png"
theme.layout_tiletop = theme.dir .. "/icons/tiletop.png"
theme.layout_fairv = theme.dir .. "/icons/fairv.png"
theme.layout_fairh = theme.dir .. "/icons/fairh.png"
theme.layout_spiral = theme.dir .. "/icons/spiral.png"
theme.layout_dwindle = theme.dir .. "/icons/dwindle.png"
theme.layout_max = theme.dir .. "/icons/max.png"
theme.layout_fullscreen = theme.dir .. "/icons/fullscreen.png"
theme.layout_magnifier = theme.dir .. "/icons/magnifier.png"
theme.layout_floating = theme.dir .. "/icons/floating.png"
theme.widget_ac = theme.dir .. "/icons/ac.png"
theme.widget_battery = theme.dir .. "/icons/battery.png"
theme.widget_battery_low = theme.dir .. "/icons/battery_low.png"
theme.widget_battery_empty = theme.dir .. "/icons/battery_empty.png"
theme.widget_brightness = theme.dir .. "/icons/brightness.png"
theme.widget_mem = theme.dir .. "/icons/mem.png"
theme.widget_cpu = theme.dir .. "/icons/cpu.png"
theme.widget_temp = theme.dir .. "/icons/temp.png"
theme.widget_net = theme.dir .. "/icons/net.png"
theme.widget_hdd = theme.dir .. "/icons/hdd.png"
theme.widget_music = theme.dir .. "/icons/note.png"
theme.widget_music_on = theme.dir .. "/icons/note_on.png"
theme.widget_music_pause = theme.dir .. "/icons/pause.png"
theme.widget_music_stop = theme.dir .. "/icons/stop.png"
theme.widget_vol = theme.dir .. "/icons/vol.png"
theme.widget_vol_low = theme.dir .. "/icons/vol_low.png"
theme.widget_vol_no = theme.dir .. "/icons/vol_no.png"
theme.widget_vol_mute = theme.dir .. "/icons/vol_mute.png"
theme.widget_mail = theme.dir .. "/icons/mail.png"
theme.widget_mail_on = theme.dir .. "/icons/mail_on.png"
theme.widget_task = theme.dir .. "/icons/task.png"
theme.widget_scissors = theme.dir .. "/icons/scissors.png"
theme.tasklist_plain_task_name = true
theme.tasklist_disable_icon = true
theme.useless_gap = 6
theme.titlebar_close_button_focus = theme.dir .. "/icons/titlebar/close_focus.png"
theme.titlebar_close_button_normal = theme.dir .. "/icons/titlebar/close_normal.png"
theme.titlebar_ontop_button_focus_active = theme.dir .. "/icons/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = theme.dir .. "/icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive = theme.dir .. "/icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = theme.dir .. "/icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_sticky_button_focus_active = theme.dir .. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = theme.dir .. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive = theme.dir .. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = theme.dir .. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_floating_button_focus_active = theme.dir .. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = theme.dir .. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive = theme.dir .. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = theme.dir .. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_maximized_button_focus_active = theme.dir .. "/icons/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = theme.dir .. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive = theme.dir .. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme.dir .. "/icons/titlebar/maximized_normal_inactive.png"

local mypacman = pacman_widget({ popup_bg_color = color.popup .. opacity.hi })
mypacman.font = theme.font

local markup = lain.util.markup
local separators = lain.util.separators

-- Clock
local textclock = wibox.widget.textclock()
textclock.font = theme.font
textclock.format = "%B %d - %I:%M %p"

-- Calendar widget
local cw = calendar_widget({
	theme = "nord",
	opacity = "DD",
	placement = "top_right",
	start_sunday = true,
	auto_hide = true,
	timeout = 3,
})
textclock:connect_signal("button::press", function(_, _, _, button)
	if button == 1 then
		cw.toggle()
	end
end)

-- Taskwarrior
local task = wibox.widget.imagebox(theme.widget_task)
lain.widget.contrib.task.attach(task, {
	-- do not colorize output
	show_cmd = "task | sed -r 's/\\x1B\\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g'",
})
task:buttons(my_table.join(awful.button({}, 1, lain.widget.contrib.task.prompt)))

-- ALSA volume
theme.volume = lain.widget.alsabar({
	notification_preset = { font = "Terminus 10", fg = theme.fg_normal },
})

-- Separators
local arrow = separators.arrow_left

function theme.powerline_rl(cr, width, height)
	local arrow_depth, offset = height / 2, 0

	-- Avoid going out of the (potential) clip area
	if arrow_depth < 0 then
		width = width + 2 * arrow_depth
		offset = -arrow_depth
	end

	cr:move_to(offset + arrow_depth, 0)
	cr:line_to(offset + width, 0)
	cr:line_to(offset + width - arrow_depth, height / 2)
	cr:line_to(offset + width, height)
	cr:line_to(offset + arrow_depth, height)
	cr:line_to(offset, height / 2)

	cr:close_path()
end

function theme.at_screen_connect(s)
	-- Quake application
	s.quake = lain.util.quake({ app = awful.util.terminal })

	-- Tags
	awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt()
	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	-- We need one layoutbox per screen.
	s.mylayoutbox = awful.widget.layoutbox(s)
	s.mylayoutbox:buttons(my_table.join(
		awful.button({}, 1, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 2, function()
			awful.layout.set(awful.layout.layouts[1])
		end),
		awful.button({}, 3, function()
			awful.layout.inc(-1)
		end),
		awful.button({}, 4, function()
			awful.layout.inc(1)
		end),
		awful.button({}, 5, function()
			awful.layout.inc(-1)
		end)
	))
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)

	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

	-- Create the wibox
	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		height = dpi(26),
		bg = theme.bg_normal,
		fg = theme.fg_normal,
	})

	-- Add widgets to the wibox
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			--spr,
			s.mytaglist,
			s.mypromptbox,
			-- spr,
			wibox.container.background(mysystray, color_wibox.secondary),
		},
		wibox.container.background(s.mytasklist, theme.bg_normal), -- Middle widget
		{ -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			wibox.container.background(nvidia_widget({ popup_bg = color.popup .. opacity.hi }), color_wibox.primary),
			arrow(color_wibox.primary, color_wibox.secondary),
			wibox.container.background(ram_widget.widget, color_wibox.secondary),
			arrow(color_wibox.secondary, color_wibox.primary),
			wibox.container.background(cpu_widget({ popup_bg = color.popup .. opacity.hi }), color_wibox.primary),
			arrow(color_wibox.primary, color_wibox.secondary),
			wibox.container.background(
				wibox.widget({
					wibox.widget.textbox("FS: "),
					fs_widget({
						mounts = fs_mounts,
						popup_bg = color.popup .. opacity.hi,
						popup_border_color = "#4C566A",
					}),
					layout = wibox.layout.fixed.horizontal,
				}),
				color_wibox.secondary
			),
			arrow(color_wibox.secondary, color_wibox.primary),
			wibox.container.background(mypacman, color_wibox.primary),
			arrow(color_wibox.primary, color_wibox.secondary),
			wibox.container.background(
				wibox.container.margin(
					volume_widget({ widget_type = "icon_and_text", use_pactl = true }),
					dpi(3),
					dpi(3)
				),
				color_wibox.secondary
			),
			arrow(color_wibox.secondary, color_wibox.primary),
			wibox.container.background(wibox.container.margin(textclock, dpi(4), dpi(8)), color_wibox.primary),
			s.mylayoutbox,
		},
	})
end

theme.mysystray = mysystray
return theme
