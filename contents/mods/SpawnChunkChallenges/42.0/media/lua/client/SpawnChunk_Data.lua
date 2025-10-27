-- SpawnChunk_Data.lua
-- Persistent data management (saves across sessions)
-- CHARACTER-SPECIFIC DATA - Each character gets their own challenge state

SpawnChunk = SpawnChunk or {}

-----------------------  CHARACTER-SPECIFIC DATA ACCESS  ---------------------------

-- Get the current player's username for data namespacing
function SpawnChunk.getUsername()
    local pl = getPlayer()
    if not pl then return nil end
    return pl:getUsername()
end

-- Get character-specific data for current player
function SpawnChunk.getData()
    local pl = getPlayer()
    if not pl then return {} end
    
    local username = SpawnChunk.getUsername()
    if not username then return {} end
    
    -- Store data in player's mod data (persists across sessions)
    local modData = pl:getModData()
    
    -- Initialize the SpawnChunk table if it doesn't exist
    modData.SpawnChunk = modData.SpawnChunk or {}
    
    -- Initialize character-specific data if it doesn't exist
    modData.SpawnChunk[username] = modData.SpawnChunk[username] or {
        isInitialized = false,
        spawnX = 0,
        spawnY = 0,
        spawnZ = 0,
        boundarySize = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.BoundarySize) or 50,
        killCount = 0,
        killTarget = 10,
        isComplete = false,
        
        -- Visual element tracking (per-character)
        markersCreated = false,
        mapSymbolCreated = false,
        
        -- Debug tracking fields (lifetime stats per-character)
        totalSpawned = 0,        -- Total zombies spawned this life
        totalSoundWaves = 0,     -- Total sound waves emitted this life
        maxSoundRadius = 0,      -- Maximum sound radius used this life
    }
    
    return modData.SpawnChunk[username]
end

-- Get data for a specific username (used for cleanup operations)
function SpawnChunk.getDataForUsername(username)
    local pl = getPlayer()
    if not pl then return {} end
    if not username then return {} end
    
    local modData = pl:getModData()
    modData.SpawnChunk = modData.SpawnChunk or {}
    modData.SpawnChunk[username] = modData.SpawnChunk[username] or {}
    
    return modData.SpawnChunk[username]
end

function SpawnChunk.saveData()
    -- Data is automatically saved with player mod data
    -- This function exists for explicit save calls if needed
    local pl = getPlayer()
    if pl then
        pl:saveData()
    end
end

-----------------------  DEBUG FUNCTIONS  ---------------------------

function SpawnChunk.printStatus()
    local username = SpawnChunk.getUsername()
    local data = SpawnChunk.getData()
    print("=== SPAWN CHUNK STATUS ===")
    print("Character: " .. (username or "UNKNOWN"))
    print("Initialized: " .. tostring(data.isInitialized))
    print("Spawn Point: " .. data.spawnX .. ", " .. data.spawnY .. ", " .. data.spawnZ)
    print("Boundary Size: " .. data.boundarySize)
    print("Kills: " .. data.killCount .. " / " .. data.killTarget)
    print("Complete: " .. tostring(data.isComplete))
    print("--- Debug Stats ---")
    print("Total Spawned: " .. (data.totalSpawned or 0))
    print("Sound Waves: " .. (data.totalSoundWaves or 0))
    print("Max Sound Radius: " .. (data.maxSoundRadius or 0))
    print("========================")
end

function SpawnChunk.resetChallenge()
    local data = SpawnChunk.getData()
    data.isInitialized = false
    data.killCount = 0
    data.isComplete = false
    data.totalSpawned = 0
    data.totalSoundWaves = 0
    data.maxSoundRadius = 0
    data.markersCreated = false
    data.mapSymbolCreated = false
    print("Challenge reset!")
    SpawnChunk.initialize()
end
