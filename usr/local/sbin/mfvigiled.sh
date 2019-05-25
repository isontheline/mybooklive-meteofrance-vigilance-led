#!/bin/bash

while :; do
  echo "red" > /sys/class/leds/a3g_led/color

  curl -s -XGET -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36" http://vigilance.meteofrance.com/data/NXFR33_LFPW_.xml -o /tmp/NXFR33_LFPW_.xml

  sleep 600
  
done
