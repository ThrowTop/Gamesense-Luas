-- local variables for API functions. any changes to the line below will be lost on re-generation
local client_delay_call, client_set_event_callback, globals_frametime, globals_realtime, math_floor, renderer_gradient, require, ui_get, ui_is_menu_open, ui_menu_position, ui_menu_size, ui_new_color_picker, ui_new_combobox, ui_new_slider, ui_reference, ui_set_callback, ui_set_visible = client.delay_call, client.set_event_callback, globals.frametime, globals.realtime, math.floor, renderer.gradient, require, ui.get, ui.is_menu_open, ui.menu_position, ui.menu_size, ui.new_color_picker, ui.new_combobox, ui.new_slider, ui.reference, ui.set_callback, ui.set_visible

local function lerp_color(c1, c2, t)
    local r = math_floor(c1[1] * (1 - t) + c2[1] * t + 0.5)
    local g = math_floor(c1[2] * (1 - t) + c2[2] * t + 0.5)
    local b = math_floor(c1[3] * (1 - t) + c2[3] * t + 0.5)
    local a = math_floor(c1[4] * (1 - t) + c2[4] * t + 0.5)

    return { r, g, b, a }
end

local function lerp(start, vend, time)
    return start + (vend - start) * time
end

local function rectangle_gradient(x, y, w, h, precision, t_left, t_right, b_left, b_right)
    if w < h then
        for i = 0, w - 1, precision do
            local t = i / w
            local clr = lerp_color(t_left, t_right, t)
            local clr2 = lerp_color(b_left, b_right, t)
            renderer_gradient(x + i, y, precision, h, clr[1], clr[2], clr[3], clr[4], clr2[1], clr2[2], clr2[3], clr2[4], false)
        end
    else
        for i = 0, h - 1, precision do
            local t = i / h
            local clr = lerp_color(t_left, b_left, t)
            local clr2 = lerp_color(t_right, b_right, t)
            renderer_gradient(x, y + i, w, precision, clr[1], clr[2], clr[3], clr[4], clr2[1], clr2[2], clr2[3], clr2[4], true)
        end
    end
end

local function hsv_to_rgb(h, s, v, a)
    local r, g, b

    local i = math_floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return r * 255, g * 255, b * 255, a * 255
end

local function rgb_func(angle, rgb_split_ratio)
    local r, g, b, a = hsv_to_rgb(angle, 1, 1, 1)

    r = r * rgb_split_ratio
    g = g * rgb_split_ratio
    b = b * rgb_split_ratio

    return r, g, b, a
end


---UI ELEMENTS
local vector = require("vector")
local tab, cont = "Misc", "Settings"
local menu = {
    style = ui_new_combobox(tab, cont, "[ \aAAFF00FFBorder Glow Style\aFFFFFFFF ]", { "-", "gamesense", "Manual" }),
    [1] = ui_new_color_picker(tab, cont, "\n", 255, 255, 255, 255),
    [2] = ui_new_color_picker(tab, cont, "\n", 255, 255, 255, 255),
    [3] = ui_new_color_picker(tab, cont, "\n", 255, 255, 255, 255),
    [4] = ui_new_color_picker(tab, cont, "\n", 255, 255, 255, 255),
    thickness = ui_new_slider(tab, cont, "Thickness", 1, 500, 5, true, "px"),
    speed = ui_new_slider(tab, cont, "Speed", 1, 10, 5, true, "f"),
}

local menu_key = ui_reference("Misc", "Settings", "Menu key")
local menu_open = ui_is_menu_open()

local style
local function vis_fix(element)
    style = ui_get(element)
    for i = 1, 4 do
        ui_set_visible(menu[i], style == "Manual")
    end
    ui_set_visible(menu.thickness, style ~= "-")
    ui_set_visible(menu.speed, style == "gamesense")
end
ui_set_callback(menu.style, vis_fix)
vis_fix(menu.style)

local t = { 0, 0, 0, 0 } -- transparent color
local rgb_offset = { 0, 0.25, 0.5, 0.75 }
local fade_alpha = 1
local key_down = false

client_set_event_callback("paint_ui", function()
    if style == "-" then return end
    local p = vector(ui_menu_position())
    local s = vector(ui_menu_size())

    local m_key = ui_get(menu_key)
    if not key_down and m_key then
        key_down = true
        menu_open = not menu_open
        client_delay_call(0.3, function() menu_open = ui_is_menu_open() end)
    end

    if not m_key then
        key_down = false
    end

    fade_alpha = lerp(fade_alpha, (menu_open and 1 or 0), globals_frametime() * 1 / 0.05)
    if fade_alpha < 0.05 then return end

    local rgb_split_ratio = 1
    local time = globals_realtime() * (ui_get(menu.speed) / 10) % 1
    local thickness = ui_get(menu.thickness) + 1

    local c = {}
    if style == "Manual" then
        for i = 1, 4 do
            c[i] = { ui_get(menu[i]) }
        end
    else
        for i = 1, 4 do
            c[i] = { rgb_func((time - rgb_offset[i]) % 1, rgb_split_ratio) }
        end
    end

    c[1][4] = c[1][4] * fade_alpha
    c[2][4] = c[2][4] * fade_alpha
    c[3][4] = c[3][4] * fade_alpha
    c[4][4] = c[4][4] * fade_alpha

    local precs = 1                                                                                  --precision precs cus funny
    rectangle_gradient(p.x, p.y - thickness, s.x, thickness, precs, t, t, c[1], c[2])                --Top
    rectangle_gradient(p.x, p.y + s.y, s.x, thickness - precs, precs, c[4], c[3], t, t)              -- Bottom
    rectangle_gradient(p.x - thickness, p.y, thickness, s.y, precs, t, c[1], t, c[4])                -- Left
    rectangle_gradient(p.x + s.x, p.y, thickness - precs, s.y, precs, c[2], t, c[3], t)              -- Right

    rectangle_gradient(p.x - thickness, p.y - thickness, thickness, thickness, precs, t, t, t, c[1]) --Top left
    rectangle_gradient(p.x - thickness, p.y + s.y, thickness, thickness, precs, t, c[4], t, t)       -- Bottom Left
    rectangle_gradient(p.x + s.x, p.y - thickness, thickness, thickness, precs, t, t, c[2], t)       -- Top Right
    rectangle_gradient(p.x + s.x, p.y + s.y, thickness, thickness, precs, c[3], t, t, t)             -- Bottom Right
end)