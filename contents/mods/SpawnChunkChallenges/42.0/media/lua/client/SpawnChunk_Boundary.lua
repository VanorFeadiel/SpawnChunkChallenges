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

-----------------------  TELEPORTATION FUNCTIONS  ---------------------------

-- Proven teleportation method (based on working RV mod for Build 42)
function SpawnChunk.doTeleport(pl, x, y, z)
    if not pl then 
        print("ERROR: Player object is nil")
        return false
    end
    
    -- Simple, direct teleportation (Build 42 method)
    pl:setX(x)
    pl:setLastX(x)
    pl:setY(y)
    pl:setLastY(y)
    pl:setZ(z)
    pl:setLastZ(z)
    
    print(string.format("Teleported to: %d %d %d", math.floor(x), math.floor(y), math.floor(z)))
    return true
end

function SpawnChunk.teleportToSpawn()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    -- Store current position for debugging
    local oldX, oldY, oldZ = pl:getX(), pl:getY(), pl:getZ()
    
    -- Check if player is already very close to spawn (prevent unnecessary teleportation)
    local dx = math.abs(oldX - data.spawnX)
    local dy = math.abs(oldY - data.spawnY)
    if dx <= 3 and dy <= 3 then
        print(string.format("Player already near spawn (%d,%d), skipping teleportation", oldX, oldY))
        return
    end
    
    -- Simple teleportation (following RV mod pattern)
    print(string.format("Teleporting from (%d,%d,%d) to spawn (%d,%d,%d)", 
        oldX, oldY, oldZ, data.spawnX, data.spawnY, data.spawnZ))
    
    SpawnChunk.doTeleport(pl, data.spawnX, data.spawnY, data.spawnZ)
    
    -- Play sound and show message
    pl:playSound("WallHit")
    pl:setHaloNote("You cannot leave until the challenge is complete!", 255, 50, 50, 200)
    
    -- Recreate visual markers using the same method as initial creation
    -- Remove existing markers
    if SpawnChunk.removeGroundMarkers then
        SpawnChunk.removeGroundMarkers()
    end
    
    -- Reset the flag so markers can be recreated
    data.markersCreated = false
    
    -- Recreate markers with minimal delay
    local timer = 0
    local function recreateMarkersDelayed()
        timer = timer + 1
        if timer >= 5 then -- ~0.15 second delay (much faster)
            if SpawnChunk.createGroundMarkers then
                SpawnChunk.createGroundMarkers()
                print("SpawnChunk_Boundary: Recreated ground markers after teleportation")
            end
            Events.OnTick.Remove(recreateMarkersDelayed)
        end
    end
    Events.OnTick.Add(recreateMarkersDelayed)
    
    print("Teleportation completed")
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
    
    -- Check if player is already at spawn point (prevent teleportation loop)
    local dx = math.abs(x - data.spawnX)
    local dy = math.abs(y - data.spawnY)
    if dx <= 2 and dy <= 2 then
        return -- Player is at spawn, no need to teleport
    end
    
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