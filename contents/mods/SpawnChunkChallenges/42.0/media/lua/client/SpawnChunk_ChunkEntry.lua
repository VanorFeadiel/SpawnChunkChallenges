-- SpawnChunk_ChunkEntry.lua
-- Detect when player enters an available chunk and auto-unlock it
-- CHARACTER-SPECIFIC via getData()

SpawnChunk = SpawnChunk or {}

-----------------------  CHUNK ENTRY DETECTION  ---------------------------

local checkCounter = 0
local CHECK_INTERVAL = 30 -- Check every 30 ticks (~1 second)

function SpawnChunk.checkChunkEntry()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized or not data.chunkMode then return end
    
    -- Check periodically (not every tick for performance)
    checkCounter = checkCounter + 1
    if checkCounter < CHECK_INTERVAL then return end
    checkCounter = 0
    
    local username = SpawnChunk.getUsername()
    
    -- Detect which chunk the player is currently in
    local playerX = math.floor(pl:getX())
    local playerY = math.floor(pl:getY())
    local playerChunkKey = SpawnChunk.getChunkKeyFromPosition(playerX, playerY, data)
    
    -- Check if player is in an available chunk
    local playerChunkData = data.chunks and data.chunks[playerChunkKey]
    if not playerChunkData then return end
    
    -- If chunk is available but not unlocked, check if we can unlock it
    if playerChunkData.available and not playerChunkData.unlocked then
        -- ZERO TO HERO CHALLENGE: Check if we have banked skill unlocks to use
        if data.challengeType == "ZeroToHero" and data.pendingSkillUnlocks and #data.pendingSkillUnlocks > 0 then
            -- Use a banked skill unlock
            SpawnChunk.useSkillUnlock(playerChunkKey)
            print("[" .. username .. "] Player entered available chunk: " .. playerChunkKey .. " - Using banked skill unlock!")
            SpawnChunk.unlockChunk(playerChunkKey)
        elseif data.challengeType ~= "ZeroToHero" then
            -- PURGE/TIME challenges: Auto-unlock when entering
            print("[" .. username .. "] Player entered available chunk: " .. playerChunkKey .. " - Auto-unlocking!")
            SpawnChunk.unlockChunk(playerChunkKey)
        else
            -- Zero to Hero but no banked unlocks - don't unlock yet
            return
        end
        
        -- Update current chunk
        data.currentChunk = playerChunkKey
        
-- Show notification (challenge-specific message)
        local message
        if data.challengeType == "Purge" then
            message = "Unlocked " .. playerChunkKey .. "! Kill " .. playerChunkData.killTarget .. " zombies to complete."
        elseif data.challengeType == "Time" then
            message = "Unlocked " .. playerChunkKey .. "! Survive " .. (playerChunkData.timeTarget or data.timeTarget) .. " hours to complete."
        elseif data.challengeType == "ZeroToHero" then
            message = "Unlocked " .. playerChunkKey .. "! Level up skills to unlock more chunks."
        else
            message = "Unlocked " .. playerChunkKey .. "!"
        end
        pl:setHaloNote(message, 100, 255, 100, 300)  
		
        -- In Cardinal mode (Pattern 1), lock the other available chunks
        local unlockPattern = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ChunkUnlockPattern) or 1
        if unlockPattern == 1 then
            -- Find and lock all OTHER available chunks (player chose this direction, lock the others)
            local lockedCount = 0
            for chunkKey, chunkData in pairs(data.chunks) do
                if chunkKey ~= playerChunkKey and chunkData.available and not chunkData.unlocked then
                    -- Remove this chunk completely (make it locked)
                    data.chunks[chunkKey] = nil
                    lockedCount = lockedCount + 1
                    print("[" .. username .. "] Locked other available chunk: " .. chunkKey)
                end
            end
            print("[" .. username .. "] Locked " .. lockedCount .. " alternative direction(s) - path committed to " .. playerChunkKey)
        end
        
        -- Set spawn delay for new chunk (in-game minutes)
        local spawnDelay = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.NewChunkSpawnDelay) or 60
        if spawnDelay > 0 then
            local gameTime = getGameTime()
            local currentMinutes = gameTime:getWorldAgeHours() * 60  -- Convert hours to minutes
            data.spawnDelayUntil = currentMinutes + spawnDelay  -- Target in-game minutes
            print(string.format("[%s] Spawn system delayed for %d in-game minutes to allow exploration", username, spawnDelay))
        end
        
        -- Reset sound system for new chunk
        data.currentSoundRadius = 0
        data.lastClosestZombieDistance = nil
        data.consecutiveNonApproachingWaves = 0
        
        -- Reset boundary outdoor scan for new chunk
        data.boundaryOutdoorsChecked = false
        data.isOutdoors = false
        
        -- Recreate markers to show newly unlocked chunk and remove locked ones
        data.markersCreated = false
        data.mapSymbolCreated = false
        
        -- Remove old markers and recreate
        if SpawnChunk.removeGroundMarkers then
            SpawnChunk.removeGroundMarkers()
        end
        if SpawnChunk.removeMapSymbol then
            SpawnChunk.removeMapSymbol()
        end
        
        -- Recreate with delay
        local timer = 0
        local function recreateVisualsAfterUnlock()
            timer = timer + 1
            if timer >= 10 then
                if SpawnChunk.createGroundMarkers then
                    SpawnChunk.createGroundMarkers()
                    print("[" .. username .. "] Ground markers recreated after entering new chunk")
                end
                if SpawnChunk.addMapSymbol then
                    SpawnChunk.addMapSymbol()
                    data.mapSymbolCreated = true
                    print("[" .. username .. "] Map symbols recreated after entering new chunk")
                end
                Events.OnTick.Remove(recreateVisualsAfterUnlock)
            end
        end
        Events.OnTick.Add(recreateVisualsAfterUnlock)
    end
end

-- Hook into tick event for continuous checking
Events.OnTick.Add(SpawnChunk.checkChunkEntry)

