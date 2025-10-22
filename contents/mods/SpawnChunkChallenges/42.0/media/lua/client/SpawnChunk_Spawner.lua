-- SpawnChunk_Spawner.lua
-- Hybrid spawn/sound attraction system with debug tracking

SpawnChunk = SpawnChunk or {}

-----------------------  ZOMBIE POPULATION MANAGEMENT  ---------------------------

function SpawnChunk.ensureMinimumZombies()
    local data = SpawnChunk.getData()
    if not data or not data.isInitialized or data.isComplete then 
        print("SpawnChunk_Spawner: Skipping - not initialized or already complete")
        return 
    end

    local pl = getPlayer()
    if not pl then 
        print("SpawnChunk_Spawner: Skipping - no player")
        return 
    end

    -- Initialize debug tracking if not present
    data.totalSpawned = data.totalSpawned or 0
    data.totalSoundWaves = data.totalSoundWaves or 0
    data.maxSoundRadius = data.maxSoundRadius or 0

    -- Check if boundary has been scanned for outdoor status
    if data.boundaryOutdoorsChecked == nil then
        data.boundaryOutdoorsChecked = false
        data.isOutdoors = false
    end
    
    -- Scan ALL boundary tiles if not yet checked
    if not data.boundaryOutdoorsChecked then
        print("SpawnChunk_Spawner: Scanning boundary for outdoor tiles...")
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
        print(string.format("SpawnChunk_Spawner: Boundary scan complete - %d tiles checked, %d outdoor, Result: %s", 
            tilesChecked, outdoorTilesFound, isOutdoors and "OUTDOORS" or "INDOORS"))
    end
    
    -- Calculate search radius based on outdoor status
    local shoutRange = data.isOutdoors and 65 or 25
    local searchRadius = data.boundarySize + shoutRange
    
    -- Count zombies in range
    local nearbyZeds = getCell():getZombieList()
    local nearbyCount = 0
    local totalInCell = 0
    
    for i = 0, nearbyZeds:size() - 1 do
        local z = nearbyZeds:get(i)
        if z and not z:isDead() then
            totalInCell = totalInCell + 1
            local zx = z:getX()
            local zy = z:getY()
            local dx = math.abs(zx - data.spawnX)
            local dy = math.abs(zy - data.spawnY)
            if dx <= searchRadius and dy <= searchRadius then
                nearbyCount = nearbyCount + 1
            end
        end
    end

    print(string.format("SpawnChunk_Spawner: Population check - nearby: %d, total in cell: %d, search radius: %d", 
        nearbyCount, totalInCell, searchRadius))

    local minZeds = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.MinZombies) or 1
    
    if nearbyCount >= minZeds then 
        print(string.format("SpawnChunk_Spawner: Population sufficient (%d >= %d)", nearbyCount, minZeds))
        return 
    end

    local needed = minZeds - nearbyCount
    print(string.format("SpawnChunk_Spawner: Need %d more zombies (have %d, need %d)", needed, nearbyCount, minZeds))
    
    -- HYBRID APPROACH:
    -- If no zombies exist → Spawn them
    -- If zombies exist but not enough nearby → Attract with sound
    
    if totalInCell == 0 then
        -- NO ZOMBIES IN CELL - Must spawn
        print("SpawnChunk_Spawner: No zombies in cell, spawning...")
        SpawnChunk.spawnZombies(needed, data, pl)
    else
        -- ZOMBIES EXIST - Try sound attraction first, then spawn if needed
        print(string.format("SpawnChunk_Spawner: %d zombies in cell, using sound attraction", totalInCell))
        SpawnChunk.attractWithSound(needed, data, pl)
        
        -- If sound attraction used but we still need guarantees, spawn a few as backup
        -- This ensures minimum is met even if distant zombies don't hear
        local spawnBackup = math.min(1, needed) -- Spawn 1 as backup
        if spawnBackup > 0 then
            print(string.format("SpawnChunk_Spawner: Spawning %d backup zombie(s) with sound", spawnBackup))
            SpawnChunk.spawnZombies(spawnBackup, data, pl)
        end
    end
end

-----------------------  SOUND ATTRACTION SYSTEM  ---------------------------

function SpawnChunk.attractWithSound(needed, data, pl)
    -- Progressive sound waves - louder if more zombies needed
    -- Base sound: 50 tiles, +10 per zombie needed
    local soundRadius = 50 + (10 * needed)
    
    -- Cap at outdoor shout range to stay realistic
    local maxRange = data.isOutdoors and 65 or 25
    local effectiveRange = data.boundarySize + maxRange
    if soundRadius > effectiveRange then
        soundRadius = effectiveRange
    end
    
    -- Emit sound at spawn point
    getSoundManager():AddSound(pl, data.spawnX, data.spawnY, data.spawnZ, soundRadius, soundRadius)
    
    -- Track stats
    data.totalSoundWaves = data.totalSoundWaves + 1
    if soundRadius > data.maxSoundRadius then
        data.maxSoundRadius = soundRadius
    end
    
    print(string.format("SpawnChunk_Spawner: Sound wave emitted - radius: %d tiles (wave #%d)", 
        soundRadius, data.totalSoundWaves))
end

-----------------------  ZOMBIE SPAWNING SYSTEM  ---------------------------

function SpawnChunk.spawnZombies(count, data, pl)
    local spawnX, spawnY = data.spawnX, data.spawnY
    local size = data.boundarySize
    
    -- Check debug spawn option (separate from general debug mode)
    local debugCloseSpawn = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.DebugCloseSpawn) or false

    for i = 1, count do
        print(string.format("SpawnChunk_Spawner: Spawning zombie %d of %d", i, count))
        local x, y
        
        if debugCloseSpawn then
            -- DEBUG MODE: Spawn 5 tiles from player for testing
            local playerX = math.floor(pl:getX())
            local playerY = math.floor(pl:getY())
            x = playerX + ZombRand(-5, 6)
            y = playerY + ZombRand(-5, 6)
            print("SpawnChunk_Spawner: DEBUG CLOSE SPAWN - 5 tiles from player")
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
            print(string.format("SpawnChunk_Spawner: Spawned at (%d,%d) - Total spawned this life: %d", 
                x, y, data.totalSpawned))
        else
            print(string.format("SpawnChunk_Spawner: ERROR - No valid square at (%d,%d)", x, y))
        end
    end
end

-----------------------  EVENT HOOKS  ---------------------------

-- Run check every in-game minute
Events.EveryOneMinute.Add(SpawnChunk.ensureMinimumZombies)