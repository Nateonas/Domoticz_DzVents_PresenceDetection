--[[
dzPRESENCE
Ping devices IP-addresses (like mobile phones) in local network to check Presence
dzVents-scripts for Domoticz
Tested on version Domoticz 2024.4 Raspberry Pi 3 (bullseye)
This script is using _ping_. Make sure your firewall allows ICMP requests. If you
do not understand this, then you likely did not configure your firewall to block 
ICMP requests.

Features:
* No shell-scripts, crontab or additional package installs (arping) required
* Supports any number of devices

To do:
* Single line summery logging
* Update Domoticz wiki (https://www.domoticz.com/wiki/Presence_detection) 

Author  : Nateonas
Date    : 2024-06-07
Version : 1
Source  : initial

!! HELP !!
Please inform me when you are changing/improving this dzvents-script.
Better to improve the source so everybody can profit than create a personal fork!
see https://github.com/Nateonas
]]

--------------------------------------------------------------------------------
--  Customise user defaults     
--------------------------------------------------------------------------------
local devices_info = { {'192.168.8.51',  11925,  30},   -- Array with devices
                       {'192.168.8.52',  11926,   3},    -- IP-address, device_idx, cooldown period in minutes
                       {'Anyhome'     ,  11938,   0}}   -- Use "Anyhome" for a 'anyone home'-switch
--                       ^^^^^^^^^^^     ^^^    ^^^     -- You can extend this array with any number of devices
--                       IP-address      Idx    cooldown
-- Notes:
-- Make a virtual switch for every device and input the Idx in devices_info
-- Make sure that your devices have FIXED IP-addresses
-- Cooldown period in minutes (minimum period without responses before turning the device off.
-- As a rule of thumb use a cooldown period of 30 minutes for Apple devices 
-- (Apples turn off wifi turn when the screen is turned off)
-- For other devices, e.g. Android, 3-5 minutes is fine.

local scriptVar    = 'dzPresence'                -- name for logging and shellcallback, no need to change
local pingcommand  = 'ping -q -w 5'          -- ping command, no need to change. Script processes received responses, only summary results are required, ping for 5 seconds.

return
{
--------------------------------------------------------------------------------
    on =
    {
        timer = { 'every 1 minutes' },
        shellCommandResponses = { scriptVar .. "*" },  -- trigger on ANY callback starting with "dzPresence": dzPresence1, dzPresence2, etc.
    },

--------------------------------------------------------------------------------
    logging = {
    -- uncomment below to see the info or debug logging
        level = domoticz.LOG_INFO,
        --level = domoticz.LOG_DEBUG,

        -- marker: A string that is prefixed before each log message. That way you can easily create a filter 
        -- in the Domoticz log to see just these messages. marker defaults to scriptname
        marker = scriptVar
    },

--------------------------------------------------------------------------------
    execute = function(domoticz, item)

-- easy logging functions
    local function dlog(text) return domoticz.log(text, domoticz.LOG_DEBUG) end -- DEBUG log
    local function ilog(text) return domoticz.log(text, domoticz.LOG_INFO)  end -- INFO log
    local function flog(text) return domoticz.log(text, domoticz.LOG_FORCE) end -- Forced (always log regardless of logging setting)
    local function elog(text) return domoticz.log(text, domoticz.LOG_ERROR) end -- Error logging

--------------------------------------------------------------------------------
-- send periodic pings for all devices in devices_info (except anyhome)
--------------------------------------------------------------------------------
        if item.isTimer then
            for i = 1, #devices_info do
                local ip = devices_info[i][1]
                if string.match(ip,"%d+%.%d+%.%d+%.%d+") ~= nil then        -- ip looks like ip-address (not anyhome)
                    local shellcommand = pingcommand .. ' ' ..  ip          -- e.g. ping -q -w 5 192.168.1.1
    		        ilog (shellcommand)
                    domoticz.executeShellCommand(
                    {
                        command  = shellcommand,
                        callback = scriptVar .. i,                          -- dzPresence1, dzPresence2, etc.
                        timeout  = 10,                                      -- timeout in seconds before closing shell (in case of no shell output)
                    })
                end
            end

--------------------------------------------------------------------------------
-- Process the ping-results (shell-output)
--------------------------------------------------------------------------------
        elseif item.isShellCommandResponse then

            local successcount    = 0
            local devicenr        = tonumber(string.match(item.trigger, "%d+"))  -- "dzPresence1" -> 1 -> results for first device in devices_info, etc.
            local device_idx      = devices_info[devicenr][2]
            local device_cooldown = devices_info[devicenr][3]

            if item.statusCode == 0 then                                    -- process result (in item.json, -item.xml, -item.lines or item.data)
			    dlog (item.data)
			    local pingresult = string.match(item.data, "%d+ received")  -- fetch the number of received responses, %d+ means any number of digits
			    dlog (pingresult)
			    successcount = tonumber(string.match(pingresult, "%d+"))    -- fetch just the number of received responses from the string and convert to number
            end

		     if successcount > 0 then
		        domoticz.devices(device_idx).switchOn()                     -- switch On if there is a response regardless of the state, to update lastUpdate/reset cooldown
		    elseif domoticz.devices(device_idx).lastUpdate.minutesAgo >= device_cooldown 
		       and domoticz.devices(device_idx).state ~= "Off" then
			    domoticz.devices(device_idx).switchOff()                    -- only switch Off after the cooldown period and if not already Off
		    end

--------------------------------------------------------------------------------
-- Log the results
--------------------------------------------------------------------------------
            ilog (successcount .. " responses from " .. 
		          domoticz.devices(device_idx).name .. 
                  " (currently " ..
                  domoticz.devices(device_idx).state ..
		          "), last update " .. 
		          domoticz.devices(device_idx).lastUpdate.minutesAgo .. 
		          " minutes ago")

--------------------------------------------------------------------------------
-- Update Anyone Home device (the code needs beautification :-)
--------------------------------------------------------------------------------
            local any_idx     = -1                                            -- Check if a anyhome-switch is present
            local anyhome   = false                                           -- starting with nobody home (false)
            for i = 1, #devices_info do
                local device_ip  = devices_info[i][1]
                local device_idx = devices_info[i][2]
    		    if string.match(device_ip,"%d+%.%d+%.%d+%.%d+") == nil then  -- If not an IP address then anyhome-switch 
    		        any_idx = device_idx                                     -- Anyhone switch present, remember idx
    		    else       
                    anyhome = anyhome or domoticz.devices(device_idx).active -- if any device is present, anyhome is set to true
                end
            end                
            if any_idx ~= -1  then                                           -- if idx is saved then set anyhome
                if anyhome and domoticz.devices(and_idx).inActive then       -- switch On if Off and any device is present
                    domoticz.devices(any_idx).switchOn()
                end
                if not anyhome and domoticz.devices(and_idx).active then     -- switch Off if On and no device is present
                    domoticz.devices(any_idx).switchOff()
                end    
            end
        end -- item.isTimer else item.isShellCommandResponse
    end
}
