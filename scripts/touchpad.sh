#!/usr/bin/env bash
## Detect and configure touchpad. See 'man synclient' for more info.
if egrep -iq 'touchpad' /proc/bus/input/devices; then
	synclient VertEdgeScroll=0
	synclient HorizTwoFingerScroll=1
	synclient PalmDetect=1
fi
