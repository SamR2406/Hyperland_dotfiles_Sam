#!/bin/bash
# ── wifi-picker.sh ────────────────────────────────────────
# Description: Rofi-based WiFi network picker using nmcli
# Usage: Called on-click from waybar network module
# Dependencies: nmcli, rofi, notify-send
# ──────────────────────────────────────────────────────────

rofi_cmd="rofi -dmenu -p 󰤨 WiFi -i"

# Make sure WiFi is enabled before scanning. This lets left-click recover
# after right-click disabled the radio.
nmcli radio wifi on 2>/dev/null

# Scan for networks
notify-send "󰤨 WiFi" "Scanning for networks..." -t 2000

nmcli dev wifi rescan 2>/dev/null
sleep 1

# List available networks: signal + ssid, sorted by signal
networks=$(nmcli -t -f signal,ssid dev wifi list 2>/dev/null \
  | sort -t: -k1 -rn \
  | awk -F: '
      $2 != "" {
        sig = $1
        ssid = $2
        if (sig >= 80) icon = "󰤨"
        else if (sig >= 60) icon = "󰤥"
        else if (sig >= 40) icon = "󰤢"
        else if (sig >= 20) icon = "󰤟"
        else icon = "󰤯"
        printf "%s  %-30s  %s%%\n", icon, ssid, sig
      }
  ' \
  | sort -u -k2,2)  # deduplicate by ssid

# Show in rofi
chosen=$(echo -e "$networks" | $rofi_cmd)
[ -z "$chosen" ] && exit 0

# Extract SSID from chosen line (second field)
ssid=$(echo "$chosen" | awk '{print $2}')
[ -z "$ssid" ] && exit 0

# Check if already saved
saved=$(nmcli -t -f name con show | grep -Fx "$ssid")

if [ -n "$saved" ]; then
  # Known network — just connect
  notify-send "󰤨 WiFi" "Connecting to $ssid..." -t 2000
  nmcli con up "$ssid" && \
    notify-send "󰤨 WiFi" "Connected to $ssid" -t 3000 || \
    notify-send "󰤫 WiFi" "Failed to connect to $ssid" -t 3000
else
  # Unknown network — ask for password
  password=$(rofi -dmenu -p "󰌋 Password for $ssid" -password)
  if [ -n "$password" ]; then
    notify-send "󰤨 WiFi" "Connecting to $ssid..." -t 2000
    nmcli dev wifi connect "$ssid" password "$password" && \
      notify-send "󰤨 WiFi" "Connected to $ssid" -t 3000 || \
      notify-send "󰤫 WiFi" "Failed — wrong password?" -t 3000
  fi
fi
