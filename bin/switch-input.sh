#!/usr/bin/env bash
set -euo pipefail

selection=${1:-}

main_sn="7Z1S093"
alt_sn="1C0DSP3"

next_main=""
next_alt=""

if [ -n "$selection" ]; then
  echo "received input selection $selection" | systemd-cat -t switch-input -p info
  case "$selection" in
    dp1)
      next_main="0x0f"
      ;;
    usbc)
      next_main="0x1b"
      ;;
    desktop)
      next_main="0x0f"
      next_alt="0x11"
      ;;
    dock)
      next_main="0x1b"
      next_alt="0x0f"
      ;;
  esac
else
  current_main=$(ddcutil getvcp --sn "$main_sn" 60 --brief | awk '{ print $4 }')

  case "$current_main" in
    x1b)
      next_main="0x0f"
      ;;
    x0f)
      next_main="0x1b"
      ;;
  esac
fi

if [ -n "$next_main" ]; then
  echo "switching main monitor to input $next_main" | systemd-cat -t switch-input -p info
  ddcutil --sn "$main_sn" setvcp 60 "$next_main" &
fi

if [ -n "$next_alt" ]; then
  echo "switching alt monitor to input $next_alt" | systemd-cat -t switch-input -p info
  ddcutil --sn "$alt_sn" setvcp 60 "$next_alt" &
fi

wait

