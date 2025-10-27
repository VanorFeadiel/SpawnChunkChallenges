-- SpawnChunk_Data.lua
-- Persistent data management (saves across sessions)
-- CHARACTER-SPECIFIC DATA - Each character gets their own challenge state

SpawnChunk = SpawnChunk or {}

-- MOD VERSION (update this when mod.info changes)
SpawnChunk.MOD_VERSION = "0.3.1.020"

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
        
        -- ADDITIVE CHUNKS DATA (new)
        chunks = {},                -- Dictionary of chunk data: ["chunk_0_0"] = {unlocked, completed, killCount, killTarget}
        currentChunk = "chunk_0_0", -- Key of the active chunk
        chunkMode = false,          -- Whether additive chunks mode is enabled
        
        -- Visual element tracking (per-character)
        markersCreated = false,
        mapSymbolCreated = false,
        
        -- Debug tracking fields (lifetime stats per-character)
        totalSpawned = 0,        -- Total zombies spawned this life
        totalSoundWaves = 0,     -- Total sound waves emitted this life
        maxSoundRadius = 0,      -- Maximum sound radius used this life
        
        -- Stuck zombie tracking (NEW)
        stuckZombiesByDirection = {},  -- Track stuck zombies per cardinal direction
        lastSpawnDirection = nil,       -- Last direction used for spawning
        challengeStuckFlag = false,     -- True if all 4 directions have stuck zombies
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

-----------------------  CHUNK MANAGEMENT FUNCTIONS  ---------------------------

-- Parse chunk key to get chunk grid coordinates
-- "chunk_1_2" -> {chunkX=1, chunkY=2}
function SpawnChunk.parseChunkKey(chunkKey)
    local chunkX, chunkY = chunkKey:match("chunk_(-?%d+)_(-?%d+)")
    if chunkX and chunkY then
        return {chunkX = tonumber(chunkX), chunkY = tonumber(chunkY)}
    end
    return nil
end

-- Create chunk key from chunk coordinates
-- {chunkX=1, chunkY=2} -> "chunk_1_2"
function SpawnChunk.getChunkKey(chunkX, chunkY)
    return string.format("chunk_%d_%d", chunkX, chunkY)
end

-- Get the chunk key for a given world position
function SpawnChunk.getChunkKeyFromPosition(worldX, worldY, data)
    local spawnX = data.spawnX
    local spawnY = data.spawnY
    local boundarySize = data.boundarySize
    local chunkSize = (boundarySize * 2) + 1  -- Full chunk size including both edges
    
    -- Calculate which chunk this position falls into
    -- Offset by (boundarySize + 0.5) to center the calculation on chunk boundaries
    local offsetX = worldX - spawnX + boundarySize + 0.5
    local offsetY = worldY - spawnY + boundarySize + 0.5
    
    -- Divide by chunk size and floor to get chunk coordinates
    local chunkX = math.floor(offsetX / chunkSize)
    local chunkY = math.floor(offsetY / chunkSize)
    
    return SpawnChunk.getChunkKey(chunkX, chunkY)
end

-- Get world coordinates for the center of a chunk
function SpawnChunk.getChunkCenter(chunkKey, data)
    local coords = SpawnChunk.parseChunkKey(chunkKey)
    if not coords then return nil, nil end
    
    local boundarySize = data.boundarySize
    local chunkSize = (boundarySize * 2) + 1
    
    local centerX = data.spawnX + (coords.chunkX * chunkSize)
    local centerY = data.spawnY + (coords.chunkY * chunkSize)
    
    return centerX, centerY
end

-- Get the boundary bounds for a specific chunk
-- Returns: minX, minY, maxX, maxY
function SpawnChunk.getChunkBounds(chunkKey, data)
    local centerX, centerY = SpawnChunk.getChunkCenter(chunkKey, data)
    if not centerX then return nil end
    
    local size = data.boundarySize
    return centerX - size, centerY - size, centerX + size, centerY + size
end

-- Get list of adjacent chunk keys (cardinal directions: N, E, S, W)
function SpawnChunk.getAdjacentChunks(chunkKey)
    local coords = SpawnChunk.parseChunkKey(chunkKey)
    if not coords then return {} end
    
    return {
        north = SpawnChunk.getChunkKey(coords.chunkX, coords.chunkY - 1),
        east = SpawnChunk.getChunkKey(coords.chunkX + 1, coords.chunkY),
        south = SpawnChunk.getChunkKey(coords.chunkX, coords.chunkY + 1),
        west = SpawnChunk.getChunkKey(coords.chunkX - 1, coords.chunkY),
    }
end

-- Initialize a chunk in the data structure
function SpawnChunk.initChunk(chunkKey, unlocked, completed)
    local data = SpawnChunk.getData()
    data.chunks = data.chunks or {}
    
    if not data.chunks[chunkKey] then
        data.chunks[chunkKey] = {
            unlocked = unlocked or false,
            completed = completed or false,
            available = false,  -- New state: can be unlocked by entering
            killCount = 0,
            killTarget = 10,  -- Will be recalculated on unlock
        }
    end
    
    return data.chunks[chunkKey]
end

-- Get chunk data for a specific chunk
function SpawnChunk.getChunkData(chunkKey)
    local data = SpawnChunk.getData()
    data.chunks = data.chunks or {}
    return data.chunks[chunkKey]
end

-- Mark a chunk as available (can be unlocked by entering)
function SpawnChunk.makeChunkAvailable(chunkKey)
    local chunkData = SpawnChunk.initChunk(chunkKey, false, false)
    chunkData.available = true
    local username = SpawnChunk.getUsername()
    print("[" .. username .. "] Chunk available: " .. chunkKey)
    return chunkData
end

-- Unlock a chunk (and initialize if needed)
function SpawnChunk.unlockChunk(chunkKey)
    local chunkData = SpawnChunk.initChunk(chunkKey, true, false)
    chunkData.unlocked = true
    chunkData.available = false  -- No longer just available, now unlocked
    local username = SpawnChunk.getUsername()
    print("[" .. username .. "] Unlocked chunk: " .. chunkKey)
    return chunkData
end

-- Mark a chunk as completed
function SpawnChunk.completeChunk(chunkKey)
    local data = SpawnChunk.getData()
    if data.chunks[chunkKey] then
        data.chunks[chunkKey].completed = true
        local username = SpawnChunk.getUsername()
        print("[" .. username .. "] Completed chunk: " .. chunkKey)
    end
end

-- Get list of all unlocked chunks
function SpawnChunk.getUnlockedChunks()
    local data = SpawnChunk.getData()
    local unlocked = {}
    
    if data.chunks then
        for chunkKey, chunkData in pairs(data.chunks) do
            if chunkData.unlocked then
                table.insert(unlocked, chunkKey)
            end
        end
    end
    
    return unlocked
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
    
    -- Show chunk mode info
    if data.chunkMode then
        print("--- CHUNK MODE ---")
        print("Current Chunk: " .. (data.currentChunk or "none"))
        local currentChunkData = data.chunks and data.chunks[data.currentChunk]
        if currentChunkData then
            print("Chunk Kills: " .. currentChunkData.killCount .. " / " .. currentChunkData.killTarget)
            print("Chunk Complete: " .. tostring(currentChunkData.completed))
        end
        print("Total Unlocked Chunks: " .. #SpawnChunk.getUnlockedChunks())
    else
        print("Kills: " .. data.killCount .. " / " .. data.killTarget)
        print("Complete: " .. tostring(data.isComplete))
    end
    
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
    
    -- Reset chunk data if in chunk mode
    if data.chunkMode then
        data.chunks = {}
        data.currentChunk = "chunk_0_0"
    end
    
    print("Challenge reset!")
    SpawnChunk.initialize()
end
