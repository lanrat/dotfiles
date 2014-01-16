--------------------------------------
----            Includes          ----
--------------------------------------
-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")

-- Theme handling library
require("beautiful")

-- Notification library
require("naughty")

--Expose like plugin
require("modules/revelation")

--calendaar popup
require('calendar2')

--freedesktop menus
require('modules/awesome-freedesktop/freedesktop.utils')
require('modules/awesome-freedesktop/freedesktop.menu')

--for widgets
require("vicious")

require("xrandr")


require("layouts/browse")
require("layouts/termfair")
require("layouts/uselessfair")
require("layouts/uselesstile")

--local keydoc = require("keydoc")

--------------------------------------
----           Variables          ----
--------------------------------------

-- {{{ Variable definitions
-- This is used later as the default terminal and editor to run.
terminal = "terminator"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor
web_browser = "google-chrome"
file_manager = "thunar"
lock_command = "xscreensaver-command -lock"
exit_command = "cb-exit"
prtsc_command = "xfce4-screenshooter"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"


--------------------------------------
----        Layout Settings       ----
--------------------------------------

-- number of columns
vain.layout.termfair.nmaster   = 3
-- min number of rows (yes the var-name is backwards)
vain.layout.termfair.ncol      = 1

-- percent of space for main window
vain.layout.browse.mwfact_global = 0.6
-- 0 for non-overlapping, 1 for ovelapping
vain.layout.browse.ncol = 1
-- reduces the size of the main window if "overlapping slave column" is activated.
-- This allows you to see if there are any windows in your slave column.
vain.layout.browse.extra_padding = 5

--------------------------------------
----        Plugin Settings       ----
--------------------------------------

--set default naughty timeout
naughty.config.default_preset.timeout = 2


-- Themes define colours, icons, and wallpapers
beautiful.init( awful.util.getdir("config") .. "/darkburn/theme.lua")


--------------------------------------
----        Error Handleing       ----
--------------------------------------

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}


--------------------------------------
----       Tags and Layout        ----
--------------------------------------

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.max,
    awful.layout.suit.floating,
    vain.layout.browse,
    vain.layout.termfair,
    --vain.layout.uselesstile,
    vain.layout.uselessfair,
    --awful.layout.suit.magnifier,
    --awful.layout.suit.tile.left,
    --awful.layout.suit.tile.top,
    --awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    --awful.layout.suit.max.fullscreen,
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {
    names = { '⠒', '⠓', '⠣', '⠧', '⠗', '⠝', '⠵', '⠹', '⠳' },
    layout = { layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1],},
}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag(tags.names, s, tags.layout)
end
-- }}}
--
--awful.layout.set(vain.layout.termfair, tags[1][2])
--awful.tag.setnmaster(3, tags[1][2])
--awful.tag.setncol(1, tags[1][2])

--------------------------------------
----             Menu             ----
--------------------------------------

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

menu_items = freedesktop.menu.new()
table.insert(menu_items, { "awesome", myawesomemenu, beautiful.awesome_icon })
table.insert(menu_items, { "Exit", exit_command })

mymainmenu = awful.menu.new({ items = menu_items, width = beautiful.menu_width })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}


--------------------------------------
----             WiBox            ----
--------------------------------------

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

--calendar plugin
calendar2.addCalendarToWidget(mytextclock)

--separator widget
separator = widget({ type = "textbox" })
separator.text = "|"

--space widget
space = widget({ type = "textbox" })
space.text = " "


-- RAM usage widget
memwidget = awful.widget.progressbar()
memwidget:set_width(8)
memwidget:set_height(beautiful.menu_height)
memwidget:set_vertical(true)
memwidget:set_background_color(beautiful.bg_widget)
memwidget:set_color(beautiful.fg_widget)
memwidget:set_gradient_colors({ beautiful.fg_widget, beautiful.fg_center_widget, beautiful.fg_end_widget })
-- RAM usage tooltip
memwidget_t = awful.tooltip({ objects = { memwidget.widget },})
vicious.cache(vicious.widgets.mem)
vicious.register(memwidget, vicious.widgets.mem,
                function (widget, args)
                    memwidget_t:set_text(" RAM: " .. args[1] .. "% "  .. args[2] .. "MB / " .. args[3] .. "MB ")
                    return args[1]
                 end, 5)
                 --update every 5 seconds

-- CPU usage widget
cpuwidget = awful.widget.graph()
cpuwidget:set_width(30)
cpuwidget:set_height(beautiful.menu_height)
cpuwidget:set_background_color(beautiful.bg_widget)
cpuwidget:set_color(beautiful.fg_widget)
cpuwidget:set_gradient_angle(180)
cpuwidget:set_gradient_colors({ beautiful.fg_widget, fg_center_widget, beautiful.fg_end_widget })
cpuwidget_t = awful.tooltip({ objects = { cpuwidget.widget },})
-- Register CPU widget
vicious.register(cpuwidget, vicious.widgets.cpu, 
                    function (widget, args)
                        cpuwidget_t:set_text("CPU Usage: " .. args[1] .. "%")
                        return args[1]
                    end, 2)

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = beautiful.menu_height })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        separator,
        space,
        memwidget.widget,
        space,
        separator,
        space,
        cpuwidget.widget,
        space,
        separator,
        s == 1 and mysystray or nil,  --only place the systray on the primary screen
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}


--------------------------------------
----         Key bindings         ----
--------------------------------------

-- {{{ Change workspace on scroll
root.buttons(awful.util.table.join(
    --awful.button({ }, 3, function () mymainmenu:toggle() end), --I dont want a menu when I click on the desktop
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}


-- {{{ Key bindings
globalkeys = awful.util.table.join(

    --keydoc.group("Layout manipulation"),


    --plugins
    awful.key({ modkey, }, "e", revelation),
    --awful.key({ modkey, }, "F1", keydoc.display), --TODO finish this, needs arg string as last param

    --TODO make work
    awful.key({}, "XF86Display", xrandr),
    
    --Conky toggle
    awful.key({ }, "Pause", raise_conky, lower_conky),
    --awful.key({}, "Pause", toggle_conky)

    --Move Client to Workspace Left/Right
    --only works with 3.5, For 3.4 visit link
    --http://awesome.naquadah.org/wiki/Move_Window_to_Workspace_Left/Right
    awful.key({ modkey, "Shift"   }, "Left",
        function (c)
            local curidx = awful.tag.getidx()
            if curidx == 1 then
                awful.client.movetotag(tags[client.focus.screen][9])
            else
                awful.client.movetotag(tags[client.focus.screen][curidx - 1])
            end
            --awful.tag.viewprev
        end),
    awful.key({ modkey, "Shift"   }, "Right",
        function (c)
            local curidx = awful.tag.getidx()
            if curidx == 9 then
                awful.client.movetotag(tags[client.focus.screen][1])
            else
                awful.client.movetotag(tags[client.focus.screen][curidx + 1])
            end
            --awful.tag.viewnext
        end), 
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev      ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    --awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end), --we dont like the menu

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey,           }, "w", function () awful.util.spawn(web_browser) end), --hotkey to start web-browser
    awful.key({ modkey,           }, "f", function () awful.util.spawn(file_manager) end), --hotkey to start my file manager
    awful.key({ modkey, "Control" }, "l", function () awful.util.spawn(lock_command) end), --lock screen
    awful.key( { }                 , "Print" , function () awful.util.spawn(prtsc_command) end), --screenshot
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    -- Standard program
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)


-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}


--------------------------------------
---              Rules            ----
--------------------------------------

clientkeys = awful.util.table.join(
    awful.key({ modkey, }, "F11",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    --awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    --Move Client to Monitor Left/Right
    awful.key({ modkey,           }, "o",      function(c) awful.client.movetoscreen(c,c.screen-1) end ),
    awful.key({ modkey,           }, "p",      function(c) awful.client.movetoscreen(c,c.screen+1) end ),
    
    --awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "Conky" },
        properties = {
            floating = true,
            sticky = true,
            ontop = false,
            focusable = false,
            size_hints = {"program_position", "program_size"}
        }
    }
}
-- }}}


--------------------------------------
---         Misc Functions        ----
--------------------------------------

function get_conky()
    local clients = client.get()
    local conky = nil
    local i = 1
    while clients[i]
    do
        if clients[i].class == "Conky"
        then
            conky = clients[i]
        end
        i = i + 1
    end
    return conky
end
function raise_conky()
    local conky = get_conky()
    if conky
    then
        conky.ontop = true
    end
end
function lower_conky()
    local conky = get_conky()
    if conky
    then
        conky.ontop = false
    end
end
function toggle_conky()
    local conky = get_conky()
    if conky
    then
        if conky.ontop
        then
            conky.ontop = false
        else
            conky.ontop = true
        end
    end
end

--------------------------------------
---         Signal Function       ----
--------------------------------------

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    -- window focus followes the mouse
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}


--------------------------------------
----           Autostart          ----
--------------------------------------

require("autostart")

