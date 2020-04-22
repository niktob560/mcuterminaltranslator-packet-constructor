#!/bin/bash

dir=$(echo "`dirname "$0"`")

INVERSE='\033[7m'
NORMAL='\033[0m'

LGREEN='\033[1;32m'
LMAGENTA='\033[1;35m'
LCYAN='\033[1;36m'

dec2hex() {
    a=$1
    a=$(printf "%x" $a)
    (( $1 < 16 )) && echo "0"$a || echo $a
}

if [ ! -z $1 ]; then #do input
    mode=$1
else
    #get type of packet
    interactive=1
    echo "Type of pachet [cmd/var/arr]"
    read line
    mode=$line
fi

case $mode in
    "cmd")
        head=64
        ;;
    "var")
        head=128
        ;;
    "arr")
        head=192
        ;;
    *)
        echo -e $LRED"Packet type invalid"$NORMAL; exit 1
        ;;
esac

#get payload
if [ ! -z "$2" ]; then
    line=$2
else
    echo "Print payload byte-by-byte"
    read line
fi

if [ ! -z "$3" ]; then
    dev_id=$3
elif [ ! -z $interactive ]; then
    echo "Print device id"
    read dev_id
fi


if [ ! -z $dev_id ]; then
    dev_id=$(echo $dev_id | tr -d ' ')
fi

# payload=$(echo $line | tr -s ' ')
payload=$line

len=$(echo " "$payload | sed 's/\w//g' | wc -c)

#construct header byte
head=$(( $head + $len ))

#construct raw packet
if [ -z $dev_id ]; then
    packet=$head" 0 0 "$payload
else
    packet=$head" 0 0 "$dev_id" "$payload
fi

#construct checksum
index=0
ch1=1
for i in $packet; do
    if (( $(( $index % 2 )) != 0 )); then
        ch0=$(( $ch0 + $i ))
    else
        ch1=$(( $ch1 + $i ))
    fi
    index=$(($index+1))
done
ch0=$(( $ch0 % 255 ))
ch1=$(( $ch1 % 255 ))

head=$(dec2hex $head)
ch0=$(dec2hex $ch0)
ch1=$(dec2hex $ch1)

for i in $payload; do
    _payload=$_payload"$(dec2hex $i) "
done

if [ -z $dev_id ]; then
    packet=$INVERSE''$LMAGENTA''$head" "$LCYAN" "$ch0"  "$ch1" "$NORMAL" "$_payload
else
    dev_id=$(dec2hex $dev_id)
    packet=$INVERSE''$LMAGENTA''$head" "$LCYAN" "$ch0"  "$ch1" "$LGREEN" "$dev_id" "$NORMAL" "$_payload
fi

if [ -z $interactive ]; then
    echo -e "$packet"
else
    echo "Final packet: $(echo -e $packet)"
fi
