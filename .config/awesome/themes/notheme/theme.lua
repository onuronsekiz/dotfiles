--{{{ Import necessary modules
local gears = require("gears")
local lain = require("lain")
local awful = require("awful")
local beautiful = require("beautiful")
local wibox = require("wibox")
local naughty = require("naughty")
--local dpi = require("beautiful.xresources").apply_dpi
local udisks = require("widgets.udisks-widget.udisks")
local logout_menu = require("widgets.logout-menu-widget.logout-menu")
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility
local volume_menu = require("widgets.volume-widget.volume")

local theme = {}

theme.dir = os.getenv("HOME") .. "/.config/awesome/themes/notheme"
--theme.wallpaper = theme.dir .. "/void-wallpaper.png"
theme.wallpaper = theme.dir .. "/cthulhu-wallpaper.png"
theme.volume = volume_menu.widget
theme.font = "Dejavu Sans 9"
theme.icon_theme = "Adwaita"
theme.mono_font = "Liberation Mono 10"
theme.opacity_normal = 0.95
theme.opacity_active = 1
theme.fg_normal = '#ABB2BF'
theme.fg_focus = '#ABB2BF'
theme.fg_urgent = '#ABB2BF'
theme.bg_normal = '#1e222a'
theme.bg_focus = '#383C44'
theme.bg_urgent = '#120900'
theme.bg_hover = '#515865'
theme.border_normal = '#383C44'
theme.border_focus = '#555C69'
theme.border_marked = '#ABB2BF'
theme.border_hover = '#515865'
theme.border_width = 1
theme.tasklist_bg_focus = '#383C44'
theme.tasklist_plain_task_name = true
theme.tasklist_disable_icon = true
theme.useless_gap = 4 
theme.gap_single_client = true

theme.notification_font = theme.font
theme.notification_shape = gears.shape.rounded_rect
theme.notification_border_color = theme.border_focus
theme.notification_border_width = theme.border_width
theme.notification_opacity = theme.opacity_normal

theme.taglist_font = 'icomoon-feather 9'
theme.taglist_font_small = 'icomoon-feather 8'

theme.hotkeys_hide_without_description = false
theme.hotkeys_border_color = theme.border_hover
theme.hotkeys_border_width = theme.border_width
theme.hotkeys_font = theme.mono_font
theme.hotkeys_description_font = theme.mono_font
theme.hotkeys_shape = gears.shape.rounded_rect

beautiful.tooltip_border_color = theme.border_focus
beautiful.tooltip_border_width = theme.border_width
beautiful.tooltip_opacity = theme.opacity_normal
beautiful.tooltip_bg = theme.bg_normal
beautiful.tooltip_fg = theme.fg_normal
beautiful.tooltip_font = theme.font
beautiful.tooltip_shape = gears.shape.rounded_rect
beautiful.tooltip_align = "bottom"

theme.removable_default_mounted   = theme.dir .. "/icons/removable_default_mounted.png"
theme.removable_default_unmounted = theme.dir .. "/icons/removable_default_unmounted.png"
theme.removable_usb_mounted       = theme.dir .. "/icons/removable_usb_mounted.png"
theme.removable_usb_unmounted     = theme.dir .. "/icons/removable_usb_unmounted.png"

theme.taglist_squares_sel = theme.dir .. "/icons/square.png"
theme.taglist_squares_unsel = theme.dir .. "/icons/square.png"

local terminal = "alacritty"
udisks_filemanager = "pcmanfm-qt"

--{{{ create os widgets
local markup = lain.util.markup
local keyboardlayout = awful.widget.keyboardlayout:new()

awful.util.tagnames = {"  ", "  ", "  ", "  ", "  ", "  ", "  ", "  ", "  "}

-- Textclock
local clock = wibox.widget.textclock("%H:%M",60)

-- Calendar
local cal = lain.widget.cal({
	attach_to = {clock},
	followtag = true,
	notification_preset = {
		font = theme.mono_font,
		fg = theme.fg_normal,
		bg = theme.bg_normal,
	}
})

-- MEM
local memicon = lain.widget.mem({
	settings = function()
		widget:set_markup('<span color="#E5C07B">MEM:  ' .. mem_now.used .. 'MB</span>')
	end
})

local mem_tooltip = awful.tooltip {
	objects = { memicon.widget },
	margins_topbottom = 6,
	margins_leftright = 10,
	font = theme.mono_font,
	timer_function = function()
		local cmd = [[free -h | awk '{if ($NL<2) printf("\t%s\t%s\t%s\tcache\t%s\n",$1,$2,$3,$6); else {for (i=1;i<=7;i++){if (i!=5) {printf("%s\t",$i)}}print "" };}']]
		awful.spawn.easy_async_with_shell(cmd, function(result) mem_tooltip_text = result end)
		mem_tooltip_text = string.format("%s\n\n%s", "<b>Memory information</b>", mem_tooltip_text):gsub("\n[^\n]*$", "")
		return mem_tooltip_text
	end,
}

-- CPU
local cpuicon = lain.widget.cpu({
	settings = function()
		widget:set_markup('<span color="#E06C75">CPU:  ' .. cpu_now.usage .. '%</span>')
	end
})

local cpu_tooltip = awful.tooltip {
	objects = { cpuicon.widget },
	margins_topbottom = 6,
	margins_leftright = 10,
	font = theme.mono_font,
	timer_function = function()
		local cmd = [[top -bn 1 | awk 'NR==7,NR==17 {printf("%s\t%s\t%s\t%s\n",$1,$2,$9,$12)}']]
		awful.spawn.easy_async_with_shell(cmd, function(result) cpu_tooltip_text = result end)
		cpu_tooltip_text = string.format("%s\n\n%s", "<b>Process information</b>", cpu_tooltip_text):gsub("\n[^\n]*$", "")
		return cpu_tooltip_text
	end,
}

-- FileSystem
local fsicon = awful.widget.watch([[bash -c "df -h / | tail -n 1 | awk '{print $(NF-1)}'"]], 15, function(widget,stdout) 
	widget:set_markup('<span color="#9A3AC7">FS:  ' .. stdout .. '</span>')
end)

local fs_tooltip = awful.tooltip {
	objects = { fsicon },
	font = theme.mono_font,
	margins_topbottom = 6,
	margins_leftright = 10,
	timer_function = function()
		local cmd = [[df -h | grep -v 'tmpfs\|/sys']]
		awful.spawn.easy_async_with_shell(cmd, function(result) fs_tooltip_text = result end)
		fs_tooltip_text = string.format("%s", fs_tooltip_text):gsub("\n[^\n]*$", "")
		if fs_tooltip_text == "nil" then
			fs_tooltip_text = "<b>Filesystem not found</b>"
		else
			fs_tooltip_text = string.format("%s\n\n%s", "<b>Filesystem information</b>", fs_tooltip_text)
		end
		return fs_tooltip_text
	end,
}

-- Battery
local baticon = lain.widget.bat({
		battery = "BAT0",
		settings = function()
			if bat_now.status ~= "N/A" then
				widget:set_markup('<span color="#61AFEF">BAT:  ' .. bat_now.perc .. '%</span>')
			else
				widget:set_markup('<span color="#61AFEF">BAT:  ' .. "AC" .. '</span>')
			end
		end
})

local bat_tooltip = awful.tooltip {
	objects = { baticon.widget },
	margins_topbottom = 6,
	margins_leftright = 10,
	timer_function = function()
		if bat_now.status == "Charging" then
			bat_tooltip_text = "<b>Battery status</b>\n\n" .. bat_now.status .. "\n" .. bat_now.time .. " to charge\n" .. bat_now.watt .. "W (+)"
		elseif bat_now.status == "Discharging" then
			bat_tooltip_text = "<b>Battery status</b>\n\n" .. bat_now.status .. "\n" .. bat_now.time .. " remains\n" .. bat_now.watt .. "W (-)"
		elseif bat_now.status == "Full" then
			bat_tooltip_text = "<b>Battery status</b>\n\nBattery is full.\nYou can unplug."
		else
			bat_tooltip_text = "<b>Battery status</b>\n\nNot Available"
		end
		return bat_tooltip_text
	end,
}

-- Net
local neticon = lain.widget.net({
	settings = function()
		widget:set_markup('<span color= "#ABB2BF">NET:  ' .. net_now.received .. " ↓↑ " .. net_now.sent .. '</span>')
	end
})

neticon.widget:buttons(my_table.join(awful.button({}, 3,
function ()
	awful.spawn(string.format("%s -e connman-ncurses", terminal))
end)))

local net_tooltip = awful.tooltip {
	objects = { neticon.widget },
	font = theme.mono_font,
	margins_topbottom = 6,
	margins_leftright = 10,
	timer_function = function()
		local cmd = [[ip route get 1.1.1.1 | awk '{print "<b>Interface : </b>" $5 ORS "<b>Gateway   : </b>" $3 ORS "<b>Local IP  : </b>" $7}' | head -n 3 && echo -ne "<b>Public IP : </b>" && wget -T 1 -qO- ipecho.net/plain && ip addr show $(ip route get 1.1.1.1 | awk '{print $5}')  | head -n 2 | tail -n 1 | awk '{print ORS "<b>Device    : </b>" $2}']]
		awful.spawn.easy_async_with_shell(cmd, function(result) net_tooltip_text = result end)
		net_tooltip_text = string.format("%s", net_tooltip_text):gsub("\n[^\n]*$", "")
		if net_tooltip_text == "nil" or net_tooltip_text == "<b>No Network</b>" or net_tooltip_text == "<b>Public IP : </b>" then
			net_tooltip_text = "<b>No Network</b>"
		else
			net_tooltip_text = string.format("%s\n\n%s", "<b>Network information</b>", net_tooltip_text)
		end
		return net_tooltip_text
	end,
}

-- Volume
local vol_tooltip = awful.tooltip {
	objects = { volume_menu().widget },
	margins_topbottom = 6,
	margins_leftright = 10,
	markup = "<b>Sound status</b>\n\nLeft click to mute/unmute.\nRight click to toggle devices.\nMiddle click to open mixer.\nScroll to raise/lower volume." 
}

-- Music
local prev_icon = wibox.widget.textbox('')
local next_icon = wibox.widget.textbox('')
local stop_icon = wibox.widget.textbox('')
local mocicon = wibox.widget.textbox()
mocwidget = lain.widget.contrib.moc({
	settings = function()
		if moc_now.state == "PLAY" then
			mocicon:set_markup('') --
		elseif moc_now.state == "PAUSE" then
			mocicon:set_markup('<span color="#e54c62"></span>') --
		else 
			mocicon:set_markup('')
		end
	end
})

musicwidget = wibox.widget {
	{
		{
			{
				font = theme.taglist_font_small,
				widget = prev_icon,
			},
			{
				font = theme.taglist_font_small,
				widget = mocicon,
			},
			{
				font = theme.taglist_font_small,
				widget = stop_icon ,
			},
			{
				font = theme.taglist_font_small,
				widget = next_icon,
			},
			spacing = 4,
			layout = wibox.layout.fixed.horizontal
		},
		margins = 0,
		layout = wibox.container.margin
	},
	widget = wibox.container.background	
}

prev_icon:buttons(my_table.join(awful.button({}, 1,
function ()
	os.execute("mocp -r")
	mocwidget.update()
end)))

mocicon:buttons(my_table.join(awful.button({}, 1,
function ()
	if moc_now.state ~= "PLAY" and moc_now.state ~= "PAUSE" then
		if moc_now.state ~= "STOP" then
			os.execute("mocp -S")
		end
		os.execute([[mocp -ca "$(sed 's:/\?$:/:g' ~/.moc/last_directory)" -p]])
		os.execute("mocp -c")
	else
		os.execute("mocp -G")
	end
	mocwidget.update()
end)))

stop_icon:buttons(my_table.join(awful.button({}, 1,
function ()
	os.execute("mocp -s")
	mocwidget.update()
end)))

next_icon:buttons(my_table.join(awful.button({}, 1,
function ()
	os.execute("mocp -f")
	mocwidget.update()
end)))

musicwidget:buttons(my_table.join(awful.button({}, 3,
function ()
	awful.spawn(string.format("%s --title mocp -e mocp", terminal))
end)))

moc_tooltip = awful.tooltip{
	objects = { musicwidget },
	margins_topbottom = 6,
	margins_leftright = 10,	
	timer_function = function() 
		if moc_now.state == "PLAY" then
			moc_tooltip_text = "<b>Now Playing</b>\n\n" .. moc_notification_preset.text
		elseif moc_now.state == "PAUSE" then
			moc_tooltip_text = "<b>Paused</b>\n\n" .. moc_notification_preset.text
		else
			moc_tooltip_text = "<b>Not Playing</b>"
		end
		return moc_tooltip_text
	end,
}

-- Virtual Keyboard and Layout
local keyboardwidget = wibox.widget{
	{	
		{
			widget = wibox.widget{markup = '', font = theme.taglist_font, widget = wibox.widget.textbox},
		},	
		--{
		--	widget = keyboardlayout,
		--},
		--spacing= -4,
		margins = 0,
		layout = wibox.container.margin
	},
	shape = gears.shape.circle,
	widget = wibox.container.background	
}

keyboardwidget:buttons(my_table.join(awful.button({}, 1,
function ()
	awful.screen.focused().virtual_keyboard:toggle()
end)))

local keyboardwidget_tooltip = awful.tooltip {
	objects = { keyboardwidget },
	margins_topbottom = 6,
	margins_leftright = 10,
	markup = "<b>Virtual keyboard</b>\n\nClick to toggle",
}

--Udisk storage list widget
local udisks_widget_tooltip = awful.tooltip {
	objects = { udisks },
	font =  beautiful.font,
	border_color = beautiful.border_focus,
	border_width = beautiful.border_width,
	bg = beautiful.bg_normal,
	fg = beautiful.fg_normal,
	opacity = beautiful.opacity_normal,
	shape = gears.shape.rounded_rect,
	align = "bottom",
	margins_topbottom = 6,
	margins_leftright = 10,
	markup = "<b>Storage list</b>\n\nClick to toggle list\nLeft click to mount/browse disk.\nRight click to unmount disk.\nMiddle click to poweroff disk."
}

--Drop-down terminal emulator
local dropdownwidget = wibox.widget{
	{	
		{
			widget = wibox.widget{markup = '', font = theme.taglist_font, widget = wibox.widget.textbox},
		},	
		margins = 0,
		layout = wibox.container.margin
	},
	shape = gears.shape.circle,
	widget = wibox.container.background	
}

dropdownwidget:buttons(my_table.join(awful.button({}, 1,
function ()
	awful.screen.focused().quake:toggle()
end)))

local dropdownwidget_tooltip = awful.tooltip {
	objects = { dropdownwidget },
	margins_topbottom = 6,
	margins_leftright = 10,
	markup = "<b>Drop-down terminal</b>\n\nClick to toggle",
}

--Screenshot tool
local flameshotwidget = wibox.widget{
	{	
		{
			widget = wibox.widget{markup = '', font = theme.taglist_font, widget = wibox.widget.textbox},
		},	
		margins = 0,
		layout = wibox.container.margin
	},
	shape = gears.shape.circle,
	widget = wibox.container.background	
}

local flameshotwidget_tooltip = awful.tooltip {
	objects = { flameshotwidget },
	margins_topbottom = 6,
	margins_leftright = 10,
	markup = "<b>Screenshot tool</b>\n\nLeft click to select and copy to clipboard.\nMiddle click to select and save to file.\nRight click to save screen to file.",
}

flameshotwidget:buttons(my_table.join(
awful.button({}, 1, function ()
	flameshotwidget_tooltip.visible = false
	awful.spawn("flameshot gui -c")
end),
awful.button({}, 2, function ()
	flameshotwidget_tooltip.visible = false
	awful.spawn("flameshot gui -p Pictures/")
end),
awful.button({}, 3, function ()
	flameshotwidget_tooltip.visible = false
	awful.spawn("flameshot full -p Pictures/")
end)
))

--Systray
local systemtray = wibox.widget.systray()
systemtray.visible = true
local trayicon = wibox.widget {font = theme.taglist_font,widget = wibox.widget.textbox,markup = ""}
---[[
trayicon:buttons(my_table.join(awful.button({}, 1,
function ()
	if 	systemtray.visible == false then
	 	trayicon:set_markup("") 
	else
	 	trayicon:set_markup("") 
	end
	systemtray.visible = not systemtray.visible 
end)))
systemtray:set_base_size(10)

local systemtray_tooltip = awful.tooltip {
	objects = { trayicon },
	margins_topbottom = 6,
	margins_leftright = 10,
	markup = "<b>System tray</b>\n\nClick to toggle",
}

-- Separators
local spr = wibox.widget.textbox('   ')
local slspr = wibox.widget.textbox(' ')

--{{{ function that configures virtual spaces 
function theme.at_screen_connect(s)
	-- Quake application
	s.quake = lain.util.quake({ app = terminal, argname = "--title %s", extra = "--class QuakeDD", visible = false, horiz = "center", height = 0.3, width = 0.75 }) 
	
	-- Virtual keyboard
	local virtual_keyboard = require("widgets.virtual_keyboard-widget.virtual_keyboard")
	s.virtual_keyboard = virtual_keyboard:new({ screen = s } )
	
	-- Set wallpaper
	gears.wallpaper.maximized(theme.wallpaper, s)
	
	-- Tags
	awful.tag(awful.util.tagnames, s, awful.layout.suit.tile )
	
	-- Create a promptbox for each screen
	s.mypromptbox = awful.widget.prompt{prompt='<b>Run: </b>',fg='#BC3D39',bg_cursor='#BC3D39'}

	--Monitor widget
	local monitorwidget = wibox.widget {
		{
			{
				{
					font = theme.taglist_font_small,
					widget = wibox.widget.textbox(''),
				},
				{
					font = theme.taglist_font_small,
					widget = wibox.widget.textbox(s.index),
				},
				spacing = 2,
				layout = wibox.layout.fixed.horizontal
			},
			margins = 0,
			layout = wibox.container.margin
		},
		widget = wibox.container.background	
	}
	
	-- Create a taglist widget
	s.mytaglist = awful.widget.taglist {
		screen = s,
		filter = awful.widget.taglist.filter.all,
		style = {shape = gears.shape.rounded_bar},
		layout = {
			spacing = 0,
			spacing_widget = {
				color = '#dddddd',
				bg_focus = '#daeeff',
				fg_focus = '#003040',
				shape = gears.shape.rounded_bar,
			},
			layout = wibox.layout.fixed.horizontal
		},
		widget_template = {
			{
				{
					{
						id = 'text_role',
						widget = wibox.widget.textbox,
					},
					layout = wibox.layout.fixed.horizontal,
				},
				left = 10,
				right = 10,
				widget = wibox.container.margin
			},
			id = 'background_role',
			widget = wibox.container.background,
		},
		buttons = awful.util.taglist_buttons
	}
	
	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist {
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = awful.util.tasklist_buttons,
		style = {
			shape_border_width = theme.border_width,
			shape_border_color = theme.border_focus, 
			shape = gears.shape.rounded_bar,
		},
		layout = {
			spacing = 20,
			spacing_widget = {
				{
					forced_width = 5,
					shape = gears.shape.circle,
					widget = wibox.widget.separator
				},
				valign = 'center',
				halign = 'center',
				widget = wibox.container.place,
			},
			layout = wibox.layout.flex.horizontal
		},
		-- Notice that there is *NO* wibox.wibox prefix, it is a template,
		-- not a widget instance.
		widget_template = {
			{
				{
					{
						id	 = 'text_role',
						widget = wibox.widget.textbox,
					},
					layout = wibox.layout.fixed.horizontal,
				},
				left = 10,
				right = 10,
				widget = wibox.container.margin
			},
			id	 = 'background_role',
			widget = wibox.container.background,
		},
	}
	local sgeo = s.geometry
	s.mywibox = wibox {
		screen = s,
		bg = theme.bg_normal,
		fg = theme.fg_normal,
 		height = 22,
		x = sgeo.x + 2*theme.useless_gap,
		y = sgeo.y + theme.useless_gap,
		width = screen[s].geometry.width - 4*theme.useless_gap,
		shape = gears.shape.rounded_bar,
		border_width = theme.border_width,
		border_color = theme.border_normal,
		visible = true,
	}
	s.mywibox:setup {
		layout = wibox.layout.align.horizontal,
		spacing = 16,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
			s.mytaglist,
			spr,
			monitorwidget,
			slspr,
			udisks(),
			slspr,
			wibox.layout.margin(keyboardwidget, 0, 0, 1, 0),
			slspr,
			flameshotwidget,
			slspr,
			wibox.layout.margin(dropdownwidget, 0, 0, 1, 0),
			slspr,
			s.mypromptbox,
			spr,
		},
		s.mytasklist, -- Middle widget
		{ -- Right widgets
			spr,
			neticon,
			spr,
			fsicon,
			spr,
			memicon,
			spr,
			cpuicon,
			spr,
			baticon,
			spr,
			layout = wibox.layout.fixed.horizontal,
			wibox.layout.margin(volume_menu().widget,0,0,0,0),
			slspr,
			wibox.layout.margin(musicwidget,1,0,-1,0),
			slspr,
			wibox.layout.margin(trayicon,2,2,4,5),
			wibox.layout.margin(systemtray,0,0,7,5),
			slspr,
			clock,
			slspr,
			wibox.layout.margin(logout_menu(),0,-1,-1,0),
			slpr,slspr,
		}
	}
	s.mywibox:struts({
		left=0, 
		right=0,
		top=22+2*theme.useless_gap, 
		bottom=0
	})
end

return theme