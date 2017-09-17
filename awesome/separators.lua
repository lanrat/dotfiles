
--[[
                                                   
     Licensed under GNU General Public License v2  
      * (c) 2015, Luke Bonham                      
      * (c) 2015, plotnikovanton     
      * (c) 2017, lanrat     

--]]

local wibox     = require("wibox")
local beautiful = require("beautiful")
local gears     = require("gears")

-- Lain Cairo separators util submodule
-- lain.util.separators
local separators = {}

local height = beautiful.awful_widget_height or 0
local width  = beautiful.separators_width or 9
local chevron_thickness = beautiful.chevron_thickness or 4

-- [[ Arrow

-- Right
function separators.arrow_right(col1, col2)
    local widget = wibox.widget.base.make_widget()

    widget.fit = function(m, w, h) return width, height end

    widget.draw = function(mycross, wibox, cr, width, height)
        if col2 ~= "alpha" then
            cr:set_source_rgb(gears.color.parse_color(col2))
            cr:new_path()
            cr:move_to(0, 0)
            cr:line_to(width, height/2)
            cr:line_to(width, 0)
            cr:close_path()
            cr:fill()

            cr:new_path()
            cr:move_to(0, height)
            cr:line_to(width, height/2)
            cr:line_to(width, height)
            cr:close_path()
            cr:fill()
        end

        if col1 ~= "alpha" then
            cr:set_source_rgb(gears.color.parse_color(col1))
            cr:new_path()
            cr:move_to(0, 0)
            cr:line_to(width, height/2)
            cr:line_to(0, height)
            cr:close_path()
            cr:fill()
        end
   end

   return widget
end

-- Left
function separators.arrow_left(col1, col2)
    local widget = wibox.widget.base.make_widget()

    widget.fit = function(m, w, h) return width, height end

    widget.draw = function(mycross, wibox, cr, width, height)
        if col1 ~= "alpha" then
            cr:set_source_rgb(gears.color.parse_color(col1))
            cr:new_path()
            cr:move_to(width, 0)
            cr:line_to(0, height/2)
            cr:line_to(0, 0)
            cr:close_path()
            cr:fill()

            cr:new_path()
            cr:move_to(width, height)
            cr:line_to(0, height/2)
            cr:line_to(0, height)
            cr:close_path()
            cr:fill()
        end

        if col2 ~= "alpha" then
            cr:new_path()
            cr:move_to(width, 0)
            cr:line_to(0, height/2)
            cr:line_to(width, height)
            cr:close_path()

            cr:set_source_rgb(gears.color.parse_color(col2))
            cr:fill()
        end
   end

   return widget
end

function separators.chevron_left(col1)
    local widget = wibox.widget.base.make_widget()

    widget.fit = function(m, w, h) return width, height end

    widget.draw = function(mycross, wibox, cr, width, height)
        cr:new_path()
        cr:move_to(width, 0)
        cr:line_to(0, height/2)
        cr:line_to(width, height)
        cr:line_to(width, height-chevron_thickness)
        cr:line_to(chevron_thickness, height/2)
        cr:line_to(width, chevron_thickness)
        cr:close_path()

        cr:set_source_rgb(gears.color.parse_color(col1))
        cr:fill()
   end

   return widget
end

function separators.chevron_right(col1)
    local widget = wibox.widget.base.make_widget()

    widget.fit = function(m, w, h) return width, height end

    widget.draw = function(mycross, wibox, cr, width, height)
        cr:new_path()
        cr:move_to(0, 0)
        cr:line_to(width, height/2)
        cr:line_to(0, height)
        cr:line_to(0, height-chevron_thickness)
        cr:line_to(width-chevron_thickness, height/2)
        cr:line_to(0, chevron_thickness)
        cr:close_path()

        cr:set_source_rgb(gears.color.parse_color(col1))
        cr:fill()
   end

   return widget
end

-- ]]


-- [[ insert seperators into layouts

-- Arrow Separators
separators.left = separators.chevron_left(beautiful.bg_focus)
--local left_dl = separators.arrow_left(beautiful.bg_focus, "alpha")
--local left_ld = separators.arrow_left("alpha", beautiful.bg_focus)

separators.right = separators.chevron_right(beautiful.bg_focus)
--local right_dl = separators.arrow_right(beautiful.bg_focus, "alpha")
--local right_ld = separators.arrow_right("alpha", beautiful.bg_focus)
--local space = wibox.widget.textbox(' ')


-- left arrrow Widgets
local right_toggle = true
function separators.group_right (...)
    local args = {...}
    local layout = wibox.layout.fixed.horizontal()
    if right_toggle then
        layout:add(separators.arrow_right("alpha", beautiful.bg_focus))
        for i, n in pairs(args) do
            layout:add(wibox.container.background(n, beautiful.bg_focus))
        end
        layout:add(separators.arrow_right(beautiful.bg_focus, "alpha"))
    else
        layout:add(separators.arrow_right(beautiful.bg_focus, "alpha"))
        for i, n in pairs(args) do
            layout:add(n)
        end
        layout:add(separators.arrow_right("alpha", beautiful.bg_focus))
    end
    right_toggle = not right_toggle
    return layout
end

-- right arrrow Widgets
local left_toggle = true
function separators.group_left (...)
    local args = {...}
    local layout = wibox.layout.fixed.horizontal()
    if left_toggle then
        layout:add(separators.arrow_left("alpha", beautiful.bg_focus))
        for i, n in pairs(args) do
            layout:add(wibox.widget.background(n ,beautiful.bg_focus))
        end
        layout:add(separators.arrow_left(beautiful.bg_focus, "alpha"))
    else
        layout:add(separators.arrow_left(beautiful.bg_focus, "alpha"))
        for i, n in pairs(args) do
            layout:add(n)
        end
        layout:add(separators.arrow_left("alpha", beautiful.bg_focus))
    end
    left_toggle = not left_toggle
    return layout
end

-- ]]


return separators
