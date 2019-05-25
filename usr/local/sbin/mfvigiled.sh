#!/bin/bash

# Changer ici le département :
DEPARTEMENT_A_VERIFIER="87"

while :; do
  echo "red" > /sys/class/leds/a3g_led/color

  curl \
  -s \
  -XGET \
  -o /tmp/NXFR33_LFPW_.xml \
  --connect-timeout 15 \
  --max-time 10 \
  --retry 5 \
  --retry-delay 5 \
  --retry-max-time 60 \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36" \
  http://vigilance.meteofrance.com/data/NXFR33_LFPW_.xml
  

  # Pas de vigilance : coul="1"
  # Vigilance jaune : coul="2"
  # Vigilance orange : coul="3"
  # Vigilance rouge : coul="4"
  

  # Attente de 10 minutes avant la prochaine actualisation
  sleep 600
done
