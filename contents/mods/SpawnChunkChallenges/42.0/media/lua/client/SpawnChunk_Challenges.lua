-- SpawnChunk_Challenges.lua
-- Challenge type system and progress tracking for Purge, Time, and Zero to Hero challenges
--modversion=0.3.2.026

SpawnChunk = SpawnChunk or {}

-----------------------  CHALLENGE TYPE MANAGEMENT  ---------------------------

-- Get current challenge type from sandbox options
function SpawnChunk.getChallengeType()
    local challengeType = SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ChallengeType or "Purge"
    return challengeType
end

-- Check if chunk is completed based on challenge type
function SpawnChunk.isChunkCompleted()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return false end
    
    local challengeType = data.challengeType
    
    if challengeType == "Purge" then
        -- Purge Challenge: Kill zombies
        if data.chunkMode then
            local currentChunkData = data.chunks[data.currentChunk]
            if currentChunkData then
                return currentChunkData.killCount >= currentChunkData.killTarget
            end
        else
            return data.killCount >= data.killTarget
        end
        
    elseif challengeType == "Time" then
        -- Time Challenge: Spend time in chunk (in-game hours)
        if data.chunkMode then
            -- CHUNK MODE: Check current chunk's time
            local currentChunkData = data.chunks[data.currentChunk]
            if currentChunkData then
                return currentChunkData.timeHours >= currentChunkData.timeTarget
            end
            return false
        else
            -- CLASSIC MODE: Check global time
            return data.timeHours >= data.timeTarget
        end
        
    elseif challengeType == "ZeroToHero" then
        -- Zero to Hero: Skills at level 10
        -- AUTO-DETECT: Check all tracked skills (including modded skills)
        local pl = getPlayer()
        if not pl then return false end
        
        -- Get all tracked skills from lastSkillLevels
        local trackedSkills = {}
        if data.lastSkillLevels then
            for skillName, _ in pairs(data.lastSkillLevels) do
                table.insert(trackedSkills, skillName)
            end
        end
        
        -- If no tracked skills yet, get all player perks using XP system (Build 42 compatible)
        if #trackedSkills == 0 then
            local xpSystem = pl:getXp()
            if xpSystem then
                -- Iterate through all perks using Perks enum
                for i = 0, Perks.getMaxIndex() - 1 do
                    local perk = PerkFactory.getPerk(Perks.fromIndex(i))
                    if perk then
                        local perkType = perk:getType()
                        local skillName = perkType:toString()
                        local level = pl:getPerkLevel(perkType)
                        if level > 0 then
                            table.insert(trackedSkills, skillName)
                        end
                    end
                end
            end
        end
        
        -- Check if all tracked skills are at level 10
        local allMaxed = true
        for _, skillName in ipairs(trackedSkills) do
            local perk = Perks.FromString(skillName)
            if perk then
                local skillLevel = pl:getPerkLevel(perk)
                if skillLevel < 10 then
                    allMaxed = false
                    break
                end
            end
        end
        
        return allMaxed
    end
    
    return false
end

-- Check if current challenge has pending unlocks (banked skill levels for Zero to Hero)
function SpawnChunk.hasPendingUnlocks()
    local data = SpawnChunk.getData()
    return data.pendingSkillUnlocks and #data.pendingSkillUnlocks > 0
end

-- Get challenge progress as formatted text for HUD
function SpawnChunk.getChallengeProgressText()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return "Not initialized" end
    
    local challengeType = data.challengeType
    
    if challengeType == "Purge" then
        if data.chunkMode then
            local currentChunkData = data.chunks[data.currentChunk]
            if currentChunkData then
                return "Kills: " .. currentChunkData.killCount .. " / " .. currentChunkData.killTarget
            end
        else
            return "Kills: " .. data.killCount .. " / " .. data.killTarget
        end
        
    elseif challengeType == "Time" then
        if data.chunkMode then
            -- CHUNK MODE: Show current chunk's time
            local currentChunkData = data.chunks[data.currentChunk]
            if currentChunkData then
                return string.format("Time: %.1f / %.0f hours", 
                    currentChunkData.timeHours or 0, 
                    currentChunkData.timeTarget or data.timeTarget)
            end
            return "Time: 0.0 / " .. data.timeTarget .. " hours"
        else
            -- CLASSIC MODE: Show global time
            return string.format("Time: %.1f / %d hours", data.timeHours, data.timeTarget)
        end
        
    elseif challengeType == "ZeroToHero" then
        -- SIMPLIFIED HUD: Just show skill count and banked unlocks
        local pl = getPlayer()
        local skillCount = 0
        
        if pl then
            -- Count tracked skills (skills with level > 0)
            local xpSystem = pl:getXp()
            if xpSystem then
                for i = 0, Perks.getMaxIndex() - 1 do
                    local perk = PerkFactory.getPerk(Perks.fromIndex(i))
                    if perk then
                        local perkType = perk:getType()
                        local level = pl:getPerkLevel(perkType)
                        if level > 0 then
                            skillCount = skillCount + 1
                        end
                    end
                end
            end
        end
        
        -- Simple display: just counts
        local unlocksCount = #(data.pendingSkillUnlocks or {})
        local text = "Skills tracked: " .. skillCount
        
        if unlocksCount > 0 then
            text = text .. " (+" .. unlocksCount .. " unlocks)"
        end
        
        -- Show settlement timer if active
        if data.chunkEntryTime then
            local gameTime = getGameTime()
            local currentHours = gameTime:getWorldAgeHours()
            local hoursSinceEntry = currentHours - data.chunkEntryTime
            local minutesRemaining = (1.0 - hoursSinceEntry) * 60
            
            if minutesRemaining > 0 then
                -- Timer still counting down
                text = text .. string.format(" [Timer: %.0fm]", minutesRemaining)
            else
                -- Timer expired
                local readyFlag = data.readyToUnlock or false
                if unlocksCount > 0 and readyFlag then
                    text = text .. " [Timer: Completing...]"
                elseif unlocksCount > 0 and not readyFlag then
                    text = text .. " [Timer: Ready, waiting...]"
                else
                    text = text .. " [Timer: Need unlock!]"
                end
            end
        else
            -- No timer - show ready status
            local readyFlag = data.readyToUnlock or false
            if readyFlag and unlocksCount > 0 then
                text = text .. " [Ready to unlock!]"
            end
        end
        
        return text
    end
    
    return "Unknown challenge type"
end

-- Track time progression for Time Challenge
function SpawnChunk.updateTimeProgress()
    local data = SpawnChunk.getData()
    if not data.isInitialized or data.challengeType ~= "Time" then return end
    
    local pl = getPlayer()
    if not pl then return end
    
    -- Determine if we should count time based on player location
    local shouldCountTime = false
    local targetChunkKey = nil
    
    if data.chunkMode then
        -- CHUNK MODE: Check if player is in valid chunk
        local playerX = math.floor(pl:getX())
        local playerY = math.floor(pl:getY())
        local playerChunkKey = SpawnChunk.getChunkKeyFromPosition(playerX, playerY, data)
        local playerChunkData = data.chunks and data.chunks[playerChunkKey]
        
        if playerChunkData and playerChunkData.unlocked then
            -- Player is in an unlocked chunk
            local timeInAnyChunk = data.timeInAnyChunk or false
            
            if timeInAnyChunk then
                -- Count time in ANY unlocked chunk (but not completed ones)
                if not playerChunkData.completed then
                    shouldCountTime = true
                    targetChunkKey = playerChunkKey
                end
            else
                -- CRITICAL: Only count time in CURRENT CHALLENGE CHUNK (not completed)
                -- The "current chunk" is the one the player is actively working on
                if playerChunkKey == data.currentChunk and not playerChunkData.completed then
                    shouldCountTime = true
                    targetChunkKey = playerChunkKey
                end
            end
        end
    else
        -- CLASSIC MODE: Always count time (no chunk restrictions)
        shouldCountTime = true
    end
    
    -- If we shouldn't count time, exit early
    if not shouldCountTime then return end
    
    -- Calculate elapsed time using game time
    local gameTime = getGameTime()
    local currentMinutes = gameTime:getWorldAgeHours() * 60
    
    -- Initialize last time check if not exists
    data.lastTimeCheckMinutes = data.lastTimeCheckMinutes or currentMinutes
    
    -- Calculate elapsed time since last check
    local elapsedMinutes = currentMinutes - data.lastTimeCheckMinutes
    data.lastTimeCheckMinutes = currentMinutes
    
    -- Don't add time if elapsed is negative (shouldn't happen, but safety check)
    if elapsedMinutes < 0 then
        elapsedMinutes = 0
    end
    
    -- Convert minutes to hours
    local elapsedHours = elapsedMinutes / 60
    
    -- Add time to appropriate location
    if data.chunkMode then
        -- CHUNK MODE: Add time to specific chunk
        if targetChunkKey and data.chunks[targetChunkKey] then
            data.chunks[targetChunkKey].timeHours = (data.chunks[targetChunkKey].timeHours or 0) + elapsedHours
        end
    else
        -- CLASSIC MODE: Add time to global counter
        data.timeHours = (data.timeHours or 0) + elapsedHours
    end
end

-- Track skill progression for Zero to Hero Challenge
function SpawnChunk.updateSkillProgress()
    local data = SpawnChunk.getData()
    if not data.isInitialized or data.challengeType ~= "ZeroToHero" then return end
    
    local pl = getPlayer()
    if not pl then return end
    
    -- Initialize skill tracking
    data.lastSkillLevels = data.lastSkillLevels or {}
    
    -- AUTO-DETECT: Get all perks using XP system (Build 42 compatible)
    local xpSystem = pl:getXp()
    if not xpSystem then return end
    
    -- Track if we earned our FIRST unlock (0→1)
    local hadUnlocks = #(data.pendingSkillUnlocks or {})
    
    -- Iterate through all perks using Perks enum
    for i = 0, Perks.getMaxIndex() - 1 do
        local perk = PerkFactory.getPerk(Perks.fromIndex(i))
        if perk then
            local perkType = perk:getType()
            local skillName = perkType:toString()
            local currentLevel = pl:getPerkLevel(perkType)
            local lastLevel = data.lastSkillLevels[skillName] or 0
            
            -- Check if skill leveled up (including 0 to 1)
            if currentLevel > lastLevel then
                -- Add to pending unlocks queue
                data.pendingSkillUnlocks = data.pendingSkillUnlocks or {}
                
                -- Check if skill has already reached 10 (don't bank again)
                local alreadyCompleted = false
                for _, completed in ipairs(data.completedSkills or {}) do
                    if completed == skillName then
                        alreadyCompleted = true
                        break
                    end
                end
                
                -- Calculate how many levels were gained
                local levelsGained = currentLevel - lastLevel
                local username = SpawnChunk.getUsername()
                
                -- If not at level 10 yet, bank one unlock PER level gained
                if not alreadyCompleted and currentLevel < 10 then
                    -- Add one unlock for EACH level gained
                    for i = 1, levelsGained do
                        local levelReached = lastLevel + i
                        table.insert(data.pendingSkillUnlocks, {skill = skillName, level = levelReached})
                    end
                    
                    local totalUnlocks = #data.pendingSkillUnlocks
                    print("[" .. username .. "] Skill: " .. skillName .. " +" .. levelsGained .. " levels → " .. totalUnlocks .. " unlocks")
                elseif currentLevel >= 10 and not alreadyCompleted then
                    -- Skill reached level 10!
                    data.completedSkills = data.completedSkills or {}
                    table.insert(data.completedSkills, skillName)
                    print("[" .. username .. "] SKILL COMPLETED: " .. skillName .. " reached level 10!")
                end
                
                data.lastSkillLevels[skillName] = currentLevel
            end
        end
    end
    
    -- CRITICAL: If this was a NEW unlock in Chunk Mode, handle appropriately
    local hasUnlocksNow = #(data.pendingSkillUnlocks or {})
    if data.chunkMode and hasUnlocksNow > hadUnlocks then
        local username = SpawnChunk.getUsername()
        local unlocksGained = hasUnlocksNow - hadUnlocks
        print("[" .. username .. "] Gained " .. unlocksGained .. " unlock(s), total now: " .. hasUnlocksNow)
        
        -- Check if we're ready to use an unlock (flag must be true)
        local readyToUse = data.readyToUnlock or false
        print("[" .. username .. "] readyToUnlock flag: " .. tostring(readyToUse))
        
        if readyToUse then
            -- Ready to use unlock - complete the current yellow chunk
            print("[" .. username .. "] Ready to unlock - completing chunk immediately")
            
            if SpawnChunk.useZeroToHeroUnlockForCompletion and SpawnChunk.useZeroToHeroUnlockForCompletion() then
                -- Show visual feedback
                pl:setHaloNote("Skill leveled! Chunk completing...", 100, 255, 100, 150)
                
                -- Complete the current chunk (this will unlock neighbors and pick new current)
                if SpawnChunk.onChunkComplete then
                    SpawnChunk.onChunkComplete(data.currentChunk)
                end
                
                -- Recreate visual markers to show new state
                data.markersCreated = false
                if SpawnChunk.createGroundMarkers then
                    SpawnChunk.createGroundMarkers()
                end
            end
        else
            -- Not ready yet (timer is active) - just bank the unlock
            print("[" .. username .. "] Settlement timer active - unlock banked for later")
            pl:setHaloNote("Skill leveled! Unlock banked (waiting for timer)", 100, 255, 100, 150)
        end
    end
end

-- Use a banked skill unlock when completing chunk
function SpawnChunk.useSkillUnlock(chunkKey)
    local data = SpawnChunk.getData()
    if not data.pendingSkillUnlocks or #data.pendingSkillUnlocks == 0 then return false end
    
    -- Remove oldest pending unlock
    table.remove(data.pendingSkillUnlocks, 1)
    
    local username = SpawnChunk.getUsername()
    print("[" .. username .. "] Used banked skill unlock for chunk: " .. chunkKey)
    
    return true
end

-----------------------  EVENT HANDLERS  ---------------------------

-- Time Challenge: Update progress every tick and check completion
Events.OnTick.Add(function()
    SpawnChunk.updateTimeProgress()
    
    -- Check for Time Challenge completion
    local data = SpawnChunk.getData()
    if data.isInitialized and data.challengeType == "Time" then
        local pl = getPlayer()
        if pl and SpawnChunk.isChunkCompleted() then
            -- CRITICAL: Check if chunk is NOT already completed (prevent multiple calls)
            if data.chunkMode then
                local currentChunkData = data.chunks[data.currentChunk]
                if currentChunkData and not currentChunkData.completed then
                    local username = SpawnChunk.getUsername()
                    print("[" .. username .. "] Time Challenge completed! Chunk unlocked.")
                    SpawnChunk.onChunkComplete(data.currentChunk)
                end
            else
                if not data.isComplete then
                    local username = SpawnChunk.getUsername()
                    print("[" .. username .. "] Time Challenge completed! Victory!")
                    SpawnChunk.onVictory()
                end
            end
        end
    end
end)

-- Zero to Hero Challenge: Update skill progress every tick and check timer
local timerCheckCounter = 0
local TIMER_CHECK_INTERVAL = 60  -- Check every 60 ticks (~1 second)

Events.OnTick.Add(function()
    SpawnChunk.updateSkillProgress()
    
    local data = SpawnChunk.getData()
    
    -- Check for Zero to Hero timer expiration (check less frequently for performance)
    timerCheckCounter = timerCheckCounter + 1
    if timerCheckCounter >= TIMER_CHECK_INTERVAL then
        timerCheckCounter = 0
        
        if data.isInitialized and data.challengeType == "ZeroToHero" and data.chunkMode then
            -- Check if timer exists and has expired
            if data.chunkEntryTime then
                local gameTime = getGameTime()
                local currentHours = gameTime:getWorldAgeHours()
                local hoursSinceEntry = currentHours - data.chunkEntryTime
                local timerExpired = hoursSinceEntry >= 1.0
                
                if timerExpired then
                    local unlocksAvailable = #(data.pendingSkillUnlocks or {})
                    local username = SpawnChunk.getUsername()
                    
                    print("[" .. username .. "] Timer expired!")
                    
                    -- Clear the timer
                    if SpawnChunk.clearChunkEntryTimer then
                        SpawnChunk.clearChunkEntryTimer()
                    end
                    
                    -- Set readyToUnlock flag to TRUE
                    data.readyToUnlock = true
                    print("[" .. username .. "] readyToUnlock = true")
                    
                    -- If unlocks available, try to complete the yellow chunk NOW
                    if unlocksAvailable > 0 then
                        print("[" .. username .. "] Unlocks available: " .. unlocksAvailable .. " - attempting completion")
                        
                        -- Find the current yellow (unlocked but not completed) chunk
                        local yellowChunkKey = nil
                        if data.chunks then
                            for chunkKey, chunkData in pairs(data.chunks) do
                                if chunkData.unlocked and not chunkData.completed then
                                    yellowChunkKey = chunkKey
                                    break
                                end
                            end
                        end
                        
                        if yellowChunkKey then
                            print("[" .. username .. "] Found yellow chunk: " .. yellowChunkKey .. " - completing it")
                            
                            -- Use one unlock to complete the chunk
                            if SpawnChunk.useZeroToHeroUnlockForCompletion and SpawnChunk.useZeroToHeroUnlockForCompletion() then
                                local pl = getPlayer()
                                if pl then
                                    local remainingUnlocks = #(data.pendingSkillUnlocks or {})
                                    pl:setHaloNote("Settlement complete! (" .. remainingUnlocks .. " unlocks remaining)", 100, 255, 100, 150)
                                end
                                
                                -- Set yellow chunk as current and complete it
                                data.currentChunk = yellowChunkKey
                                
                                if SpawnChunk.onChunkComplete then
                                    SpawnChunk.onChunkComplete(yellowChunkKey)
                                end
                                
                                -- Recreate visual markers
                                data.markersCreated = false
                                if SpawnChunk.createGroundMarkers then
                                    SpawnChunk.createGroundMarkers()
                                end
                            end
                        else
                            print("[" .. username .. "] WARNING: No yellow chunk found after timer expiration")
                        end
                    else
                        print("[" .. username .. "] No unlocks available - waiting for skill gain")
                    end
                end
            end
        end
    end
    
    -- Check for Zero to Hero victory (all skills at level 10)
    if data.isInitialized and data.challengeType == "ZeroToHero" then
        local pl = getPlayer()
        -- CRITICAL: Check if NOT already complete (prevent multiple calls)
        if pl and not data.isComplete and SpawnChunk.isChunkCompleted() then
            local username = SpawnChunk.getUsername()
            print("[" .. username .. "] ALL SKILLS REACHED LEVEL 10! Victory - boundaries removed!")
            
            -- Mark as complete and remove boundaries
            data.isComplete = true
            
            -- Remove visual markers
            if SpawnChunk.removeGroundMarkers then
                SpawnChunk.removeGroundMarkers()
            end
            if SpawnChunk.removeMapSymbol then
                SpawnChunk.removeMapSymbol()
            end
            
            -- Show victory message
            pl:setHaloNote("VICTORY! All skills maxed - Free exploration unlocked!", 0, 255, 0, 500)
            pl:playSound("VictorySound")
            
            -- Call victory if exists
            if SpawnChunk.onVictory then
                SpawnChunk.onVictory()
            end
        end
    end
end)
