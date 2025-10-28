-- SpawnChunk_Challenges.lua
-- Challenge type system and progress tracking for Purge, Time, and Zero to Hero challenges

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
        return data.timeHours >= data.timeTarget
        
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
        
        -- If no tracked skills yet, get all player perks
        if #trackedSkills == 0 then
            local perkList = pl:getPerks()
            if perkList then
                for i = 0, perkList:size() - 1 do
                    local perk = perkList:get(i)
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
        return string.format("Time: %.1f / %d hours", data.timeHours, data.timeTarget)
        
    elseif challengeType == "ZeroToHero" then
        local skillProgress = ""
        local pl = getPlayer()
        
        if pl then
            -- AUTO-DETECT: Get all perks from the player (includes modded skills)
            local perkList = pl:getPerks()
            local skillTexts = {}
            local trackedSkills = {}
            
            if perkList then
                for i = 0, perkList:size() - 1 do
                    local perk = perkList:get(i)
                    if perk then
                        local perkType = perk:getType()
                        local skillName = perkType:toString()
                        local level = pl:getPerkLevel(perkType)
                        
                        -- Only show skills that have at least 1 level (not level 0)
                        if level > 0 then
                            table.insert(trackedSkills, skillName)
                            table.insert(skillTexts, skillName .. ": " .. level .. "/10")
                        end
                    end
                end
            end
            
            -- Update lastSkillLevels to include newly discovered skills
            data.lastSkillLevels = data.lastSkillLevels or {}
            for _, skillName in ipairs(trackedSkills) do
                local perk = Perks.FromString(skillName)
                if perk then
                    data.lastSkillLevels[skillName] = pl:getPerkLevel(perk)
                end
            end
            
            skillProgress = table.concat(skillTexts, ", ")
        end
        
        -- Show pending unlocks if any
        if #(data.pendingSkillUnlocks or {}) > 0 then
            skillProgress = skillProgress .. " (+" .. #data.pendingSkillUnlocks .. " banked)"
        end
        
        return "Skills: " .. (skillProgress ~= "" and skillProgress or "Loading...")
    end
    
    return "Unknown challenge type"
end

-- Track time progression for Time Challenge
function SpawnChunk.updateTimeProgress()
    local data = SpawnChunk.getData()
    if not data.isInitialized or data.challengeType ~= "Time" then return end
    
    local pl = getPlayer()
    if not pl then return end
    
    -- Check if we should count time based on TimeInAnyChunk setting
    local timeInAnyChunk = data.timeInAnyChunk or false
    
    if timeInAnyChunk then
        -- Count time in ANY unlocked chunk
        local playerX = math.floor(pl:getX())
        local playerY = math.floor(pl:getY())
        local playerChunkKey = SpawnChunk.getChunkKeyFromPosition(playerX, playerY, data)
        local playerChunkData = data.chunks and data.chunks[playerChunkKey]
        
        -- Only count if player is in an unlocked chunk
        if not (playerChunkData and playerChunkData.unlocked) then
            return  -- Player not in unlocked chunk, don't count time
        end
    else
        -- Only count time in NEW (incomplete) chunks
        local playerX = math.floor(pl:getX())
        local playerY = math.floor(pl:getY())
        local playerChunkKey = SpawnChunk.getChunkKeyFromPosition(playerX, playerY, data)
        local playerChunkData = data.chunks and data.chunks[playerChunkKey]
        
        -- Only count if player is in current chunk AND it's not completed
        if not (playerChunkData and playerChunkData.unlocked and not playerChunkData.completed) then
            return  -- Player not in valid chunk, don't count time
        end
    end
    
    -- Use real-time delta instead of getHoursSurvived()
    -- This requires tracking last tick time and calculating elapsed time per tick
    local gameTime = getGameTime()
    local currentMinutes = gameTime:getWorldAgeHours() * 60
    
    data.lastTimeCheck = data.lastTimeCheck or currentMinutes
    local elapsedMinutes = currentMinutes - data.lastTimeCheck
    data.lastTimeCheck = currentMinutes
    
    -- Add elapsed time (convert minutes to hours)
    data.timeHours = (data.timeHours or 0) + (elapsedMinutes / 60)
end

-- Track skill progression for Zero to Hero Challenge
function SpawnChunk.updateSkillProgress()
    local data = SpawnChunk.getData()
    if not data.isInitialized or data.challengeType ~= "ZeroToHero" then return end
    
    local pl = getPlayer()
    if not pl then return end
    
    -- Initialize skill tracking
    data.lastSkillLevels = data.lastSkillLevels or {}
    
    -- AUTO-DETECT: Get all perks from player (includes modded skills)
    local perkList = pl:getPerks()
    if not perkList then return end
    
    for i = 0, perkList:size() - 1 do
        local perk = perkList:get(i)
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
                
                -- If not at level 10 yet, bank the unlock
                if not alreadyCompleted and currentLevel < 10 then
                    table.insert(data.pendingSkillUnlocks, {skill = skillName, level = currentLevel})
                    local username = SpawnChunk.getUsername()
                    print("[" .. username .. "] Skill leveled up: " .. skillName .. " level " .. currentLevel .. " (banked for unlock - " .. #data.pendingSkillUnlocks .. " unlocks available)")
                elseif currentLevel >= 10 and not alreadyCompleted then
                    -- Skill reached level 10!
                    table.insert(data.completedSkills, skillName)
                    local username = SpawnChunk.getUsername()
                    print("[" .. username .. "] ⭐ SKILL COMPLETED: " .. skillName .. " reached level 10!")
                end
                
                data.lastSkillLevels[skillName] = currentLevel
            end
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
            local username = SpawnChunk.getUsername()
            print("[" .. username .. "] Time Challenge completed! Chunk unlocked.")
            
            if data.chunkMode then
                SpawnChunk.onChunkComplete(data.currentChunk)
            else
                SpawnChunk.onVictory()
            end
        end
    end
end)

-- Zero to Hero Challenge: Update skill progress every tick and check victory
Events.OnTick.Add(function()
    SpawnChunk.updateSkillProgress()
    
    -- Check for Zero to Hero victory (all skills at level 10)
    local data = SpawnChunk.getData()
    if data.isInitialized and data.challengeType == "ZeroToHero" then
        local pl = getPlayer()
        if pl and SpawnChunk.isChunkCompleted() then
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
