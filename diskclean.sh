#!/bin/bash
#
#
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

reset () {
    CYCLES=0
    OLDEST_FILE=""
    OLDEST_DATE=0
}

reset

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
        return 0
    else
        echo "Usage of $USAGE% is within limit of $MAX_USAGE percent."
        return 1
    fi
}

check_age () {

    FILE="$1"
    FILE_DATE=`stat -c %Z "$FILE"`

    NOW=`date +%s`
    AGE=$((NOW-FILE_DATE))
    if [ "$AGE" -gt "$OLDEST_DATE" ]
    then
        export OLDEST_DATE="$AGE"
        export OLDEST_FILE="$FILE"
    fi
}

process_file () {

    FILE="$1"

    #
    # Replace the following commands with wathever you want to do with
    # this file. You can delete files but also move files or do something else.
    #
    echo "Deleting oldest file $FILE"
    rm -f "$FILE"
}

while check_capacity
do
	echo "$CYCLES  / $MAX_CYCLES"
    if [ "$CYCLES" -gt "$MAX_CYCLES" ]
    then
        echo "Error: after $MAX_CYCLES deleted files still not enough free space."
        exit 1
    fi

    #reset

    FILES=`find "$HOME_FOLDER" -type f`

    IFS=$'\n'
    for x in $FILES
    do
        check_age "$x"
    done

    if [ -e "$OLDEST_FILE" ]
    then
        #
        # Do something with file.
        #
        process_file "$OLDEST_FILE"
    else
        echo "Error: somehow, item $OLDEST_FILE disappeared."
    fi
    ((CYCLES++))
done
echo
