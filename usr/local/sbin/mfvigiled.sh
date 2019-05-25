#!/bin/bash

# Changer ici le département :
DEPARTEMENT_A_VERIFIER="87"

# Mode debug :
DEBUG=0

while :; do
  if [ $DEBUG -eq 1 ]; then
    echo "Downloading vigilance..."
  fi;

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
  COUL="0"
  COULEUR_OK=0
  
  # Pas propre :(
  COUL1=$(cat /tmp/NXFR33_LFPW_.xml | grep "dep=\"$DEPARTEMENT_A_VERIFIER\" coul=\"1\"" | wc -l)
  COUL2=$(cat /tmp/NXFR33_LFPW_.xml | grep "dep=\"$DEPARTEMENT_A_VERIFIER\" coul=\"1\"" | wc -l)
  COUL3=$(cat /tmp/NXFR33_LFPW_.xml | grep "dep=\"$DEPARTEMENT_A_VERIFIER\" coul=\"1\"" | wc -l)
  COUL4=$(cat /tmp/NXFR33_LFPW_.xml | grep "dep=\"$DEPARTEMENT_A_VERIFIER\" coul=\"1\"" | wc -l)
  
  if [ $COUL1 -eq 1 ]; then
    COUL="1"
  fi
  
  if [ $COUL2 -eq 1 ]; then
    COUL="2"
  fi
  
  if [ $COUL3 -eq 1 ]; then
    COUL="3"
  fi
  
  if [ $COUL4 -eq 1 ]; then
    COUL="4"
  fi
  
  # Boucle de 5 minute :
  for j in {1..5}; do
    for j in {1..60}; do
      if [ $COUL -eq "1" ]; then
        echo "green" > /sys/class/leds/a3g_led/color
        echo "no" > /sys/class/leds/a3g_led/blink
        COULEUR_OK=1
        
        if [ $DEBUG -eq 1 ]; then
          echo "Setting led color to green"
        fi;
      fi

      if [ $COUL -eq "2" ]; then
        echo "yellow" > /sys/class/leds/a3g_led/color
        echo "no" > /sys/class/leds/a3g_led/blink
        COULEUR_OK=1
        
        if [ $DEBUG -eq 1 ]; then
          echo "Setting led color to yellow"
        fi;
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
        
        if [ $DEBUG -eq 1 ]; then
          echo "Setting led color to red"
        fi;
      fi

      if [ $COULEUR_OK -eq 0 ]; then
        echo "blue" > /sys/class/leds/a3g_led/color
        echo "yes" > /sys/class/leds/a3g_led/blink
        
        if [ $DEBUG -eq 1 ]; then
          echo "Setting led color to blue"
        fi;
      fi

      # Attente d'une seconde avant actualisation de la led à nouveau
      sleep 1
    done
  done
done
