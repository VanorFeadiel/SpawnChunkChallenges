-- SpawnChunk_Spawner.lua
-- Hybrid spawn/sound attraction system with debug tracking
-- CHARACTER-SPECIFIC via getData()

SpawnChunk = SpawnChunk or {}

-----------------------  ZOMBIE POPULATION MANAGEMENT  ---------------------------

function SpawnChunk.ensureMinimumZombies()
    local data = SpawnChunk.getData()
    if not data or not data.isInitialized or data.isComplete then 
        return 
    end

    local pl = getPlayer()
    if not pl then 
        return 
    end

    local username = SpawnChunk.getUsername()

    -- Initialize debug tracking if not present
    data.totalSpawned = data.totalSpawned or 0
    data.totalSoundWaves = data.totalSoundWaves or 0
    data.maxSoundRadius = data.maxSoundRadius or 0
    
    -- Initialize zombie tracking for movement detection
    data.lastClosestZombieDistance = data.lastClosestZombieDistance or nil
    data.currentSoundRadius = data.currentSoundRadius or 0

    -- Check if boundary has been scanned for outdoor status
    if data.boundaryOutdoorsChecked == nil then
        data.boundaryOutdoorsChecked = false
        data.isOutdoors = false
    end
    
    -- Scan ALL boundary tiles if not yet checked
    if not data.boundaryOutdoorsChecked then
        print("[" .. username .. "] Scanning boundary for outdoor tiles...")
        local isOutdoors = false
        local tilesChecked = 0
        local outdoorTilesFound = 0
        
        local size = data.boundarySize
        
        -- Top and bottom edges (full width)
        for x = data.spawnX - size, data.spawnX + size do
            -- Top edge
            local square = getCell():getGridSquare(x, data.spawnY - size, data.spawnZ)
            if square then
                tilesChecked = tilesChecked + 1
                if not square:hasFloor() and not square:HasStairs() then
                    isOutdoors = true
                    outdoorTilesFound = outdoorTilesFound + 1
                end
            end
            
            -- Bottom edge
            square = getCell():getGridSquare(x, data.spawnY + size, data.spawnZ)
            if square then
                tilesChecked = tilesChecked + 1
                if not square:hasFloor() and not square:HasStairs() then
                    isOutdoors = true
                    outdoorTilesFound = outdoorTilesFound + 1
                end
            end
        end
        
        -- Left and right edges (exclude corners already checked)
        for y = data.spawnY - size + 1, data.spawnY + size - 1 do
            -- Left edge
            local square = getCell():getGridSquare(data.spawnX - size, y, data.spawnZ)
            if square then
                tilesChecked = tilesChecked + 1
                if not square:hasFloor() and not square:HasStairs() then
                    isOutdoors = true
                    outdoorTilesFound = outdoorTilesFound + 1
                end
            end
            
            -- Right edge
            square = getCell():getGridSquare(data.spawnX + size, y, data.spawnZ)
            if square then
                tilesChecked = tilesChecked + 1
                if not square:hasFloor() and not square:HasStairs() then
                    isOutdoors = true
                    outdoorTilesFound = outdoorTilesFound + 1
                end
            end
        end
        
        data.isOutdoors = isOutdoors
        data.boundaryOutdoorsChecked = true
        print(string.format("[%s] Boundary scan complete - %d tiles checked, %d outdoor, Result: %s", 
            username, tilesChecked, outdoorTilesFound, isOutdoors and "OUTDOORS" or "INDOORS"))
    end
    
    -- Calculate search radius 
    -- Maximum sound reach is boundary + 125, so search slightly beyond that
    local searchRadius = data.boundarySize + 125
    
    -- Count zombies in range and find closest
    local nearbyZeds = getCell():getZombieList()
    local nearbyCount = 0
    local totalInCell = 0
    local closestZombieDistance = nil
    
    for i = 0, nearbyZeds:size() - 1 do
        local z = nearbyZeds:get(i)
        if z and not z:isDead() then
            totalInCell = totalInCell + 1
            local zx = z:getX()
            local zy = z:getY()
            local dx = math.abs(zx - data.spawnX)
            local dy = math.abs(zy - data.spawnY)
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if dx <= searchRadius and dy <= searchRadius then
                nearbyCount = nearbyCount + 1
            end
            
            -- Track closest zombie
            if not closestZombieDistance or distance < closestZombieDistance then
                closestZombieDistance = distance
            end
        end
    end

    local minZeds = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.MinZombies) or 1
    
    if nearbyCount >= minZeds then 
        return 
    end

    local needed = minZeds - nearbyCount
    
    -- SMART SOUND SYSTEM:
    -- Determine when to start sound based on outdoor status
    local effectiveYellRange = data.isOutdoors and 20 or 10
    local soundTriggerDistance = data.boundarySize + effectiveYellRange + 1
    
    -- Check if we need to start or adjust sound waves
    local shouldEmitSound = false
    local zombieApproaching = false
    
    if closestZombieDistance then
        -- Check if zombie is beyond effective yell range
        if closestZombieDistance > soundTriggerDistance then
            -- Check if zombie is getting closer
            if data.lastClosestZombieDistance then
                zombieApproaching = closestZombieDistance < data.lastClosestZombieDistance
            end
            
            -- Emit sound if: no previous sound OR zombie not approaching
            if data.currentSoundRadius == 0 or not zombieApproaching then
                shouldEmitSound = true
            end
        end
        
        -- Store current distance for next check
        data.lastClosestZombieDistance = closestZombieDistance
    end
    
    -- If no zombies in cell at all, we must spawn
    if totalInCell == 0 then
        print("[" .. username .. "] No zombies in cell, spawning...")
        SpawnChunk.spawnZombies(needed, data, pl)
    elseif shouldEmitSound then
        -- Emit sound wave
        SpawnChunk.attractWithSound(data, pl, closestZombieDistance, zombieApproaching)
        
        -- Spawn 1 backup zombie if sound has been going for a while
        if data.totalSoundWaves > 5 then
            print(string.format("[%s] Spawning 1 backup zombie (sound waves: %d)", username, data.totalSoundWaves))
            SpawnChunk.spawnZombies(1, data, pl)
        end
    end
end

-----------------------  SOUND ATTRACTION SYSTEM  ---------------------------

function SpawnChunk.attractWithSound(data, pl, closestZombieDistance, zombieApproaching)
    local username = SpawnChunk.getUsername()
    
    -- Determine initial sound radius
    if data.currentSoundRadius == 0 then
        -- First sound: start at boundary + 5
        data.currentSoundRadius = data.boundarySize + 5
        print(string.format("[%s] Starting sound attraction at %d tiles (boundary + 5)", 
            username, data.currentSoundRadius))
    else
        -- Zombie not approaching, increase radius by 5
        if not zombieApproaching then
            data.currentSoundRadius = data.currentSoundRadius + 5
            print(string.format("[%s] Zombie not approaching, increasing sound to %d tiles (+5)", 
                username, data.currentSoundRadius))
        else
            print(string.format("[%s] Zombie approaching! Maintaining sound at %d tiles", 
                username, data.currentSoundRadius))
        end
    end
    
    -- Cap at boundary + 125 (reasonable maximum)
    local maxDistance = data.boundarySize + 125
    if data.currentSoundRadius > maxDistance then
        data.currentSoundRadius = maxDistance
    end
    
    local soundRadius = data.currentSoundRadius
    
    -- Emit sound at spawn point using Build 42 API
    local soundManager = getSoundManager()
    if soundManager then
        soundManager:AddSound(pl, data.spawnX, data.spawnY, data.spawnZ, soundRadius, soundRadius)
        
        -- Track stats
        data.totalSoundWaves = data.totalSoundWaves + 1
        if soundRadius > data.maxSoundRadius then
            data.maxSoundRadius = soundRadius
        end
        
        print(string.format("[%s] Sound wave #%d emitted - radius: %d tiles, closest zombie: %.1f tiles", 
            username, data.totalSoundWaves, soundRadius, closestZombieDistance or 0))
    else
        -- Fallback: Use player's thump sound if sound manager unavailable
        print("[" .. username .. "] SoundManager unavailable, using addSound as fallback")
        addSound(pl, pl:getX(), pl:getY(), pl:getZ(), soundRadius, soundRadius)
        
        data.totalSoundWaves = data.totalSoundWaves + 1
        if soundRadius > data.maxSoundRadius then
            data.maxSoundRadius = soundRadius
        end
    end
end

-----------------------  ZOMBIE SPAWNING SYSTEM  ---------------------------

function SpawnChunk.spawnZombies(count, data, pl)
    local spawnX, spawnY = data.spawnX, data.spawnY
    local size = data.boundarySize
    
    local username = SpawnChunk.getUsername()
    
    -- Check debug spawn option (separate from general debug mode)
    local debugCloseSpawn = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.DebugCloseSpawn) or false

    for i = 1, count do
        print(string.format("[%s] Spawning zombie %d of %d", username, i, count))
        local x, y
        
        if debugCloseSpawn then
            -- DEBUG MODE: Spawn 5 tiles from player for testing
            local playerX = math.floor(pl:getX())
            local playerY = math.floor(pl:getY())
            x = playerX + ZombRand(-5, 6)
            y = playerY + ZombRand(-5, 6)
            print("[" .. username .. "] DEBUG CLOSE SPAWN - 5 tiles from player")
        elseif size <= 20 then
            -- Small boundary: spawn just outside (size + 5 to size + 10)
            local spawnOffset = size + ZombRand(5, 11)
            if ZombRand(2) == 0 then
                x = spawnX + spawnOffset * (ZombRand(2) == 0 and -1 or 1)
                y = spawnY + ZombRand(-size, size + 1)
            else
                x = spawnX + ZombRand(-size, size + 1)
                y = spawnY + spawnOffset * (ZombRand(2) == 0 and -1 or 1)
            end
        else
            -- Normal: spawn 20 tiles outside boundary
            local spawnOffset = size + 20
            if ZombRand(2) == 0 then
                x = spawnX + spawnOffset * (ZombRand(2) == 0 and -1 or 1)
                y = spawnY + ZombRand(-size, size + 1)
            else
                x = spawnX + ZombRand(-size, size + 1)
                y = spawnY + spawnOffset * (ZombRand(2) == 0 and -1 or 1)
            end
        end

        -- Attempt spawn
        local square = getCell():getGridSquare(x, y, pl:getZ())
        if square then
            addZombiesInOutfit(x, y, pl:getZ(), 1, nil, nil)
            data.totalSpawned = data.totalSpawned + 1
            print(string.format("[%s] Spawned at (%d,%d) - Total spawned this life: %d", 
                username, x, y, data.totalSpawned))
        else
            print(string.format("[%s] ERROR - No valid square at (%d,%d)", username, x, y))
        end
    end
end

-----------------------  EVENT HOOKS  ---------------------------

-- Run check every in-game minute
Events.EveryOneMinute.Add(SpawnChunk.ensureMinimumZombies)
