-------------------------------------------------
-- The Ultimate Volume Widget for Awesome Window Manager
-- More details could be found here:
-- https://github.com/streetturtle/awesome-wm-widgets/tree/master/volume-widget

-- @author Pavel Makhov
-- @copyright 2020 Pavel Makhov
-------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local lain = require("lain")
local spawn = require("awful.spawn")
local gears = require("gears")
local beautiful = require("beautiful")
local font = 'Dejavu Sans 8'

local LIST_DEVICES_CMD = [[sh -c "pacmd list-sinks; pacmd list-sources"]]

local volume = {}

local rows  = { layout = wibox.layout.fixed.vertical }

volume.widget = lain.widget.alsa({
	settings = function()
		if volume_now.status == "off" then
			volicon = "VOL muted:  "
		else
			volicon = "VOL:  "
		end
		widget:set_markup('<span color="#98c379">' .. volicon .. volume_now.level .. '%</span>')
		widget:set_font(font)
	end
})

local popup = awful.popup{
    bg = beautiful.bg_normal,
    ontop = true,
    visible = false,
    shape = gears.shape.rounded_rect,
    maximum_width = 300,
	preferred_positions = {'bottom','left'},
	preferred_anchors = 'front',
    offset = { y = 4, x = -126 },
    widget = {}
}

local function split(string_to_split, separator)
    if separator == nil then separator = "%s" end
    local t = {}

    for str in string.gmatch(string_to_split, "([^".. separator .."]+)") do
        table.insert(t, str)
    end

    return t
end

function extract_sinks_and_sources(pacmd_output)
    local sinks = {}
    local sources = {}
    local device
    local properties
    local ports
    local in_sink = false
    local in_source = false
    local in_device = false
    local in_properties = false
    local in_ports = false
    for line in pacmd_output:gmatch("[^\r\n]+") do
        if string.match(line, 'source%(s%) available.') then
            in_sink = false
            in_source = true
        end
        if string.match(line, 'sink%(s%) available.') then
            in_sink = true
            in_source = false
        end

        if string.match(line, 'index:') then
            in_device = true
            in_properties = false
            device = {
                id = line:match(': (%d+)'),
                is_default = string.match(line, '*') ~= nil
            }
            if in_sink then
                table.insert(sinks, device)
            elseif in_source then
                table.insert(sources, device)
            end
        end

        if string.match(line, '^\tproperties:') then
            in_device = false
            in_properties = true
            properties = {}
            device['properties'] = properties
        end

        if string.match(line, 'ports:') then
            in_device = false
            in_properties = false
            in_ports = true
            ports = {}
            device['ports'] = ports
        end

        if string.match(line, 'active port:') then
            in_device = false
            in_properties = false
            in_ports = false
            device['active_port'] = line:match(': (.+)'):gsub('<',''):gsub('>','')
        end

        if in_device then
            local t = split(line, ': ')
            local key = t[1]:gsub('\t+', ''):lower()
            local value = t[2]:gsub('^<', ''):gsub('>$', '')
            device[key] = value
        end

        if in_properties then
            local t = split(line, '=')
            local key = t[1]:gsub('\t+', ''):gsub('%.', '_'):gsub('-', '_'):gsub(':', ''):gsub("%s+$", "")
            local value
            if t[2] == nil then
                value = t[2]
            else
                value = t[2]:gsub('"', ''):gsub("^%s+", ""):gsub(' Analog Stereo', '')
            end
            properties[key] = value
        end

        if in_ports then
            local t = split(line, ': ')
            local key = t[1]
            if key ~= nil then
                key = key:gsub('\t+', '')
            end
            ports[key] = t[2]
        end
    end

    return sinks, sources
end

local function build_main_line(device)
    if device.active_port ~= nil and device.ports[device.active_port] ~= nil then
        return device.properties.device_description .. ' · ' .. device.ports[device.active_port]
    else
        return device.properties.device_description
    end
end

local function build_rows(devices, on_checkbox_click, device_type)
    local device_rows  = { layout = wibox.layout.fixed.vertical }
    for _, device in pairs(devices) do

        local checkbox = wibox.widget {
            checked = device.is_default,
            color = beautiful.bg_normal,
            paddings = 2,
            shape = gears.shape.circle,
            forced_width = 12,
            forced_height = 12,
            check_color = beautiful.fg_urgent,
            widget = wibox.widget.checkbox
        }

        checkbox:connect_signal("button::press", function()
            spawn.easy_async(string.format([[sh -c 'pacmd set-default-%s "%s"']], device_type, device.name), function()
                on_checkbox_click()
            end)
        end)

        local row = wibox.widget {
            {
                {
                    {
                        checkbox,
                        valign = 'center',
                        layout = wibox.container.place,
                    },
                    {
                        {
                            text = build_main_line(device),
							align = 'left',
                            widget = wibox.widget.textbox
                        },
                        left = 10,
                        layout = wibox.container.margin
                    },
                    spacing = 8,
                    layout = wibox.layout.align.horizontal
                },
                margins = 4,
                layout = wibox.container.margin
            },
            bg = beautiful.bg_normal,
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

        row:connect_signal("button::press", function()
            spawn.easy_async(string.format([[sh -c 'pacmd set-default-%s "%s"']], device_type, device.name), function()
                on_checkbox_click()
            end)
        end)

        table.insert(device_rows, row)
    end

    return device_rows
end

local function build_header_row(text)
    return wibox.widget{
        {
            markup = "<b>" .. text .. "</b>",
            align = 'center',
            widget = wibox.widget.textbox
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    }
end

local function rebuild_popup()
    spawn.easy_async(LIST_DEVICES_CMD, function(stdout)

        local sinks, sources = extract_sinks_and_sources(stdout)

        for i = 0, #rows do rows[i]=nil end

        table.insert(rows, build_header_row("SINKS"))
        table.insert(rows, build_rows(sinks, function() rebuild_popup() end, "sink"))
        table.insert(rows, build_header_row("SOURCES"))
        table.insert(rows, build_rows(sources, function() rebuild_popup() end, "source"))

        popup:setup(rows)
		popup.border_width = beautiful.border_width
		popup.border_color = beautiful.border_focus
		popup.opacity = beautiful.opacity
		popup.fg = beautiful.fg_normal
    end)
end


local function worker(user_args)

    local args = user_args or {}
    local mixer_cmd = args.mixer_cmd or 'pulsemixer'
	local terminal = 'alacritty'
    function volume:inc(s)
        spawn("amixer set Master 5%+")
		volume.widget.update()
    end

    function volume:dec(s)
        spawn("amixer set Master 5%-")
		volume.widget.update()
    end

    function volume:toggle()
        os.execute(string.format("%s set %s toggle", volume.widget.cmd, volume.widget.togglechannel or volume.widget.channel))
		volume.widget.update()
    end

    function volume:mixer()
        if mixer_cmd then
			spawn(string.format("%s -e %s", terminal, mixer_cmd))
        end
    end

    volume.widget.widget:buttons(
            awful.util.table.join(
                    awful.button({}, 3, function()
                        if popup.visible then
                            popup.visible = not popup.visible
                        else
                            rebuild_popup()
                            popup:move_next_to(mouse.current_widget_geometry)
                        end
                    end),
                    awful.button({}, 4, function() volume:inc() end),
                    awful.button({}, 5, function() volume:dec() end),
                    awful.button({}, 2, function() volume:mixer() end),
                    awful.button({}, 1, function() volume:toggle() end)
            )
    )

    return volume.widget
end

return setmetatable(volume, { __call = function(_, ...) return worker(...) end })