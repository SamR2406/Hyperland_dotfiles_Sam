#!/bin/bash
# ── pia.sh ────────────────────────────────────────────────
# Description: Shows PIA VPN connection status with shield icon
# Usage: Waybar `custom/pia` every 5s
# Dependencies: piactl
# ──────────────────────────────────────────────────────────

state=$(/usr/local/bin/piactl get connectionstate)
region=$(/usr/local/bin/piactl get region)
vpnip=$(/usr/local/bin/piactl get vpnip)

# Capitalise region for display (mexico → Mexico)
region_display=$(echo "$region" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

case "$state" in
  "Connected")
    icon="󰒃"
    fg="#56b6c2"
    text="<span foreground='$fg'>$icon $region_display</span>"
    tooltip="VPN: Connected\nRegion: $region_display\nVPN IP: $vpnip"
    ;;
  "Connecting"|"Reconnecting"|"DisconnectingToReconnect")
    icon="󰒄"
    fg="#fab387"
    text="<span foreground='$fg'>$icon $region_display...</span>"
    tooltip="VPN: $state\nRegion: $region_display"
    ;;
  "Disconnected")
    icon="󱘖"
    fg="#ffffff"
    text="<span foreground='$fg'>$icon</span>"
    tooltip="VPN: Disconnected\nLast region: $region_display"
    ;;
  *)
    icon="󰒄"
    fg="#bf616a"
    text="<span foreground='$fg'>$icon</span>"
    tooltip="VPN: $state"
    ;;
esac

echo "{\"text\":\"$text\",\"tooltip\":\"$tooltip\"}"