#!/usr/bin/env bash
# pactl is required
# passing arg

#check=$(pactl list short | grep -E "RUNNING.*alsa_output|alsa_output.*RUNNING")
check=$(pactl -f json list sink-inputs | jq -r '.[].properties | select(."application.name")["application.name"]')
#check_mic=$(pactl list short | grep -E "RUNNING.*alsa_input|alsa_input.*RUNNING")
check_mic=$(pactl -f json list source-outputs | jq -r '.[].properties | select(."application.name")["application.name"]')
check_webcam=$(lsof /dev/video* | grep mem | awk '{print $1}')

speaker_check() {

    if [ -z "$check" ]; then
        echo ""
    else
        echo "󰓃 $check"
    fi

}

mic_check() {

    if [ -z "$check_mic" ]; then
        echo ""
    else
        echo " $check_mic"
    fi
}

cam_check() {

    if [ -z "$check_webcam" ]; then
        echo ""
    else
        echo "󰖠 $check_webcam"
    fi

}

all_check() {
    res=""
    if [ ! -z "$check" ]; then
        res+="󰓃 $check "
    fi

    if [ ! -z "$check_mic" ]; then
        res+=" $check_mic "
    fi

    if [ ! -z "$check_webcam" ]; then
        res+="󰖠 $check_webcam"
    fi

    echo $res
}

left() {
    if [ -n "$check" ] || [ -n "$check_webcam" ] || [ -n "$check_mic" ]; then
        echo " "
    else
        echo ""
    fi
}

right() {
    if [ -n "$check" ] || [ -n "$check_webcam" ] || [ -n "$check_mic" ]; then
        echo " "
    else
        echo ""
    fi
}

if [ "$1" == "S" ]; then
    speaker_check
elif [ "$1" == "M" ]; then
    mic_check
elif [ "$1" == "C" ]; then
    cam_check
elif [ "$1" == "A" ]; then
    all_check
elif [ "$1" == "l" ]; then
    left
elif [ "$1" == "r" ]; then
    right
else
    exit
fi
