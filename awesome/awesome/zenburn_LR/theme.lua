-------------------------------
--  "Zenburn" awesome theme  --
--    By Adrian C. (anrxc)   --
-------------------------------

-- Alternative icon sets and widget icons:
--  * http://awesome.naquadah.org/wiki/Nice_Icons

-- {{{ Main
theme = {}
--TODO better wallpaper handling
theme.wallpaper_cmd = { "awsetbg -a .wallpaper.jpg" }
-- }}}

-- {{{ Styles
theme.font      = "sans 8"

-- {{{ Colors
theme.fg_normal = "#DCDCCC"
theme.fg_focus  = "#F0DFAF"
theme.fg_urgent = "#CC9393"
theme.bg_normal = "#000000"
theme.bg_focus  = "#111111"
theme.bg_urgent = "#3F3F3F"
-- }}}

-- {{{ Borders
--theme.border_width  = "1"
theme.border_width  = "0"
theme.border_normal = "#3F3F3F"
theme.border_focus  = "#6F6F6F"
theme.border_marked = "#CC9393"
-- }}}

-- {{{ Titlebars
theme.titlebar_bg_focus  = "#3F3F3F"
theme.titlebar_bg_normal = "#3F3F3F"
-- }}}

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- Example:
--theme.taglist_bg_focus = "#CC9393"
-- }}}


--TODO use these variables
-- {{{ Widgets
-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.fg_widget        = "#AECF96"
--theme.fg_center_widget = "#88A175"
--theme.fg_end_widget    = "#FF5656"
--theme.bg_widget        = "#494B4F"
--theme.border_widget    = "#3F3F3F"
-- }}}

-- {{{ Mouse finder
theme.mouse_finder_color = "#CC9393"
-- mouse_finder_[timeout|animate_timeout|radius|factor]
-- }}}

-- {{{ Menu
-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = "15"
theme.menu_width  = "100"
-- }}}

-- {{{ Icons
-- {{{ Taglist
theme.taglist_squares_sel   = ".config/awesome/zenburn_LR/taglist/squarefz.png"
theme.taglist_squares_unsel = ".config/awesome/zenburn_LR/taglist/squarez.png"
--theme.taglist_squares_resize = "false"
-- }}}

-- {{{ Misc
theme.awesome_icon           = ".config/awesome/zenburn_LR/awesome-icon.png"
theme.menu_submenu_icon      = "/usr/share/awesome/themes/default/submenu.png"
theme.tasklist_floating_icon = "/usr/share/awesome/themes/default/tasklist/floatingw.png"
-- }}}

-- {{{ Layout
theme.layout_tile       = ".config/awesome/zenburn_LR/layouts/tile.png"
theme.layout_tileleft   = ".config/awesome/zenburn_LR/layouts/tileleft.png"
theme.layout_tilebottom = ".config/awesome/zenburn_LR/layouts/tilebottom.png"
theme.layout_tiletop    = ".config/awesome/zenburn_LR/layouts/tiletop.png"
theme.layout_fairv      = ".config/awesome/zenburn_LR/layouts/fairv.png"
theme.layout_fairh      = ".config/awesome/zenburn_LR/layouts/fairh.png"
theme.layout_spiral     = ".config/awesome/zenburn_LR/layouts/spiral.png"
theme.layout_dwindle    = ".config/awesome/zenburn_LR/layouts/dwindle.png"
theme.layout_max        = ".config/awesome/zenburn_LR/layouts/max.png"
theme.layout_fullscreen = ".config/awesome/zenburn_LR/layouts/fullscreen.png"
theme.layout_magnifier  = ".config/awesome/zenburn_LR/layouts/magnifier.png"
theme.layout_floating   = ".config/awesome/zenburn_LR/layouts/floating.png"
-- }}}

-- {{{ Titlebar
theme.titlebar_close_button_focus  = ".config/awesome/zenburn_LR/titlebar/close_focus.png"
theme.titlebar_close_button_normal = ".config/awesome/zenburn_LR/titlebar/close_normal.png"

theme.titlebar_ontop_button_focus_active  = ".config/awesome/zenburn_LR/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = ".config/awesome/zenburn_LR/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive  = ".config/awesome/zenburn_LR/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = ".config/awesome/zenburn_LR/titlebar/ontop_normal_inactive.png"

theme.titlebar_sticky_button_focus_active  = ".config/awesome/zenburn_LR/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = ".config/awesome/zenburn_LR/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive  = ".config/awesome/zenburn_LR/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = ".config/awesome/zenburn_LR/titlebar/sticky_normal_inactive.png"

theme.titlebar_floating_button_focus_active  = ".config/awesome/zenburn_LR/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = ".config/awesome/zenburn_LR/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive  = ".config/awesome/zenburn_LR/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = ".config/awesome/zenburn_LR/titlebar/floating_normal_inactive.png"

theme.titlebar_maximized_button_focus_active  = ".config/awesome/zenburn_LR/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = ".config/awesome/zenburn_LR/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = ".config/awesome/zenburn_LR/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = ".config/awesome/zenburn_LR/titlebar/maximized_normal_inactive.png"
-- }}}
-- }}}

return theme
