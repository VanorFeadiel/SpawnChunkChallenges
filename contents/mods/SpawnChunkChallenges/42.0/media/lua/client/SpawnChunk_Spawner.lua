-- SpawnChunk_Spawner.lua
-- Hybrid spawn/sound attraction system with debug tracking
-- CHARACTER-SPECIFIC via getData()

SpawnChunk = SpawnChunk or {}

-----------------------  OBJECT ANALYSIS HELPERS  ---------------------------

-- Determine if an object is opaque (blocks vision) or transparent
function SpawnChunk.isObjectOpaque(obj)
    if not obj then return false end
    
    local objectName = obj:getObjectName() or ""
    local spriteName = obj:getSprite() and obj:getSprite():getName() or ""
    
    -- Check for transparent/see-through objects
    local transparentKeywords = {
        "chainlink", "chain link", "wire", "metal fence", "fence metal",
        "window", "glass", "bars", "iron bars", "railing"
    }
    
    for _, keyword in ipairs(transparentKeywords) do
        if string.find(string.lower(objectName), keyword) or 
           string.find(string.lower(spriteName), keyword) then
            return false  -- Transparent
        end
    end
    
    -- Opaque by default (wooden fences, walls, doors, etc.)
    return true
end

-- Get detailed object information for logging
function SpawnChunk.getObjectInfo(obj)
    if not obj then return "Unknown" end
    
    local objectName = obj:getObjectName() or "Unknown"
    local spriteName = obj:getSprite() and obj:getSprite():getName() or "Unknown"
    local isOpaque = SpawnChunk.isObjectOpaque(obj)
    
    return {
        name = objectName,
        sprite = spriteName,
        opaque = isOpaque,
        displayName = objectName .. (isOpaque and " (Opaque)" or " (Transparent)")
    }
end

-----------------------  ZOMBIE ATTACK DETECTION  ---------------------------

function SpawnChunk.checkZombieAttacking(closestZombie, data)
    local username = SpawnChunk.getUsername()
    
    if not closestZombie then
        -- No zombie, clear attack data
        data.attackTargetName = nil
        data.attackTargetHealth = nil
        data.attackTargetMaxHealth = nil
        data.attackTargetObject = nil
        data.lastAttackTargetHealth = nil
        data.damageThisCycle = nil
        data.attackLogCounter = 0
        data.zombieAttackingStructure = false
        return
    end
    
    local targetDetected = false
    local zombieTarget = nil
    local targetName = "Unknown"
    local targetHealth = nil
    local targetMaxHealth = nil
    local zombieAttackingStructure = false
    
    -- METHOD 1: Check zombie's direct target
    zombieTarget = closestZombie:getTarget()
    if zombieTarget and not instanceof(zombieTarget, "IsoPlayer") and not instanceof(zombieTarget, "IsoZombie") then
        targetDetected = true
        zombieAttackingStructure = true
        
        -- Get target information
        targetName = zombieTarget:getObjectName() or "Structure"
        
        -- Try different methods to get health depending on object type
        if instanceof(zombieTarget, "IsoThumpable") then
            targetHealth = zombieTarget:getHealth()
            targetMaxHealth = zombieTarget:getMaxHealth()
        elseif zombieTarget.getHealth then
            targetHealth = zombieTarget:getHealth()
            if zombieTarget.getMaxHealth then
                targetMaxHealth = zombieTarget:getMaxHealth()
            end
        end
    end
    
    -- METHOD 2: Check if zombie is thumping (attacking animation/state)
    local isThumpingState = closestZombie:isCurrentState(ThumpState.instance())
    if isThumpingState then
        zombieAttackingStructure = true
        
        -- If we don't have a target from Method 1, try to find what they're attacking
        if not targetDetected then
            -- Get thump target from zombie's current state
            local thumpTarget = closestZombie:getThumpTarget()
            if thumpTarget then
                targetDetected = true
                zombieTarget = thumpTarget
                targetName = thumpTarget:getObjectName() or "Structure"
                
                if instanceof(thumpTarget, "IsoThumpable") then
                    targetHealth = thumpTarget:getHealth()
                    targetMaxHealth = thumpTarget:getMaxHealth()
                elseif thumpTarget.getHealth then
                    targetHealth = thumpTarget:getHealth()
                    if thumpTarget.getMaxHealth then
                        targetMaxHealth = thumpTarget:getMaxHealth()
                    end
                end
            else
                -- Thumping but can't identify target
                targetName = "Unknown Structure"
            end
        end
    end
    
    -- METHOD 3: Check zombie's path target (might be trying to get through something)
    if not targetDetected then
        local pathTarget = closestZombie:getPathTargetX()
        if pathTarget then
            -- Zombie has a path blocked, might be attacking obstacle
            -- Check if zombie is close to any thumpable objects
            local zx = closestZombie:getX()
            local zy = closestZombie:getY()
            local zz = closestZombie:getZ()
            local square = getCell():getGridSquare(zx, zy, zz)
            
            if square then
                -- Check for thumpable objects in adjacent squares
                for dx = -1, 1 do
                    for dy = -1, 1 do
                        local checkSquare = getCell():getGridSquare(zx + dx, zy + dy, zz)
                        if checkSquare then
                            local objects = checkSquare:getObjects()
                            for i = 0, objects:size() - 1 do
                                local obj = objects:get(i)
                                if obj and instanceof(obj, "IsoThumpable") then
                                    -- Found a thumpable object nearby
                                    local thumpObj = obj
                                    if thumpObj:canBeDamaged() then
                                        targetDetected = true
                                        zombieTarget = thumpObj
                                        targetName = thumpObj:getObjectName() or "Structure"
                                        targetHealth = thumpObj:getHealth()
                                        targetMaxHealth = thumpObj:getMaxHealth()
                                        -- Don't break, keep checking for closer objects
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Store attack info if we found a target
    if targetDetected or zombieAttackingStructure then
        -- Get detailed object information
        local objectInfo = SpawnChunk.getObjectInfo(zombieTarget)
        
        data.attackTargetName = targetName
        data.attackTargetHealth = targetHealth
        data.attackTargetMaxHealth = targetMaxHealth
        data.attackTargetObject = zombieTarget
        data.attackTargetOpaque = objectInfo.opaque  -- NEW: Track if opaque
        data.attackTargetInfo = objectInfo           -- NEW: Full object info
        data.zombieAttackingStructure = true
        
        -- Track health over time to detect actual damage
        local damageDealt = false
        if targetHealth then
            if not data.lastAttackTargetHealth then
                data.lastAttackTargetHealth = targetHealth
                data.damageThisCycle = false
            elseif targetHealth < data.lastAttackTargetHealth then
                -- Health decreased = actual damage!
                damageDealt = true
                data.damageThisCycle = true
                local damageTaken = data.lastAttackTargetHealth - targetHealth
                data.lastAttackTargetHealth = targetHealth
                print(string.format("[%s] ⚔ DAMAGE DEALT! %s took %.1f damage (%.0f / %.0f remaining)", 
                    username, targetName, damageTaken, targetHealth, targetMaxHealth or 0))
            else
                -- Health same or increased (shouldn't happen), no damage this cycle
                data.damageThisCycle = false
            end
        else
            -- No health info available
            data.damageThisCycle = nil  -- Unknown
        end
        
        -- Log attack detection (only log periodically to avoid spam)
        data.attackLogCounter = (data.attackLogCounter or 0) + 1
        if data.attackLogCounter % 10 == 1 then  -- Log every 10th check (every 10 seconds)
            print(string.format("[%s] Zombie attacking: %s (health: %s / %s) - Damage: %s", 
                username, targetName, 
                targetHealth and string.format("%.0f", targetHealth) or "?",
                targetMaxHealth and string.format("%.0f", targetMaxHealth) or "?",
                data.damageThisCycle == true and "YES" or (data.damageThisCycle == false and "NO" or "UNKNOWN")))
        end
    else
        -- No attack target, clear attack data
        data.attackTargetName = nil
        data.attackTargetHealth = nil
        data.attackTargetMaxHealth = nil
        data.attackTargetObject = nil
        data.lastAttackTargetHealth = nil
        data.damageThisCycle = nil
        data.attackLogCounter = 0
        data.zombieAttackingStructure = false
    end
end

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
    
    -- CHUNK MODE: Check if current chunk is completed
    if data.chunkMode and data.currentChunk then
        local currentChunkData = SpawnChunk.getChunkData(data.currentChunk)
        if currentChunkData and currentChunkData.completed then
            -- Current chunk is completed, stop spawning until player enters new chunk
            print("[" .. username .. "] Current chunk completed, spawning paused until new chunk entered")
            return
        end
    end
    
    -- Check if spawn delay is active (for new chunks) - using in-game time
    if data.spawnDelayUntil then
        local gameTime = getGameTime()
        local currentMinutes = gameTime:getWorldAgeHours() * 60  -- Convert hours to minutes
        
        if currentMinutes < data.spawnDelayUntil then
            -- Still in delay period, don't spawn/attract
            return
        else
            -- Delay period ended
            data.spawnDelayUntil = nil
            print("[" .. username .. "] Spawn delay ended (in-game time), spawning system now active")
        end
    end

    -- Initialize debug tracking if not present
    data.totalSpawned = data.totalSpawned or 0
    data.totalSoundWaves = data.totalSoundWaves or 0
    data.maxSoundRadius = data.maxSoundRadius or 0
    
    -- Initialize zombie tracking for movement detection
    data.lastClosestZombieDistance = data.lastClosestZombieDistance or nil
    data.currentSoundRadius = data.currentSoundRadius or 0
    data.consecutiveNonApproachingWaves = data.consecutiveNonApproachingWaves or 0

    -- Get reference point (spawn point in classic mode, current chunk center in chunk mode)
    local refX, refY, refZ
    if data.chunkMode and data.currentChunk then
        refX, refY = SpawnChunk.getChunkCenter(data.currentChunk, data)
        refZ = data.spawnZ
        if not refX or not refY then
            -- Fallback to spawn if chunk center calculation fails
            print("[" .. username .. "] WARNING: getChunkCenter returned nil, using spawn point as fallback")
            refX, refY, refZ = data.spawnX, data.spawnY, data.spawnZ
        end
    else
        refX, refY, refZ = data.spawnX, data.spawnY, data.spawnZ
    end
    
    -- Final safety check
    if not refX or not refY or not refZ then
        print("[" .. username .. "] ERROR: Invalid reference coordinates, cannot process spawner")
        return
    end

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
        for x = refX - size, refX + size do
            -- Top edge
            local square = getCell():getGridSquare(x, refY - size, refZ)
            if square then
                tilesChecked = tilesChecked + 1
                if not square:hasFloor() and not square:HasStairs() then
                    isOutdoors = true
                    outdoorTilesFound = outdoorTilesFound + 1
                end
            end
            
            -- Bottom edge
            square = getCell():getGridSquare(x, refY + size, refZ)
            if square then
                tilesChecked = tilesChecked + 1
                if not square:hasFloor() and not square:HasStairs() then
                    isOutdoors = true
                    outdoorTilesFound = outdoorTilesFound + 1
                end
            end
        end
        
        -- Left and right edges (exclude corners already checked)
        for y = refY - size + 1, refY + size - 1 do
            -- Left edge
            local square = getCell():getGridSquare(refX - size, y, refZ)
            if square then
                tilesChecked = tilesChecked + 1
                if not square:hasFloor() and not square:HasStairs() then
                    isOutdoors = true
                    outdoorTilesFound = outdoorTilesFound + 1
                end
            end
            
            -- Right edge
            square = getCell():getGridSquare(refX + size, y, refZ)
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
    local zombiesInChunk = 0  -- Zombies within chunk boundary (for minZeds check)
    local zombiesInSearchRadius = 0  -- Zombies within search radius (for tracking)
    local totalInCell = 0
    local closestZombieDistance = nil
    local closestZombieFromPlayer = nil
    local closestZombie = nil
    
    for i = 0, nearbyZeds:size() - 1 do
        local z = nearbyZeds:get(i)
        if z and not z:isDead() then
            totalInCell = totalInCell + 1
            local zx = z:getX()
            local zy = z:getY()
            
            -- Distance from chunk center (for sound/spawn logic)
            local dx = math.abs(zx - refX)
            local dy = math.abs(zy - refY)
            local distance = math.sqrt(dx * dx + dy * dy)
            
            -- Distance from player (for debug display)
            local playerDx = math.abs(zx - pl:getX())
            local playerDy = math.abs(zy - pl:getY())
            local playerDistance = math.sqrt(playerDx * playerDx + playerDy * playerDy)
            
            -- Count zombies within chunk boundary
            if distance <= data.boundarySize then
                zombiesInChunk = zombiesInChunk + 1
            end
            
            -- Count zombies within search radius (for tracking)
            if dx <= searchRadius and dy <= searchRadius then
                zombiesInSearchRadius = zombiesInSearchRadius + 1
            end
            
            -- Track closest zombie (from chunk center)
            if not closestZombieDistance or distance < closestZombieDistance then
                closestZombieDistance = distance
                closestZombieFromPlayer = playerDistance
                closestZombie = z
            end
        end
    end
    
    -- Store closest zombie distance from player for HUD display
    data.closestZombieFromPlayer = closestZombieFromPlayer

    local minZeds = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.MinZombies) or 1
    
    -- ALWAYS check for attacking zombies (moved BEFORE early return)
    SpawnChunk.checkZombieAttacking(closestZombie, data)
    
    -- Only return early if we have enough zombies INSIDE the chunk
    if zombiesInChunk >= minZeds then 
        return 
    end

    local needed = minZeds - zombiesInChunk
    
    -- SMART SOUND SYSTEM:
    -- Determine when to start sound based on outdoor status
    local effectiveYellRange = data.isOutdoors and 20 or 10
    local soundTriggerDistance = data.boundarySize + effectiveYellRange + 1
    
    -- Check if we need to start or adjust sound waves
    local shouldEmitSound = false
    local zombieApproaching = false
    local zombieAttackingStructure = data.zombieAttackingStructure or false
    
    if closestZombieDistance then
        -- Check if zombie is beyond effective yell range
        if closestZombieDistance > soundTriggerDistance then
            -- Check if zombie is getting closer
            if data.lastClosestZombieDistance then
                zombieApproaching = closestZombieDistance < data.lastClosestZombieDistance
            end
            
            -- Emit sound if: no previous sound OR zombie not approaching (and not attacking structure)
            if data.currentSoundRadius == 0 or (not zombieApproaching and not zombieAttackingStructure) then
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
        -- Track consecutive non-approaching waves (zombie might be stuck behind obstacle)
        -- NEW: Only reset if zombie is ACTUALLY making progress (dealing damage), not just attacking
        local zombieMakingProgress = false
        
        if zombieApproaching then
            -- Zombie is getting closer = making progress
            zombieMakingProgress = true
        elseif zombieAttackingStructure and data.damageThisCycle == true then
            -- Zombie is attacking AND actually dealing damage = making progress
            zombieMakingProgress = true
        elseif zombieAttackingStructure and data.damageThisCycle == nil then
            -- Zombie attacking but no health data (indestructible structure) = STUCK!
            -- Don't count as progress
            print(string.format("[%s] Zombie attacking indestructible structure (no damage possible)", username))
        end
        
        if not zombieMakingProgress then
            -- Zombie not making progress = potentially stuck
            data.consecutiveNonApproachingWaves = data.consecutiveNonApproachingWaves + 1
        else
            -- Reset counter only if zombie is making actual progress
            data.consecutiveNonApproachingWaves = 0
            
            -- Clear ALL stuck zombie tracking (zombie is making progress!)
            for dir, stuckInfo in pairs(data.stuckZombiesByDirection) do
                if stuckInfo.zombie == closestZombie then
                    print(string.format("[%s] Zombie from %s direction is making progress, clearing stuck status", username, dir))
                    SpawnChunk.clearStuckZombie(dir, data)
                end
            end
        end
        
        -- Check if zombie is likely stuck (e.g., behind fence, in building, etc.)
        local STUCK_THRESHOLD = 10  -- 10 minutes of non-approaching = likely stuck
        if data.consecutiveNonApproachingWaves >= STUCK_THRESHOLD then
            print(string.format("[%s] Zombie appears stuck after %d sound waves (distance: %.1f)", 
                username, data.consecutiveNonApproachingWaves, closestZombieDistance or 0))
            
            -- Get next spawn direction (rotate through N, E, S, W)
            local spawnDirection = SpawnChunk.getNextSpawnDirection(data)
            data.lastSpawnDirection = spawnDirection
            
            -- Track this stuck zombie by direction with exact position
            local stuckX, stuckY = nil, nil
            if closestZombie then
                stuckX = math.floor(closestZombie:getX())
                stuckY = math.floor(closestZombie:getY())
            end
            
            data.stuckZombiesByDirection[spawnDirection] = {
                zombie = closestZombie,
                isStuck = true,
                targetName = data.attackTargetName or "Unknown",
                targetOpaque = data.attackTargetOpaque or false,
                timestamp = os.time(),
                stuckX = stuckX,  -- NEW: Track exact position
                stuckY = stuckY   -- NEW: Track exact position
            }
            
            -- If zombie is stuck on OPAQUE object, despawn it first
            local shouldDespawn = false
            if data.attackTargetOpaque and closestZombie then
                shouldDespawn = true
                local despawned = SpawnChunk.despawnZombie(closestZombie, 
                    "Stuck on opaque object: " .. (data.attackTargetName or "Unknown"), data)
                
                if despawned then
                    print(string.format("[%s] Despawned stuck zombie on opaque %s", 
                        username, data.attackTargetName or "structure"))
                end
            else
                print(string.format("[%s] Keeping stuck zombie (transparent %s - visible)", 
                    username, data.attackTargetName or "structure"))
            end
            
            -- Spawn backup zombie in different direction
            print(string.format("[%s] Spawning backup zombie from %s direction", username, spawnDirection))
            SpawnChunk.spawnZombies(needed, data, pl, spawnDirection)
            
            -- Check if all 4 directions are now stuck
            data.challengeStuckFlag = SpawnChunk.checkChallengeStuck(data)
            
            if data.challengeStuckFlag then
                print(string.format("[%s] ⚠️ WARNING: All 4 cardinal directions have stuck zombies! Challenge may be impossible!", username))
            end
            
            -- DON'T reset counter - keep tracking for new zombie too!
            -- Only reset sound system
            data.currentSoundRadius = 0
            data.lastClosestZombieDistance = nil
        else
            -- Emit sound wave at reference point
            SpawnChunk.attractWithSound(data, pl, closestZombieDistance, zombieApproaching, refX, refY, refZ)
            
            -- Spawn 1 backup zombie if sound has been going for a while (but not stuck yet)
            if data.totalSoundWaves > 5 and data.consecutiveNonApproachingWaves < STUCK_THRESHOLD / 2 then
                print(string.format("[%s] Spawning 1 backup zombie (sound waves: %d)", username, data.totalSoundWaves))
                SpawnChunk.spawnZombies(1, data, pl)
            end
        end
    else
        -- Reset counter if we're not emitting sound (zombie might be close enough now)
        data.consecutiveNonApproachingWaves = 0
    end
end

-----------------------  SOUND ATTRACTION SYSTEM  ---------------------------

function SpawnChunk.attractWithSound(data, pl, closestZombieDistance, zombieApproaching, soundX, soundY, soundZ)
    local username = SpawnChunk.getUsername()
    
    -- Use provided coordinates, or fall back to spawn point
    soundX = soundX or data.spawnX
    soundY = soundY or data.spawnY
    soundZ = soundZ or data.spawnZ
    
    -- Safety check: ensure coordinates are valid numbers
    if not soundX or not soundY or not soundZ then
        print("[" .. username .. "] ERROR: Invalid sound coordinates, skipping sound emission")
        return
    end
    
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
    
    -- Emit sound at specified coordinates using Build 42 API
    -- Use addSound (global function) which is the standard PZ API for generating sound
    addSound(pl, soundX, soundY, soundZ, soundRadius, soundRadius)
    
    -- Track stats
    data.totalSoundWaves = data.totalSoundWaves + 1
    if soundRadius > data.maxSoundRadius then
        data.maxSoundRadius = soundRadius
    end
    
    print(string.format("[%s] Sound wave #%d emitted at (%.0f, %.0f) - radius: %d tiles, closest zombie: %.1f tiles", 
        username, data.totalSoundWaves, soundX, soundY, soundRadius, closestZombieDistance or 0))
end

-----------------------  DIRECTIONAL SPAWNING HELPERS  ---------------------------

-- Get next spawn direction (rotates through N, E, S, W)
function SpawnChunk.getNextSpawnDirection(data)
    local directions = {"north", "east", "south", "west"}
    local lastDir = data.lastSpawnDirection
    
    -- If no last direction, start with north
    if not lastDir then
        return "north"
    end
    
    -- Find current direction index
    local currentIndex = 1
    for i, dir in ipairs(directions) do
        if dir == lastDir then
            currentIndex = i
            break
        end
    end
    
    -- Get next direction (wrap around)
    local nextIndex = (currentIndex % 4) + 1
    return directions[nextIndex]
end

-- Check if all 4 cardinal directions have stuck zombies
function SpawnChunk.checkChallengeStuck(data)
    local stuckCount = 0
    local directions = {"north", "east", "south", "west"}
    
    for _, dir in ipairs(directions) do
        if data.stuckZombiesByDirection[dir] and 
           data.stuckZombiesByDirection[dir].isStuck then
            stuckCount = stuckCount + 1
        end
    end
    
    return stuckCount >= 4
end

-- Clear stuck zombie tracking for a direction (called when zombie makes progress or dies)
function SpawnChunk.clearStuckZombie(direction, data)
    if data.stuckZombiesByDirection[direction] then
        data.stuckZombiesByDirection[direction] = nil
        
        -- Recheck if challenge is still stuck
        data.challengeStuckFlag = SpawnChunk.checkChallengeStuck(data)
    end
end

-- Despawn a zombie (remove from world)
function SpawnChunk.despawnZombie(zombie, reason, data)
    if not zombie or zombie:isDead() then return false end
    
    local username = SpawnChunk.getUsername()
    local zx = math.floor(zombie:getX())
    local zy = math.floor(zombie:getY())
    
    print(string.format("[%s] Despawning zombie at (%d, %d) - Reason: %s", 
        username, zx, zy, reason))
    
    -- Remove from world
    zombie:removeFromWorld()
    zombie:removeFromSquare()
    
    return true
end

-----------------------  ZOMBIE SPAWNING SYSTEM  ---------------------------

function SpawnChunk.spawnZombies(count, data, pl, preferredDirection)
    -- In chunk mode, use current chunk center; otherwise use spawn point
    local spawnX, spawnY
    if data.chunkMode and data.currentChunk then
        spawnX, spawnY = SpawnChunk.getChunkCenter(data.currentChunk, data)
        if not spawnX then
            -- Fallback to original spawn if chunk center calculation fails
            spawnX, spawnY = data.spawnX, data.spawnY
        end
    else
        spawnX, spawnY = data.spawnX, data.spawnY
    end
    
    local size = data.boundarySize
    
    local username = SpawnChunk.getUsername()
    
    -- Check debug spawn option (separate from general debug mode)
    local debugCloseSpawn = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.DebugCloseSpawn) or false

    for i = 1, count do
        local direction = preferredDirection or "random"
        print(string.format("[%s] Spawning zombie %d of %d (direction: %s)", username, i, count, direction))
        local x, y
        
        if debugCloseSpawn then
            -- DEBUG MODE: Spawn 5 tiles from player for testing
            local playerX = math.floor(pl:getX())
            local playerY = math.floor(pl:getY())
            x = playerX + ZombRand(-5, 6)
            y = playerY + ZombRand(-5, 6)
            print("[" .. username .. "] DEBUG CLOSE SPAWN - 5 tiles from player")
        elseif preferredDirection then
            -- DIRECTIONAL SPAWN: Spawn in specific cardinal direction
            local spawnOffset = (size <= 20) and (size + ZombRand(5, 11)) or (size + 20)
            
            -- SMART SPREAD: Avoid previous stuck positions in this direction
            local spread = 0
            local stuckInfo = data.stuckZombiesByDirection[direction]
            
            if stuckInfo and stuckInfo.stuckX and stuckInfo.stuckY then
                -- Calculate where previous zombie got stuck relative to spawn center
                local stuckOffsetX = stuckInfo.stuckX - spawnX
                local stuckOffsetY = stuckInfo.stuckY - spawnY
                
                -- Spawn on OPPOSITE side of the edge
                if direction == "north" or direction == "south" then
                    -- North/South: spread is X-axis
                    if stuckOffsetX > 0 then
                        -- Stuck on right side, spawn on left
                        spread = ZombRand(-size, -size/2)
                        print(string.format("[%s] Previous stuck on RIGHT, spawning LEFT (spread: %d)", username, spread))
                    else
                        -- Stuck on left side, spawn on right
                        spread = ZombRand(size/2, size + 1)
                        print(string.format("[%s] Previous stuck on LEFT, spawning RIGHT (spread: %d)", username, spread))
                    end
                else
                    -- East/West: spread is Y-axis
                    if stuckOffsetY > 0 then
                        -- Stuck on bottom side, spawn on top
                        spread = ZombRand(-size, -size/2)
                        print(string.format("[%s] Previous stuck on BOTTOM, spawning TOP (spread: %d)", username, spread))
                    else
                        -- Stuck on top side, spawn on bottom
                        spread = ZombRand(size/2, size + 1)
                        print(string.format("[%s] Previous stuck on TOP, spawning BOTTOM (spread: %d)", username, spread))
                    end
                end
            else
                -- No previous stuck position, use full random spread
                spread = ZombRand(-size, size + 1)
            end
            
            -- Calculate spawn coordinates based on direction
            if direction == "north" then
                x = spawnX + spread
                y = spawnY - spawnOffset
            elseif direction == "south" then
                x = spawnX + spread
                y = spawnY + spawnOffset
            elseif direction == "east" then
                x = spawnX + spawnOffset
                y = spawnY + spread
            elseif direction == "west" then
                x = spawnX - spawnOffset
                y = spawnY + spread
            end
            
            print(string.format("[%s] Directional spawn: %s at offset %d, spread %d (position: %d, %d)", 
                username, direction, spawnOffset, spread, x or 0, y or 0))
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
