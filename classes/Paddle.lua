-- Breakout - Love2D Game for Android & Windows
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_abs = math.abs

local Paddle = {}
Paddle.__index = Paddle

function Paddle.new(x, y, width, height)
    local instance = setmetatable({}, Paddle)

    instance.x = x
    instance.y = y
    instance.width = width
    instance.height = height
    instance.dx = 0
    instance.color = {0.2, 0.7, 1.0}
    instance.sticky = false
    instance.laser = false

    return instance
end

function Paddle:update(dt, screenWidth, keysPressed)
    -- Handle continuous movement if keysPressed is provided
    if keysPressed then
        self.dx = 0

        -- Left movement (A key or left arrow)
        if keysPressed["left"] or keysPressed["a"] then
            self.dx = -400
        end

        -- Right movement (D key or right arrow)
        if keysPressed["right"] or keysPressed["d"] then
            self.dx = 400
        end
    end

    self.x = self.x + self.dx * dt

    -- Keep paddle within screen bounds
    if self.x < 0 then
        self.x = 0
    elseif self.x + self.width > screenWidth then
        self.x = screenWidth - self.width
    end

    -- Slow down paddle (only if no keys are pressed)
    if not keysPressed or (not keysPressed["left"] and not keysPressed["right"] and
                          not keysPressed["a"] and not keysPressed["d"]) then
        self.dx = self.dx * 0.9
        if math_abs(self.dx) < 10 then
            self.dx = 0
        end
    end
end

function Paddle:draw()
    -- Main paddle
    love.graphics.setColor(self.color[1], self.color[2], self.color[3])
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)

    -- Inner glow
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", self.x + 2, self.y + 2, self.width - 4, self.height - 4, 3, 3)

    -- Sticky paddle indicator
    if self.sticky then
        love.graphics.setColor(0.9, 0.9, 0.2, 0.6)
        love.graphics.rectangle("fill", self.x, self.y - 5, self.width, 3, 2, 2)
    end

    -- Laser indicators
    if self.laser then
        love.graphics.setColor(1.0, 0.3, 0.3, 0.8)
        love.graphics.rectangle("fill", self.x - 5, self.y, 5, self.height, 2, 2)
        love.graphics.rectangle("fill", self.x + self.width, self.y, 5, self.height, 2, 2)
    end
end

return Paddle