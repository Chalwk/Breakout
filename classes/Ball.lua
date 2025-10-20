-- Breakout - Love2D Game for Android & Windows
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_abs = math.abs
local table_insert = table.insert
local table_remove = table.remove

local Ball = {}
Ball.__index = Ball

function Ball.new(x, y, sounds)
    local instance = setmetatable({}, Ball)

    instance.x = x
    instance.y = y
    instance.radius = 8
    instance.dx = 0
    instance.dy = 0
    instance.stuck = true
    instance.color = {1.0, 0.8, 0.2}
    instance.trail = {}
    instance.sounds = sounds

    return instance
end

function Ball:update(dt, screenWidth, screenHeight, paddle)
    -- Add to trail
    table_insert(self.trail, {x = self.x, y = self.y, alpha = 1.0})
    if #self.trail > 8 then
        table_remove(self.trail, 1)
    end

    -- Update trail alpha
    for i, pos in ipairs(self.trail) do
        pos.alpha = i / #self.trail
    end

    if self.stuck then
        -- Follow paddle
        self.x = paddle.x + paddle.width / 2
        self.y = paddle.y - self.radius - 1
        return
    end

    -- Move ball
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- Wall collisions
    if self.x - self.radius < 0 then
        self.x = self.radius
        self.dx = -self.dx
    elseif self.x + self.radius > screenWidth then
        self.x = screenWidth - self.radius
        self.dx = -self.dx
    end

    if self.y - self.radius < 0 then
        self.y = self.radius
        self.dy = -self.dy
    end

    -- Paddle collision
    if self.y + self.radius > paddle.y and
       self.y - self.radius < paddle.y + paddle.height and
       self.x + self.radius > paddle.x and
       self.x - self.radius < paddle.x + paddle.width then

        self.y = paddle.y - self.radius
        self.dy = -math_abs(self.dy)

        -- Adjust angle based on where ball hits paddle
        local hitPos = (self.x - paddle.x) / paddle.width
        self.dx = (hitPos - 0.5) * 400

        -- Stick to paddle if sticky power-up is active
        if paddle.sticky then
            self.stuck = true
        end
        self.sounds.paddle_hit:play()
    end
end

function Ball:draw()
    -- Draw trail
    for _, pos in ipairs(self.trail) do
        love.graphics.setColor(self.color[1], self.color[2], self.color[3], pos.alpha * 0.5)
        love.graphics.circle("fill", pos.x, pos.y, self.radius * 0.7)
    end

    -- Draw ball
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.circle("fill", self.x, self.y, self.radius)

    -- Inner glow
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.circle("line", self.x, self.y, self.radius - 1)
end

return Ball