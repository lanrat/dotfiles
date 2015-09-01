#!/usr/bin/env bash
# wmtt: wm testing tool
# built from the awmtt script

#Default Variables
#TODO make this arg passable
#WM="openbox-session"
WM="awesome"
ME=$(basename ${0})
# Display and window size
D=1
SIZE="1024x640"

#Usage
usage() {
  cat <<EOF
${ME} [ start | stop | restart | -h | ] [ -D display ] [ -S windowsize ]

  start         Spawn nested ${WM} via Xephyr
  stop          Stops Xephyr
    all     Stop all instances of Xephyr 
  restart       Restart nested ${WM}
  -D|--display      Specify the display to use (e.g. 1)
  -S|--size     Specify the window size
  -h|--help     Show this help text
  
examples:
${ME} start -D 3 -S 1280x800
${ME} start (uses defaults)
${ME} stop

The defaults are -D ${D} -S ${SIZE}.

EOF
    exit 0
}
[ "$#" -lt 1 ] && usage

#Utilities
wm_pid() { pgrep -fn "$WMCOMMAND"; }
xephyr_pid() { pgrep -f xephyr_$D; }
errorout() { echo "error: $*" >&2; exit 1; }

#Executable check
WMCOMMAND=$(which $WM)
XEPHYR=$(which Xephyr)
[[ -x "$WMCOMMAND" ]] || errorout "Please install ${WM} first"
[[ -x "$XEPHYR" ]] || errorout 'Please install Xephyr first'


#Start function
start() {
    "$XEPHYR" -name xephyr_$D -ac -br -noreset -screen "$SIZE" :$D >/dev/null 2>&1 &
    sleep 1
    DISPLAY=:$D.0 "$WMCOMMAND"  &
    sleep 1
    echo "Using display $D"
    echo "$D: ${WM} PID is $(wm_pid)"
    echo "$D: Xephyr PID is $(xephyr_pid)"
}

#Stop function
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

#Restart function
restart() {
    echo -n "Restarting... "
    #TODO may need to call start, sleep, start
    for i in $(pgrep -f "${WMCOMMAND}"); do kill -s SIGHUP $i; done
}

#Parse options
parse_options() {
    while [[ -n "$1" ]];do
    case "$1" in
        -D|--display)   shift; D="$1"
                [[ ! "$D" =~ ^[0-9] ]] && errorout "$D is not a valid display number" ;;
        -S|--size)      shift; SIZE="$1" ;;
        -h|--help)      usage       ;;
        start)      input=start ;;
        stop)       input=stop  ;;
        restart|reload) input=restart   ;;
        *)          args+=( "$1" )  ;;
    esac
    shift
    done
}

#Main
main() {

  case "$input" in
    start)  start "${args[@]}"    ;;
    stop)   stop "${args[@]}"     ;;
    restart)    restart "${args[@]}"      ;;
    *)      echo "Option not recognized" ;;
  esac
}

parse_options "$@"
main
