-- Breakout - Love2D Game for Android & Windows
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local ipairs = ipairs
local math_floor = math.floor
local math_random = math.random
local table_insert = table.insert
local table_remove = table.remove

local Paddle = require("classes/Paddle")
local Ball = require("classes/Ball")
local BrickManager = require("classes/BrickManager")
local PowerUpManager = require("classes/PowerUpManager")

local Game = {}
Game.__index = Game

function Game.new()
    local game = setmetatable({}, Game)

    game.screenWidth = 1200
    game.screenHeight = 800

    game.paddle = nil
    game.balls = {}
    game.brickManager = nil
    game.powerUpManager = nil

    game.sounds = {}
    game.score = 0
    game.highScore = 0
    game.lives = 3
    game.level = 1
    game.gameOver = false
    game.paused = false
    game.difficulty = "medium"

    game.particles = {}
    game.activePowerUps = {}

    -- Load sounds
    game.sounds.paddle_hit = love.audio.newSource("assets/sounds/paddle_hit.mp3", "static")
    game.sounds.brick_hit = love.audio.newSource("assets/sounds/brick_hit.mp3", "static")
    game.sounds.score = love.audio.newSource("assets/sounds/score.mp3", "static")
    game.sounds.power_up = love.audio.newSource("assets/sounds/power_up.mp3", "static")
    game.sounds.background = love.audio.newSource("assets/sounds/background.mp3", "stream")

    if game.sounds.background then
        game.sounds.background:setLooping(true)
        game.sounds.background:setVolume(0.3)
        love.audio.play(game.sounds.background)
    end

    return game
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function Game:startNewGame(difficulty)
    self.difficulty = difficulty or "medium"

    local paddleWidth = 120
    if self.difficulty == "easy" then
        paddleWidth = 150
    elseif self.difficulty == "hard" then
        paddleWidth = 90
    end

    self.paddle = Paddle.new(self.screenWidth / 2 - paddleWidth / 2,
        self.screenHeight - 40, paddleWidth, 20)

    self.balls = {}
    table_insert(self.balls, Ball.new(self.screenWidth / 2, self.screenHeight - 60, self.sounds))

    self.brickManager = BrickManager.new()
    self.powerUpManager = PowerUpManager.new()

    self.score = 0
    self.lives = 3
    self.level = 1
    self.gameOver = false
    self.paused = false
    self.particles = {}
    self.activePowerUps = {}

    self.brickManager:generateLevel(self.level, self.screenWidth)
end

function Game:update(dt, keysPressed)
    if self.gameOver or self.paused then return end

    -- Update paddle with continuous key input
    if keysPressed then
        self.paddle:update(dt, self.screenWidth, keysPressed)
    else
        self.paddle:update(dt, self.screenWidth)
    end

    -- Update balls
    for i = #self.balls, 1, -1 do
        local ball = self.balls[i]
        ball:update(dt, self.screenWidth, self.screenHeight, self.paddle)

        -- Check if ball is lost
        if ball.y > self.screenHeight then
            table_remove(self.balls, i)
        end
    end

    -- If no balls left, lose a life
    if #self.balls == 0 then
        self.lives = self.lives - 1
        if self.lives <= 0 then
            self.gameOver = true
            if self.score > self.highScore then
                self.highScore = self.score
            end
        else
            -- Reset ball
            table_insert(self.balls, Ball.new(self.screenWidth / 2, self.screenHeight - 60))
        end
    end

    -- Update bricks
    self.brickManager:update(dt, self.screenWidth)

    -- Update power-ups
    self.powerUpManager:update(dt)

    -- Check collisions
    self:checkCollisions()

    -- Update particles
    self:updateParticles(dt)

    -- Update active power-ups
    self:updatePowerUps(dt)

    -- Check level completion
    if self.brickManager:allBricksDestroyed() then
        self.level = self.level + 1
        self.brickManager:generateLevel(self.level, self.screenWidth)
        self:resetBalls()
        self.lives = self.lives + 1 -- Bonus life for completing level
    end
end

function Game:resetBalls()
    self.balls = {}
    table_insert(self.balls, Ball.new(self.screenWidth / 2, self.screenHeight - 60))
end

function Game:checkCollisions()
    for _, ball in ipairs(self.balls) do
        -- Ball with bricks
        local brickHit = self.brickManager:checkBallCollision(ball)
        if brickHit then
            self.score = self.score + brickHit.points
            if brickHit.powerUp then
                self.powerUpManager:spawnPowerUp(brickHit.x, brickHit.y, brickHit.powerUp)
            end
            self:createBrickBreakEffect(brickHit.x, brickHit.y, brickHit.color)
            self.sounds.brick_hit:play()
        end

        -- Ball with power-ups
        local powerUp = self.powerUpManager:checkPaddleCollision(self.paddle)
        if powerUp then
            self:applyPowerUp(powerUp)
            self.sounds.power_up:play()
        end
    end
end

function Game:applyPowerUp(powerUp)
    if powerUp.type == "multiball" then
        -- Add two extra balls
        for _ = 1, 2 do
            local newBall = Ball.new(self.paddle.x + self.paddle.width / 2,
                self.paddle.y - 20)
            newBall.dx = math_random(-200, 200)
            newBall.dy = -200
            table_insert(self.balls, newBall)
        end
    elseif powerUp.type == "sticky" then
        self.paddle.sticky = true
        self.activePowerUps.sticky = { duration = 10, startTime = love.timer.getTime() }
    elseif powerUp.type == "expand" then
        self.paddle.width = math.min(200, self.paddle.width + 40)
        self.activePowerUps.expand = { duration = 8, startTime = love.timer.getTime() }
    elseif powerUp.type == "laser" then
        self.paddle.laser = true
        self.activePowerUps.laser = { duration = 6, startTime = love.timer.getTime() }
    elseif powerUp.type == "life" then
        self.lives = self.lives + 1
    end
end

function Game:updatePowerUps(dt)
    for effect, powerUp in pairs(self.activePowerUps) do
        powerUp.duration = powerUp.duration - dt

        if powerUp.duration <= 0 then
            self.activePowerUps[effect] = nil

            -- Revert effects
            if effect == "sticky" then
                self.paddle.sticky = false
            elseif effect == "expand" then
                self.paddle.width = self.difficulty == "easy" and 150 or
                    self.difficulty == "hard" and 90 or 120
            elseif effect == "laser" then
                self.paddle.laser = false
            end
        end
    end
end

function Game:updateParticles(dt)
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.life = particle.life - dt
        particle.x = particle.x + particle.dx * dt
        particle.y = particle.y + particle.dy * dt

        if particle.life <= 0 then
            table_remove(self.particles, i)
        end
    end
end

function Game:createBrickBreakEffect(x, y, color)
    for _ = 1, 15 do
        table_insert(self.particles, {
            x = x + 25,
            y = y + 10,
            dx = (math_random() - 0.5) * 300,
            dy = (math_random() - 0.5) * 300,
            life = 1.0,
            size = math_random(2, 6),
            color = { color[1], color[2], color[3], 0.9 }
        })
    end
end

function Game:draw()
    -- Draw game elements
    self.brickManager:draw()

    for _, ball in ipairs(self.balls) do
        ball:draw()
    end

    self.paddle:draw()
    self.powerUpManager:draw()

    -- Draw particles
    self:drawParticles()

    -- Draw UI
    self:drawUI()

    if self.gameOver then
        self:drawGameOver()
    elseif self.paused then
        self:drawPaused()
    end
end

function Game:drawParticles()
    for _, particle in ipairs(self.particles) do
        local alpha = particle.life * 0.8
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
end

function Game:drawUI()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.medium)

    -- Score and high score
    love.graphics.print("Score: " .. self.score, 20, 20)
    love.graphics.print("High Score: " .. self.highScore, 20, 50)

    -- Level and lives
    love.graphics.printf("Level: " .. self.level, 0, 20, self.screenWidth - 20, "right")
    love.graphics.printf("Lives: " .. self.lives, 0, 50, self.screenWidth - 20, "right")

    -- Active power-ups
    local powerUpY = 90
    love.graphics.setFont(self.fonts.small)
    for effect, powerUp in pairs(self.activePowerUps) do
        local timeLeft = math_floor(powerUp.duration * 10) / 10
        love.graphics.print(effect:upper() .. ": " .. timeLeft .. "s", 20, powerUpY)
        powerUpY = powerUpY + 20
    end

    -- Controls help
    love.graphics.setColor(1, 1, 1, 0.7)
    love.graphics.printf("ARROWS/A-D: Move Paddle | SPACE: Launch Ball | P: Pause | R: Restart | ESC: Menu",
        0, self.screenHeight - 18, self.screenWidth, "center")
end

function Game:drawGameOver()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    love.graphics.setFont(self.fonts.large)
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.printf("GAME OVER", 0, self.screenHeight / 2 - 100, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.medium)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Final Score: " .. self.score, 0, self.screenHeight / 2 - 30, self.screenWidth, "center")
    love.graphics.printf("High Score: " .. self.highScore, 0, self.screenHeight / 2, self.screenWidth, "center")
    love.graphics.printf("Level Reached: " .. self.level, 0, self.screenHeight / 2 + 30, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.printf("Click anywhere to continue", 0, self.screenHeight / 2 + 80, self.screenWidth, "center")
end

function Game:drawPaused()
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    love.graphics.setFont(self.fonts.large)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, self.screenHeight / 2 - 50, self.screenWidth, "center")

    love.graphics.setFont(self.fonts.small)
    love.graphics.printf("Press P to resume", 0, self.screenHeight / 2 + 20, self.screenWidth, "center")
end

function Game:handleKeypress(key)
    if key == "p" then
        self.paused = not self.paused
    elseif key == "r" then
        self:startNewGame(self.difficulty)
    elseif key == "space" then
        -- Launch any stuck balls
        for _, ball in ipairs(self.balls) do
            if ball.stuck then
                ball.stuck = false
                ball.dy = -200
            end
        end
    end
end

function Game:isGameOver()
    return self.gameOver
end

function Game:setFonts(fonts)
    self.fonts = fonts
end

return Game
