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
        boundarySize = 50,
        killCount = 0,
        killTarget = 10,
        isComplete = false
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
    print("========================")
end

function SpawnChunk.resetChallenge()
    local data = SpawnChunk.getData()
    data.isInitialized = false
    data.killCount = 0
    data.isComplete = false
    print("Challenge reset!")
    SpawnChunk.initialize()
end