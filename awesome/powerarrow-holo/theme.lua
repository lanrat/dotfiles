--[[
     Holo Awesome WM config 2.0
     github.com/copycat-killer 
--]]
local awful = require("awful")
local xresources = require("beautiful").xresources
local dpi = xresources.apply_dpi

-- inherit default theme
local theme = dofile(awful.util.get_themes_dir() .. "default/theme.lua")  

theme.icon_dir                      = awful.util.get_configuration_dir() .. "powerarrow-holo/icons/"

theme.font                          = "Tamsyn 10"
theme.taglist_font                  = "Tamsyn 12"
theme.fg_normal                     = "#FFFFFF"
theme.fg_focus                      = "#0099CC"
theme.bg_normal                     = "#242424"
theme.bg_focus                      = "#313131"
theme.fg_urgent                     = "#CC9393"
theme.bg_urgent                     = "#2A1F1E"
theme.border_width                  = "1"
theme.border_normal                 = "#252525"
theme.border_focus                  = "#0099CC"
theme.taglist_fg_focus              = "#4CB7DB"
theme.tasklist_bg_normal            = "#222222"
theme.tasklist_fg_focus             = "#4CB7DB"
--theme.textbox_widget_margin_top     = 1
--theme.awful_widget_height           = 14
--theme.awful_widget_margin_top       = 2 -- these are unused?
theme.menu_height                   = dpi(15)
theme.menu_width                    = dpi(150)
theme.bg_systray                    = theme.bg_normal

theme.awesome_icon                  = theme.icon_dir .. "awesome_icon.png"
theme.submenu_icon                  = theme.icon_dir .. "submenu.png"
theme.taglist_squares_sel           = theme.icon_dir .. "square_sel.png"
theme.taglist_squares_unsel         = theme.icon_dir .. "square_unsel.png"

-- example to generate icons automatically:
-- https://awesomewm.org/apidoc/sample%20files/theme.lua.html
-- need newer version 4.1?
-- missing core files in: /usr/share/awesome/

theme.tasklist_disable_icon         = true
theme.tasklist_floating_icon        = ""
theme.tasklist_maximized_horizontal = ""
theme.tasklist_maximized_vertical   = ""

theme.useless_gap                   = dpi(3)
theme.border_width                  = dpi(1)

-- can et more when upgrade to 4.1
-- https://awesomewm.org/doc/api/documentation/89-NEWS.md.html
--
return theme
