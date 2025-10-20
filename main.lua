-- Breakout - Love2D Game for Android & Windows
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local Game = require("classes/Game")
local Menu = require("classes/Menu")
local BackgroundManager = require("classes/BackgroundManager")

local game, menu, backgroundManager
local screenWidth, screenHeight
local gameState = "menu"
local fonts = {}

-- Add key state tracking
local keysPressed = {}

local function updateScreenSize()
    screenWidth = love.graphics.getWidth()
    screenHeight = love.graphics.getHeight()
end

function love.load()
    love.window.setTitle("Breakout")
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("smooth")

    -- Load fonts
    fonts.small = love.graphics.newFont(16)
    fonts.medium = love.graphics.newFont(22)
    fonts.large = love.graphics.newFont(52)
    fonts.section = love.graphics.newFont(18)

    -- Set default font
    love.graphics.setFont(fonts.medium)

    game = Game.new()
    menu = Menu.new()
    backgroundManager = BackgroundManager.new()

    menu:setFonts(fonts)
    game:setFonts(fonts)

    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end

function love.update(dt)
    updateScreenSize()

    if gameState == "menu" then
        menu:update(dt, screenWidth, screenHeight)
    elseif gameState == "playing" then
        -- Pass key states to game update
        game:update(dt, keysPressed)
    elseif gameState == "options" then
        menu:update(dt, screenWidth, screenHeight)
    end

    backgroundManager:update(dt)
end

function love.draw()
    backgroundManager:draw(screenWidth, screenHeight, gameState)

    if gameState == "menu" or gameState == "options" then
        menu:draw(screenWidth, screenHeight, gameState)
    elseif gameState == "playing" then
        game:draw()
    end
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        if gameState == "menu" then
            local action = menu:handleClick(x, y, "menu")
            if action == "start" then
                gameState = "playing"
                game:startNewGame(menu:getDifficulty())
            elseif action == "options" then
                gameState = "options"
            elseif action == "help" then
                menu.showHelp = not menu.showHelp
            elseif action == "quit" then
                love.event.quit()
            end
        elseif gameState == "options" then
            local action = menu:handleClick(x, y, "options")
            if not action then return end
            if action == "back" then
                gameState = "menu"
            elseif action:sub(1, 4) == "diff" then
                local difficulty = action:sub(6)
                menu:setDifficulty(difficulty)
            end
        elseif gameState == "playing" then
            if game:isGameOver() then
                gameState = "menu"
            end
        end
    end
end

function love.keypressed(key)
    keysPressed[key] = true

    if key == "escape" then
        if gameState == "playing" or gameState == "options" then
            gameState = "menu"
        else
            love.event.quit()
        end
    elseif gameState == "playing" then
        game:handleKeypress(key)
    end
end

function love.keyreleased(key)
    keysPressed[key] = nil
end

function love.resize(w, h)
    updateScreenSize()
    menu:setScreenSize(screenWidth, screenHeight)
    game:setScreenSize(screenWidth, screenHeight)
end
