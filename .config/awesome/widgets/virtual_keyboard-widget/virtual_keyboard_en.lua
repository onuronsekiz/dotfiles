-- Dependency: xdotool
--
-- Usage:
-- 1. Save as "virtual_keyboard.lua" in ~/.config/awesome/
-- 2. Add a virtual_keyboard for every screen:
--		awful.screen.connect_for_each_screen(function(s)
--			...
--			local virtual_keyboard = require("virtual_keyboard")
--			s.virtual_keyboard = virtual_keyboard:new({ screen = s } )
--			...
--		end)
-- 3. Toggle by using: awful.screen.focused().virtual_keyboard:toggle()

local awful = require("awful")
local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi

local module = {}

local key_size = dpi(50)
local mod_fg_color = "#A9DD9D"
local mod_bg_color = "#2B373E"
local accent_fg_color = "#2B373E"
local accent_bg_color = "#A9DD9D"
local press_fg_color = "#2B373E"
local press_bg_color = "#A1BFCF"

function module.button(attributes)
	local attr = attributes or {}
	attr.togglable = attr.toggleable or false
	attr.size = attr.size or 1.0
	attr.name = attr.name or ""
	attr.keycode = attr.keycode or attr.name or nil
	attr.bg = attr.bg or "#2B373E"
	attr.fg = attr.fg or "#A1BFCF"
	attr.spacing = attr.spacing or dpi(3)
	local textbox = wibox.widget.textbox(attr.name)
	textbox.font = "Liberation Mono 12"
	local box = wibox.widget.base.make_widget_declarative({
			{
				{
					{
						{
							textbox,
							fill_vertical = false,
							fill_horizontal = false,
							valign = true,
							halign = true,
							widget = wibox.container.place
						},
						widget = wibox.container.margin
					},
					id = "bg",
					opacity = (string.len(attr.name) == 0) and 0 or 1,
					fg = attr.fg,
					bg = attr.bg,
					widget = wibox.container.background
				},
				right = attr.spacing,
				top = attr.spacing,
				forced_height = key_size,
				forced_width = key_size * attr.size,
				widget = wibox.container.margin
			},
			widget = wibox.container.background,
			bg = "#56666f"

		})
	local boxbg = box:get_children_by_id("bg")[1]
	boxbg:connect_signal("button::press", function()
		if not attr.keycode then
			awful.spawn("xdotool key " .. attr.name)
		else
			awful.spawn("xdotool key " .. attr.keycode)
		end

		boxbg.bg = press_bg_color
		boxbg.fg = press_fg_color

		awful.spawn.easy_async_with_shell("sleep 0.3", function()
			boxbg.bg = attr.bg
			boxbg.fg = attr.fg
		end)

	end)
	return box
end

function module:new(config)
	local conf = config or {}
	conf.visible = false

	conf.screen = conf.screen or awful.screen.focused()
	conf.position = conf.position or "bottom"

	-- wibox
	local bar = awful.wibar({
			position = conf.position,
			screen = conf.screen,
			height = (6 * key_size),
			bg = "#56666f",
			visible = conf.visible
		})
	bar:setup{
		widget = wibox.container.margin,
		{
			widget = wibox.container.background,
			{
				layout = wibox.layout.fixed.vertical,
				spacing = 0,
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 7,
						forced_height = key_size,
						module.button({
								name = "Esc",
								size = 1.25,
								keycode = "Escape",
								fg = accent_fg_color,
								bg = accent_bg_color,
							}),
						module.button({ name = "F1" }),
						module.button({ name = "F2" }),
						module.button({ name = "F3" }),
						module.button({ name = "F4" }),
						module.button({ name = "F5" }),
						module.button({ name = "F6" }),
						module.button({ name = "F7" }),
						module.button({ name = "F8" }),
						module.button({ name = "F9" }),
						module.button({ name = "F10" }),
						module.button({ name = "F11" }),
						module.button({ name = "F12" }),
					},
					{ layout = wibox.layout.fixed.horizontal }
				},
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						forced_height = key_size,
						module.button({
								name = "é\n\"",
								size = 1,
								keycode = "quotedbl",
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({ name = "!\n1" }),
						module.button({ name = "\'\n2", keycode = 2 }),
						module.button({ name = "^\n3 #", keycode = 3 }),
						module.button({ name = "+\n4 $" }),
						module.button({ name = "%\n5" }),
						module.button({ name = "&amp;\n6" }),
						module.button({ name = "/\n7 {" }),
						module.button({ name = "(\n8 [" }),
						module.button({ name = ")\n9 ]" }),
						module.button({ name = "=\n0 }" }),
						module.button({ name = "?\n* \\", keycode = "asterisk" }),
						module.button({ name = "_\n-", keycode = "minus" }),
						--module.button({ name = "-", keycode = "minus" }),
						--module.button({ name = "=", keycode = "equal" }),
						module.button({
								name = "Backspace",
								size = 2.0,
								keycode = "BackSpace",
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						-- module.button({
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "Insert" }),
						-- module.button({ name = "Home" }),
						-- module.button({
						--     name = "PageUp",
						--     keycode = "Page_Up"
						-- })
						--
						--
					},
					{ layout = wibox.layout.fixed.horizontal }
				},
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						forced_height = key_size,
						module.button({
								name = "Tab",
								size = 1.75,
								keycode = "Tab",
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({ name = "q @" }),
						module.button({ name = "w" }),
						module.button({ name = "e €" }),
						module.button({ name = "r" }),
						module.button({ name = "t ₺" }),
						module.button({ name = "y" }),
						module.button({ name = "u" }),
						module.button({ name = "ı", keycode = "idotless" }),
						module.button({ name = "o" }),
						module.button({ name = "p" }),
						module.button({ name = "ğ", keycode = "gbreve" }),
						module.button({ name = "ü ~", keycode = "udiaeresis" }),
						--module.button({ name = "[", keycode = "bracketleft" }),
						--module.button({ name = "]", keycode = "bracketright" }),
						module.button({
								name = "Num\nLock",
								size = 1.25,
								keycode = "Num_Lock",
								fg = accent_fg_color,
								bg = accent_bg_color,
							}),
						-- module.button({
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "Delete" }),
						-- module.button({ name = "End" }),
						-- module.button({
						--     name = "PageDown",
						--     keycode = "Page_Down"
						-- })
					},
					{ layout = wibox.layout.fixed.horizontal }
				},
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						module.button({
								name = "Caps",
								size = 1.5,
								keycode = "Caps_Lock",
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({ name = "a" }),
						module.button({ name = "s" }),
						module.button({ name = "d" }),
						module.button({ name = "f" }),
						module.button({ name = "g" }),
						module.button({ name = "h" }),
						module.button({ name = "j" }),
						module.button({ name = "k" }),
						module.button({ name = "l" }),
						module.button({ name = "ş ´", keycode = "scedilla" }),
						module.button({ name = "i" }),
						module.button({ name = ";\n, `", keycode = "comma" }),
						--module.button({ name = ";", keycode = "semicolon" }),
						--module.button({ name = "'", keycode = "apostrophe" }),
						module.button({
								name = "Enter",
								size = 1.5,
								--size = 2.25,
								keycode = "Return",
								fg = accent_fg_color,
								bg = accent_bg_color,
							}),
						-- module.button({
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "" }),
						-- module.button({ name = "" }),
						-- module.button({ name = "" })
					},
					{ layout = wibox.layout.fixed.horizontal }
				},
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						module.button({
								name = "Shift",
								size = 1.25,
								keycode = "keydown Shift_L sleep 2 keyup Shift_L",
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({ name = "&gt;\n&lt; |", keycode = 94 }),
						module.button({ name = "z" }),
						module.button({ name = "x" }),
						module.button({ name = "c" }),
						module.button({ name = "v" }),
						module.button({ name = "b" }),
						module.button({ name = "n" }),
						module.button({ name = "m" }),
						module.button({ name = "ö", keycode = "odiaeresis" }),
						module.button({ name = "ç", keycode = "ccedilla" }),
						module.button({ name = ":\n.", keycode = "period" }),
						--module.button({ name = ",", keycode = "comma" }),
						--module.button({ name = ".", keycode = "period" }),
						--module.button({ name = "/", keycode = "slash" }),
						module.button({
								name = "Shift",
								size = 2.75,
								keycode = "keydown Shift_R sleep 2 keyup Shift_R",
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						-- module.button({
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "" }),
						-- module.button({ name = "Up" }),
						-- module.button({ name = "" })
					},
					{ layout = wibox.layout.fixed.horizontal }
				},
				{
					layout = wibox.layout.align.horizontal,
					expand = "none",
					{ layout = wibox.layout.fixed.horizontal },
					{
						layout = wibox.layout.grid,
						orientation = "horizontal",
						horizontal_expand = false,
						homogeneous = false,
						spacing = 0,
						module.button({
								name = "Ctrl",
								keycode = "keydown Control_L sleep 2 keyup Control_L",
								size = 1.5,
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({
								name = "Super",
								keycode = "keydown Super_L sleep 2 keyup Super_L",
								size = 1.25,
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({
								name = "Alt",
								keycode = "keydown Alt_L sleep 2 keyup Alt_L",
								size = 1.25,
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({
								name = " ",
								size = 5.75,
								keycode = "space"
							}),
						module.button({
								name = "AltGr",
								keycode = "keydown ISO_Level3_Shift sleep 2 keyup ISO_Level3_Shift",
								size = 1.25,
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({
								name = "OFF",
								keycode = "Super_L+z",
								size = 1,
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({
								name = "Menu",
								keycode = 135,
								size = 1.25,
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						module.button({
								name = "Ctrl",
								keycode = "keydown Control_R sleep 2 keyup Control_R",
								size = 1.75,
								fg = mod_fg_color, bg = mod_bg_color,
							}),
						-- module.button({
						--     name = "",
						--     size = 0.25
						-- }),
						-- module.button({ name = "Left" }),
						-- module.button({ name = "Down" }),
						-- module.button({ name = "Right" })
					},
					{ layout = wibox.layout.fixed.horizontal }
				}
			}
		}
	}
	conf.bar = bar
	local dropdown = setmetatable(conf, { __index = module })
	return dropdown
end

function module:toggle()
	self.bar.visible = not self.bar.visible
end

return setmetatable(module, { __call = function(_, ...)
	return module:new(...)
end })
