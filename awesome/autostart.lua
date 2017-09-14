local awful = require("awful")

function run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
    findme = cmd:sub(0, firstspace-1)
  end
  awful.spawn.with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

run_once("mate-settings-daemon")
run_once("compton")
-- run_once("wmname LG3D") -- fixes some java apps

-- applets
run_once("nm-applet")
run_once("mate-power-manager")
run_once("mate-volume-control-applet")
run_once("mate-screensaver")
run_once("blueman-applet")
run_once("nitrogen --restore")
