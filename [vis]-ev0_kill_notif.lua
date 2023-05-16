-- local variables for API functions. any changes to the line below will be lost on re-generation
local client_screen_size, client_userid_to_entindex, entity_get_local_player, entity_get_player_name, globals_curtime, globals_frametime, math_abs, require, ui_get, ui_new_checkbox, ui_new_color_picker, ui_set_callback = client.screen_size, client.userid_to_entindex, entity.get_local_player, entity.get_player_name, globals.curtime, globals.frametime, math.abs, require, ui.get, ui.new_checkbox, ui.new_color_picker, ui.set_callback

local surface = require("gamesense/surface")

local master_switch = ui_new_checkbox("Visuals", "Other ESP", "Kill notifications")
local clr = ui_new_color_picker("Visuals", "Other ESP", "notifications clr", 173, 255, 0, 255)

local function lerp(start, vend, time)
    return start + (vend - start) * time
end

local font = {
    surface.create_font("Verdana", 34, 700, {0x010,0x080}),
    surface.create_font("Verdana", 24, 700, {0x010,0x080}),
    surface.create_font("Verdana", 14, 700, {0x010,0x080}),
}

local alpha = 0
local notif = {} do
    local cur_kills = 0
    local total_kills = 0

    local latest = {
        time = 0,
        player = ""
    }

    local txt,size

    function notif.on_paint()
        local x,y = client_screen_size()
        local time_left = math_abs(globals_curtime() - latest.time)
        if time_left < 4 then
            alpha = lerp(alpha, ((time_left < 0.1 or time_left > 3) and 0 or 255), globals_frametime() * 6)
    
            local r,g,b,a = ui_get(clr)
    
            surface.draw_text(x*0.5-size[1][1]*0.5, y/2-200, r,g,b,         alpha, font[1], txt[1])
            surface.draw_text(x*0.5-size[2][1]*0.5, y/2-170, 255, 255, 255, alpha, font[2], txt[2])
            surface.draw_text(x*0.5-size[3][1]*0.5, y/2-150, 255, 255, 255, alpha, font[3], txt[3])
        end
    end

    function notif.on_death(e)
        local lp = entity_get_local_player()
        local player = client_userid_to_entindex(e.userid)
        if player == lp then
            cur_kills = 0
            latest.time = 0
            return
        end
        if client_userid_to_entindex(e.attacker) ~= lp then return end
        latest.player = entity_get_player_name(player)
        latest.time = globals_curtime()
        cur_kills = cur_kills + 1
        total_kills = total_kills + 1

        txt = {
            cur_kills .. (cur_kills == 1 and " ENEMY ELIMINATED" or " ENEMIES ELIMINATED"),
            "YOU FRAGGED " .. latest.player,
            "with total kills of " .. total_kills,
        }
        size = {
            {surface.get_text_size(font[1], txt[1])},
            {surface.get_text_size(font[2], txt[2])},
            {surface.get_text_size(font[3], txt[3])},
        }
    end

    function notif.reset_cur()
        cur_kills = 0
    end

    function notif.reset_tot()
        total_kills = 0
    end
end

ui_set_callback(master_switch, function (self)
    local enabled = ui_get(self)

    local update_callback = enabled and client.set_event_callback or client.unset_event_callback

    update_callback("paint", notif.on_paint)
    update_callback("round_prestart", notif.reset_cur)
    update_callback("cs_match_end_restart", notif.reset_tot)
    update_callback("game_start", notif.reset_tot)
    update_callback("game_newmap", notif.reset_tot)
    update_callback("player_death", notif.on_death)

    if not enabled then
        notif.reset_tot()
        notif.reset_cur()
    end
end, true)
