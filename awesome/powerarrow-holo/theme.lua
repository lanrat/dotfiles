--[[
                                
     Holo Awesome WM config 2.0 
     github.com/copycat-killer  
                                
--]]

theme                               = {}

theme.icon_dir                      = os.getenv("HOME") .. "/.config/awesome/powerarrow-holo/icons"

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
theme.textbox_widget_margin_top     = 1
theme.awful_widget_height           = 14
theme.awful_widget_margin_top       = 2 -- these are unused?
theme.menu_height                   = "20"
theme.menu_width                    = "400"
theme.bg_systray                    = theme.bg_normal 

theme.awesome_icon                  = theme.icon_dir .. "/awesome_icon.png"
theme.submenu_icon                  = theme.icon_dir .. "/submenu.png"
theme.taglist_squares_sel           = theme.icon_dir .. "/square_sel.png"
theme.taglist_squares_unsel         = theme.icon_dir .. "/square_unsel.png"

theme.clock                         = theme.icon_dir .. "/widgets/clock.png"
theme.calendar                      = theme.icon_dir .. "/widgets/cal.png"
theme.cpu                           = theme.icon_dir .. "/widgets/cpu.png"
theme.mem                           = theme.icon_dir .. "/widgets/mem.png"
--theme.net_up                        = theme.icon_dir .. "/net_up.png"
--theme.net_down                      = theme.icon_dir .. "/net_down.png"

theme.layout_tile                   = theme.icon_dir .. "/layouts/tile.png"
theme.layout_tilegaps               = theme.icon_dir .. "/layouts/tilegaps.png"
theme.layout_tileleft               = theme.icon_dir .. "/layouts/tileleft.png"
theme.layout_tilebottom             = theme.icon_dir .. "/layouts/tilebottom.png"
theme.layout_tiletop                = theme.icon_dir .. "/layouts/tiletop.png"
theme.layout_fairv                  = theme.icon_dir .. "/layouts/fairv.png"
theme.layout_fairh                  = theme.icon_dir .. "/layouts/fairh.png"
theme.layout_spiral                 = theme.icon_dir .. "/layouts/spiral.png"
theme.layout_dwindle                = theme.icon_dir .. "/layouts/dwindle.png"
theme.layout_max                    = theme.icon_dir .. "/layouts/max.png"
theme.layout_fullscreen             = theme.icon_dir .. "/layouts/fullscreen.png"
theme.layout_magnifier              = theme.icon_dir .. "/layouts/magnifier.png"
theme.layout_floating               = theme.icon_dir .. "/layouts/floating.png"

-- hide icons in client list
theme.tasklist_disable_icon         = true
theme.tasklist_floating_icon        = ""
theme.tasklist_maximized_horizontal = ""
theme.tasklist_maximized_vertical   = ""

-- lain related
theme.useless_gap_width             = 10
theme.layout_uselesstileleft        = theme.icon_dir .. "/layouts/uselesstileleft.png"
theme.layout_uselesstiletop         = theme.icon_dir .. "/layouts/uselesstiletop.png"

-- lain
theme.layout_cascade               = theme.icon_dir .. "/layouts/cascadew.png"
theme.layout_cascadetile               = theme.icon_dir .. "/layouts/cascadetilew.png"
theme.layout_centerfair  = theme.icon_dir .. "/layouts/centerfairw.png"
theme.layout_centerwork               = theme.icon_dir .. "/layouts/centerworkw.png"
theme.layout_termfair               = theme.icon_dir .. "/layouts/termfairw.png"
theme.layout_uselessfair            = theme.icon_dir .. "/layouts/uselessfair.png"
theme.layout_uselesspiral            = theme.icon_dir .. "/layouts/uselesspiral.png"
theme.layout_uselesstile            = theme.icon_dir .. "/layouts/uselesstile.png"

return theme
