-- SpawnChunk_Kills.lua
-- Track zombie kills and check for victory
-- CHARACTER-SPECIFIC via getData()

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
        local currentChunkData = data.chunks and data.chunks[data.currentChunk]
        if not currentChunkData then return end
        if currentChunkData.completed then return end
        
        -- Increment kill counter for current chunk
        currentChunkData.killCount = currentChunkData.killCount + 1
        
        print("[" .. username .. "] Chunk " .. data.currentChunk .. " - Kill " .. currentChunkData.killCount .. " / " .. currentChunkData.killTarget)
        
        -- Show progress notification every 5 kills
        if currentChunkData.killCount % 5 == 0 then
            pl:setHaloNote("Chunk " .. data.currentChunk .. " - Kills: " .. currentChunkData.killCount .. " / " .. currentChunkData.killTarget, 100, 255, 100, 150)
        end
        
        -- Check for chunk completion
        if currentChunkData.killCount >= currentChunkData.killTarget then
            SpawnChunk.onChunkComplete(data.currentChunk)
        end
    else
        -- CLASSIC MODE: Track kills globally
        if data.isComplete then return end
        
        -- Increment kill counter
        data.killCount = data.killCount + 1
        
        print("[" .. username .. "] Kill " .. data.killCount .. " / " .. data.killTarget)
        
        -- Show progress notification every 5 kills
        if data.killCount % 5 == 0 then
            pl:setHaloNote("Kills: " .. data.killCount .. " / " .. data.killTarget, 100, 255, 100, 150)
        end
        
        -- Check for victory
        if data.killCount >= data.killTarget then
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
    pl:setHaloNote("Chunk " .. chunkKey .. " Complete! Adjacent chunks unlocked!", 100, 255, 100, 300)
    
    -- Give reward items
    local inv = pl:getInventory()
    inv:AddItem("Base.WaterBottleFull")
    inv:AddItem("Base.Bandage")
    
    -- Get adjacent chunks
    local adjacentChunks = SpawnChunk.getAdjacentChunks(chunkKey)
    
    -- Unlock adjacent chunks based on sandbox setting
    local unlockPattern = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ChunkUnlockPattern) or 1
    
    -- Pattern 1: Cardinal only (N, E, S, W)
    -- Pattern 2: All adjacent (including diagonals - not yet implemented)
    
    local newChunksUnlocked = 0
    for direction, adjacentKey in pairs(adjacentChunks) do
        -- Check if chunk is already unlocked
        local adjacentData = SpawnChunk.getChunkData(adjacentKey)
        if not adjacentData or not adjacentData.unlocked then
            -- Unlock the chunk
            local newChunk = SpawnChunk.unlockChunk(adjacentKey)
            
            -- Calculate kill target for new chunk (same formula as initial chunk)
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
            
            print("[" .. username .. "] Unlocked adjacent chunk: " .. adjacentKey .. " (direction: " .. direction .. ") with target: " .. target)
            newChunksUnlocked = newChunksUnlocked + 1
        end
    end
    
    print("[" .. username .. "] Unlocked " .. newChunksUnlocked .. " new chunk(s)")
    
    -- Reset visual markers flag to redraw boundaries for new chunks
    data.markersCreated = false
    data.mapSymbolCreated = false
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
