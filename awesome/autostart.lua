local r = require("runonce")

r.run("nm-applet")
r.run("dropbox start")
r.run("xscreensaver -no-splash")
r.run("pnmixer")
r.run("xfce4-volumed")
r.run("xfce4-power-manager")
r.run("xset b off")
--r.run("conky")
-- make java work
r.run(" wmname LG3D")
