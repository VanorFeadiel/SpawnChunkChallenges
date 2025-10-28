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
        -- Check if all skills (Aiming, Fitness, Strength, Sprinting, Lightfoot, Sneak) are at 10
        local pl = getPlayer()
        if not pl then return false end
        
        local allMaxed = true
        local requiredSkills = {"Aiming", "Fitness", "Strength", "Sprinting", "Lightfoot", "Sneak"}
        
        for _, skillName in ipairs(requiredSkills) do
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
        local requiredSkills = {"Aiming", "Fitness", "Strength", "Sprinting", "Lightfoot", "Sneak"}
        local pl = getPlayer()
        
        if pl then
            local skillTexts = {}
            for _, skillName in ipairs(requiredSkills) do
                local perk = Perks.FromString(skillName)
                if perk then
                    local level = pl:getPerkLevel(perk)
                    table.insert(skillTexts, skillName .. ": " .. level .. "/10")
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
    
    -- Get time survived in-game (already tracked by the game)
    local hoursSurvived = pl:getHoursSurvived()
    
    -- Store the last checked value to detect increases
    data.lastHoursChecked = data.lastHoursChecked or 0
    
    -- If time has increased, update the challenge time
    if hoursSurvived > data.lastHoursChecked then
        data.timeHours = (data.timeHours or 0) + (hoursSurvived - data.lastHoursChecked)
        data.lastHoursChecked = hoursSurvived
    end
end

-- Track skill progression for Zero to Hero Challenge
function SpawnChunk.updateSkillProgress()
    local data = SpawnChunk.getData()
    if not data.isInitialized or data.challengeType ~= "ZeroToHero" then return end
    
    local pl = getPlayer()
    if not pl then return end
    
    local requiredSkills = {"Aiming", "Fitness", "Strength", "Sprinting", "Lightfoot", "Sneak"}
    
    -- Initialize skill tracking
    data.lastSkillLevels = data.lastSkillLevels or {}
    
    for _, skillName in ipairs(requiredSkills) do
        local perk = Perks.FromString(skillName)
        if perk then
            local currentLevel = pl:getPerkLevel(perk)
            local lastLevel = data.lastSkillLevels[skillName] or 0
            
            -- Check if skill leveled up
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
                    print("[" .. username .. "] Skill leveled up: " .. skillName .. " level " .. currentLevel .. " (banked for unlock)")
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

