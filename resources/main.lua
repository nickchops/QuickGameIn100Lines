dofile("VirtualResolution.lua")
dofile("NodeUtility.lua")

appWidth = 640
appHeight = 960

nextBallTime = 3
math.randomseed(os.time())
ballRadius = 30
balls = {}

vr = virtualResolution
vr:initialise{userSpaceW=appWidth, userSpaceH=appHeight}
vr:applyToScene(director:getCurrentScene())

sky = director:createSprite(0,0,"sky.png")
tween:from(sky, {alpha=0, time=1})
setDefaultSize(sky, appWidth, appHeight)

score = 0
scoreBg = director:createRectangle({x=appWidth/2-70, y=appHeight-90, w=140, h=50, color=color.black, zOrder=1})
scoreLabel = director:createLabel({x=appWidth/2-60, y=appHeight-90, text = "SCORE: 0", color=color.white, zOrder=2, sCale=2, yScale=2})

function setScore(val)
    score = val
    scoreLabel.text = "SCORE: " .. val
end

function destroyBall(ball)
    ball:removeEventListener("collision", ballHit)
    destroyNode(ball)
end

function ballHit(event)
    if event.phase == "began" then
        balls = {event.nodeA, event.nodeB}
        
        for k,ball in pairs(balls) do
            tween:to(ball, {xScale=2, yScale=2, alpha=0, time=0.5, onComplete=destroyBall})
            
            if ball.isTarget then
                setScore(score+1)
                ball.isTarget = nil
                ballTimer:cancel()
                nextBallTime = math.max(nextBallTime * 0.9, 0.5)
                ballTimer = system:addTimer(dropBall, nextBallTime, 0)
            end
        end
    end
end

function dropBall()
    local ball = director:createSprite({x=math.random(50,appWidth-50), y=ballMaxY, source="beachball.png", xAnchor=0.5, yAnchor=0.5})
    
    setDefaultSize(ball, 60)
    physics:addNode(ball, {radius=30})
    ball:addEventListener("collision", ballHit)
    ball.isTarget = true
    table.insert(balls, ball)
end
ballTimer = system:addTimer(dropBall, nextBallTime, 0)
dropBall()

events ={}
function events.orientation()
    vr:update()
    vr:applyToScene(director:getCurrentScene())
    ballMinX = vr.userWinMinX - ballRadius
    ballMaxX = vr.userWinMaxX + ballRadius
    ballMinY = vr.userWinMinY - ballRadius
    ballMaxY = vr.userWinMaxY + ballRadius
end
events.orientation()

function events:touch(event)
    local x,y = vr:getUserPos(event.x,event.y)
    
    if event.phase == "ended" then
        local ball = director:createSprite({x=appWidth/2, y=ballMinY, source="beachball.png", xAnchor=0.5, yAnchor=0.5, color=color.red})
        setDefaultSize(ball, 60)
        physics:addNode(ball, {radius=30})
        ball:addEventListener("collision", ballHit)
        ball.physics:setLinearVelocity((x-appWidth/2)*2,y*2)
        table.insert(balls, ball)
    end
end

function events:update()
    for k,ball in pairs(balls) do
        if ball.x < ballMinX or ball.x > ballMaxX or ball.y < ballMinY then
            if ball.isTarget then
                setScore(0)
            end
            destroyNode(ball)
            balls[k] = nil
        end
    end
end

system:addEventListener({"touch", "update", "orientation"}, events)
