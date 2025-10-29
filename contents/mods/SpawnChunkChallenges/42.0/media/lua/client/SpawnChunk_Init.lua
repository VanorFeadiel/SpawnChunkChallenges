-- SpawnChunk_Init.lua
-- Initialize challenge when player spawns
-- CHARACTER-SPECIFIC INITIALIZATION
--modversion=0.3.2.026

SpawnChunk = SpawnChunk or {}

-----------------------  INITIALIZATION  ---------------------------

function SpawnChunk.initialize()
    local pl = getPlayer()
    if not pl then return end
    
    local username = SpawnChunk.getUsername()
    local data = SpawnChunk.getData()
    
    -- Check if already initialized
    if data.isInitialized then
        print("[" .. username .. "] Challenge already initialized")
        print("Spawn point: " .. data.spawnX .. ", " .. data.spawnY)
        if data.chunkMode then
            local currentChunk = data.chunks and data.chunks[data.currentChunk]
            if currentChunk then
                print("Current Chunk: " .. data.currentChunk .. " - Kills: " .. currentChunk.killCount .. " / " .. currentChunk.killTarget)
            end
        else
            print("Kills: " .. data.killCount .. " / " .. data.killTarget)
        end
        return
    end
    
    -- Initialize on first spawn
    local x = math.floor(pl:getX())
    local y = math.floor(pl:getY())
    local z = math.floor(pl:getZ())
    
    -- Check if chunk mode is enabled
    local chunkModeEnabled = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.EnableChunkMode) or false
    
    -- Initialize challenge type from sandbox options
    local challengeTypeValue = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ChallengeType) or 1
    local challengeType
    if challengeTypeValue == 1 then
        challengeType = "Purge"
    elseif challengeTypeValue == 2 then
        challengeType = "Time"
    elseif challengeTypeValue == 3 then
        challengeType = "ZeroToHero"
    else
        challengeType = "Purge"  -- Default fallback
    end
    data.challengeType = challengeType
    
    -- Initialize challenge-specific settings
    if challengeType == "Time" then
        data.timeTarget = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.TimeChallengeDuration) or 12
        data.timeInAnyChunk = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.TimeInAnyChunk) or false
        data.timeHours = 0
elseif challengeType == "ZeroToHero" then
        -- Initialize skill tracking for Zero to Hero
        data.pendingSkillUnlocks = {}
        data.completedSkills = {}
        data.lastSkillLevels = {}
        
        -- AUTO-DETECT: Initialize baseline for ALL skills (including level 0)
        if pl then
            -- Use XP system instead of perks (more reliable in Build 42)
            local xpSystem = pl:getXp()
            if xpSystem then
                -- Iterate through all perks using Perks enum
                for i = 0, Perks.getMaxIndex() - 1 do
                    local perk = PerkFactory.getPerk(Perks.fromIndex(i))
                    if perk then
                        local perkType = perk:getType()
                        local skillName = perkType:toString()
                        local level = pl:getPerkLevel(perkType)
                        -- Track ALL skills, even level 0 (establishes baseline for detection)
                        data.lastSkillLevels[skillName] = level
                    end
                end
            end
        end
    end
    
    -- Calculate boundary size and area
    local boundarySize = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.BoundarySize) or 50
    local boundaryArea = (boundarySize * 2 + 1) * (boundarySize * 2 + 1) -- Full area including edges
    local baselineArea = 101 * 101 -- 50x50 boundary = 101x101 area
    local areaMultiplier = boundaryArea / baselineArea
    
    -- Calculate kill target for Purge challenge (only if needed)
    local target = 10  -- Default/fallback value
    if challengeType == "Purge" then
        local cell = getCell()
        local zombieList = cell and cell:getZombieList()
        local totalZombies = zombieList and zombieList:size() or 100
        local baseTarget = math.floor(totalZombies / 9)
        
        -- Apply area scaling and kill multiplier from sandbox options
        local killMultiplier = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.KillMultiplier) or 1.0
        target = math.floor(baseTarget * areaMultiplier * killMultiplier)
        
        -- Ensure minimum target of 5
        if target < 5 then target = 5 end
    end
    
    -- Store spawn data
    data.spawnX = x
    data.spawnY = y
    data.spawnZ = z
    data.boundarySize = boundarySize
    data.chunkMode = chunkModeEnabled
    data.isInitialized = true
    
    -- Initialize based on mode
    if chunkModeEnabled then
        -- CHUNK MODE: Initialize first chunk (chunk_0_0)
        data.currentChunk = "chunk_0_0"
        data.chunks = {}
        
        local firstChunk = SpawnChunk.initChunk("chunk_0_0", true, false)
        
        -- Set challenge-specific targets for first chunk
        if challengeType == "Purge" then
            firstChunk.killTarget = target
            firstChunk.killCount = 0
        elseif challengeType == "Time" then
            firstChunk.timeHours = 0
            firstChunk.timeTarget = data.timeTarget
            firstChunk.killTarget = 0
            firstChunk.killCount = 0
        elseif challengeType == "ZeroToHero" then
            firstChunk.killTarget = 0
            firstChunk.killCount = 0
            firstChunk.timeHours = 0
            firstChunk.timeTarget = 0
        end
        
        -- Legacy fields kept at 0 for compatibility
        data.killCount = 0
        data.killTarget = 0
        data.isComplete = false
        
        print("=== SPAWN CHUNK CHALLENGE STARTED (CHUNK MODE) ===")
        print("Character: " .. username)
        print("Challenge Type: " .. challengeType)
        print("Spawn: " .. x .. ", " .. y .. ", " .. z)
        print("Boundary Size: " .. data.boundarySize .. " tiles per chunk")
        print("Boundary Area: " .. boundaryArea .. " tiles (multiplier: " .. string.format("%.2f", areaMultiplier) .. ")")
        print("First Chunk: chunk_0_0")
        
        if challengeType == "Purge" then
            print("Kill Target: " .. target .. " zombies (multiplier: " .. ((SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.KillMultiplier) or 1.0) .. ")")
        elseif challengeType == "Time" then
            print("Time Target: " .. data.timeTarget .. " hours")
        elseif challengeType == "ZeroToHero" then
            print("Zero to Hero: Level all skills to unlock chunks")
        end
        print("===================================================")
        
        -- Show on-screen message based on challenge type
        local challengeMessage
        if challengeType == "Time" then
            challengeMessage = "Time Challenge Started! Survive " .. data.timeTarget .. " hours to unlock adjacent chunks."
        elseif challengeType == "ZeroToHero" then
            challengeMessage = "Zero to Hero Challenge Started! Level skills to unlock chunks."
        else
            challengeMessage = "Purge Challenge Started! Kill " .. target .. " zombies to unlock adjacent chunks."
        end
        pl:setHaloNote(challengeMessage, 255, 255, 100, 300)
    else
        -- CLASSIC MODE: Single boundary
        data.killCount = 0
        data.killTarget = target
        data.isComplete = false
        data.currentChunk = "chunk_0_0"  -- Set for compatibility but not used
        
        print("=== SPAWN CHUNK CHALLENGE STARTED (CLASSIC MODE) ===")
        print("Character: " .. username)
        print("Challenge Type: " .. challengeType)
        print("Spawn: " .. x .. ", " .. y .. ", " .. z)
        print("Boundary: " .. data.boundarySize .. " tiles")
        print("Boundary Area: " .. boundaryArea .. " tiles (multiplier: " .. string.format("%.2f", areaMultiplier) .. ")")
        
        if challengeType == "Purge" then
            print("Kill Target: " .. target .. " zombies (multiplier: " .. ((SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.KillMultiplier) or 1.0) .. ")")
        elseif challengeType == "Time" then
            print("Time Target: " .. data.timeTarget .. " hours")
        elseif challengeType == "ZeroToHero" then
            print("Zero to Hero: Level all skills to 10 to escape")
        end
        print("====================================================")
        
        -- Show on-screen message based on challenge type
        local challengeMessage
        if challengeType == "Time" then
            challengeMessage = "Time Challenge Started! Survive " .. data.timeTarget .. " hours to escape."
        elseif challengeType == "ZeroToHero" then
            challengeMessage = "Zero to Hero Challenge Started! Level all skills to 10 to escape."
        else
            challengeMessage = "Purge Challenge Started! Kill " .. target .. " zombies to escape."
        end
        pl:setHaloNote(challengeMessage, 255, 255, 100, 300)
    end
end

-- Code to Handle Player's Death - CHARACTER SPECIFIC
Events.OnPlayerDeath.Add(function(playerWhoJustDied)
    -- Get the dying player's username
    local username = playerWhoJustDied:getUsername()
    
    -- Get the dying player's specific data
    local modData = playerWhoJustDied:getModData()
    modData.SpawnChunk = modData.SpawnChunk or {}
    modData.SpawnChunk[username] = modData.SpawnChunk[username] or {}
    local data = modData.SpawnChunk[username]
    
    -- Reset challenge data for THIS character only
    data.isInitialized = false
    data.killCount = 0
    data.isComplete = false
    
    -- Reset chunk data if in chunk mode
    if data.chunkMode then
        data.chunks = {}
        data.currentChunk = "chunk_0_0"
        print("[" .. username .. "] Chunk data reset on death")
    end
    
    -- Reset boundary outdoor scan flag (important for additive chunks feature)
    data.boundaryOutdoorsChecked = false
    data.isOutdoors = false
    
    -- Reset debug tracking stats (lifetime stats reset on death)
    data.totalSpawned = 0
    data.totalSoundWaves = 0
    data.maxSoundRadius = 0
    
    -- Reset visual marker flags so they'll be recreated at new spawn
    data.markersCreated = false
    -- mapSymbolCreated stays true (keep old symbols on map)
    
    print("[" .. username .. "] Challenge reset on death (including stats and boundary outdoor status)")
    
    -- Clean up THIS character's ground markers (but keep map symbols and other characters' markers)
    -- We need to access the character-specific marker storage
    if SpawnChunk.characterMarkers and SpawnChunk.characterMarkers[username] then
        for _, marker in ipairs(SpawnChunk.characterMarkers[username]) do
            if marker and marker.remove then
                marker:remove()
            end
        end
        SpawnChunk.characterMarkers[username] = {}
        print("[" .. username .. "] Removed ground markers on death")
    end
end)

-- Initialize after a short delay to ensure player is fully loaded
Events.OnGameStart.Add(function()
    -- Wait 1 second then initialize
    local function delayedInit()
        SpawnChunk.initialize()
    end
    
    -- Use game time event for delay
    Events.OnTick.Add(function()
        delayedInit()
        Events.OnTick.Remove(delayedInit)
    end)
end)
