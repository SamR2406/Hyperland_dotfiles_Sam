#!/bin/bash
# ── bluetooth-manager.sh ──────────────────────────────────
# Description: Rofi-based Bluetooth manager using bluetoothctl
# Usage: Called on-click from waybar bluetooth module
# Dependencies: bluetoothctl, rofi, notify-send
# ──────────────────────────────────────────────────────────

rofi_cmd="rofi -dmenu -p 󰂯 Bluetooth -i"

# Check if bluetooth is powered
bt_power=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

# ── Main menu ─────────────────────────────────────────────
if [ "$bt_power" = "yes" ]; then
    menu="󰂯  Scan for devices\n󰂲  Turn Off\n──────────────\n$(bluetoothctl devices Paired | awk '{$1=$2=""; print "󰂱 " $0}' | sed 's/^  //')"
else
    menu="󰂯  Turn On"
fi

chosen=$(echo -e "$menu" | $rofi_cmd)
[ -z "$chosen" ] && exit 0

# ── Actions ───────────────────────────────────────────────
case "$chosen" in

  *"Turn On"*)
    bluetoothctl power on
    notify-send "󰂯 Bluetooth" "Turned on" -t 2000
    ;;

  *"Turn Off"*)
    bluetoothctl power off
    notify-send "󰂲 Bluetooth" "Turned off" -t 2000
    ;;

  *"Scan for devices"*)
    notify-send "󰂯 Bluetooth" "Scanning for 10 seconds..." -t 3000

    # Scan in background and collect devices
    bluetoothctl scan on &
    scan_pid=$!
    sleep 10
    kill $scan_pid 2>/dev/null
    bluetoothctl scan off 2>/dev/null

    # List found devices
    devices=$(bluetoothctl devices | awk '{$1=""; print "󰂯 " $0}' | sed 's/^  //')
    [ -z "$devices" ] && notify-send "󰂯 Bluetooth" "No devices found" -t 3000 && exit 0

    # Pick a device
    chosen_device=$(echo -e "$devices" | rofi -dmenu -p "󰂯 Connect to" -i)
    [ -z "$chosen_device" ] && exit 0

    # Extract MAC address
    mac=$(bluetoothctl devices | grep "${chosen_device#󰂯 }" | awk '{print $2}')
    [ -z "$mac" ] && exit 0

    # Pair and connect
    notify-send "󰂯 Bluetooth" "Connecting to ${chosen_device#󰂯 }..." -t 2000
    bluetoothctl pair "$mac" 2>/dev/null
    bluetoothctl connect "$mac" && \
      notify-send "󰂯 Bluetooth" "Connected to ${chosen_device#󰂯 }" -t 3000 || \
      notify-send "󰂲 Bluetooth" "Failed to connect" -t 3000
    ;;

  *) 
    # Clicked a paired device — connect or disconnect
    device_name=$(echo "$chosen" | sed 's/^󰂱 //')
    mac=$(bluetoothctl devices Paired | grep "$device_name" | awk '{print $2}')
    [ -z "$mac" ] && exit 0

    # Check if already connected
    is_connected=$(bluetoothctl info "$mac" | grep "Connected: yes")

    if [ -n "$is_connected" ]; then
      action=$(echo -e "󰂲  Disconnect\n󰗑  Remove device" | rofi -dmenu -p "$device_name" -i)
      case "$action" in
        *"Disconnect"*)
          bluetoothctl disconnect "$mac" && \
            notify-send "󰂲 Bluetooth" "Disconnected from $device_name" -t 3000
          ;;
        *"Remove"*)
          bluetoothctl remove "$mac" && \
            notify-send "󰂲 Bluetooth" "Removed $device_name" -t 3000
          ;;
      esac
    else
      bluetoothctl connect "$mac" && \
        notify-send "󰂯 Bluetooth" "Connected to $device_name" -t 3000 || \
        notify-send "󰂲 Bluetooth" "Failed to connect" -t 3000
    fi
    ;;

esac