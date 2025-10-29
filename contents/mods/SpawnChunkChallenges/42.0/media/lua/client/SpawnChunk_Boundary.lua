-- SpawnChunk_Boundary.lua
-- Check if player is within boundary and teleport if outside
-- CHARACTER-SPECIFIC via getData()
--modversion=0.3.2.024

SpawnChunk = SpawnChunk or {}

-----------------------  BOUNDARY CHECKING  ---------------------------

function SpawnChunk.isInBounds(x, y)
    local data = SpawnChunk.getData()
    if not data.isInitialized then return true end
    
    -- Zero to Hero: If all skills at level 10, no boundaries!
    if data.challengeType == "ZeroToHero" and data.isComplete then
        return true
    end
    
    -- In chunk mode, check if position is within ANY unlocked or available chunk
    if data.chunkMode then
        local unlockedChunks = SpawnChunk.getUnlockedChunks()
        if #unlockedChunks == 0 then return false end
        
        -- Check if player is within any unlocked or available chunk
        for _, chunkKey in ipairs(unlockedChunks) do
            local minX, minY, maxX, maxY = SpawnChunk.getChunkBounds(chunkKey, data)
            if minX then
                if x >= minX and x <= maxX and y >= minY and y <= maxY then
                    return true
                end
            end
        end
        
        -- Also check available chunks (can be entered but not unlocked yet)
        if data.chunks then
            for chunkKey, chunkData in pairs(data.chunks) do
                if chunkData.available and not chunkData.unlocked then
                    local minX, minY, maxX, maxY = SpawnChunk.getChunkBounds(chunkKey, data)
                    if minX then
                        if x >= minX and x <= maxX and y >= minY and y <= maxY then
                            return true  -- Allow entry to available chunks
                        end
                    end
                end
            end
        end
        
        return false  -- Not in any unlocked or available chunk
    else
        -- Classic mode: single boundary check
        if data.isComplete then return true end -- Allow free movement after completion
        
        local dx = math.abs(x - data.spawnX)
        local dy = math.abs(y - data.spawnY)
        
        return dx <= data.boundarySize and dy <= data.boundarySize
    end
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
    
    local username = SpawnChunk.getUsername()
    print(string.format("[%s] Teleported to: %d %d %d", username, math.floor(x), math.floor(y), math.floor(z)))
    return true
end

function SpawnChunk.teleportToSpawn()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    local username = SpawnChunk.getUsername()
    
    -- Store current position for debugging
    local oldX, oldY, oldZ = pl:getX(), pl:getY(), pl:getZ()
    
    -- Check if player is already very close to spawn (prevent unnecessary teleportation)
    local dx = math.abs(oldX - data.spawnX)
    local dy = math.abs(oldY - data.spawnY)
    if dx <= 3 and dy <= 3 then
        print(string.format("[%s] Player already near spawn (%d,%d), skipping teleportation", username, oldX, oldY))
        return
    end
    
    -- Simple teleportation (following RV mod pattern)
    print(string.format("[%s] Teleporting from (%d,%d,%d) to spawn (%d,%d,%d)", 
        username, oldX, oldY, oldZ, data.spawnX, data.spawnY, data.spawnZ))
    
    SpawnChunk.doTeleport(pl, data.spawnX, data.spawnY, data.spawnZ)
    
    -- Play sound and show message
    pl:playSound("WallHit")
    
    local data = SpawnChunk.getData()
    if data.chunkMode then
        pl:setHaloNote("You cannot leave unlocked chunks!", 255, 50, 50, 200)
    else
        pl:setHaloNote("You cannot leave until the challenge is complete!", 255, 50, 50, 200)
    end
    
    -- Recreate THIS character's visual markers
    -- Remove existing markers for this character
    if SpawnChunk.characterMarkers and SpawnChunk.characterMarkers[username] then
        for _, marker in ipairs(SpawnChunk.characterMarkers[username]) do
            if marker and marker.remove then
                marker:remove()
            end
        end
        SpawnChunk.characterMarkers[username] = {}
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
                print("[" .. username .. "] Recreated ground markers after teleportation")
            end
            Events.OnTick.Remove(recreateMarkersDelayed)
        end
    end
    Events.OnTick.Add(recreateMarkersDelayed)
    
    print("[" .. username .. "] Teleportation completed")
end

-----------------------  CHUNK CHANGE DETECTION  ---------------------------

-- Track last chunk player was in (per-player)
SpawnChunk.lastPlayerChunk = SpawnChunk.lastPlayerChunk or {}

-- Detect when player enters a new chunk and handle Zero to Hero unlocks
function SpawnChunk.detectChunkChange()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized or not data.chunkMode then return end
    
    local username = SpawnChunk.getUsername()
    local x = math.floor(pl:getX())
    local y = math.floor(pl:getY())
    
    -- Get current chunk
    local currentChunkKey = SpawnChunk.getChunkKeyFromPosition(x, y, data)
    local lastChunk = SpawnChunk.lastPlayerChunk[username]
    
    -- If chunk changed
    if currentChunkKey ~= lastChunk then
        SpawnChunk.lastPlayerChunk[username] = currentChunkKey
        
        -- ZERO TO HERO: Check if entering available (blue) chunk with banked unlocks
        if data.challengeType == "ZeroToHero" then
            local chunkData = data.chunks and data.chunks[currentChunkKey]
            
            -- Entering available (blue) chunk?
            if chunkData and chunkData.available and not chunkData.unlocked then
                print("[" .. username .. "] Entered chunk " .. currentChunkKey)
                
                -- STEP 1: Unlock the chunk and make it current (YELLOW)
                SpawnChunk.unlockChunk(currentChunkKey)
                data.currentChunk = currentChunkKey
                
                -- STEP 2: Start 1-hour settlement timer and set readyToUnlock to FALSE
                if SpawnChunk.startChunkEntryTimer then
                    SpawnChunk.startChunkEntryTimer()
                end
                data.readyToUnlock = false
                print("[" .. username .. "] readyToUnlock = false (timer started)")
                
                -- STEP 3: Clear ALL other available (blue) chunks - they become inaccessible
                if SpawnChunk.clearAllAvailableChunks then
                    SpawnChunk.clearAllAvailableChunks()
                end
                
                -- STEP 4: Visual feedback
                local remainingUnlocks = #(data.pendingSkillUnlocks or {})
                pl:setHaloNote("Chunk entered! Settlement timer: 1 hour", 100, 255, 255, 150)
                
                -- Recreate visual markers to show new state
                data.markersCreated = false
                if SpawnChunk.createGroundMarkers then
                    SpawnChunk.createGroundMarkers()
                end
            end
        end
    end
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
    
    -- Detect chunk changes (for Zero to Hero cascade)
    SpawnChunk.detectChunkChange()
    
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
