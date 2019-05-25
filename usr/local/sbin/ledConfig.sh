#!/bin/bash
#
# (c) 2012 Western Digital Technologies, Inc. All rights reserved.
#
# ledConfigs.sh 
#   This file defines hw dependent APIs for LED control. 
#   It's more about LED access mechanism (led driver interface) 
#   and not LED policies.
#

#---------------------
# add stderr to stdout
exec 2>&1

PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /usr/local/sbin/share-param.sh


RET_OK=0
RET_ERR_PARAMS=1

LED_COLOR=/usr/local/nas/led_color
LED_BLINK=/sys/class/leds/a3g_led/blink

# Define LED modes
LED_STAT_OK=0
LED_STAT_WARN=1
LED_STAT_ERR=2
LED_STAT_IN_PROG=3

# Define LED state array
LED_STAT=( "LED_STAT_OK" \
           "LED_STAT_WARN" \
           "LED_STAT_ERR" \
           "LED_STAT_IN_PROG" \
         )
# Define error priorities. In case mutiple errors occur, 
# the lower index of the LED_EV_ERR_PRI array has higher priority.
# Currently, 'overtemp' is the top priority and others are FIFO.
LED_EV_ERR_PRI=( "LED_EV_THERMO" \
                 "LED_EV_FW_UPDATE"\
               )
# Normal color map  0 --------------------------------------5-------------------------------------10---------------12---------------------15
LED_NORMAL_MODE=(  "on"    "on"    "blink" "on"    "on"    "on"    "on"    "off" "on"    "on"    "on"    "on"    "on"    "on"    "on"    "on")
LED_NORMAL_COLOR=( "green" "green" "green" "green" "green" "green" "green" "off" "green" "green" "green" "green" "green" "green" "blue"  "white")
# Error color maps
#                0-----------------------------5--------------------------------10-----------12 -----------------15
LED_ERR_MODE=(  "on"  "on"  "on"  "on"  "on"  "blink"  "on"  "off" "on"  "on"  "on"  "on"  "blink"  "on"  "on"  "on")
LED_ERR_COLOR=( "red" "red" "red" "red" "red" "yellow" "red" "off" "red" "red" "red" "red" "yellow" "red" "red" "white")
# Warning color maps
#                 0--------------------------------5------------------------------------10-----------12 --------------------15
LED_WARN_MODE=(  "on"  "on"  "on"  "on"  "on"    "blink"  "on"   "off" "blink"  "on"  "on"  "on"  "blink"  "on"    "on"    "on")
LED_WARN_COLOR=( "red" "red" "red" "red" "white" "yellow" "blue" "off" "yellow" "red" "red" "red" "yellow" "white" "white" "white")
# Error color maps

# Define LED events
LED_EV_SYSTEM=0
LED_EV_DISK_SMART=1
LED_EV_DISK_IO=2
LED_EV_RAID_CFG=3
LED_EV_FW_UPDATE=4
LED_EV_NETWORK=5
LED_EV_DISK_STBY=6
LED_EV_HALT=7
LED_EV_THERMO=8
LED_EV_VOLUME=9
LED_EV_DISK_LOW_CAP=10
LED_EV_DISK_UNSUPPORTED=11
LED_EV_DEGRADED_MIR=12
LED_EV_MASTER_INST=13
LED_EV_FRESH_INST=14
LED_EV_VFT_HALT=15

# Define LED event array
LED_EV=( "LED_EV_SYSTEM" \
         "LED_EV_DISK_SMART" \
         "LED_EV_DISK_IO" \
         "LED_EV_RAID_CFG" \
         "LED_EV_FW_UPDATE" \
         "LED_EV_NETWORK" \
         "LED_EV_DISK_STBY" \
         "LED_EV_HALT" \
         "LED_EV_THERMO" \
         "LED_EV_VOLUME" \
         "LED_EV_DISK_LOW_CAP" \
         "LED_EV_DISK_UNSUPPORTED" \
         "LED_EV_DEGRADED_MIR"\
         "LED_EV_MASTER_INST"\
         "LED_EV_FRESH_INST"\
         "LED_EV_VFT_HALT"\
       )
   
LED_ERR_LOG_EV=( \
               )
LED_ERR_LOG_ST=( \
               )

TMP_ERR_LOG_EV=/tmp/led_err_ev
TMP_ERR_LOG_ST=/tmp/led_err_st
TMP_LED_CUR_EVENT=/tmp/led_cur_ev
TMP_LED_CUR_STATE=/tmp/led_cur_st
################################################################
#
# led_ctrl( status, color): 
#   status = on|off|yes|no (yes|no is to control blinking)
#   color = red|blue|green|yellow|white
#
################################################################
function led_ctrl () {
   if [ $# -lt 1 ]; then
      echo -n "color="
      cat $LED_COLOR
      echo -n "blink="
      cat $LED_BLINK
   fi
   local stat=$1
   local color=$2
   
   case "$stat" in
      "on")
          echo $color > $LED_COLOR
          ;; 
      "off")
          echo off > $LED_COLOR
          ;; 
      "blink")
          echo $color > $LED_COLOR
          echo yes > $LED_BLINK
          ;;
      "no_blink")
          echo no > $LED_BLINK 
          ;; 
       *)
   esac

   return $RET_OK
}
