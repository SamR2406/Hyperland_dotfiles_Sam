#!/bin/bash
# ── network.sh ────────────────────────────────────────────
# Description: Shows ethernet/wifi status with signal bar
# Usage: Waybar `custom/network` every 5s
# Dependencies: nmcli, awk, ip
# ──────────────────────────────────────────────────────────

# Detect active ethernet interface
eth_iface=$(ip link show | awk -F: '$0 ~ /^[0-9]+: e/{print $2; exit}' | tr -d ' ')
eth_connected=false
if [ -n "$eth_iface" ]; then
  eth_state=$(cat /sys/class/net/$eth_iface/operstate 2>/dev/null)
  [ "$eth_state" = "up" ] && eth_connected=true
fi

# Detect active wifi
wifi_info=$(nmcli -t -f active,ssid,signal,device dev wifi 2>/dev/null | grep '^yes')
wifi_ssid=$(echo "$wifi_info" | cut -d: -f2)
wifi_signal=$(echo "$wifi_info" | cut -d: -f3)
wifi_iface=$(echo "$wifi_info" | cut -d: -f4)

# Get IPs
eth_ip=$(ip -4 addr show "$eth_iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
wifi_ip=$(ip -4 addr show "$wifi_iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)

# ── Build display text ─────────────────────────────────────

text=""
tooltip=""

# Ethernet section
if [ "$eth_connected" = true ]; then
  eth_fg="#56b6c2"
  text="<span foreground='$eth_fg'>󰈀</span>"
  tooltip="Ethernet: $eth_iface\nIP: ${eth_ip:-N/A}"
else
  eth_fg="#4c566a"
  text="<span foreground='$eth_fg'>󰈂</span>"
  tooltip="Ethernet: disconnected"
fi

# WiFi section
if [ -n "$wifi_ssid" ] && [ -n "$wifi_signal" ]; then
  sig=$wifi_signal

  # Signal icon
  if [ "$sig" -ge 80 ]; then
    wifi_icon="󰤨"
    wifi_fg="#56b6c2"
  elif [ "$sig" -ge 60 ]; then
    wifi_icon="󰤥"
    wifi_fg="#56b6c2"
  elif [ "$sig" -ge 40 ]; then
    wifi_icon="󰤢"
    wifi_fg="#fab387"
  elif [ "$sig" -ge 20 ]; then
    wifi_icon="󰤟"
    wifi_fg="#fab387"
  else
    wifi_icon="󰤭"
    wifi_fg="#bf616a"
  fi

  text="$text  <span foreground='$wifi_fg'>$wifi_icon $wifi_ssid</span>"
  tooltip="$tooltip\n\nWiFi: $wifi_ssid ($wifi_iface)\nSignal: $sig%\nIP: ${wifi_ip:-N/A}"
else
  text="$text  <span foreground='#FF746C'>󰤭</span>"
  tooltip="$tooltip\n\nWiFi: off"
fi

# Final JSON
echo "{\"text\":\"$text\",\"tooltip\":\"$tooltip\"}"