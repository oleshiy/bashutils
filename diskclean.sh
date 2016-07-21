#!/bin/bash
# Mounted volume to be monitored.
MOUNT="$1"

# Folder to clean
HOME_FOLDER="$2"

# Maximum threshold of volume used as an integer that represents a percentage:
# 95 = 95%.
MAX_USAGE="$3"

# Failsafe mechansim. Delete a maxium of MAX_CYCLES files, raise an error after
# that. Prevents possible runaway script. Disable by choosing a high value.
MAX_CYCLES=100
CYCLES=0

# Capacity OK
CC=1

if [ -z "$MOUNT" ] || [ ! -e "$MOUNT" ] || [ ! -d "$MOUNT" ] || [ -z "$MAX_USAGE" ] || [ -z "$HOME_FOLDER" ] || [ ! -e "$HOME_FOLDER" ] || [ ! -d "$HOME_FOLDER" ]
then
    echo "Usage: $0 <mountpoint> <homefolder> <threshold>"
    echo "Where threshold is a percentage."
    echo
    echo "Example: $0 /home /home/data 90"
    echo "If disk usage of /storage exceeds 90% the oldest"
    echo "file(s) will be deleted until usage is below 90%."
    echo
    exit 1
fi

check_capacity () {

    USAGE=`df -hP | grep "$MOUNT" | awk '{ print $5 }' | sed s/%//g`
    if [ ! "$?" == "0" ]
    then
        echo "Error: mountpoint $MOUNT not found in df output."
        exit 1
    fi

    if [ -z "$USAGE" ]
    then
        echo "Didn't get usage information of $MOUNT"
        echo "Mountpoint does not exist or please remove trailing slash."
        exit 1
    fi

    if [ "$USAGE" -gt "$MAX_USAGE" ]
    then
        echo "Usage of $USAGE% exceeded limit of $MAX_USAGE percent."
        #return 0
        CC=0
    else
        echo "Usage of $USAGE% is within limit of $MAX_USAGE percent."
        #return 1
		CC=1
    fi
}

process_file () {

    FILE="$1"

    #
    # Replace the following commands with wathever you want to do with
    # this file. You can delete files but also move files or do something else.
    #
    echo "Deleting file $FILE"
    rm -f "$FILE"
}


FILES=`find "$HOME_FOLDER" -type f -print0 | xargs -r0 stat -c %y\ %n | sort | awk {'print $4'}`

check_capacity
if [ "$CC" -eq 0  ] 
then
	for x in $FILES
	do
		echo "---------------------"
		echo $x
		check_capacity	
		# Failsafe 
		echo "$CYCLES  / $MAX_CYCLES"
		if [ "$CYCLES" -gt "$MAX_CYCLES" ]
		then
			echo "After $MAX_CYCLES exit."
			exit 1
		fi
		if [ "$CC" -eq 0  ] 
		then
			process_file "$x"
		else
	        exit 1
		fi
		((CYCLES++))
	done
fi

echo
