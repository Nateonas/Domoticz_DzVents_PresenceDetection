# dzPRESENCE
Ping devices IP-addresses (like mobile phones) in local network to check Presence
dzVents-scripts for Domoticz
Tested on version Domoticz 2024.4 Raspberry Pi 3 (bullseye)
This script is using _ping_. Make sure your firewall allows ICMP requests. If you
do not understand this, then you likely did not configure your firewall to block 
ICMP requests.

# Features:
* No shell-scripts, crontab or additional package installs (arping) required
* Supports any number of devices

#
To do:
* Single line summery logging
* Update Domoticz wiki (https://www.domoticz.com/wiki/Presence_detection) 

#
Author  : Nateonas
Date    : 2024-06-07
Version : 1
Source  : initial

!! HELP !!
Please inform me when you are changing/improving this dzvents-script.
Better to improve the source so everybody can profit than create a personal fork!
see https://github.com/Nateonas
