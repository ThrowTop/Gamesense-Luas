local bgcontents = "\x14\x14\x14\xFF\x14\x14\x14\xFF\x0C\x0C\x0C\xFF\x14\x14\x14\xFF\x0C\x0C\x0C\xFF\x14\x14\x14\xFF\x0C\x0C\x0C\xFF\x14\x14\x14\xFF\x0C\x0C\x0C\xFF\x14\x14\x14\xFF\x14\x14\x14\xFF\x14\x14\x14\xFF\x0C\x0C\x0C\xFF\x14\x14\x14\xFF\x0C\x0C\x0C\xFF\x14\x14\x14\xFF"
local bgtexture = renderer.load_rgba(bgcontents, 4, 4)

local rect_outline = function(x, y, w, h, r, g, b, a, t)
    renderer.rectangle(x, y, w - t, t, r, g, b, a)
    renderer.rectangle(x, y + t, t, h - t, r, g, b, a)
    renderer.rectangle(x + w - t, y, t, h - t, r, g, b, a)
    renderer.rectangle(x + t, y + h - t, w - t, t, r, g, b, a)
end

local function gs_gradient(x, y, w, a_mul)
    local alpha = { 255, 128 }
    local width = math.floor(w / 2)
    local width2 = x + w - (x + width)

    for i = 1, 2 do
        local a = alpha[i] * a_mul
        renderer.gradient(x, y + i, width, 1, 55, 177, 218, a, 201, 84, 192, a, true)
        renderer.gradient(x + width, y + i, width2, 1, 201, 84, 192, a, 204, 227, 54, a, true)
    end
end

local function gs_window(x, y, w, h, alpha, grad)
    local inbounds = { x = x + 6, y = y + (grad and 10 or 6), w = w - 12, h = h - (grad and 16 or 12) }

    renderer.texture(bgtexture, inbounds.x, inbounds.y, inbounds.w, inbounds.h, 255,255,255,255 * alpha, "r")

    rect_outline(x, y, w, h, 12, 12, 12, 255 * alpha, 1)
    rect_outline(x + 1, y + 1, w - 2, h - 2, 60, 60, 60, 255 * alpha, 1)
    rect_outline(x + 2, y + 2, w - 4, h - 4, 40, 40, 40, 255 * alpha, 3)
    rect_outline(x + 5, y + 5, w - 10, h - 10, 60, 60, 60, 255 * alpha, 1)

    if grad then
        rect_outline(x + 6, y + 6, w - 12, 4, 12, 12, 12, 255 * alpha, 1)
        renderer.rectangle(x + 7, y + 8, w - 14, 1, 3, 2, 13, 255 * alpha)
        gs_gradient(x + 7, y + 6, w - 14, alpha)
    end

    return inbounds
end

return gs_window
