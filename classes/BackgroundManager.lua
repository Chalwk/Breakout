-- Breakout - Love2D Game for Android & Windows
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove

local BackgroundManager = {}
BackgroundManager.__index = BackgroundManager

function BackgroundManager.new()
    local instance = setmetatable({}, BackgroundManager)
    instance.particles = {}
    instance.time = 0
    instance:initParticles()
    return instance
end

function BackgroundManager:initParticles()
    self.particles = {}
    for _ = 1, 80 do
        table_insert(self.particles, {
            x = math_random() * 1200,
            y = math_random() * 800,
            size = math_random(1, 4),
            speed = math_random(10, 50),
            angle = math_random() * math_pi * 2,
            pulseSpeed = math_random(0.5, 3),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 3),
            life = math_random(5, 20),
            maxLife = math_random(5, 20),
            color = {
                math_random(0.1, 0.3),
                math_random(0.5, 0.8),
                math_random(0.8, 1.0)  -- Blue theme
            }
        })
    end
end

function BackgroundManager:update(dt)
    self.time = self.time + dt

    -- Update particles
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt

        if particle.life <= 0 then
            table_remove(self.particles, i)
        else
            particle.x = particle.x + math_cos(particle.angle) * particle.speed * dt
            particle.y = particle.y + math_sin(particle.angle) * particle.speed * dt

            if particle.x < -100 then particle.x = 1300 end
            if particle.x > 1300 then particle.x = -100 end
            if particle.y < -100 then particle.y = 900 end
            if particle.y > 900 then particle.y = -100 end
        end
    end

    while #self.particles < 80 do
        table_insert(self.particles, {
            x = math_random() * 1200,
            y = -50,
            size = math_random(1, 4),
            speed = math_random(10, 50),
            angle = math_random(0.2, 0.8) * math_pi,
            pulseSpeed = math_random(0.5, 3),
            pulsePhase = math_random() * math_pi * 2,
            type = math_random(1, 3),
            life = math_random(5, 20),
            maxLife = math_random(5, 20),
            color = {
                math_random(0.1, 0.3),
                math_random(0.5, 0.8),
                math_random(0.8, 1.0)  -- Blue theme
            }
        })
    end
end

function BackgroundManager:draw(screenWidth, screenHeight, gameState)
    local time = love.timer.getTime()

    -- Breakout-themed gradient background (blue/purple theme)
    for y = 0, screenHeight, 2 do
        local progress = y / screenHeight
        local pulse = (math_sin(time * 0.5 + progress * 3) + 1) * 0.03

        local r = 0.05 + progress * 0.05 + pulse
        local g = 0.1 + progress * 0.1 + pulse * 0.5
        local b = 0.15 + progress * 0.15 + pulse * 0.8

        love.graphics.setColor(r, g, b, 0.9)
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Grid pattern (representing the brick layout)
    love.graphics.setColor(0.2, 0.4, 0.6, 0.15)
    local gridSize = 40
    for x = 0, screenWidth, gridSize do
        love.graphics.line(x, 0, x, screenHeight)
    end
    for y = 0, screenHeight, gridSize do
        love.graphics.line(0, y, screenWidth, y)
    end

    -- Additional decorative elements for Breakout theme
    love.graphics.setColor(0.3, 0.5, 0.8, 0.1)
    for i = 1, 5 do
        local wave = math_sin(time * 0.8 + i) * 20
        love.graphics.rectangle("line",
            wave + i * 200,
            100 + math_sin(time * 1.2 + i) * 30,
            80, 25, 3, 3
        )
    end

    -- Particles
    for _, particle in ipairs(self.particles) do
        local lifeProgress = particle.life / particle.maxLife
        local pulse = (math_sin(particle.pulsePhase + time * particle.pulseSpeed) + 1) * 0.5
        local currentSize = particle.size * (0.7 + pulse * 0.3)
        local alpha = lifeProgress * (0.2 + pulse * 0.3)

        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)

        if particle.type == 1 then
            love.graphics.circle("fill", particle.x, particle.y, currentSize)
        elseif particle.type == 2 then
            love.graphics.rectangle("fill", particle.x - currentSize, particle.y - currentSize,
                                  currentSize * 2, currentSize * 2)
        else
            self:drawDiamond(particle.x, particle.y, currentSize)
        end
    end

    -- Paddle-like element at bottom
    love.graphics.setColor(0.2, 0.7, 1.0, 0.2)
    local paddleWidth = 150
    local paddleX = (screenWidth - paddleWidth) / 2 + math_sin(time) * 50
    love.graphics.rectangle("fill", paddleX, screenHeight - 30, paddleWidth, 15, 5, 5)

    -- Ball-like elements floating around
    love.graphics.setColor(1.0, 0.8, 0.2, 0.3)
    for i = 1, 3 do
        local ballX = (math_sin(time * 0.7 + i * 2) * 0.5 + 0.5) * screenWidth
        local ballY = 200 + math_sin(time * 0.9 + i) * 100
        love.graphics.circle("fill", ballX, ballY, 8)
    end
end

function BackgroundManager:drawDiamond(x, y, size)
    love.graphics.polygon("fill",
        x, y - size,
        x + size, y,
        x, y + size,
        x - size, y
    )
end

return BackgroundManager