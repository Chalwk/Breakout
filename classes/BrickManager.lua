-- Breakout - Love2D Game for Android & Windows
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_sin = math.sin
local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert

local BrickManager = {}
BrickManager.__index = BrickManager

function BrickManager.new()
    local instance = setmetatable({}, BrickManager)

    instance.bricks = {}
    instance.movingBricks = {}
    instance.animationTime = 0

    return instance
end

function BrickManager:generateLevel(level, screenWidth)
    self.bricks = {}
    self.movingBricks = {}

    local rows = 6 + math_floor(level / 2)
    local cols = 10
    local brickWidth = 80
    local brickHeight = 25
    local spacing = 5

    local startX = (screenWidth - (cols * (brickWidth + spacing))) / 2
    local startY = 100

    local brickTypes = {
        -- Regular bricks (70% chance)
        {
            color = { 0.9, 0.2, 0.2 }, -- Red
            points = 10,
            health = 1,
            powerUp = nil,
            chance = 0.7
        },
        {
            color = { 0.2, 0.7, 0.9 }, -- Blue
            points = 20,
            health = 1,
            powerUp = nil,
            chance = 0.7
        },
        -- Special bricks (20% chance)
        {
            color = { 0.9, 0.7, 0.2 }, -- Orange
            points = 50,
            health = 2,
            powerUp = "multiball",
            chance = 0.2
        },
        {
            color = { 0.6, 0.2, 0.8 }, -- Purple
            points = 30,
            health = 1,
            powerUp = "sticky",
            chance = 0.2
        },
        {
            color = { 0.2, 0.9, 0.4 }, -- Green
            points = 40,
            health = 1,
            powerUp = "expand",
            chance = 0.2
        },
        {
            color = { 1.0, 0.3, 0.6 }, -- Pink
            points = 60,
            health = 3,
            powerUp = "laser",
            chance = 0.1
        },
        {
            color = { 1.0, 0.9, 0.2 }, -- Yellow
            points = 25,
            health = 1,
            powerUp = "life",
            chance = 0.1
        }
    }

    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            -- Skip some bricks randomly for variation
            if math_random() > 0.2 then
                local x = startX + col * (brickWidth + spacing)
                local y = startY + row * (brickHeight + spacing)

                -- Choose brick type based on chance
                local roll = math_random()
                local current = 0
                local selectedType

                for _, brickType in ipairs(brickTypes) do
                    current = current + brickType.chance
                    if roll <= current then
                        selectedType = brickType
                        break
                    end
                end

                local brick = {
                    x = x,
                    y = y,
                    width = brickWidth,
                    height = brickHeight,
                    color = selectedType.color,
                    points = selectedType.points,
                    health = selectedType.health,
                    maxHealth = selectedType.health,
                    powerUp = selectedType.powerUp,
                    moving = math_random() < 0.3, -- 30% chance to be moving
                    moveDirection = math_random() > 0.5 and 1 or -1,
                    moveSpeed = math_random(50, 100)
                }

                table_insert(self.bricks, brick)
                if brick.moving then
                    table_insert(self.movingBricks, brick)
                end
            end
        end
    end
end

function BrickManager:update(dt, screenWidth)
    self.animationTime = self.animationTime + dt

    -- Update moving bricks
    for _, brick in ipairs(self.movingBricks) do
        brick.x = brick.x + brick.moveSpeed * brick.moveDirection * dt

        -- Reverse direction at screen edges
        if brick.x < 0 then
            brick.x = 0
            brick.moveDirection = 1
        elseif brick.x + brick.width > screenWidth then
            brick.x = screenWidth - brick.width
            brick.moveDirection = -1
        end
    end
end

function BrickManager:checkBallCollision(ball)
    for i, brick in ipairs(self.bricks) do
        if ball.x + ball.radius > brick.x and
            ball.x - ball.radius < brick.x + brick.width and
            ball.y + ball.radius > brick.y and
            ball.y - ball.radius < brick.y + brick.height then
            -- Determine collision side and reflect ball
            local overlapLeft = ball.x + ball.radius - brick.x
            local overlapRight = brick.x + brick.width - (ball.x - ball.radius)
            local overlapTop = ball.y + ball.radius - brick.y
            local overlapBottom = brick.y + brick.height - (ball.y - ball.radius)

            local minOverlap = math.min(overlapLeft, overlapRight, overlapTop, overlapBottom)

            if minOverlap == overlapLeft or minOverlap == overlapRight then
                ball.dx = -ball.dx
            else
                ball.dy = -ball.dy
            end

            -- Damage brick
            brick.health = brick.health - 1

            if brick.health <= 0 then
                table.remove(self.bricks, i)
                -- Remove from moving bricks if it was there
                for j, movingBrick in ipairs(self.movingBricks) do
                    if movingBrick == brick then
                        table.remove(self.movingBricks, j)
                        break
                    end
                end
                return brick
            end
        end
    end
    return nil
end

function BrickManager:draw()
    for _, brick in ipairs(self.bricks) do
        local pulse = (math_sin(self.animationTime * 5) + 1) * 0.1
        local healthRatio = brick.health / brick.maxHealth

        love.graphics.setColor(
            brick.color[1] * healthRatio + pulse,
            brick.color[2] * healthRatio + pulse,
            brick.color[3] * healthRatio + pulse
        )

        love.graphics.rectangle("fill", brick.x, brick.y, brick.width, brick.height, 3, 3)

        -- Health indicator for multi-health bricks
        if brick.health < brick.maxHealth then
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.rectangle("line", brick.x + 2, brick.y + 2,
                brick.width - 4, brick.height - 4, 2, 2)
        end

        -- Power-up indicator
        if brick.powerUp then
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.circle("fill", brick.x + brick.width / 2,
                brick.y + brick.height / 2, 3)
        end
    end
end

function BrickManager:allBricksDestroyed()
    return #self.bricks == 0
end

return BrickManager
