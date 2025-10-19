-- SpawnChunk_Boundary.lua
-- Check if player is within boundary and teleport if outside
-- Adding comment to have a change in file and test workshop update

SpawnChunk = SpawnChunk or {}

-----------------------  BOUNDARY CHECKING  ---------------------------

function SpawnChunk.isInBounds(x, y)
    local data = SpawnChunk.getData()
    if not data.isInitialized then return true end
    if data.isComplete then return true end -- Allow free movement after completion
    
    local dx = math.abs(x - data.spawnX)
    local dy = math.abs(y - data.spawnY)
    
    return dx <= data.boundarySize and dy <= data.boundarySize
end

function SpawnChunk.teleportToSpawn()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    -- Teleport player back to spawn
    pl:setX(data.spawnX)
    pl:setY(data.spawnY)
    pl:setZ(data.spawnZ)
    
    -- Play sound and show message
    pl:playSound("WallHit")
    pl:setHaloNote("You cannot leave until the challenge is complete!", 255, 50, 50, 200)
    
    print("Player teleported back to spawn")
end

-----------------------  BOUNDARY ENFORCEMENT  ---------------------------

local checkCounter = 0
local CHECK_INTERVAL = 10 -- Check every 10 ticks (~0.3 seconds)

function SpawnChunk.checkBoundary()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized or data.isComplete then return end
    
    -- Check every X ticks to reduce performance impact
    checkCounter = checkCounter + 1
    if checkCounter < CHECK_INTERVAL then return end
    checkCounter = 0
    
    local x = math.floor(pl:getX())
    local y = math.floor(pl:getY())
    
    -- Check if player is outside boundary
    if not SpawnChunk.isInBounds(x, y) then
        SpawnChunk.teleportToSpawn()
    end
end

-- Hook into tick event for continuous checking
Events.OnTick.Add(SpawnChunk.checkBoundary)

-----------------------  DEBUG VISUALIZATION  ---------------------------

function SpawnChunk.drawBoundary()
    -- Optional: Draw boundary markers on map
    -- This would require ISUIElement rendering
    -- For now, just a placeholder for future enhancement
end