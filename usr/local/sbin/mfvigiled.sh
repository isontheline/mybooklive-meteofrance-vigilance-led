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
  COUL="1"
  COULEUR_OK=0
  
  if [ $COUL -eq "1" ]; then
    echo "green" > /sys/class/leds/a3g_led/color
    echo "no" > /sys/class/leds/a3g_led/blink
    COULEUR_OK=1
  fi
  
  if [ $COUL -eq "2" ]; then
    echo "yellow" > /sys/class/leds/a3g_led/color
    echo "no" > /sys/class/leds/a3g_led/blink
    COULEUR_OK=1
  fi
  
  if [ $COUL -eq "3" ]; then
    echo "yellow" > /sys/class/leds/a3g_led/color
    echo "yes" > /sys/class/leds/a3g_led/blink
    COULEUR_OK=1
  fi
  
  if [ $COUL -eq "4" ]; then
    echo "red" > /sys/class/leds/a3g_led/color
    echo "yes" > /sys/class/leds/a3g_led/blink
    COULEUR_OK=1
  fi
  
  if [ $COULEUR_OK -eq 0 ]; then
    echo "blue" > /sys/class/leds/a3g_led/color
    echo "yes" > /sys/class/leds/a3g_led/blink
  fi

  # Attente de 10 minutes avant la prochaine actualisation
  sleep 600
done
