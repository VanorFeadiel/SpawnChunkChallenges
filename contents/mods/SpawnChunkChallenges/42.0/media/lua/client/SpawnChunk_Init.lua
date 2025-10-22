-- SpawnChunk_Init.lua
-- Initialize challenge when player spawns

SpawnChunk = SpawnChunk or {}

-----------------------  INITIALIZATION  ---------------------------

function SpawnChunk.initialize()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    
    -- Check if already initialized
    if data.isInitialized then
        print("SpawnChunk: Challenge already initialized")
        print("Spawn point: " .. data.spawnX .. ", " .. data.spawnY)
        print("Kills: " .. data.killCount .. " / " .. data.killTarget)
        return
    end
    
    -- Initialize on first spawn
    local x = math.floor(pl:getX())
    local y = math.floor(pl:getY())
    local z = math.floor(pl:getZ())
    
    -- Calculate kill target based on cell zombie population and boundary area
    local cell = getCell()
    local zombieList = cell and cell:getZombieList()
    local totalZombies = zombieList and zombieList:size() or 100
    local baseTarget = math.floor(totalZombies / 9)
    -- if baseTarget < 5 then baseTarget = 5 end -- Minimum 5
    
    -- Scale target based on boundary area (50x50 = 2500 tiles is baseline)
    local boundarySize = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.BoundarySize) or 50
    local boundaryArea = (boundarySize * 2 + 1) * (boundarySize * 2 + 1) -- Full area including edges
    local baselineArea = 101 * 101 -- 50x50 boundary = 101x101 area
    local areaMultiplier = boundaryArea / baselineArea
    
    -- Apply area scaling and kill multiplier from sandbox options
    local killMultiplier = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.KillMultiplier) or 1.0
    local target = math.floor(baseTarget * areaMultiplier * killMultiplier)
    
    -- Ensure minimum target of 5
    if target < 5 then target = 5 end
    
    -- Store spawn data
    data.spawnX = x
    data.spawnY = y
    data.spawnZ = z
    data.boundarySize = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.BoundarySize) or 50
    data.killCount = 0
    data.killTarget = target
    data.isComplete = false
    data.isInitialized = true
    
    print("=== SPAWN CHUNK CHALLENGE STARTED ===")
    print("Spawn: " .. x .. ", " .. y .. ", " .. z)
    print("Boundary: " .. data.boundarySize .. " tiles")
    print("Boundary Area: " .. boundaryArea .. " tiles (multiplier: " .. string.format("%.2f", areaMultiplier) .. ")")
    print("Kill Target: " .. target .. " zombies (base: " .. baseTarget .. ", multiplier: " .. killMultiplier .. ")")
    print("====================================")
    
    -- Show on-screen message
    pl:setHaloNote("Challenge Started! Kill " .. target .. " zombies to escape.", 255, 255, 100, 300)
end

-- Code to Handle Player's Death
Events.OnPlayerDeath.Add(function(playerWhoJustDied)
    -- Get the dying player's specific data
    local modData = playerWhoJustDied:getModData()
    modData.SpawnChunk = modData.SpawnChunk or {}
    local data = modData.SpawnChunk
    
    -- Reset challenge data
    data.isInitialized = false
    data.killCount = 0
    data.isComplete = false
    
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
    
    print("SpawnChunk_Init: Challenge reset on death (including stats and boundary outdoor status)")
    
    -- Clean up ground markers (but keep map symbols)
    if SpawnChunk.removeGroundMarkers then
        SpawnChunk.removeGroundMarkers()
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