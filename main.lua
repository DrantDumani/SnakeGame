local gameState = "menu"
local folder = love.filesystem.getSaveDirectory()
local path = folder.."/HiScore"


function getHiScore()
    if not love.filesystem.getInfo("HiScore.txt") then
        local newScore = love.filesystem.newFile("HiScore.txt")
        newScore:open("w")
        newScore:write("0")
        newScore:close()
        scoreData = newScore:read()
        scoreData = tonumber(scoreData)
        newScore:write(tostring(scoreData))
        newScore:close()
    end
    local scoreFile = love.filesystem.newFile("HiScore.txt")
    scoreFile:open("r")
    high_score = scoreFile:read()
    high_score = tonumber(high_score)
end

function updateHiScore()
    if score > high_score then
        local scoreFile = love.filesystem.newFile("HiScore.txt")
        scoreFile:open("w")
        scoreFile:write(tostring(score))
        scoreFile:close()
        getHiScore()
    end
end

function menu(xDim, yDim, yMenuPos)
    menuTbl = {}
    local opts = {"easy", "medium", "hard"}
    local diffTimers = {0.3, 0.15, 0.06}
    for i = 1, #opts do
        table.insert(menuTbl,
        	{text = opts[i], timer = diffTimers[i], x = 10, 
        	y = yMenuPos + yDim*(i-1),
        	wdth = xDim, hght = yDim})
    end
end

local function start()
    height = love.graphics.getHeight();
    width = love.graphics.getWidth();
    cellSize = 15
    heightMod = 20
    widthMod = 25
    boxHeight = heightMod * cellSize
    boxWidth = widthMod * cellSize
    
    startX =  (width / 2) - (boxWidth / 2)
    startY = (height / 2) - (boxHeight / 2)
    
    snake = {
    	    {x = (2*cellSize) + startX , y = 0 + startY},
    	    {x = (1*cellSize) + startX, y = 0 + startY},
    	    {x = 0 + startX, y = 0 + startY}
    	}
    touchCntrlTbl = {}
    gameOverTimer = 3
    foodTbl = {}
    wurms = {}
    spawnFood(foodTbl);
    snakeDir = "right"
    dirQueue = "left"
    bullets = {}
    scoreTimer = 3
    scoreTimerMax = scoreTimer
    score = 0
    getHiScore()
    menu(startX - 10, boxHeight / 3, startY)
end


local function moveSnake(dir)
    local nextXPos = snake[1].x
    local nextYPos = snake[1].y
    
    if dir == "right" then
        nextXPos = nextXPos + cellSize
    elseif dir == "left" then
        nextXPos = nextXPos - cellSize
    elseif dir == "down" then
        nextYPos = nextYPos + cellSize
    elseif dir == "up" then
        nextYPos = nextYPos - cellSize
    end
    
    table.insert(snake, 1,
    	    {x = nextXPos, y = nextYPos})
    	if snake[1].x == foodTbl[1].x and snake[1].y == foodTbl[1].y then
        table.remove(foodTbl)
        spawnFood(foodTbl)
        score = score + 5 * math.floor(scoreTimer + 1)
        scoreTimer = scoreTimerMax
    else
        table.remove(snake)
    end
end

function offScreen(obj)
    if obj.x < startX or 
    obj.x > (startX + (widthMod - 1) * cellSize) or
    obj.y < startY or
    obj.y > (startY + (heightMod - 1) * cellSize) then
        return true
    end
end

function isAliveCheck()
    if offScreen(snake[1]) then
        gameState = "game over"
    end
    
    for i = 2, #snake do
        if collisionChck(snake[1], snake[i]) then
            gameState = "game over"
        end
    end
    
    for index, wurm in ipairs(wurms) do
        for j, sctn in ipairs(snake) do
            for i, seg in ipairs(wurm) do
                if sctn.x == seg.x and 
                    sctn.y == seg.y then
                    gameState = "game over"
                end
            end
        end
    end    
end

function love.keypressed(key, scancode, isrepeat)
    if key == "up" then
        dirQueue = "up"
    elseif key == "down" then 
        dirQueue = "down"
    elseif key == "right" then 
        dirQueue = "right"
    elseif key == "left" then 
        dirQueue = "left"
    end
end

function compareDir()
    if dirQueue == "up" and snakeDir ~= "down" then
        snakeDir = dirQueue
    elseif dirQueue == "down" and snakeDir ~= "up" then
        snakeDir = dirQueue
    elseif dirQueue == "right" and snakeDir ~= "left" then
        snakeDir = dirQueue
    elseif dirQueue == "left" and snakeDir ~= "right" then
        snakeDir = dirQueue
    end
end

function love.mousepressed(x, y, button, isTouch, presses)
    if gameState == "menu" then
        for i = 1, #menuTbl do
            if x >= menuTbl[i].x and x <= menuTbl[i].x + menuTbl[i].wdth and
                y >= menuTbl[i].y and y <= menuTbl[i].y + menuTbl[i].hght then
                timer = menuTbl[i].timer
                timerMax = timer
                gameState = "playing"
            end
        end
    end
end

function love.touchpressed(id, x, y, dx, dy)
    if gameState == "playing" then
        table.insert(touchCntrlTbl,
    	        {id = id, x = x, y = y, 
    	         dx = 0, dy = 0})
    elseif gameState == "menu" then
        for i = 1, #menuTbl do
            if x >= menuTbl[i].x and x <= menuTbl[i].x + menuTbl[i].wdth and
                y >= menuTbl[i].y and y <= menuTbl[i].y + menuTbl[i].hght then
                timer = menuTbl[i].timer
                timerMax = timer
                gameState = "playing"
            end
        end
    end
end

function love.touchmoved(id, x, y, dx, dy)
    if gameState == "playing" and touchCntrlTbl[1] then
        touchCntrlTbl[1].dx = touchCntrlTbl[1].dx + dx
        touchCntrlTbl[1].dy = touchCntrlTbl[1].dy + dy
    end
end

function love.touchreleased(id, x, y, dx, dy)
    if gameState == "playing" and touchCntrlTbl[1] then
        local xDist = touchCntrlTbl[1].dx
        local yDist = touchCntrlTbl[1].dy
        if math.abs(xDist) > math.abs(yDist) then
            if math.abs(xDist) >= 5 then
                if xDist > 0 and dirQueue ~= "left" then
                    dirQueue = "right"
                elseif dirQueue ~= "right" then
                    dirQueue = "left"
                end
            end
        elseif math.abs(yDist) > math.abs(xDist) then
            if math.abs(yDist) >= 5 then
                if yDist > 0 and dirQueue ~= "up" then
                    dirQueue = "down"
                elseif dirQueue ~= "down" then
                    dirQueue = "up"
                end
            end
        end
        table.remove(touchCntrlTbl, 1)
    end
end

function spawnFood(tbl)
    local spwnPnts = {}
    local possibleDir = {"up", "down", "left", "right"}
    for xPos = 0, widthMod - 1 do
        for yPos = 0, heightMod - 1 do
            local spwnX = (xPos*cellSize) + startX
            local spwnY = (yPos*cellSize) + startY
            local viableSpwnPnt = true
            for index, segment in ipairs(snake) do
                if segment.x == spwnX and segment.y == spwnY then
                    viableSpwnPnt = false
                end
            end
            for index, wurm in ipairs(wurms) do
                for i, seg in ipairs(wurm) do
                    if seg.x == spwnX and seg.y == spwnY then
                        viableSpwnPnt = false
                    end
                end
            end
            if viableSpwnPnt then
                table.insert(spwnPnts, {x = spwnX, y = spwnY,
                	activeHazardTimer = 3, shotDelay = 0,
                	shotDelayMax = 1, release = false,
                	shotDir = possibleDir[love.math.random(1, #possibleDir)]})
            end
        end
    end
    
    table.insert(tbl, spwnPnts[love.math.random(1, #spwnPnts)])
end

function spawnBlltSeed(tbl)
    local nextXPos = tbl.x
    local nextYPos = tbl.y
    
    if tbl.shotDir == "right" then
        nextXPos = nextXPos + cellSize
    elseif tbl.shotDir == "left" then
        nextXPos = nextXPos - cellSize
    elseif tbl.shotDir == "down" then
        nextYPos = nextYPos + cellSize
    elseif tbl.shotDir == "up" then
        nextYPos = nextYPos - cellSize
    end
    
    table.insert(bullets, 
    	{x = nextXPos, y = nextYPos, 
    	dir = tbl.shotDir})
end

function spawnWurm(tbl)
    local nextXPos = tbl.x
    local nextYPos = tbl.y
    local applBirthX = nextXPos
    local applBirthY = nextYPos
    
    if tbl.shotDir == "right" then
        nextXPos = nextXPos + cellSize
    elseif tbl.shotDir == "left" then
        nextXPos = nextXPos - cellSize
    elseif tbl.shotDir == "down" then
        nextYPos = nextYPos + cellSize
    elseif tbl.shotDir == "up" then
        nextYPos = nextYPos - cellSize
    end
    
    table.insert(wurms, {
    	{x = nextXPos, y = nextYPos, 
    	dir = tbl.shotDir, appleX = applBirthX, appleY = applBirthY}
    	})
end

function moveWurms(wurm)
    if #wurm < 1 then
        return
    end
    
    local appleChck = false
    --for index, wurm in ipairs(tbl) do
        local nextXPos = wurm[1].x
        local nextYPos = wurm[1].y
        
        if wurm[1].dir == "right" then
            nextXPos = nextXPos + cellSize
        elseif wurm[1].dir == "left" then
            nextXPos = nextXPos - cellSize
        elseif wurm[1].dir == "down" then
            nextYPos = nextYPos + cellSize
        elseif wurm[1].dir == "up" then
            nextYPos = nextYPos - cellSize
        end
        
        table.insert(wurm, 1,
        	    {x = nextXPos, y = nextYPos,
        	    dir = wurm[1].dir, appleX = wurm[1].appleX,
        	    appleY = wurm[1].appleY})
        	
        	for index, apple in ipairs(foodTbl) do
        	    if wurm[1].appleX == apple.x and wurm[1].appleY == apple.y then
        	        appleChck = true
        	        break
        	    end
        	end
        	
        	if not appleChck then
        	   table.remove(wurm)
        	end
        	
        	if offScreen(wurm[1]) then
        	    table.remove(wurm, 1)
        	end
    --end
end

function moveBllts(tbl)
    for index, bullet in ipairs(tbl) do
        local nextXPos = bullet.x
        local nextYPos = bullet.y
    
        if bullet.dir == "right" then
            nextXPos = nextXPos + cellSize
        elseif bullet.dir == "left" then
            nextXPos = nextXPos - cellSize
        elseif bullet.dir == "down" then
            nextYPos = nextYPos + cellSize
        elseif bullet.dir == "up" then
            nextYPos = nextYPos - cellSize
        end
        
        bullet.x = nextXPos
        bullet.y = nextYPos
        
        if offScreen(bullet) then
            table.remove(tbl, index)
        end
        
        for i = 2, #snake do
            if collisionChck(bullet, snake[i]) then
                table.remove(tbl, index)
            end
        end
    end
end

function collisionChck(obj1, obj2)
    if obj1.x == obj2.x and obj1.y == obj2.y then
        return true
    end
end

local function drwElements(tbl, red, green, blue, alpha)
    alpha = alpha or 1
    love.graphics.setColor(red,green,blue, alpha)
    for index, item in ipairs(tbl) do
        love.graphics.rectangle(
        	    "fill",
        	    item.x,
        	    item.y,
        	    cellSize - 1,
        	    cellSize - 1)
    end
end

function love.load()
    start()
end

function love.update(dt)
    if gameState == "playing" then
        if timer <= 0 then
            compareDir()
            moveSnake(snakeDir)
            for index, wurm in ipairs(wurms) do
                moveWurms(wurm)
            end
            moveBllts(bullets)
            isAliveCheck()
            updateHiScore()
            timer = timerMax
        end
        timer = timer - dt
        if scoreTimer > 0 then
            scoreTimer = scoreTimer - dt
        else
            scoreTimer = 0
        end
        for index, apple in ipairs(foodTbl) do
            if apple.activeHazardTimer <= 0 and apple.release == false then
                --if apple.shotDelay <= 0 then
                    apple.release = true
                    spawnWurm(apple)
                    --apple.shotDelay = apple.shotDelayMax
                --else
                    --apple.shotDelay = apple.shotDelay - dt
                --end
            else
                apple.activeHazardTimer = apple.activeHazardTimer - dt
                apple.shotDelay = apple.shotDelay - dt
                if apple.shotDelay <= 0 and apple.release == false then
                    spawnBlltSeed(apple)
                    apple.shotDelay = apple.shotDelayMax
                else
                    apple.shotDelay = apple.shotDelay - dt
                end
            end
        end
    elseif gameState == "game over" then
        if gameOverTimer <= 0 then
            gameOverTimer = 3
            gameState = "menu"
            start()
        end
        gameOverTimer = gameOverTimer - dt
    end
end

function love.draw()
    love.graphics.setColor(1,1,1)
    love.graphics.print("High Score: "..high_score, 10, 0)
    love.graphics.print("Score: "..score, 250, 0)
    --draw the field
    love.graphics.rectangle("line", 
    	startX, 
    	startY, 
    	boxWidth, boxHeight)
    	
    	--draw the snake
    	if gameState == "playing" then
    	    love.graphics.setScissor(startX,
    	    startY,
    	    boxWidth + 1,
    	    boxHeight)
        drwElements(snake, 0, 1, 0)
   
    --draw the apples
        drwElements(foodTbl, 1, 0, 0)
        
    --draw the wurms
        for index, wurm in ipairs(wurms) do
            drwElements(wurm, 0, 1, 1)
        end
        
    --draw the bullets
        for index, bullet in ipairs(bullets) do
            drwElements(bullets, 1, 1, 1, 0.5)
        end
        love.graphics.setScissor()
    
      elseif gameState == "menu" then
        	--draw the menu
        	love.graphics.setColor(0,1,1)
    	for index, opt in ipairs(menuTbl) do
    	    love.graphics.rectangle("line",
    	    	    opt.x,
    	    	    opt.y,
    	    	    opt.wdth,
    	    	    opt.hght)
    	    love.graphics.print(opt.text, opt.x + 10, opt.y + 10)
    	end
    else
        love.graphics.print("Game over "..math.floor(gameOverTimer), startX, startY)
    end
end
