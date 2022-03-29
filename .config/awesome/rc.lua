local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local lain = require("lain")
local freedesktop   = require("freedesktop")
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility
local hotkeys_popup = require("awful.hotkeys_popup").widget
require("awful.hotkeys_popup.keys")

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors
	})
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		if in_error then
			return
		end
		in_error = true
		naughty.notify({
				preset = naughty.config.presets.critical,
				title = "Oops, an error happened!",
				text = tostring(err)
			})
		in_error = false
	end)
end

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.

local webbrowser = "firefox"
local filebrowser = "pcmanfm-qt"
local terminal = "alacritty"
local themes = {"notheme"}
local editor = "vim"
local chosen_theme = themes[1]
local modkey = "Mod4"
local altkey = "Mod1"
local vi_focus = false
local cycle_prev = true 
local theme_path = os.getenv("HOME") .. "/.config/awesome/themes/" .. chosen_theme 
local awesome_icon = theme_path .. "/icons/awesome16.png"

awful.layout.layouts = {
	awful.layout.suit.tile, 
	awful.layout.suit.tile.bottom, 
	awful.layout.suit.fair,
	awful.layout.suit.spiral.dwindle
}

-- Menu
local myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end }
}
awful.util.mymainmenu = freedesktop.menu.build({
    icon_size = beautiful.menu_height or 16,
    before = {
        { "Awesome", myawesomemenu, awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
    }
})

awful.util.taglist_buttons = my_table.join(
	awful.button({}, 1, function(t) t:view_only()  end),
	awful.button({modkey}, 1,
		function(t)
			if client.focus then
				client.focus:move_to_tag(t.screen)
			end
		end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({modkey}, 3,
		function(t)
			if client.focus then
				client.focus:toggle_tag(t.screen)
			end
		end),
	awful.button({}, 4, function(t) awful.tag.viewprev(t.screen) end),
	awful.button({}, 5, function(t) awful.tag.viewnext(t.screen) end)
)

awful.util.tasklist_buttons = my_table.join(
	awful.button({}, 1,
		function(c)
			if c == client.focus then
				c.minimized = true
			else
				c.minimized = false
				if not c:isvisible() and c.first_tag then
					c.first_tag:view_only()
				end
				client.focus = c
				c:raise()
			end
		end),
	awful.button({}, 2, function(c) c:kill() end),
	awful.button({}, 4, function() awful.client.focus.byidx(-1) end),
	awful.button({}, 5, function() awful.client.focus.byidx(1) end)
)


beautiful.init(string.format("%s/theme.lua", theme_path))

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
	-- Wallpaper
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		-- If wallpaper is a function, call it with the screen
		if type(wallpaper) == "function" then
			wallpaper = wallpaper(s)
		end
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end)

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)

-- {{{ Mouse bindings
root.buttons(gears.table.join(
	awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
	awful.button({ }, 4, awful.tag.viewprev),
	awful.button({ }, 5, awful.tag.viewnext)
))
-- }}}

--{{{ Layout change notification
local tagpopup = awful.popup {
	widget = {},
	placement = awful.placement.centered,
	visible = false,
	ontop = true,
	border_color = beautiful.border_focus,
	border_width = beautiful.border_width,
	margins = 4,
	shape = gears.shape.rounded_rect,
	opacity = 0.95,
}	

local function call_layout_info ()
	markup_text = "Layout = " .. awful.layout.getname(awful.layout.get(mouse.screen)) .. "\n" .. 
				"Master = " .. mouse.screen.selected_tag.master_count .. "\n" .. 
				"Column = " .. mouse.screen.selected_tag.column_count .. "\n" ..
				"Notify = " .. tostring(not naughty.is_suspended())
	tagpopup.widget = wibox.widget {
		{
			{
				{
					markup = "<b>Tag Info</b>",
					widget = wibox.widget.textbox
				},
				{
					markup = markup_text,
					widget = wibox.widget.textbox
				},
				spacing = 8,
				layout = wibox.layout.fixed.vertical
			},
			margins = 6,
			layout = wibox.container.margin
		},
		widget = wibox.container.background	
	}
	tagpopup.screen = awful.screen.focused()
	tagpopup.visible = true
	gears.timer {
		single_shot = true,
		timeout   = 1,
		autostart = true,
		callback  = function()
			tagpopup.visible = false
		end,
	}
end

--{{{ Move client to same tag across screens
local function move_client_to_screen (c,s)
	local index = c.first_tag.index
	c:move_to_screen(s)
	local tag = c.screen.tags[index]
	c:move_to_tag(tag)
	if tag then tag:view_only() end
end

--}}}

globalkeys = my_table.join(
	awful.key({ modkey }, "h", hotkeys_popup.show_help, {description = "Show help", group="awesome"}),
	awful.key({ modkey }, "a", function () awful.screen.focused().quake:toggle() end, {description = "dropdown terminal", group = "hotkeys"}),
	awful.key({ modkey}, "y",
		function()
			naughty.toggle()
			call_layout_info()
		end, {description = "Toggle notifications", group = "hotkeys"}), 
	awful.key({ modkey, "Control" }, "y",
		function()
			naughty.destroy_all_notifications()
		end, {description = "Destroy notifications", group = "hotkeys"}),
	awful.key({ modkey }, "z",
		function()
			awful.screen.focused().virtual_keyboard:toggle()
		end, {description = "Virtual Keyboard", group = "hotkeys"}),
	awful.key({}, "Print",
		function()
			os.execute("flameshot full -p Pictures/")
		end, {description = "Print Screen to File", group = "hotkeys"}),
	awful.key({altkey}, "Print",
		function()
			os.execute("flameshot gui -p Pictures/")
		end, {description = "Print Screen Select", group = "hotkeys"}),
	awful.key({"Control"}, "Print",
		function()
			os.execute("flameshot full -c")
		end, {description = "Print Screen to Clipboard", group = "hotkeys"}),
	awful.key({"Control", modkey}, "Print",
		function()
			awful.spawn("flameshot full -d 2000 -p Pictures/")
		end, {description = "Print Screen with 2s Delay", group = "hotkeys"}),
	awful.key({altkey, modkey}, "Print",
		function()
			awful.spawn("flameshot gui -c")
		end, {description = "Print Screen Select to Clipboard", group = "hotkeys"}),	
	awful.key({}, "XF86AudioPlay",
		function() 
			os.execute("mocp -G")
		end, 
		mocwidget.update(), {description = "Play", group = "hotkeys"}),
	awful.key({}, "XF86AudioPrev",
		function()
			os.execute("mocp -r")
		end, 
		mocwidget.update(), {description = "Previous", group = "hotkeys"}),
	awful.key({}, "XF86AudioNext",
		function()
			os.execute("mocp -f")
		end, 
		mocwidget.update(), {description = "Next", group = "hotkeys"}),
	awful.key({}, "XF86AudioStop",
		function()
			os.execute("mocp -s")
		end, 
		mocwidget.update(), {description = "Stop", group = "hotkeys"}),
	awful.key({}, "XF86Calculator",
		function()
			awful.spawn("mate-calc")
		end, {description = "calculator", group = "hotkeys"}),
	awful.key({modkey}, "Escape",
		function()
			awful.spawn(string.format("%s -e htop", terminal))
		end, {description = "process viewer", group = "hotkeys"}),
	awful.key({modkey}, "s",
		function()
			awful.spawn("scite")
		end, {description = "text editor", group = "hotkeys"}),
	awful.key({modkey}, "n",
		function()
			awful.spawn("notepadqq")
		end, {description = "notepadqq", group = "hotkeys"}),
	awful.key({modkey}, "w",
		function()
			awful.spawn(webbrowser)
		end, {description = "web browser", group = "hotkeys"}),
	awful.key({modkey}, "e", 
		function()
			awful.spawn(filebrowser) 
		end, {description = "file manager", group = "hotkeys"}),
	awful.key({altkey}, "Tab",
		function()
			awful.client.focus.byidx(1)
			if client.focus
				then client.focus:raise()
			end
		end, {description = 'switch to next window', group = 'client'}),
	awful.key({altkey, "Shift"}, "Tab",
		function()
			awful.client.focus.byidx(-1)
			if client.focus
				then client.focus:raise()
			end
		end, {description = 'switch to previous window', group = 'client'}),
	awful.key({modkey}, "Up",
		function()
			awful.screen.focus_relative(1)
		end, {description = "focus next screen", group = "tag"}),
	awful.key({modkey}, "Down",
		function()
			awful.screen.focus_relative(-1)
		end, {description = "focus previous screen", group = "tag"}),
	awful.key({modkey}, "Left",
		awful.tag.viewprev, {description = "view previous tag", group = "tag"}),
	awful.key({modkey}, "Right",
		awful.tag.viewnext, {description = "view next tag", group = "tag"}),
	awful.key({modkey}, "b",
		function()
			for s in screen do
				s.mywibox.visible = not s.mywibox.visible
				if s.mybottomwibox then
					s.mybottomwibox.visible = not s.mybottomwibox.visible
				end
			end
		end, {description = "toggle wibox", group = "awesome"}),
	awful.key({modkey}, "t",
		function()
			--lain.util.rename_tag()
			local traywidget = wibox.widget.systray()
			traywidget:set_screen(awful.screen.focused())
		end, {description = "move systray to screen", group = "awesome"}),
	awful.key({altkey, "Control"}, "Left",
		function()
			lain.util.move_tag(-1)
		end, {description = "move tag to the left", group = "tag"}),
	awful.key({altkey, "Control"}, "Right",
		function()
			lain.util.move_tag(1)
		end, {description = "move tag to the right", group = "tag"}),
	awful.key({modkey}, "c",
		function()
			awful.util.spawn(terminal)
		end, {description = "open terminal", group = "hotkeys"}),
	awful.key({modkey, "Control"}, "r",
		awesome.restart,
		{description = "reload awesome", group = "awesome"}),
	awful.key({modkey, "Control"}, "q",
		awesome.quit,
		{description = "quit awesome", group = "awesome"}),
	awful.key({ modkey }, "KP_Add",
		function()
			awful.tag.incncol(1) 
			call_layout_info()
		end, {description = "increase columns", group = "layout"}),
	awful.key({ modkey }, "KP_Subtract",
		function()
			awful.tag.incncol(-1)
			call_layout_info()
		end, {description = "decrease columns", group = "layout"}),
	awful.key({ modkey, "Shift" }, "KP_Add",
		function()
			awful.tag.incnmaster(1)
			call_layout_info()
		end, {description = "increase master clients", group = "layout"}),
	awful.key({ modkey, "Shift" }, "KP_Subtract",
		function()
			awful.tag.incnmaster(-1)
			call_layout_info()
		end, {description = "decrease master clients", group = "layout"}),
	awful.key({ modkey }, "Tab",
		function()
			awful.layout.inc(1)
			call_layout_info()
		end, {description = "select next layout", group = "layout"}),
	awful.key({ modkey, "Shift" }, "Tab",
		function()
			awful.layout.inc(-1)
			call_layout_info()
		end, {description = "select previous layout", group = "layout"}),
	awful.key({}, "XF86MonBrightnessUp",
		function()
			os.execute("xbacklight -inc 5")
		end, {description = "+5", group = "hotkeys"}),
	awful.key({}, "XF86MonBrightnessDown",
		function()
			os.execute("xbacklight -dec 5")
		end, {description = "-5%", group = "hotkeys"}),
	awful.key({}, "XF86AudioRaiseVolume",
		function()
			os.execute(string.format("amixer set %s 5%%+", beautiful.volume.channel))
			beautiful.volume.update()
		end, {description = "volume up", group = "hotkeys"}),
	awful.key({}, "XF86AudioLowerVolume",
		function()
			os.execute(string.format("amixer set %s 5%%-", beautiful.volume.channel))
			beautiful.volume.update()
		end, {description = "volume down", group = "hotkeys"}),
	awful.key({}, "XF86AudioMute",
		function()
			os.execute(string.format("amixer -q set %s toggle", beautiful.volume.togglechannel or beautiful.volume.channel))
			beautiful.volume.update()
		end, {description = "toggle mute", group = "hotkeys"}),
	awful.key({ modkey }, "d",
		function ()
			for _, c in ipairs(mouse.screen.selected_tag:clients()) do
				c.minimized = true
			end
		end, {description = "minimize all windows", group = "client"}),
	awful.key({ modkey, "Shift" }, "d",
		function ()
			for _, c in ipairs(mouse.screen.selected_tag:clients()) do
				c.minimized = false
			end
		end, {description = "restore all windows", group = "client"}),
	awful.key({modkey}, "space",
		function()
			awful.spawn("rofi -show drun")
		end, {description = "app launcher", group = "launcher"}),
	awful.key({modkey}, "r",
		function()
			awful.screen.focused().mypromptbox:run()
		end, {description = "execute command", group = "awesome"})
)

clientkeys = my_table.join(
	awful.key({modkey,altkey}, "Up",
		function (c)
			move_client_to_screen(c, gears.math.cycle(screen:count(), c.screen.index+1))
		end, {description = "move to next screen", group = "clients movement"}),
	awful.key({modkey,altkey}, "Down",
		function (c)
			move_client_to_screen(c, gears.math.cycle(screen:count(), c.screen.index-1))
		end, {description = "move to previous screen", group = "clients movement"}),
	awful.key({modkey,altkey}, "Right",
		function (c)
			c:move_to_tag(c.screen.tags[gears.math.cycle(#c.screen.tags, c.first_tag.index + 1)]) awful.tag.viewnext()
		end, {description = "move to next tag", group = "clients movement"}),
	awful.key({modkey,altkey}, "Left",
		function
			(c) c:move_to_tag(c.screen.tags[gears.math.cycle(#c.screen.tags, c.first_tag.index - 1)]) awful.tag.viewprev()
		end, {description = "move to previous tag", group = "clients movement"}),
	awful.key({ modkey }, "m",
		lain.util.magnify_client, {description = "magnify client", group = "client"}),
	awful.key({modkey}, "v",
		function(c)
			c.minimized = true
		end, {description = "minimize current window", group = "client"}),
	awful.key({modkey}, "f",
		function(c)
			c.fullscreen = not c.fullscreen
			c:raise()
		end, {description = "toggle fullscreen", group = "client"}),
	awful.key({modkey}, "p",
		function(c)
			c.sticky = not c.sticky
		end, {description = "toggle client sticky", group = "client"}),	
	awful.key({modkey}, "q",
		function(c)
			c:kill()
		end, {description = "close", group = "client"}),
	awful.key({modkey}, "Return",
		function(c)
			c:swap(awful.client.getmaster())
		end, {description = "move to master", group = "client"}),
	awful.key({modkey}, "KP_Enter",
		function(c)
			c:swap(awful.client.getmaster())
		end, {description = "move to master", group = "client"}),
	awful.key({modkey}, "o",
		function(c)
			c.ontop = not c.ontop
		end, {description = "always-on-top client", group = "client"}),
	awful.key({modkey, "Control"}, "o",
		function(c)
			c:move_to_screen()
		end, {description = "move to screen",group = "client"}),
	awful.key({modkey, "Control"}, "Up",
		function(c)
			if c.floating then
				c:relative_move(0, 0, 0, -20)
			else
				awful.client.incwfact(0.025)
			end
		end, {description = "Floating Resize Vertical -", group = "client"}),
	awful.key({modkey, "Control"}, "Down",
		function(c)
			if c.floating then
				c:relative_move(0, 0, 0, 20)
			else
				awful.client.incwfact(-0.025)
			end
		end, {description = "Floating Resize Vertical +", group = "client"}),
	awful.key({modkey, "Control"}, "Left",
		function(c)
			if c.floating then
				c:relative_move(0, 0, -20, 0)
			else
				awful.tag.incmwfact(-0.025)
			end
		end, {description = "Floating Resize Horizontal -", group = "client"}),
	awful.key({modkey, "Control"}, "Right",
		function(c)
			if c.floating then
				c:relative_move(0, 0, 20, 0)
			else
				awful.tag.incmwfact(0.025)
			end
		end, {description = "Floating Resize Horizontal +", group = "client"}),
	awful.key({modkey, "Shift"}, "Down",
		function(c)
			if c.floating then
				c:relative_move(0, 20, 0, 0)
			else
				awful.client.swap.byidx(1)
			end
		end, {description = "Floating Move Down", group = "client"}),
	awful.key({modkey, "Shift"}, "Up",
		function(c)
			if c.floating then
				c:relative_move(0, -20, 0, 0)
			else
				awful.client.swap.byidx(-1)
			end
		end, {description = "Floating Move Up", group = "client"}),
	awful.key({modkey, "Shift"}, "Left",
		function(c)
			if c.floating then
				c:relative_move(-20, 0, 0, 0)
			else
				awful.client.swap.byidx(-1)
			end
		end, {description = "Floating Move Left", group = "client"}),
	awful.key({modkey, "Shift"}, "Right",
		function(c)
			if c.floating then
				c:relative_move(20, 0, 0, 0)
			else
				awful.client.swap.byidx(1)
			end
		end, {description = "Floating Move Right", group = "client"})
)
-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = my_table.join(globalkeys,
	-- View tag only.
	awful.key({ modkey }, "#" .. i + 9,
		function ()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if tag then
				tag:view_only()
			end
		end, {description = "view tag #"..i, group = "tag"}),
	-- move client to tags
	awful.key({ modkey, altkey }, "#" .. i + 9,
		function ()
			local screen = awful.screen.focused()
			local tag = screen.tags[i]
			if client.focus then 
				client.focus:move_to_tag(tag) 
				tag:view_only()
			end
		end, {description = "move to tag #"..i, group = "clients movement"})
	)
end

-- Set Mouse buttons
clientbuttons = gears.table.join(
	awful.button({}, 1,
		function(c)
			c:emit_signal("request::activate", "mouse_click", {raise = true})
		end),
	awful.button({modkey, altkey}, 1, awful.client.movetotag),
	awful.button({modkey}, 1,
		function(c)
			c:emit_signal("request::activate", "mouse_click", {raise = true})
			awful.mouse.client.move(c)
		end),
	awful.button({modkey}, 3,
		function(c)
			c:emit_signal("request::activate", "mouse_click", {raise = true})
			awful.mouse.client.resize(c)
		end),
	awful.button({modkey}, 4,
		function(c)
			c:emit_signal("request::activate", "mouse_click", {raise = true})
			awful.client.floating.toggle(c)
		end)
)

-- Set keys
root.keys(globalkeys)

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	{rule = {},
	properties = {
		maximized_horizontal = false,
		maximized_vertical = false,
		maximized = false,
		border_width = beautiful.border_width + 1,
		border_color = beautiful.border_normal,
		focus = awful.client.focus.filter,
		raise = true,
		keys = clientkeys,
		buttons = clientbuttons,
		screen = awful.screen.preferred,
		placement = awful.placement.no_overlap + awful.placement.no_offscreen,
		size_hints_honor = false}	
	},
	-- Floating clients
	{rule_any = {instance = {
				"DTA", -- Firefox addon DownThemAll. 
				"copyq", -- Includes session name in class.
				"pinentry",
				},
			class = {
				"Arandr", "Nautilus", "Gnome-calculator", "feh", "Blueman-manager", "Gpick", "Kruler", "MessageWin", -- kalarm.
				"Sxiv", "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
				"Wpa_gui", "veromix", "xtightvncviewer",
				"xvkbd"},
			-- Note that the name property shown in xprop might be set slightly after creation of the client
			-- and the name shown there might not match defined rules here.
			name = {"Event Tester", -- xev.
				"xvkbd - Virtual Keyboard"
				},
			role = {"AlarmWindow", -- Thunderbird's calendar.
					"ConfigManager", -- Thunderbird's about:config.
					"pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
				}},
		properties = {floating = false}},
	{rule_any = {type = {"dialog", "normal"}}, properties = {titlebars_enabled = false}},
	{rule = {class = "Notepadqq", name = "Search"}, properties = {ontop = true}},
	{rule = {class = "Mate-calc", name = "Calculator"}, properties = {ontop = true}},
	{rule = {class = "CMST - Connman System Tray", name = "Connman System Tray"}, properties = {ontop = true}},
	{rule = {class = "Lxrandr", name = "Display Settings"}, properties = {ontop = true}},
	{rule = {class = "libreoffice*" }, properties = { floating = false, maximize = false, below = true }},
    	{rule = {class = "org.inkscape.Inkscape", name = "*" }, properties = { floating = false, maximize = false, below = true }},
		-- Set Firefox to always map on the tag named "2" on screen 1.
		-- { rule = { class = "Firefox" }, properties = { screen = 1, tag = "2" } },
}


-- Signal function to execute when a new client appears.
client.connect_signal("manage",
	function(c)
		-- Set the windows at the slave,
		-- i.e. put it at the end of others instead of setting it master.
		-- if not awesome.startup then awful.client.setslave(c) end
		if awesome.startup 
			and not c.size_hints.user_position 
			and not c.size_hints.program_position then
			-- Prevent clients from being unreachable after screen count changes.
				awful.placement.no_offscreen(c)
		end
		c.shape = function(cr,w,h)
			gears.shape.rounded_rect(cr,w,h,6)
		end
	end
)


-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter",
	function(c)
		c:emit_signal("request::activate", "mouse_enter", {raise = vi_focus})
	end
)
client.connect_signal("focus",
	function(c)
		c.border_color = beautiful.border_focus
 	end
)
client.connect_signal("unfocus",
	function(c)
		c.border_color = beautiful.border_normal
	end
)

os.execute("picom -b --config ~/.config/picom/picom.conf --xrender-sync-fence --experimental-backends")
os.execute("pactl info &")
os.execute("cmst -m &")
