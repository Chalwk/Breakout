-- Breakout - Love2D Game for Android & Windows
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_sin = math.sin
local table_insert = table.insert
local table_remove = table.remove

local PowerUpManager = {}
PowerUpManager.__index = PowerUpManager

function PowerUpManager.new()
    local instance = setmetatable({}, PowerUpManager)

    instance.powerUps = {}
    instance.animationTime = 0

    instance.powerUpTypes = {
        {
            name = "multiball",
            color = { 1.0, 0.8, 0.2 },
            symbol = "M"
        },
        {
            name = "sticky",
            color = { 0.9, 0.9, 0.2 },
            symbol = "S"
        },
        {
            name = "expand",
            color = { 0.2, 0.9, 0.4 },
            symbol = "E"
        },
        {
            name = "laser",
            color = { 1.0, 0.3, 0.3 },
            symbol = "L"
        },
        {
            name = "life",
            color = { 0.8, 0.3, 0.8 },
            symbol = "+"
        }
    }

    return instance
end

function PowerUpManager:update(dt)
    self.animationTime = self.animationTime + dt

    for i = #self.powerUps, 1, -1 do
        local powerUp = self.powerUps[i]
        powerUp.y = powerUp.y + powerUp.speed * dt

        -- Remove if off screen
        if powerUp.y > 800 then
            table_remove(self.powerUps, i)
        end
    end
end

function PowerUpManager:spawnPowerUp(x, y, powerUpType)
    for _, typeDef in ipairs(self.powerUpTypes) do
        if typeDef.name == powerUpType then
            table_insert(self.powerUps, {
                x = x,
                y = y,
                width = 30,
                height = 15,
                type = powerUpType,
                color = typeDef.color,
                symbol = typeDef.symbol,
                speed = 100
            })
            break
        end
    end
end

function PowerUpManager:checkPaddleCollision(paddle)
    for i, powerUp in ipairs(self.powerUps) do
        if powerUp.x < paddle.x + paddle.width and
            powerUp.x + powerUp.width > paddle.x and
            powerUp.y < paddle.y + paddle.height and
            powerUp.y + powerUp.height > paddle.y then
            table_remove(self.powerUps, i)
            return powerUp
        end
    end
    return nil
end

function PowerUpManager:draw()
    for _, powerUp in ipairs(self.powerUps) do
        local pulse = (math_sin(self.animationTime * 8) + 1) * 0.2

        love.graphics.setColor(
            powerUp.color[1] + pulse,
            powerUp.color[2] + pulse,
            powerUp.color[3] + pulse
        )

        love.graphics.rectangle("fill", powerUp.x, powerUp.y, powerUp.width, powerUp.height, 3, 3)

        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.printf(powerUp.symbol, powerUp.x, powerUp.y + 2, powerUp.width, "center")
    end
end

return PowerUpManager
