-- SpawnChunk_Progress.lua
-- Track challenge progress and completion
-- CHARACTER-SPECIFIC via getData()
--modversion=0.3.2.028

SpawnChunk = SpawnChunk or {}

-----------------------  KILL TRACKING  ---------------------------

function SpawnChunk.onZombieDead(zombie)
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    local username = SpawnChunk.getUsername()
    
    -- CHUNK MODE: Track kills per chunk
    if data.chunkMode then
        -- Detect which chunk the player is currently in
        local playerX = math.floor(pl:getX())
        local playerY = math.floor(pl:getY())
        local playerChunkKey = SpawnChunk.getChunkKeyFromPosition(playerX, playerY, data)
        
        -- Check if player is in an unlocked or available chunk
        local playerChunkData = data.chunks and data.chunks[playerChunkKey]
        if not playerChunkData then
            -- Player is in an invalid chunk, don't count kill
            print("[" .. username .. "] Kill in invalid chunk " .. playerChunkKey .. ", not counted")
            return
        end
        
        -- Check if chunk is unlocked (unlock happens automatically when player enters - see SpawnChunk_ChunkEntry.lua)
        if not playerChunkData.unlocked then
            -- Player is in a locked chunk, don't count kill
            print("[" .. username .. "] Kill in locked chunk " .. playerChunkKey .. ", not counted")
            return
        end
        
        -- Check if this chunk is already completed
        if playerChunkData.completed then
            print("[" .. username .. "] Kill in completed chunk " .. playerChunkKey .. ", not counted")
            return
        end
        
        -- Update current chunk if player moved to a different one
        if playerChunkKey ~= data.currentChunk then
            print("[" .. username .. "] Switched to chunk " .. playerChunkKey)
            data.currentChunk = playerChunkKey
            
            -- Reset sound system when switching chunks
            data.currentSoundRadius = 0
            data.lastClosestZombieDistance = nil
            data.consecutiveNonApproachingWaves = 0
            print("[" .. username .. "] Sound system reset for new chunk")
        end
        
        -- === PURGE ONLY: Apply kill location rule ===
        if data.challengeType == "Purge" then
            local killLocationRule = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.KillLocationRule) or 1
            
            -- Only check additional rules for Options 2-4 (Option 1 is current default behavior)
            if killLocationRule ~= 1 then
                -- Get zombie location
                local zombieX = math.floor(zombie:getX())
                local zombieY = math.floor(zombie:getY())
                local zombieChunkKey = SpawnChunk.getChunkKeyFromPosition(zombieX, zombieY, data)
                
                local shouldCountKill = false
                
                if killLocationRule == 2 then
                    -- Option 2: Zombie must be in current active chunk
                    -- Player can be anywhere in unlocked area, but zombie must die in active chunk
                    shouldCountKill = (zombieChunkKey == data.currentChunk)
                    
                    if not shouldCountKill then
                        print("[" .. username .. "] [Rule 2] Kill not counted - zombie in chunk " .. zombieChunkKey .. ", need chunk " .. data.currentChunk)
                    end
                    
                elseif killLocationRule == 3 then
                    -- Option 3: Either player OR zombie must be in current active chunk
                    -- Flexible rule - works if either is in the active chunk
                    local playerInCurrent = (playerChunkKey == data.currentChunk)
                    local zombieInCurrent = (zombieChunkKey == data.currentChunk)
                    shouldCountKill = (playerInCurrent or zombieInCurrent)
                    
                    if not shouldCountKill then
                        print("[" .. username .. "] [Rule 3] Kill not counted - player in " .. playerChunkKey .. ", zombie in " .. zombieChunkKey .. ", need " .. data.currentChunk)
                    end
                    
                elseif killLocationRule == 4 then
                    -- Option 4: Anywhere - always count kills
                    -- Most permissive mode, kills count regardless of location
                    shouldCountKill = true
                end
                
                -- If kill doesn't meet the location rule, don't count it
                if not shouldCountKill then
                    return
                end
            end
            -- Option 1 (default): Player is already validated to be in unlocked chunk above
        end
        
        -- Increment kill counter for the chunk player is in
        playerChunkData.killCount = playerChunkData.killCount + 1
        
        print("[" .. username .. "] Chunk " .. playerChunkKey .. " - Kill " .. playerChunkData.killCount .. " / " .. playerChunkData.killTarget)
        
		-- Show progress notification every 5 kills (PURGE ONLY)
        if data.challengeType == "Purge" and playerChunkData.killCount % 5 == 0 then
            pl:setHaloNote("Chunk " .. playerChunkKey .. " - Kills: " .. playerChunkData.killCount .. " / " .. playerChunkData.killTarget, 100, 255, 100, 150)
        end
        
        -- Check for chunk completion using challenge-specific logic
        if SpawnChunk.isChunkCompleted() then
            SpawnChunk.onChunkComplete(playerChunkKey)
        end
    else
        -- CLASSIC MODE: Track kills globally
        if data.isComplete then return end
        
        -- === PURGE ONLY: Apply kill location rule ===
        if data.challengeType == "Purge" then
            local killLocationRule = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.KillLocationRule) or 1
            
            -- In classic mode, Option 2-4 don't make much sense since there's only one area
            -- But we'll implement Option 4 as "always count" for consistency
            if killLocationRule == 4 then
                -- Always count in Option 4 (no boundary check)
                -- Skip the normal boundary validation
            else
                -- Options 1-3: Use normal boundary validation (player must be in bounds)
                local playerX = math.floor(pl:getX())
                local playerY = math.floor(pl:getY())
                
                if not SpawnChunk.isInBounds(playerX, playerY) then
                    print("[" .. username .. "] [Classic] Kill outside boundary, not counted")
                    return
                end
            end
        end
        
        -- Increment kill counter
        data.killCount = data.killCount + 1
        
        print("[" .. username .. "] Kill " .. data.killCount .. " / " .. data.killTarget)
        
		-- Show progress notification every 5 kills (PURGE ONLY)
        if data.challengeType == "Purge" and data.killCount % 5 == 0 then
            pl:setHaloNote("Kills: " .. data.killCount .. " / " .. data.killTarget, 100, 255, 100, 150)
        end
        
        -- Check for victory using challenge-specific logic
        if SpawnChunk.isChunkCompleted() then
            SpawnChunk.onVictory()
        end
    end
end

-- Hook into zombie death event
Events.OnZombieDead.Add(SpawnChunk.onZombieDead)

-----------------------  CHUNK COMPLETION  ---------------------------

function SpawnChunk.onChunkComplete(chunkKey)
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    local username = SpawnChunk.getUsername()
    
    -- Mark chunk as completed
    SpawnChunk.completeChunk(chunkKey)
    
    print("[" .. username .. "] === CHUNK COMPLETE! ===")
    print("[" .. username .. "] Completed: " .. chunkKey)
    
    -- Play completion sound
    pl:playSound("LevelUp")
    
    -- Show completion message
    local unlockPattern = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ChunkUnlockPattern) or 1
    local message = unlockPattern == 1 and 
        "Chunk " .. chunkKey .. " Complete! Walk to an adjacent chunk to unlock it!" or
        "Chunk " .. chunkKey .. " Complete! Adjacent chunks unlocked!"
    pl:setHaloNote(message, 100, 255, 100, 300)
    
    -- Give reward items
    local inv = pl:getInventory()
    inv:AddItem("Base.WaterBottleFull")
    --inv:AddItem("Base.Bandage")  --commented out for now keep in code as extra example.
    
    -- === NEW LOGIC: Scan ALL completed chunks and make their unlocked neighbors available ===
    -- This prevents the player from getting stuck when surrounded by completed chunks
    local newChunksUnlocked = 0
    
    if data.chunks then
        -- Iterate through ALL chunks
        for scanChunkKey, scanChunkData in pairs(data.chunks) do
            -- Only process completed (green) chunks
            if scanChunkData.completed then
                -- Get the 4 cardinal neighbors of this completed chunk
                local adjacentChunks = SpawnChunk.getAdjacentChunks(scanChunkKey)
                
                for direction, adjacentKey in pairs(adjacentChunks) do
                    local adjacentData = SpawnChunk.getChunkData(adjacentKey)
                    
                    -- Only make available if the chunk is NOT already:
                    -- - unlocked (yellow/green)
                    -- - available (blue)
                    -- - completed (green)
                    local shouldMakeAvailable = not adjacentData or 
                        (not adjacentData.unlocked and not adjacentData.available and not adjacentData.completed)
                    
                    if shouldMakeAvailable then
                        local newChunk
                        
                        if unlockPattern == 1 then
                            -- Pattern 1 (Cardinal): Mark as available (blue)
                            newChunk = SpawnChunk.makeChunkAvailable(adjacentKey)
                        else
                            -- Pattern 2 (All Adjacent): Unlock immediately  
                            newChunk = SpawnChunk.unlockChunk(adjacentKey)
                        end
                        
                        -- Initialize chunk data based on challenge type
                        if data.challengeType == "Purge" then
                            -- PURGE CHALLENGE: Calculate kill target for new chunk
                            local cell = getCell()
                            local zombieList = cell and cell:getZombieList()
                            local totalZombies = zombieList and zombieList:size() or 100
                            local baseTarget = math.floor(totalZombies / 9)
                            
                            local boundarySize = data.boundarySize
                            local boundaryArea = (boundarySize * 2 + 1) * (boundarySize * 2 + 1)
                            local baselineArea = 101 * 101
                            local areaMultiplier = boundaryArea / baselineArea
                            
                            local killMultiplier = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.KillMultiplier) or 1.0
                            local target = math.floor(baseTarget * areaMultiplier * killMultiplier)
                            if target < 5 then target = 5 end
                            
                            newChunk.killTarget = target
                            newChunk.killCount = 0
                            
                            print("[" .. username .. "] Made chunk available: " .. adjacentKey .. " (beside completed " .. scanChunkKey .. ") - Kill target: " .. target)
                            
                        elseif data.challengeType == "Time" then
                            -- TIME CHALLENGE: Set time target for new chunk
                            newChunk.timeHours = 0
                            newChunk.timeTarget = data.timeTarget or 12
                            
                            -- Set kill fields to 0 (not used, but kept for compatibility)
                            newChunk.killTarget = 0
                            newChunk.killCount = 0
                            
                            print("[" .. username .. "] Made chunk available: " .. adjacentKey .. " (beside completed " .. scanChunkKey .. ") - Time target: " .. newChunk.timeTarget .. " hours")
                            
                        elseif data.challengeType == "ZeroToHero" then
                            -- ZERO TO HERO: Uses banking system, doesn't need per-chunk tracking
                            -- Set fields to 0 for compatibility
                            newChunk.killTarget = 0
                            newChunk.killCount = 0
                            newChunk.timeHours = 0
                            newChunk.timeTarget = 0
                            
                            print("[" .. username .. "] Made chunk available: " .. adjacentKey .. " (beside completed " .. scanChunkKey .. ") - Zero to Hero (banking)")
                        end
                        
                        newChunksUnlocked = newChunksUnlocked + 1
                    end
                end
            end
        end
    end
    
    print("[" .. username .. "] Made " .. newChunksUnlocked .. " chunk(s) available (beside ALL completed chunks)")
    
    -- Force immediate marker refresh to show available chunks (especially for Time/ZtH)
    if data.challengeType ~= "Purge" then
        -- Non-Purge challenges: Immediately mark for recreation (no delay needed without spawner)
        data.markersCreated = false
        data.mapSymbolCreated = false
    end
    
    -- Reset sound system when switching to new chunks
    data.currentSoundRadius = 0
    data.lastClosestZombieDistance = nil
    data.consecutiveNonApproachingWaves = 0
    
    -- Recreate visual markers immediately to show completed/unlocked chunks
    data.markersCreated = false
    data.mapSymbolCreated = false
    
    -- Remove old markers first
    if SpawnChunk.removeGroundMarkers then
        SpawnChunk.removeGroundMarkers()
    end
    if SpawnChunk.removeMapSymbol then
        SpawnChunk.removeMapSymbol()
    end
    
    -- Recreate markers with minimal delay (lag issue fixed, so can be faster now)
    local timer = 0
    local groundMarkersCreated = false
    
    local function recreateVisuals()
        timer = timer + 1
        
        -- Create ground markers first (after 5 ticks = 0.15 seconds)
        if timer >= 5 and not groundMarkersCreated then
            if SpawnChunk.createGroundMarkers then
                SpawnChunk.createGroundMarkers()
                print("[" .. username .. "] Ground markers recreated after chunk completion")
                groundMarkersCreated = true
            end
        end
        
        -- Create map symbols after ground markers (after 15 ticks = 0.5 seconds total)
        if timer >= 15 then
            if SpawnChunk.addMapSymbol then
                SpawnChunk.addMapSymbol()
                data.mapSymbolCreated = true
                print("[" .. username .. "] Map symbols recreated after chunk completion")
            end
            Events.OnTick.Remove(recreateVisuals)
        end
    end
    Events.OnTick.Add(recreateVisuals)
end

-----------------------  VICTORY CONDITION  ---------------------------

function SpawnChunk.onVictory()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if data.isComplete then return end -- Already won
    
    local username = SpawnChunk.getUsername()
    print("[" .. username .. "] === VICTORY! ===")
    
    -- Mark as complete
    data.isComplete = true
    
    -- Play victory sound
    pl:playSound("LevelUp")
    
    -- Show victory message
    pl:setHaloNote("CHALLENGE COMPLETE! You are free to explore!", 100, 255, 100, 500)
    
    -- Give victory item (a note)
    local inv = pl:getInventory()
    local item = inv:AddItem("Base.Book") -- Using vanilla book as placeholder
    if item then
        item:setName("Purge Completion Certificate")
        -- Note: Custom items would require items.txt definition
        print("[" .. username .. "] Victory item awarded")
    end
    
    -- Optional: Give reward items
    inv:AddItem("Base.Axe")
    inv:AddItem("Base.Antibiotics")
    inv:AddItem("Base.WaterBottleFull")
    
    print("[" .. username .. "] You can now leave the spawn area!")
end

-----------------------  UI DISPLAY  ---------------------------

function SpawnChunk.getProgressString()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return "" end
    
    if data.chunkMode then
        local currentChunkData = data.chunks and data.chunks[data.currentChunk]
        if not currentChunkData then return "" end
        if currentChunkData.completed then return "Chunk " .. data.currentChunk .. " Complete!" end
        
        return "Chunk " .. data.currentChunk .. " - Kills: " .. currentChunkData.killCount .. " / " .. currentChunkData.killTarget
    else
        if data.isComplete then return "Challenge Complete!" end
        return "Kills: " .. data.killCount .. " / " .. data.killTarget
    end
end

-- Optional: Add UI display (would need ISUIElement implementation)
-- For now, progress shown via periodic notifications
