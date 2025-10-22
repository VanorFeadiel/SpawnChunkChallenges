-- SpawnChunk_Data.lua
-- Persistent data management (saves across sessions)

SpawnChunk = SpawnChunk or {}

-----------------------  DATA MANAGEMENT  ---------------------------

function SpawnChunk.getData()
    local pl = getPlayer()
    if not pl then return {} end
    
    -- Store data in player's mod data (persists across sessions)
    local modData = pl:getModData()
    modData.SpawnChunk = modData.SpawnChunk or {
        isInitialized = false,
        spawnX = 0,
        spawnY = 0,
        spawnZ = 0,
        boundarySize = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.BoundarySize) or 50,
        killCount = 0,
        killTarget = 10,
        isComplete = false,
        
        -- Debug tracking fields (lifetime stats)
        totalSpawned = 0,        -- Total zombies spawned this life
        totalSoundWaves = 0,     -- Total sound waves emitted this life
        maxSoundRadius = 0,      -- Maximum sound radius used this life
    }
    
    return modData.SpawnChunk
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
    local data = SpawnChunk.getData()
    print("=== SPAWN CHUNK STATUS ===")
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
    print("Challenge reset!")
    SpawnChunk.initialize()
end