-------------------------------------------------
-- Logout Menu Widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/logout-menu-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local HOME = os.getenv('HOME')
--local ICON_DIR = HOME .. '/.config/awesome/widgets/logout-menu-widget/icons/'

local logout_menu_widget = wibox.widget {
    {
        {
            --image = ICON_DIR .. 'power_w.svg',
            resize = false,
            widget = wibox.widget{markup = '', font = beautiful.taglist_font, widget = wibox.widget.textbox}, --
        },
        margins = 4,
        layout = wibox.container.margin
    },
    shape = gears.shape.circle,
    widget = wibox.container.background,
}

local popup = awful.popup {
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    --maximum_width = 400,
    offset = { y = 4, x = 8 },
    widget = {}
}

local function worker(user_args)
    local rows = { layout = wibox.layout.fixed.vertical }

    local args = user_args or {}
    local font = beautiful.taglist_font

    local onlogout = args.onlogout or function () awesome.quit() end
    local onreboot = args.onreboot or function() awful.spawn.with_shell("sudo reboot") end
    local onsuspend = args.onsuspend or function() awful.spawn.with_shell("sudo zzz") end
    local onpoweroff = args.onpoweroff or function() awful.spawn.with_shell("sudo poweroff") end

	
    local menu_items = {
        { name = '  Log out', command = onlogout },
        { name = '  Suspend', command = onsuspend },
        { name = '  Reboot', command = onreboot },
        { name = '  Poweroff', command = onpoweroff },
    }

    for _, item in ipairs(menu_items) do

        local row = wibox.widget {
            {
                {
                    {
                        markup = item.name,
                        font = font,
                        widget = wibox.widget.textbox
                    },
                    spacing = 12,
                    layout = wibox.layout.fixed.horizontal
                },
                margins = 8,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            fg = beautiful.fg_normal,
            widget = wibox.container.background
        }

        row:connect_signal("mouse::enter", function(c) c:set_bg(beautiful.bg_focus) end)
        row:connect_signal("mouse::leave", function(c) c:set_bg(beautiful.bg_normal) end)

        local old_cursor, old_wibox
        row:connect_signal("mouse::enter", function()
            local wb = mouse.current_wibox
            old_cursor, old_wibox = wb.cursor, wb
            wb.cursor = "hand1"
        end)
        row:connect_signal("mouse::leave", function()
            if old_wibox then
                old_wibox.cursor = old_cursor
                old_wibox = nil
            end
        end)

        row:buttons(awful.util.table.join(awful.button({}, 1, function()
            popup.visible = not popup.visible
            logout_menu_widget:set_bg(beautiful.bg_normal)
            item.command()
        end)))

        table.insert(rows, row)
    end
    popup:setup(rows)
    popup.border_width = beautiful.border_width
    popup.border_color = beautiful.border_focus
	popup.opacity = beautiful.opacity,

    logout_menu_widget:buttons(
            awful.util.table.join(
                    awful.button({}, 1, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                            logout_menu_widget:set_bg(beautiful.bg_normal)
                        else
                            popup:move_next_to(mouse.current_widget_geometry)
                            logout_menu_widget:set_bg(beautiful.bg_focus)
                        end
                    end)
            )
    )

    return logout_menu_widget

end

return setmetatable(logout_menu_widget, { __call = function(_, ...) return worker(...) end })
