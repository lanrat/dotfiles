#! /usr/bin/env bash
# info: https://wiki.archlinux.org/index.php/Bluetooth_headset#Troubleshooting
set -eu

#DEVICE_NAME="QC35"
DEVICE_NAME="Moon"
#DEVICE_NAME="PLT_BBTPRO"


list_devices()
{
    echo -e 'paired-devices\nquit' | bluetoothctl | grep "^Device"
}

reset_bt()
{
    # other options
    # rmmod btusb
    # modprobe btusb
    # rfkill block bluetooth
    # rfkill unblock bluetooth
    # /var/log# tail -F syslog
    # sudo hciconfig hci0 down
    # sudo hciconfig hci0 up 

    # turn card off
    CARD=$(pactl list cards short | cut -f2 | grep blue | head -1)
    if [ ! -z "${CARD}" ]; then
        echo "Setting audio card off: $CARD"
        pacmd set-card-profile "$CARD" off
        sleep 2
    fi

    # BT off
    echo -e 'power off\nquit' | bluetoothctl
    sleep 3

    # bt on
    echo -e 'power on\nquit' | bluetoothctl
    sleep 3
}

connect_bt()
{
    # find device MAC
    MAC=$(echo -e 'paired-devices\nquit' | bluetoothctl | grep "^Device" | grep -i "$DEVICE_NAME" | cut -d ' ' -f2)
    # bt connect
    echo -e "connect $MAC\nquit" | bluetoothctl
    echo "Waiting for Connection to settle"
    sleep 5
}

unset_audio()
{
    # find card
    CARD=$(pactl list cards short | cut -f2 | grep blue | head -1)
    if [ -z "$CARD" ]; then
        echo "No bluetooth card found"
        return $(false)
    fi

    echo "Turning profile off"
    pacmd set-card-profile "$CARD" off
    sleep 1
}

set_audio()
{
    # find card
    CARD=$(pactl list cards short | cut -f2 | grep blue | head -1)
    if [ -z "$CARD" ]; then
        echo "No bluetooth card found"
        return $(false)
    fi

    HSP_PROFILE="headset_head_unit"
    A2DP_PROFILE="a2dp_sink"
    # TODO allow HSP/A2DP toggle

    echo "Setting audio profile for card: $CARD"
    pacmd set-card-profile "$CARD" "$A2DP_PROFILE"
    sleep 1

    # set sink
    SINK=$(pactl list sinks short | cut -f2 | grep blue | head -1)
    if [ -z "${SINK}" ]; then
        echo "No bluetooth sink found"
        return $(false)
    fi
    echo "Sink: $SINK"
    pacmd set-default-sink "$SINK"
    sleep 1

    # set source
    SOURCE=$(pactl list sources short | cut -f2 | grep blue | head -1)
    if [ -z "$SOURCE" ]; then
        echo "No bluetooth source found"
        return $(false)
    fi
    echo "Source: $SOURCE"
    pacmd set-default-source $SOURCE
    sleep 1
    
    return $(true)
}

test_bt_audio()
{
    # TODO test for audio errors
    #Audio device got stuck!
    #A:   0.1 (00.0) of 237.0 (03:57.0) ??,?% 
    mplayer -endpos 00:00:05 test.mp3
}

#reset_bt
connect_bt
exit

# do other things
if set_audio;
then
    echo "Set Audio on first try!"
else
    unset_audio
    if set_audio;
    then
        echo "Set Audio on after unset!"
    else
        echo "Audio Sink failed, resetting BT"
        reset_bt
        unset_audio
        if ! set_audio;
        then
            echo "Fatal audio error, try running again?"
            exit
        fi
    fi
fi
#test_bt_audio
