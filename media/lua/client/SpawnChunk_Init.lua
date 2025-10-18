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
    
    -- Calculate kill target based on cell zombie population
    local cell = getCell()
    local zombieList = cell and cell:getZombieList()
    local totalZombies = zombieList and zombieList:size() or 100
    local target = math.floor(totalZombies / 9)
    if target < 10 then target = 10 end -- Minimum 10
    
    -- Store spawn data
    data.spawnX = x
    data.spawnY = y
    data.spawnZ = z
    data.boundarySize = 50 -- 50 tiles = ~10x10 chunk
    data.killCount = 0
    data.killTarget = target
    data.isComplete = false
    data.isInitialized = true
    
    print("=== SPAWN CHUNK CHALLENGE STARTED ===")
    print("Spawn: " .. x .. ", " .. y .. ", " .. z)
    print("Boundary: " .. data.boundarySize .. " tiles")
    print("Kill Target: " .. target .. " zombies")
    print("====================================")
    
    -- Show on-screen message
    pl:setHaloNote("Challenge Started! Kill " .. target .. " zombies to escape.", 255, 255, 100, 300)
end

-- Initialize when player is created
Events.OnPlayerDeath.Add(function()
    -- Reset on death (optional - remove if you want persistence across deaths)
    local data = SpawnChunk.getData()
    data.isInitialized = false
    data.killCount = 0
    data.isComplete = false
    print("Challenge reset on death")
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