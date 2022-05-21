local capi = { dbus = dbus }
local lgi       = require 'lgi'
local Gio       = lgi.require 'Gio'
local GLib      = lgi.require 'GLib'
local gears     = require("gears")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local awful     = require("awful")
local naughty   = require("naughty")
local math = require("math")

local system_bus = Gio.bus_get_sync(Gio.BusType.SYSTEM)
local devices = {}
local font = "icomoon-feather 9"

local udisks_widget = wibox.widget {
	{
		{
			resize = false,
			widget = wibox.widget{markup = '', font = font, widget = wibox.widget.textbox},
    	},
    	margins = 4,
		layout = wibox.container.margin
	},
	shape = gears.shape.circle,
    widget = wibox.container.background,
}

local function convert_size( oSize ) -- convert size from bytes to human readable form.
	if oSize > 1099511627776 then
		nSize = string.format("%sTB", math.floor (oSize * 100 / 1099511627776) / 100 )
	elseif oSize > 1073741824 then
		nSize = string.format("%sGB", math.floor (oSize / 1073741824) )
	elseif oSize> 1048576 then
		nSize = string.format("%sMB", math.floor (oSize / 1048576 ) )
	elseif oSize > 1024 then
		nSize = string.format("%sKB", math.floor (oSize / 1024) )
	else
		nSize = string.format("%sB", math.floor (oSize) )
	end
	return ( nSize )
end

local popup = awful.popup {
	ontop = true,
	visible = false,
	shape = gears.shape.rounded_rect,
	offset = { y = 4, x = 28 },
	widget = {}
}
local function isempty(s)
	return s == nil or s == ''
end

local function open_filemanger(device)
	if udisks_filemanager == nil then
	else
		awful.util.spawn_with_shell(udisks_filemanager .. ' "' .. device.Mounted .. '"');
	end
end

local function mount_device(device)
	if device.Mounted then
		open_filemanger(device);
	else
		ret, err = system_bus:call(
			'org.freedesktop.UDisks2',
			'/org/freedesktop/UDisks2/block_devices/' .. device.Device,
			'org.freedesktop.UDisks2.Filesystem',
			'Mount',
			GLib.Variant.new_tuple({
				GLib.Variant('a{sv}', {})
			}, 1),
			nil,
			Gio.DBusConnectionFlags.NONE,
			-1,
			nil,
			function(conn, res)
				local ret, err = system_bus:call_finish(res);
				if err then
					naughty.notify({
						preset = naughty.config.presets.critical,
						text = tostring(err),
					});
				else
					device.Mounted = tostring(ret.value[1]);
					--open_filemanger(device);
				end
			end
		);
	end

end


local function unmount_device(device)
	if device.Mounted then
		ret, err = system_bus:call(
			'org.freedesktop.UDisks2',
			'/org/freedesktop/UDisks2/block_devices/' .. device.Device,
			'org.freedesktop.UDisks2.Filesystem',
			'Unmount',
			GLib.Variant.new_tuple({
				GLib.Variant('a{sv}', {})
			}, 1),
			nil,
			Gio.DBusConnectionFlags.NONE,
			-1,
			nil,
			function(conn, res)
				local ret, err = system_bus:call_finish(res);
				if err then
					naughty.notify({
						preset = naughty.config.presets.critical,
						text = tostring(err),
					});
				end
			end
		);
	end
end


local function parse_block_devices(conn, res, callback)
	local ret, err = system_bus:call_finish(res);
	local xml = ret.value[1];

	if err then
		print(err);
		return;
	end

	for device in string.gmatch(xml, 'name="([^"]*)"') do
		devices[device] = {};
	end

	system_bus:call(
		'org.freedesktop.UDisks2',
		'/org/freedesktop/UDisks2',
		'org.freedesktop.DBus.ObjectManager',
		'GetManagedObjects',
		nil,
		nil,
		Gio.DBusConnectionFlags.NONE,
		-1,
		nil,
		function(conn, res)
			local ret, err = system_bus:call_finish(res);
			local value = ret.value[1];
			if err then
				print(err)
				callback(devices);
				return
			end
			for device_name, _ in pairs(devices) do
				local device_path = '/org/freedesktop/UDisks2/block_devices/' .. device_name;
				local device = value[device_path];
				if device and device['org.freedesktop.UDisks2.Filesystem'] and device['org.freedesktop.UDisks2.Partition'] then
					local mounted = device['org.freedesktop.UDisks2.Filesystem']['MountPoints'][1]
					local drive = value[device['org.freedesktop.UDisks2.Block']['Drive']]['org.freedesktop.UDisks2.Drive'];
					if mounted == nil then
						mounted = false
					else
						mounted = tostring(mounted)
					end
					devices[device_name] = {
						OK = true,
						Drive = device['org.freedesktop.UDisks2.Block'].Drive,
						Device = device_name,
						Label = device['org.freedesktop.UDisks2.Block'].IdLabel,
						Size = convert_size(device['org.freedesktop.UDisks2.Block'].Size),
						FS = device['org.freedesktop.UDisks2.Block'].IdType,
						--UUID = device['org.freedesktop.UDisks2.Block'].IdUUID,
						Mounted = mounted,
						Removable = drive.Removable,
						Name = '',
						ConnectionBus = drive.ConnectionBus,
					}
					if not isempty(drive.Vendor) then
						devices[device_name].Name = drive.Vendor .. ' ';
					end
					if not isempty(drive.Model) then
						devices[device_name].Name = devices[device_name].Name .. drive.Model;
					end
				else
					devices[device_name] = nil;
				end
			end
			callback(devices);
		end
	);
end


local function rescan_devices(callback)
	system_bus:call(
		'org.freedesktop.UDisks2',
		'/org/freedesktop/UDisks2/block_devices',
		'org.freedesktop.DBus.Introspectable',
		'Introspect',
		nil,
		nil,
		Gio.DBusConnectionFlags.NONE,
		-1,
		nil,
		function(conn, res)
			parse_block_devices(conn, res, callback);
		end
	);
end

local function scan_finished(devices)
	local rows = { layout = wibox.layout.fixed.vertical }
	for device, data in pairs(devices) do
		if data.Device and data.OK then
			local bus_type = data.ConnectionBus;
			local status = 'unmounted';
			local icon_name = '';
			local color = beautiful.border_focus
			if data.Mounted then
				status = 'mounted';
				color = beautiful.fg_normal
			end
			if not bus_type then
				bus_type = 'default';
			end
			icon_name = 'removable_' .. bus_type .. '_' .. status;
			if beautiful[icon_name] == nil then
				bus_type = 'default'
				icon_name = 'removable_' .. bus_type .. '_' .. status;
			end
	        local row = wibox.widget {
				{
					{
					{
					    image = beautiful[icon_name],
					    resize = false,
					    widget = wibox.widget.imagebox
					},
					{
						markup = '<span color="' .. color .. '">' .. data.Device .. '</span>',
						widget = wibox.widget.textbox
					},
					spacing = 8,
					layout = wibox.layout.fixed.horizontal
					},
					margins = 8,
					layout = wibox.container.margin
				},
				bg = beautiful.bg_normal,
				fg = beautiful.fg_normal,
				widget = wibox.container.background
			}
			if data.Mounted == false then
				data.MountedPath = ""
			else
				data.MountedPath = string.format("%s\n", data.Mounted)
			end
			if data.Label ~= '' then
				data.Label = string.format("\n%s", data.Label)
			end
			local row_info = awful.tooltip({objects = { row }, 
					font =  beautiful.font,
					border_color = beautiful.border_focus,
					border_width = beautiful.border_width,
					bg = beautiful.bg_normal,
					fg = beautiful.fg_normal,
					opacity = beautiful.opacity_normal,
					shape = gears.shape.rounded_rect,
					mode = "outside",
					margins_leftright = 10,
					margins_topbottom = 6,
					markup = string.format("%s\n/dev/%s\n%s%s (%s)%s",data.Name, data.Device, data.MountedPath, data.Size, data.FS, data.Label),
			});
			
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

			row:buttons(awful.util.table.join(
				awful.button({ }, 1, function () if data.Mounted == false then mount_device(data) else open_filemanger(data) end; end),
				awful.button({ }, 3, function () unmount_device(data) end)
			))
			table.insert(rows,row);
		end
	end
	popup:setup(rows)
	popup.border_width = beautiful.border_width
	popup.border_color = beautiful.border_focus
	popup.opacity = beautiful.opacity,
	udisks_widget:buttons(
        awful.util.table.join(
			awful.button({}, 3, function()
				if popup.visible then
					popup.visible = not popup.visible
					udisks_widget:set_bg(beautiful.bg_normal)
				else
					popup:move_next_to(mouse.current_widget_geometry)
					udisks_widget:set_bg(beautiful.bg_focus)
				end
			end)
		)
	)
	return udisks_widget
end

if capi.dbus then
	capi.dbus.add_match("system", "interface='org.freedesktop.DBus.ObjectManager', member='InterfacesAdded'")
	capi.dbus.add_match("system", "interface='org.freedesktop.DBus.ObjectManager', member='InterfacesRemoved'")
	capi.dbus.connect_signal("org.freedesktop.DBus.ObjectManager",
		function (data, text)
			if data.path == "/org/freedesktop/UDisks2" then
				rescan_devices(scan_finished);
			end
		end
	);
end

rescan_devices(scan_finished);

return setmetatable(udisks_widget, { __call = function(_, ...) return scan_finished(devices) end })
