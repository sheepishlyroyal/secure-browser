#!/bin/sh
# Respawn Chromium if its process is gone (e.g. the user closed the only window), so the
# desktop never gets stuck blank. Conservative: only restart after several CONFIRMED
# misses, and never act unless `ps` actually works inside the container (no restart loops).
sleep 45
miss=0
while true; do
  sleep 5
  state=$(docker inspect -f '{{.State.Running}}' chromium 2>/dev/null)
  [ "$state" = "true" ] || { miss=0; continue; }
  procs=$(docker exec chromium ps -e 2>/dev/null) || { miss=0; continue; }
  if echo "$procs" | grep -qiE 'chromium|chrome'; then
    miss=0
  else
    miss=$((miss + 1))
    if [ "$miss" -ge 4 ]; then
      echo "[watchdog] Chromium not running — restarting container"
      docker restart chromium >/dev/null 2>&1
      miss=0
      sleep 35
    fi
  fi
done
