dofile("VirtualResolution.lua")
dofile("NodeUtility.lua")

local appWidth = 640
local appHeight = 960

local nextMeteorTime = 2.5
math.randomseed(os.time())
local objRadius = 30
local objs = {}

-- Virtual resolution setup --
vr = virtualResolution
vr:initialise{userSpaceW=appWidth, userSpaceH=appHeight}
vr:applyToScene(director:getCurrentScene())
--director:getCurrentScene().isTouchable = false

-- Sky and label setup --
local sky = director:createSprite(0,0,"epic-sky.jpg")
tween:from(sky, {alpha=0, time=1})
setDefaultSize(sky, appWidth, appHeight)

--> TASK 1 <--

local score = 0
local scoreBg = director:createRectangle({x=appWidth/2-70, y=appHeight-90, w=140, h=50, color=color.black, zOrder=1})
local scoreLabel = director:createLabel({x=appWidth/2-60, y=appHeight-90, text = "SCORE: 0", color=color.white, zOrder=2, sCale=2, yScale=2})

function setScore(val)
    score = val
    scoreLabel.text = "SCORE: " .. val
end

-- Object collision handling
function destroyObject(obj)
    
    --> TASK 7 <--
    
    obj.dead = true
    obj:removeEventListener("collision", objHit)
    destroyNode(obj)
end

function objHit(event)
    if event.phase == "began" then
        local objs = {event.nodeA, event.nodeB}
        
        for k,obj in pairs(objs) do
            if obj.isTarget then
                tween:to(obj, {xScale=0, yScale=0, alpha=0, time=0.2, onComplete=destroyObject})
                setScore(score+1)
                obj.isTarget = nil
                
                -- create explosion of rock pieces
                for i=0,6 do
                    local rock = director:createSprite({x=event.x, y=event.y, source="meteor.png", xAnchor=0.5, yAnchor=0.5})
                    setDefaultSize(rock, math.random(80,200))
                    tween:to(rock, {xScale=0, yScale=0, alpha=0, x=event.x+math.random(-300,300), y=event.y+math.random(-100,400),
                            time=1, onComplete=destroyNode})
                end
                
                -- queue up the next meteor
                meteorTimer:cancel()
                nextMeteorTime = math.max(nextMeteorTime * 0.9, 0.5)
                meteorTimer = system:addTimer(dropMeteor, nextMeteorTime, 0)
            else
                -- rocket spins away
                tween:to(obj, {xScale=0, yScale=0, alpha=0, time=0.7, onComplete=destroyObject})
                
                -- TASK 6
            end
        end
    end
end

-- Event handler
local events ={}

-- Re-setup virtual resolution on rotation events
function events.orientation()
    vr:update()
    vr:applyToScene(director:getCurrentScene())
    objMinX = vr.userWinMinX - objRadius*2
    objMaxX = vr.userWinMaxX + objRadius*2
    objMinY = vr.userWinMinY - objRadius*2
    objMaxY = vr.userWinMaxY + objRadius*2
end
events.orientation()

-- Drop a meteor on a timer
function dropMeteor()
    local meteor = director:createSprite({x=math.random(50,appWidth-50), y=objMaxY, source="meteor.png", xAnchor=0.5, yAnchor=0.5})
    setDefaultSize(meteor, 180)
    physics:addNode(meteor, {radius=60})
    meteor:addEventListener("collision", objHit)
    meteor.isTarget = true
    table.insert(objs, meteor)
end
meteorTimer = system:addTimer(dropMeteor, nextMeteorTime, 0)
dropMeteor()

-- Fire rocket towards touch point on touch
function events:touch(event)
    local x,y = vr:getUserPos(event.x,event.y)
    
    if event.phase == "ended" then
        local xVelocity = (x-appWidth/2)*2
        local yVelocity = y*2
        
        local rocket = director:createSprite({x=appWidth/2, y=-50, source="rocket.png", xAnchor=0.5, color=color.red})
        setDefaultSize(rocket, 100)
        rocket.rotation = math.deg(math.atan2(xVelocity, yVelocity))
        
        physics:addNode(rocket, {radius=60})
        rocket.physics:setLinearVelocity(xVelocity, yVelocity)
        
        rocket:addEventListener("collision", objHit)
        
        table.insert(objs, rocket)
        
        --> TASK 4 <--
    end
end

-- Check on each loop and remove objects if they go off the screen
function events:update()
    local i = 1
    while objs[i] do
        local obj = objs[i]
        if obj.dead or obj.x < objMinX or obj.x > objMaxX or obj.y < objMinY then
            if obj.isTarget and obj.y < objMinY then
                setScore(0)
                nextMeteorTime = 2.5
                --> TASK 2 <--
            end
            
            if not obj.dead then
                destroyObject(obj)
            end
            
            table.remove(objs, i)
        else
            --> TASK 5 <--
            i=i+1
        end
    end
    
    --> TASK 3 <--
end

system:addEventListener({"touch", "update", "orientation"}, events)
