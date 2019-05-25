#!/bin/bash
#
# (c) 2011 Western Digital Technologies, Inc. All rights reserved.
#
# monitorio - Monitor disk activity, and put system into standby.  Also, monitor to trigger file tally process
##
PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
. /lib/lsb/init-functions
source /etc/priority.conf
source /etc/system.conf
source /usr/local/sbin/drive_helper.sh
[ -f /usr/local/sbin/ledConfig.sh ] && . /usr/local/sbin/ledConfig.sh

MIN_SINCE_DISK_ACCESS=/tmp/minutes_since_disk_access
TALLY_PIDFILE=/var/run/tally.pid
TALLY_DAEMON=/usr/local/bin/tally
TALLY_DIR=/var/local/nas_file_tally
TALLY_PIPE=/var/local/nas_file_tally/tallyd.pipe
MEDIACRAWLER_REWALK=/tmp/mediacrawler_rewalk
total_df_file=$TALLY_DIR/total_df

# trigger tally when df result changes by TALLY_TRIGGER_THRESH_KB
TALLY_TRIGGER_THRESH_KB=3000000

file_tally() {
        if [ ! -p $TALLY_PIPE ]; then
                mkfifo $TALLY_PIPE
        fi
        start-stop-daemon --start --quiet --oknodo --nicelevel $monitorio_nice --pidfile $TALLY_PIDFILE --make-pidfile --background --exec $TALLY_DAEMON --
        ls -s1NRA --block-size=1 /shares | awk '
        {
                if ($1 ~ /^[0-9]+$/) {
#                       printf("#4:%s:%s/%s\0\0\0\0",$1,current_dir,substr($0,index($0,$2)));
                        printf("#4:%s:%s/%s~~~~",$1,current_dir,substr($0,index($0,$2)));
                }
                else {
                        if ($1 != "total") {
                                current_dir = (substr($0,1,length($0)-1));
                        }
                }
        }
        END {
                printf("#0:0:/tmp/TALLYEND.DONE~~~~");
        }
        ' > $TALLY_PIPE
#       ' > /var/local/nas_file_tally/tallyd.txt
#       cat /var/local/nas_file_tally/tallyd.txt > $TALLY_PIPE
}

wait_system_ready() {
    while [ ! -f "/tmp/ready" ]; do
        logger -s "$0: waiting for system to become ready.."
        sleep 5
    done
}

declare -i sleepcount
declare -i rootdisk_thresh
declare -i enterStandbyTime=0
rm -f /tmp/standby
rm -f ${MEDIACRAWLER_REWALK}
source /etc/standby.conf

resetSleepCount() {
	sleepcount=0

	# if in emergency run level, set standby threshold to 1 minute, since drive should go into standby as early as possible, otherwise, read config file
	if [ "`getRunLevel.pl`" == "emergency" ]; then
		standby_time=1
		rootdisk_thresh=1
		standby_enable="enabled"
	else
		source /etc/standby.conf	
		rootdisk_thresh=`expr $standby_time - 1`
	fi
}

checkTallyTrigger() {
	result="trigger"
	if [ -f ${total_df_file} ]; then
		total_df=`cat ${total_df_file}`
		result=`df | grep /DataVolume | awk -v total_df=${total_df} -v thresh=${TALLY_TRIGGER_THRESH_KB} '{x=$3 - total_df; abs_x=(x >= 0) ? x : -x; if(abs_x >= thresh) printf("trigger")}'`
	fi
	if [ "$result" == "trigger" ]; then
		df | grep /DataVolume | awk '{print $3}' > ${total_df_file}
	fi
	echo $result
}

currentRootDevice=`cat /proc/cmdline | awk '/root/ { print $1 }' | cut -d= -f2`
rootDisk=`basename ${currentRootDevice}`
dataVolumeDisk=`basename ${dataVolumeDevice}`
drivelist=(`internalDrives`)

echo "0" > ${MIN_SINCE_DISK_ACCESS}

# wait for system to become ready
wait_system_ready

# run file tally at startup (in the background)
if [ ! -f $TALLY_DAEMON ]; then
	logger "Tally daemon not installed, exiting tally function"
else
	file_tally &
	df | grep /DataVolume | awk '{print $3}' > ${total_df_file}
fi

if [ "$1" == "debug" ]; then
        echo "1" > /proc/sys/vm/block_dump
        dmesg -c > /dev/null
fi

while :; do

    for i in ${drivelist[@]}; do
            hdparm -C $i | grep -q "standby"
            standby_test=$?
            [ "$standby_test" -eq "1" ] && break
    done

    if [ "$standby_test" -eq "0" ]; then
        sleep 5
        continue
    else
        if [ -f /tmp/standby ]; then
	    standby_since=`stat --format %z /tmp/standby`
            rm -f /tmp/standby
            # Cancel blue color and turn on green if applicable
            ledCtrl.sh LED_EV_DISK_STBY LED_STAT_OK
            ### This will allow individual components to register for wakupevents
            run-parts /etc/nas/wakeup.d
            ###
            touch ${MEDIACRAWLER_REWALK}
            currentTime=`date +%s`
            timeInStandby=`expr $currentTime - $enterStandbyTime`
            echo "exit standby after $timeInStandby (since $standby_since)"
            logger "exit standby after $timeInStandby (since $standby_since)"
            if [ "$1" == "debug" ]; then
                    dmesg -c
            fi
        fi

		resetSleepCount

        echo $sleepcount > ${MIN_SINCE_DISK_ACCESS}
        trigger_tally=0
        iow_root=`awk -v disk="${rootDisk}" '{if ($3==disk) print $10}' /proc/diskstats`
        ior_datavol=`awk -v disk="${dataVolumeDisk}" '{if ($3==disk) print $6}' /proc/diskstats`
        iow_datavol=`awk -v disk="${dataVolumeDisk}" '{if ($3==disk) print $10}' /proc/diskstats`
        if [ "$1" == "debug" ]; then
                echo "Init          ior_datavol=$ior_datavol ior_datavol2=$ior_datavol2"
                echo "              iow_datavol=$iow_datavol iow_datavol2=$iow_datavol2"
                echo "              iow_root=$iow_root       iow_root2=$iow_root2"
                dmesg -c
        fi

        while :; do
            # Wait for 60 seconds
            sleep 60
            iow_root2=`awk -v disk="${rootDisk}" '{if ($3==disk) print $10}' /proc/diskstats`
            ior_datavol2=`awk -v disk="${dataVolumeDisk}" '{if ($3==disk) print $6}' /proc/diskstats`
            iow_datavol2=`awk -v disk="${dataVolumeDisk}" '{if ($3==disk) print $10}' /proc/diskstats`

            # check for file tally sync
            if [ "$iow_datavol" -ne "$iow_datavol2" ] && [ "`checkTallyTrigger`" == "trigger" ]; then
                    incUpdateCount.pm data_volume_write &
                    # trigger mediacralwer rewalk if datavolume write and triggered from wakeup
                    if [ -f ${MEDIACRAWLER_REWALK} ]; then
                            mediacrawler_pid=`pidof mediacrawler`
                            if [ $? == 0 ]; then
                                    logger "send mediacrawler ${mediacrawler_pid} wakeup signal"
                                    kill -s 10 ${mediacrawler_pid}
                            fi
                            rm -f ${MEDIACRAWLER_REWALK}
                    fi
					
					
					if [ -f $TALLY_DAEMON ]; then
						# also run tally if installed
						pidofproc -p $TALLY_PIDFILE $TALLY_DAEMON >/dev/null

						if [ $? -ne 0 ]; then
								file_tally
						fi
						createBackupTally.sh
					fi
            fi

            # use data volume writes until near sleep threshold, then check all disk writes
            old_sleepcount=sleepcount
            if [ $((sleepcount)) -eq $((rootdisk_thresh)) ] && [ "$iow_root" -eq "$iow_root2" ]; then
                sleepcount=$((sleepcount+1))
            elif  [ $((sleepcount)) -lt $((rootdisk_thresh)) ] && [ "$ior_datavol" -eq "$ior_datavol2" ] && [ "$iow_datavol" -eq "$iow_datavol2" ]; then
                sleepcount=$((sleepcount+1))
            else
                resetSleepCount
            fi
            echo $sleepcount > ${MIN_SINCE_DISK_ACCESS}
            if [ "$1" == "debug" ]; then

                [ "$sleepcount" != "0" ] &&  echo "sleepcount: $sleepcount"
                [ "$sleepcount" == "0" ] && echo "Disk activity:"
                echo "... ior_datavol=$ior_datavol      ior_datavol2=$ior_datavol2"
                echo "... iow_datavol=$iow_datavol      iow_datavol2=$iow_datavol2"
                echo "... iow_root=$iow_root    iow_root2=$iow_root2"
                # dmesg -c
            fi
            ior_datavol=$ior_datavol2
            iow_datavol=$iow_datavol2
            iow_root=$iow_root2
            
            smartTestStatus=`getSmartTestStatus.sh | awk '{print $1}'`
            if [ "$standby_enable" == "enabled" ] && [ "$sleepcount" -eq "$standby_time" ] && [ "$smartTestStatus" != "inprogress" ]; then
                touch /tmp/standby
                enterStandbyTime=`date +%s`
                echo "Enter standby"
                if [ "$1" == "debug" ]; then
                        echo "`date`: Enter standby "
                        dmesg -c > /dev/null
                fi
                for i in ${drivelist[@]}; do
                        hdparm -y $i >/dev/null
                done

                # turn on solid blue if applicable
                ledCtrl.sh LED_EV_DISK_STBY LED_STAT_IN_PROG
                sleep 5
                break
            fi
        done
    fi
done
