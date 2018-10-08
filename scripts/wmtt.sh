#!/usr/bin/env bash
# wmtt: wm testing tool
# built from the awmtt script
# https://github.com/serialoverflow/awmtt

# Default Variables
#WM="openbox-session"
WM="awesome"
#WM=i3
ME=$(basename ${0})
# Display and window size
D=1
SIZE="1280x720"

# Usage
usage() {
  cat <<EOF
${ME} [ start | stop | restart | -h | ] [ -D display ] [ -S windowsize ] [ -W windowmanager ]

  start         Spawn nested WM via Xephyr
  stop          Stops Xephyr
    all     Stop all instances of Xephyr 
  restart       Restart nested WM
  -D|--display      Specify the display to use (e.g. 1)
  -S|--size     Specify the window size
  -W|--wm     Specify the window maanger to nest
  -h|--help     Show this help text
  
examples:
${ME} start -D 3 -S 1280x800
${ME} start (uses defaults)
${ME} stop

The defaults are -D ${D} -S ${SIZE} -W ${WM}.

EOF
    exit 0
}
[ "$#" -lt 1 ] && usage

# Utilities
wm_pid() { pgrep -fn "$WMCOMMAND"; }
xephyr_pid() { pgrep -f xephyr_$D; }
errorout() { echo "error: $*" >&2; exit 1; }

# multiple monitors
# http://movingparts.net/2008/09/25/a-poor-mans-multi-monitor-setup-on-a-single-physical-head/
# https://github.com/sulami/blog/blob/master/content/using-xephyr-to-simulate-multiple-monitors.md
# current bug: https://bugs.freedesktop.org/show_bug.cgi?id=106230
# CMD: "$XEPHYR" -name xephyr_$D -ac -br -noreset -screen "$SIZE" -screen "$SIZE"+1280+0 +extension RANDR +xinerama :$D  >/dev/null 2>&1 &

# Start function
start() {
    "$XEPHYR" -name xephyr_$D -ac -br -noreset +extension RANDR -screen "$SIZE" :$D >/dev/null 2>&1 &
    sleep 1
    DISPLAY=:$D "$WMCOMMAND" &
    sleep 1
    echo "Using $WMCOMMAND on display $D"
    echo "$D: ${WM} PID is $(wm_pid)"
    echo "$D: Xephyr PID is $(xephyr_pid)"
}

# Stop function
stop() {
    if [[ "$1" == all ]];then
        echo "Stopping all instances of Xephyr"
        kill $(pgrep Xephyr) >/dev/null 2>&1
    elif [[ $(xephyr_pid) ]];then
        echo "Stopping Xephyr for display $D"
        kill $(xephyr_pid)
    else
        echo "Xephyr is not running or you did not specify the correct display with -D"
        exit 0
    fi
}

# Restart function
restart() {
    echo -n "Restarting... "
    #TODO may need to call start, sleep, start
    for i in $(pgrep -f "${WMCOMMAND}"); do kill -s SIGHUP $i; done
}

# Show display info
info() {
    xdpyinfo -display ":$D"
}

# Parse options
parse_options() {
    while [[ -n "$1" ]];do
    case "$1" in
        -D|--display)   shift; D="$1"
                [[ ! "$D" =~ ^[0-9] ]] && errorout "$D is not a valid display number" ;;
        -S|--size)      shift; SIZE="$1" ;;
        -W|--wm)      shift; WM="$1" ;;
        -h|--help)      usage       ;;
        start)      input=start ;;
        stop)       input=stop  ;;
        info)       input=info  ;;
        restart|reload) input=restart   ;;
        *)          args+=( "$1" )  ;;
    esac
    shift
    done
}

# Main
main() {
  case "$input" in
    start)  start "${args[@]}"    ;;
    stop)   stop "${args[@]}"     ;;
    info)      info                   ;;
    restart)    restart "${args[@]}"      ;;
    *)      echo "Option not recognized" ;;
  esac
}

parse_options "$@"

# Executable check
WMCOMMAND=$(which $WM)
XEPHYR=$(which Xephyr)
[[ -x "$XEPHYR" ]] || errorout 'Please install Xephyr first'
[[ -x "$WMCOMMAND" ]] || errorout "Please install ${WM} first"

main
