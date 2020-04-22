#!/bin/bash

#Additional params for text:
BOLD='\033[1m'          #  ${BOLD}          # bold font (intense color)
DBOLD='\033[2m'         #  ${DBOLD}         # half-brightness color (dark-gray, regardless of color)
NBOLD='\033[22m'        #  ${NBOLD}         # set normal intense
UNDERLINE='\033[4m'     #  ${UNDERLINE}     # underline
NUNDERLINE='\033[4m'    #  ${NUNDERLINE}    # disable underline
BLINK='\033[5m'         #  ${BLINK}         # blinking
NBLINK='\033[5m'        #  ${NBLINK}        # disable blinking
INVERSE='\033[7m'       #  ${INVERSE}       # reverced (chars got bgcolor, background -- char colors)
NINVERSE='\033[7m'      #  ${NINVERSE}      # disable reverced
BREAK='\033[m'          #  ${BREAK}         # all attrs disabled
NORMAL='\033[0m'        #  ${NORMAL}        # all attrs disabled

# Text color:
BLACK='\033[0;30m'      #  ${BLACK}    # black char color
RED='\033[0;31m'        #  ${RED}      # red char color
GREEN='\033[0;32m'      #  ${GREEN}    # green char color
YELLOW='\033[0;33m'     #  ${YELLOW}   # yellow char color
BLUE='\033[0;34m'       #  ${BLUE}     # blue char color
MAGENTA='\033[0;35m'    #  ${MAGENTA}  # magent char color
CYAN='\033[0;36m'       #  ${CYAN}     # cyan char color
GRAY='\033[0;37m'       #  ${GRAY}     # gray char color

# Bold text color :
DEF='\033[0;39m'        #  ${DEF}
DGRAY='\033[1;30m'      #  ${DGRAY}
LRED='\033[1;31m'       #  ${LRED}
LGREEN='\033[1;32m'     #  ${LGREEN}
LYELLOW='\033[1;33m'    #  ${LYELLOW}
LBLUE='\033[1;34m'      #  ${LBLUE}
LMAGENTA='\033[1;35m'   #  ${LMAGENTA}
LCYAN='\033[1;36m'      #  ${LCYAN}
WHITE='\033[1;37m'      #  ${WHITE}

# Background color
BGBLACK='\033[40m'      #  ${BGBLACK}
BGRED='\033[41m'        #  ${BGRED}
BGGREEN='\033[42m'      #  ${BGGREEN}
BGBROWN='\033[43m'      #  ${BGBROWN}
BGBLUE='\033[44m'       #  ${BGBLUE}
BGMAGENTA='\033[45m'    #  ${BGMAGENTA}
BGCYAN='\033[46m'       #  ${BGCYAN}
BGGRAY='\033[47m'       #  ${BGGRAY}
BGDEF='\033[49m'        #  ${BGDEF}

dec2hex() {
    a=$1
    a=$(printf "%x" $a | tr -d '\n' | tr "[:lower:]" "[:upper:]")
    # echo "Converting dec $i to hex; got $a" 1>&2
    if (( $(echo $a | tr -d '\n' | wc -c) == 1 )); then
        a="0"$a
    fi
    # echo "Final conversion: $a" 1>&2
    echo $a | tr -d '\n'
}

if [ -z $1 ]; then #do input
    #get type of packet
    interactive=1
    echo "Type of pachet [cmd/var/arr]"
    read line
    mode=$line
else
    mode=$1
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
if [ -z $2 ]; then
    echo "Print payload byte-by-byte"
    read line
else
    line=$2
fi


#encode payload to hex
for i in $line; do
    a=$(echo $i | tr -d '\n')
    a=$(dec2hex $a)
    payload=$payload"$a "
done

#get num of bytes
word_len=$(echo $payload | tr -d ' ' | wc -c)
len=$(($word_len/2))

#validate length
if [[ "$mode" == "cmd" ]]; then
    if (( $len != 1 )); then
        echo -e $LRED"Cmd can have only len=1"$NORMAL; exit 1
    fi
fi
if (( $len > 63 )); then
    echo -e $LRED"Payload max len is 63"$NORMAL; exit 1
fi

#construct header byte
head=$(( $head + $len ))
head=$(dec2hex $head)

#construct raw packet
packet=$head" 00 00 "$payload

#construct checksum
index=0
ch0=0
ch1=1
for i in $packet; do
    a=$(echo "ibase=16; $i" | bc)
    if (( $(($index%2)) != 0 )); then
        ch0=$(( $ch0 + $a ))
    else
        ch1=$(( $ch1 + $a ))
    fi
    index=$(($index+1))
done
ch0=$(( $ch0 % 255 ))
ch1=$(( $ch1 % 255 ))

ch0=$(dec2hex $ch0)
ch1=$(dec2hex $ch1)

packet=$head" "$ch0" "$ch1" "$payload
if [ -z $interactive ]; then
    echo $packet
else
    echo "Final packet: $packet"
fi
