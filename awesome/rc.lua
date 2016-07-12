--[[
                                
     Holo-XPS Awesome WM config 2.0 
     github.com/lanrat/dotfiles
                                
--]]

-- {{{ Required libraries
local awful     = require("awful")
awful.rules     = require("awful.rules")
                  require("awful.autofocus")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local naughty   = require("naughty")
local drop      = require("scratchdrop")
lain      = require("lain")
local separators = require("separators")
local blingbling = require("blingbling")
local revelation = require("revelation")
vicious = require("vicious")
-- }}}

-- for testing
-- naughty.notify({ preset = naughty.config.presets.critical,
--                  title = "testing",
--                  text = serializeTable(data) })
function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0
    local tmp = string.rep(" ", depth)
    if name then tmp = tmp .. name .. " = " end
    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
    return tmp
end


-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Autostart applications
function run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
     findme = cmd:sub(0, firstspace-1)
  end
  awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

-- returns first active network interface found
function active_net()
  for line in io.lines("/proc/net/dev") do
    local device = string.match(line, "^[%s]?[%s]?[%s]?[%s]?([%w]+):")
      if device ~= nil then
        if device ~= "lo" then
          return device
      end
    end
  end
end


-- settings
run_once("nitrogen --restore")
run_once("xset b off")
run_once("mate-settings-daemon") -- GTK theme
run_once("wmname LG3D")  -- fixes some java apps
run_once("compton -b")
-- applets
run_once("nm-applet")
run_once("mate-power-manager")
run_once("mate-volume-control-applet")
run_once("mate-screensaver")
run_once("dropbox start")
run_once("blueman-applet") -- may not work on 1st boot (need to start service first)
-- }}}

-- {{{ Variable definitions
-- beautiful init
beautiful.init(os.getenv("HOME") .. "/.config/awesome/powerarrow-holo/theme.lua")

-- revelation init
revelation.init()

-- common
modkey     = "Mod4"
altkey     = "Mod1"

-- user defined
terminal   = "mate-terminal" or "urxvt" or "xterm"
--editor     = os.getenv("EDITOR") or "vim"
--editor_cmd = terminal .. " -e " .. editor
screenshot = "xfce4-screenshooter"
browser    = "google-chrome"
browser2   = "chromium"
file_browser = "caja"
gui_editor = "subl"
lock_command = "mate-screensaver-command -l"
sleep_command = "systemctl hybrid-sleep"
shutdown_command = "systemctl poweroff"

local layouts = {
    --awful.layout.suit.magnifier,
    --awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.tile,
    --awful.layout.suit.tile.left,
    --awful.layout.suit.tile.bottom,
    --awful.layout.suit.tile.top,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    --awful.layout.suit.max,

    lain.layout.uselesstile,
    lain.layout.uselessfair,
    --lain.layout.uselesspiral,
    --lain.layout.uselessfair.horizontal,
    --lain.layout.cascade,
    --lain.layout.cascadebrowse,
    --lain.layout.cascadetile,
    --lain.layout.centerfair,
    lain.layout.centerwork,
    lain.layout.termfair, --good for portraite mode
    
    --lain.layout.uselesspiral,
    --lain.layout.uselesstile.left,
    lain.layout.uselesstile.bottom, -- good for portraite mode
    --lain.layout.uselesstile.top,
    --lain.layout.uselesspiral.dwindle,
    awful.layout.suit.floating,
}
-- }}}
 
-- default layouts
-- starts at 1 (not 0)
local default_layout_landscape = 1
local default_layout_portrait = 5

-- {{{ Tags
tags = {
   names = { "❶", "❷", "❸", "❹", "❺", "❻", "❼", "❽", "❾" },
   --layout = { layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1], layouts[1]},
   layout_landscape = { layouts[default_layout_landscape], layouts[default_layout_landscape], layouts[default_layout_landscape], layouts[default_layout_landscape], layouts[default_layout_landscape], layouts[default_layout_landscape], layouts[default_layout_landscape], layouts[default_layout_landscape], layouts[default_layout_landscape]},
   layout_portrait = { layouts[default_layout_portrait], layouts[default_layout_portrait], layouts[default_layout_portrait], layouts[default_layout_portrait], layouts[default_layout_portrait], layouts[default_layout_portrait], layouts[default_layout_portrait], layouts[default_layout_portrait], layouts[default_layout_portrait]},
}

for s = 1, screen.count() do
  if screen[s].geometry.height > screen[s].geometry.width then
    -- portrait
    tags[s] = awful.tag(tags.names, s, tags.layout_portrait)
  else
    -- landscape 
    tags[s] = awful.tag(tags.names, s, tags.layout_landscape)
  end
end
-- }}}


-- {{{ Menu
myawesomemenu = {
--  TODO add shutdown/sleep
   --{ "manual", terminal .. " -e man awesome" },
  -- { "edit config", editor_cmd .. " " .. awesome.conffile },
   --{ "restart", awesome.restart },
   { "sleep", sleep_command },
   { "shutdown", shutdown_command },
   { "quit", awesome.quit }
}
app_menu = require("menugen").build_menu()
table.insert(app_menu, 1, { "System", myawesomemenu })
mymainmenu = awful.menu.new({ items = app_menu,
                              theme = { height = 24, width = 130 }})
mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
markup = lain.util.markup
space3 = markup.font("Tamsyn 3", " ")
space2 = markup.font("Tamsyn 2", " ")

calendarwidget = blingbling.calendar()
calendarwidget:set_prev_next_widget_style({ h_margin = 0,
                                    rounded_size = {0.5,0.5,0,0},
                                    background_color = beautiful.bg_focus,
                                    text_color = "#999999",
                                  })
calendarwidget:set_current_date_widget_style({ h_margin = 0,
                                    rounded_size = {0.5,0.5,0,0},
                                    background_color = beautiful.bg_focus,
                                    text_color = beautiful.fg_normal,
                                  })
calendarwidget:set_days_of_week_widget_style({ h_margin = 0,
                                    rounded_size = {0.5,0.5,0,0},
                                    background_color = beautiful.bg_focus,
                                    text_color = beautiful.fg_focus,
                                  })
calendarwidget:set_days_of_month_widget_style({ h_margin = 0,
                                    rounded_size = {0.5,0.5,0.5,0.5},
                                    background_color = beautiful.bg_focus,
                                    text_color = "#999999",
                                  })
calendarwidget:set_weeks_number_widget_style({ h_margin = 0,
                                    rounded_size = {0.5,0,0,0.5},
                                    background_color = beautiful.border_normal,
                                    text_color = "#999999",
                                  })
calendarwidget:set_corner_widget_style({ h_margin = 0,
                                    rounded_size = {0.5,0.5,0,0.5},
                                    background_color = "#00000000",
                                    text_color = "#00000000",
                                  })
calendarwidget:set_current_day_widget_style({ h_margin = 0,
                                    rounded_size = {0.5,0.5,0.5,0.5},
                                    background_color = beautiful.fg_focus,
                                    text_color = beautiful.fg_normal,
                                  })

-- CPU
cpu_graph = blingbling.line_graph({ height = 18,
                                        width = 200,
                                        show_text = true,
                                        label = "Load: $percent %",
                                        rounded_size = 0.3,
                                        graph_background_color = "#00000033"
                                      })
cpu_graph:set_width(50)
cpu_graph:set_show_text(false)
cpu_graph:set_text_background_color("#00000000")
cpu_graph:set_graph_background_color("#00000040")
cpu_graph:set_graph_color("#4CB7DB50") -- TODO use theme (blingbling globals?)
cpu_graph:set_graph_line_color("#4CB7DB") -- TODO use theme (blingbling globals?)
vicious.register(cpu_graph, vicious.widgets.cpu,'$1',2)

-- MEM
mem_bar = blingbling.progress_graph()
mem_bar:set_graph_background_color("#7000040")
mem_bar:set_graph_color("#4CB7DB50") -- TODO use theme (blingbling globals?)
mem_bar:set_graph_line_color("#4CB7DB") -- TODO use theme (blingbling globals?)
mem_bar:set_width(15)
mem_bar:set_height(18)
vicious.register(mem_bar, vicious.widgets.mem,'$1',2)

-- NET
--netwidget = blingbling.net({interface = "wlan0", show_text = true})
--net_iface = active_net()
--if net_iface ~= nil then
--  netwidget = blingbling.net({interface = active_net(), show_text = true})
--  netwidget:set_graph_line_color("#4CB7DB") -- TODO use theme
--  netwidget:set_graph_color("#4CB7DB50") -- TODO use theme
--  netwidget:set_text_background_color("#00000000")
--  netwidget:set_ippopup()
--  netwidget:set_show_text(false)
--  netwidget:set_width(15)
--  netwidget:set_height(18)
--end

-- Arrow Separators
arrl = separators.chevron_left(beautiful.bg_focus)
arrl_dl = separators.arrow_left(beautiful.bg_focus, "alpha")
arrl_ld = separators.arrow_left("alpha", beautiful.bg_focus)
arrr = separators.chevron_right(beautiful.bg_focus)
arrr_dl = separators.arrow_right(beautiful.bg_focus, "alpha")
arrr_ld = separators.arrow_right("alpha", beautiful.bg_focus)
spr = wibox.widget.textbox(' ')

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
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
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
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
    --mytaglist[s] = blingbling.tagslist(s,  awful.widget.taglist.filter.all, mytaglist.buttons --[[, { normal = {}, focus ={}, urgent={}, occupied={} }--]])

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = 24 })

    -- Widgets that are aligned to the upper left
    local left_layout = wibox.layout.fixed.horizontal()

    -- left arrrow Widgets
    local left_layout_toggle = true
    local function left_layout_add (...)
        local arg = {...}
        if left_layout_toggle then
            left_layout:add(arrr_ld)
            for i, n in pairs(arg) do
                left_layout:add(wibox.widget.background(n ,beautiful.bg_focus))
            end
        else
            left_layout:add(arrr_dl)
            for i, n in pairs(arg) do
                left_layout:add(n)
            end
        end
        left_layout_toggle = not left_layout_toggle
    end

    left_layout:add(mylauncher)
    left_layout_add(mytaglist[s])
    left_layout_add(mypromptbox[s])
    left_layout:add(arrr)
    left_layout:add(spr)

    -- Widgets that are aligned to the upper right
    local right_layout = wibox.layout.fixed.horizontal()

    -- right arrrow Widgets
    local right_layout_toggle = true
    local function right_layout_add (...)
        local arg = {...}
        if right_layout_toggle then
            right_layout:add(arrl_ld)
            for i, n in pairs(arg) do
                right_layout:add(wibox.widget.background(n ,beautiful.bg_focus))
            end
        else
            right_layout:add(arrl_dl)
            for i, n in pairs(arg) do
                right_layout:add(n)
            end
        end
        right_layout_toggle = not right_layout_toggle
    end

    right_layout:add(spr)
    right_layout:add(arrl)

    right_layout_add(cpu_graph)

    right_layout_add(mem_bar)

    if netwidget ~= nil then
      right_layout_add(netwidget)
    end

    if s == 1 then
      local systray = wibox.widget.systray()
      right_layout_add(systray)
    end

    right_layout_add(calendarwidget)

    right_layout_add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)

    mywibox[s]:set_bg(beautiful.bg_normal) -- TOOD set color instead os using an image
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    --awful.button({ }, 3, function () mymainmenu:toggle() end), -- click on background for menu
    --awful.button({ }, 4, awful.tag.viewnext), --scroll for next workspace
    --awful.button({ }, 5, awful.tag.viewprev) --scroll for previous workspace
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    -- Take a screenshot
    awful.key( { }       , "Print" , function () awful.util.spawn(screenshot) end),

    -- Tag browsing
    awful.key({ modkey }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey }, "Escape", awful.tag.history.restore),

    -- Revelation
    awful.key({ modkey, }, "e", revelation),

    -- Non-empty tag browsing
    awful.key({ altkey }, "Left", function () lain.util.tag_view_nonempty(-1) end),
    awful.key({ altkey }, "Right", function () lain.util.tag_view_nonempty(1) end),

    -- Default client focus
    awful.key({ altkey }, "k",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ altkey }, "j",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    -- By direction client focus
    awful.key({ modkey }, "j",
        function()
            awful.client.focus.bydirection("down")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "k",
        function()
            awful.client.focus.bydirection("up")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "h",
        function()
            awful.client.focus.bydirection("left")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "l",
        function()
            awful.client.focus.bydirection("right")
            if client.focus then client.focus:raise() end
        end),

    -- Show/Hide Wibox
    awful.key({ modkey }, "b", function ()
        mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible
    end),

    -- On the fly useless gaps change
    awful.key({ altkey, "Control" }, "=", function () lain.util.useless_gaps_resize(1) end),
    awful.key({ altkey, "Control" }, "-", function () lain.util.useless_gaps_resize(-1) end),

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
    awful.key({ altkey, "Shift"   }, "l",      function () awful.tag.incmwfact( 0.05)     end),
    awful.key({ altkey, "Shift"   }, "h",      function () awful.tag.incmwfact(-0.05)     end),
    awful.key({ modkey, "Shift"   }, "l",      function () awful.tag.incnmaster(-1)       end),
    awful.key({ modkey, "Shift"   }, "h",      function () awful.tag.incnmaster( 1)       end),
    awful.key({ modkey, "Control" }, "l",      function () awful.tag.incncol(-1)          end),
    awful.key({ modkey, "Control" }, "h",      function () awful.tag.incncol( 1)          end),
    awful.key({ modkey,           }, "space",  function () awful.layout.inc(layouts,  1)  end),
    awful.key({ modkey, "Shift"   }, "space",  function () awful.layout.inc(layouts, -1)  end),
    awful.key({ modkey, "Control" }, "n",      awful.client.restore),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r",      awesome.restart),
    awful.key({ modkey, "Shift"   }, "q",      awesome.quit),

    -- Dropdown terminal
    awful.key({ modkey,	          }, "z",      function () drop(terminal) end),

    -- User programs
    -- TODO update shortcuts
    awful.key({ modkey }, "q", function () awful.util.spawn(browser) end),
    awful.key({ modkey }, "w", function () awful.util.spawn(browser2) end),
    awful.key({ modkey }, "c", function () awful.util.spawn(file_browser) end),
    awful.key({ modkey }, "s", function () awful.util.spawn(gui_editor) end),
    awful.key({ modkey }, "v", function () awful.util.spawn(lock_command) end),

    -- Prompt
    awful.key({ modkey }, "r", function () mypromptbox[mouse.screen]:run() end),
    --awful.key({ modkey }, "x",
    --          function ()
    --              awful.prompt.run({ prompt = "Run Lua code: " },
    --              mypromptbox[mouse.screen].widget,
    --              awful.util.eval, nil,
    --              awful.util.getdir("cache") .. "/history_eval")
    --          end)

    -- move window and view to workspace left or right
    awful.key({ modkey, "Shift"   }, "Left",
       function (c)
          local curidx = awful.tag.getidx()
          if curidx == 1 then
              awful.client.movetotag(tags[client.focus.screen][#tags[client.focus.screen]])
          else
              awful.client.movetotag(tags[client.focus.screen][curidx - 1])
          end
          awful.tag.viewidx(-1)
      end),
    awful.key({ modkey, "Shift"   }, "Right",
      function (c)
          local curidx = awful.tag.getidx()
          if curidx == #tags[client.focus.screen] then
              awful.client.movetotag(tags[client.focus.screen][1])
          else
              awful.client.movetotag(tags[client.focus.screen][curidx + 1])
          end
          awful.tag.viewidx(1)
      end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    --awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
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
        end),
    -- move clients between monitors
    awful.key({ modkey,           }, "o",      function(c) awful.client.movetoscreen(c,c.screen-1) end ),
    awful.key({ modkey,           }, "p",      function(c) awful.client.movetoscreen(c,c.screen+1) end )
)

-- Bind all key numbers to tags.
-- be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
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

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons,
	                   size_hints_honor = false } },
    { rule = { class = "URxvt" },
          properties = { opacity = 0.99 } },

    { rule = { instance = "plugin-container" },
          properties = { tag = tags[1][1] } },

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
local sloppyfocus_last = {c=nil}
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    -- TOOD this can cause the non-active window to have the mouse over it
    client.connect_signal("mouse::enter", function(c)
         if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
             -- Skip focusing the client if the mouse wasn't moved.
             if c ~= sloppyfocus_last.c then
                 client.focus = c
                 sloppyfocus_last.c = c
             end
         end
     end)
end)

-- No border for maximized clients
client.connect_signal("focus",
    function(c)
        if c.maximized_horizontal == true and c.maximized_vertical == true then
            c.border_color = beautiful.border_normal
        else
            c.border_color = beautiful.border_focus
        end
    end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ Arrange signal handler
for s = 1, screen.count() do screen[s]:connect_signal("arrange", function ()
        local clients = awful.client.visible(s)
        local layout  = awful.layout.getname(awful.layout.get(s))

        if #clients > 0 then -- Fine grained borders and floaters control
            for _, c in pairs(clients) do -- Floaters always have borders
                if awful.client.floating.get(c) or layout == "floating" then
                    c.border_width = beautiful.border_width

                -- No borders with only one visible client
                elseif #clients == 1 or layout == "max" then
                    c.border_width = 0
                    -- if only 1 client remove useless gaps
                    -- TODO find the correct way to do this
                    --beautiful.useless_gap_width = 0
                else
                    c.border_width = beautiful.border_width
                end
            end
        end
      end)
end
-- }}}
