--[[

     Licensed under GNU General Public License v2
      * (c) 2013,      Luca CPZ
      * (c) 2010-2012, Peter Hofmann

--]]

local helpers = require("lain.helpers")
local naughty = require("naughty")
local wibox   = require("wibox")
local string  = string

-- Network infos
-- lain.widget.net

function convert_size( oSize ) -- convert size from bytes to human readable form.
	local oldsize = cSize
	if oSize > 1099511627776 then
		nSize = string.format("%sT", math.floor (oSize * 100 / 1099511627776) / 100 )
	elseif oSize > 1073741824 then
		nSize = string.format("%sG", math.floor (oSize / 1073741824))
	elseif oSize> 1048576 then
		nSize = string.format("%sM", math.floor (oSize / 1048576))
	elseif oSize > 1024 then
		nSize = string.format("%sK", math.floor (oSize / 1024))
	else
		nSize = string.format("%sB", math.floor (oSize))
	end
	return ( nSize )
end

local function factory(args)
    local net        = { widget = wibox.widget.textbox(), devices = {} }
    local args       = args or {}
    local timeout    = args.timeout or 2
    local notify     = args.notify or "on"
    local wifi_state = args.wifi_state or "off"
    local eth_state  = args.eth_state or "off"
    local screen     = args.screen or 1
    local settings   = args.settings or function() end

    -- Compatibility with old API where iface was a string corresponding to 1 interface
    net.iface = (args.iface and (type(args.iface) == "string" and {args.iface}) or
                (type(args.iface) == "table" and args.iface)) or {}

    function net.get_device()
        helpers.line_callback("ip link", function(line)
            net.iface[#net.iface + 1] = not string.match(line, "LOOPBACK") and string.match(line, "(%w+): <") or nil
        end)
    end

    if #net.iface == 0 then net.get_device() end

    function net.update()
        -- These are the totals over all specified interfaces
        net_now = {
            devices  = {},
            -- Bytes since last iteration
            sent     = 0,
            received = 0
        }

        for _, dev in ipairs(net.iface) do
            local dev_now    = {}
            local dev_before = net.devices[dev] or { last_t = 0, last_r = 0 }
            local now_t      = tonumber(helpers.first_line(string.format("/sys/class/net/%s/statistics/tx_bytes", dev)) or 0)
            local now_r      = tonumber(helpers.first_line(string.format("/sys/class/net/%s/statistics/rx_bytes", dev)) or 0)

            dev_now.carrier  = helpers.first_line(string.format("/sys/class/net/%s/carrier", dev)) or "0"
            dev_now.state    = helpers.first_line(string.format("/sys/class/net/%s/operstate", dev)) or "down"

            dev_now.sent     = (now_t - dev_before.last_t) / timeout
            dev_now.received = (now_r - dev_before.last_r) / timeout

            net_now.sent     = net_now.sent + dev_now.sent
            net_now.received = net_now.received + dev_now.received

            dev_now.sent     = string.format("%s", convert_size(dev_now.sent))
            dev_now.received = string.format("%s", convert_size(dev_now.received))

            dev_now.last_t   = now_t
            dev_now.last_r   = now_r

            if wifi_state == "on" and helpers.first_line(string.format("/sys/class/net/%s/uevent", dev)) == "DEVTYPE=wlan" and string.match(dev_now.carrier, "1") then
                dev_now.wifi   = true
                dev_now.signal = tonumber(string.match(helpers.lines_from("/proc/net/wireless")[3], "(%-%d+%.)")) or nil
            end

            if eth_state == "on" and helpers.first_line(string.format("/sys/class/net/%s/uevent", dev)) ~= "DEVTYPE=wlan" and string.match(dev_now.carrier, "1") then
                dev_now.ethernet = true
            end

            net.devices[dev] = dev_now

            -- Notify only once when connection is lost
            if string.match(dev_now.carrier, "0") and notify == "on" and helpers.get_map(dev) then
                naughty.notify {
                    title    = dev,
                    text     = "No carrier",
                    icon     = helpers.icons_dir .. "no_net.png",
                    screen   = screen
                }
                helpers.set_map(dev, false)
            elseif string.match(dev_now.carrier, "1") then
                helpers.set_map(dev, true)
            end

            net_now.carrier = dev_now.carrier
            net_now.state = dev_now.state
            net_now.devices[dev] = dev_now
            -- net_now.sent and net_now.received will be
            -- the totals across all specified devices
        end

        net_now.sent = string.format("%s", convert_size(net_now.sent))
        net_now.received = string.format("%s", convert_size(net_now.received))

        widget = net.widget
        settings()
    end

    helpers.newtimer("network", timeout, net.update)

    return net
end

return factory
