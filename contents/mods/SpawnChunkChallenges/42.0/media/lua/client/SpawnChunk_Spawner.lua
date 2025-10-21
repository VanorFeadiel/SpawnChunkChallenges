-- SpawnChunk_Spawner.lua
-- Ensures a minimum zombie presence near the spawn chunk (modular)

SpawnChunk = SpawnChunk or {}

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

    -- Check if boundary has been scanned for outdoor status
    -- This flag persists and is only reset on death (for future additive chunks feature)
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
        
        -- Scan entire boundary perimeter (all 4 edges)
        local size = data.boundarySize
        
        -- Top and bottom edges (full width)
        for x = data.spawnX - size, data.spawnX + size do
            -- Top edge
            local square = getCell():getGridSquare(x, data.spawnY - size, data.spawnZ)
            if square then
                tilesChecked = tilesChecked + 1
                -- Check if square has no roof (outdoors)
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
        
        -- Store results
        data.isOutdoors = isOutdoors
        data.boundaryOutdoorsChecked = true
        print(string.format("SpawnChunk_Spawner: Boundary scan complete - %d tiles checked, %d outdoor tiles found, Result: %s", 
            tilesChecked, outdoorTilesFound, isOutdoors and "OUTDOORS" or "INDOORS"))
    end
    
    -- Calculate search radius based on stored outdoor status
    -- Shout range: ~70 tiles outdoors, ~25 tiles indoors (walls block sound)
    local shoutRange = data.isOutdoors and 65 or 25
    local searchRadius = data.boundarySize + shoutRange
    
    print(string.format("SpawnChunk_Spawner: Boundary is %s, using shout range: %d tiles", 
        data.isOutdoors and "OUTDOORS" or "INDOORS", shoutRange))
    local nearbyZeds = getCell():getZombieList()
    local count = 0
    local totalInCell = 0
    
    for i = 0, nearbyZeds:size() - 1 do
        local z = nearbyZeds:get(i)
        if z and not z:isDead() then
            totalInCell = totalInCell + 1
            -- Check if zombie is within search radius of spawn point
            local zx = z:getX()
            local zy = z:getY()
            local dx = math.abs(zx - data.spawnX)
            local dy = math.abs(zy - data.spawnY)
            if dx <= searchRadius and dy <= searchRadius then
                count = count + 1
            end
        end
    end

    print(string.format("SpawnChunk_Spawner: Checking zombie population for spawn, nearby population: %d (total in cell: %d, search radius: %d)", 
        count, totalInCell, searchRadius))

    -- Get minimum zombies from sandbox options
    local minZeds = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.MinZombies) or 1
    print(string.format("SpawnChunk_Spawner: Minimum zombies setting: %d", minZeds))
    
    if count >= minZeds then 
        print(string.format("SpawnChunk_Spawner: Population sufficient (%d >= %d), no spawn needed", count, minZeds))
        return 
    end

    local needed = minZeds - count
    print(string.format("SpawnChunk_Spawner: Need to spawn %d zombies", needed))
    local spawnX, spawnY = data.spawnX, data.spawnY
    local size = data.boundarySize
    
    -- Check if debug mode is enabled for close spawning
    local debugMode = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.DebugMode) or false

    for i = 1, needed do
        print(string.format("SpawnChunk_Spawner: Attempting to spawn zombie %d of %d", i, needed))
        local x, y
        
        if debugMode then
            -- DEBUG MODE: Spawn close to player for testing
            local playerX = math.floor(pl:getX())
            local playerY = math.floor(pl:getY())
            x = playerX + ZombRand(-5, 6)
            y = playerY + ZombRand(-5, 6)
            print("SpawnChunk_Spawner: DEBUG MODE - Spawning close to player")
        elseif size <= 10 then
            -- Fallback: spawn within 30x30 centered on spawn (safe in small chunks)
            x = spawnX + ZombRand(-15, 16)
            y = spawnY + ZombRand(-15, 16)
        else
            -- Spawn 20 tiles outside the boundary (within shout range, accounting for fog)
            local spawnOffset = size + 20
            if ZombRand(2) == 0 then
                -- outside left/right edges
                x = spawnX + spawnOffset * (ZombRand(2) == 0 and -1 or 1)
                y = spawnY + ZombRand(-size, size + 1)
            else
                -- outside top/bottom edges
                x = spawnX + ZombRand(-size, size + 1)
                y = spawnY + spawnOffset * (ZombRand(2) == 0 and -1 or 1)
            end
        end

        -- Try multiple spawning methods for reliability
        local spawned = false
        
        -- Method 1: Try addZombiesInOutfit
        local square = getCell():getGridSquare(x, y, pl:getZ())
        if square then
            addZombiesInOutfit(x, y, pl:getZ(), 1, nil, nil)
            spawned = true
            print(string.format("SpawnChunk_Spawner: Method 1 (addZombiesInOutfit) - Spawned at (%d,%d), Player at (%d,%d)", 
                x, y, math.floor(pl:getX()), math.floor(pl:getY())))
        else
            print(string.format("SpawnChunk_Spawner: ERROR - No valid square at (%d,%d)", x, y))
        end
        
        -- Method 2: If in debug mode and method 1 didn't work, try createZombieInOutfit
        if debugMode and not spawned then
            local zombie = createZombieInOutfit("Naked", x, y, pl:getZ(), nil)
            if zombie then
                spawned = true
                print(string.format("SpawnChunk_Spawner: Method 2 (createZombieInOutfit) - Spawned at (%d,%d)", x, y))
            else
                print("SpawnChunk_Spawner: ERROR - createZombieInOutfit failed")
            end
        end
    end

    print(string.format("SpawnChunk_Spawner: Ensured minimum zombies, attempted to spawn %d", needed))
end

-- Run check every in-game minute (non-invasive, respects existing init/death/reset flows)
Events.EveryOneMinute.Add(SpawnChunk.ensureMinimumZombies)
