-- SpawnChunk_Spawner.lua
-- Ensures a minimum zombie presence near the spawn chunk (modular)

SpawnChunk = SpawnChunk or {}

function SpawnChunk.ensureMinimumZombies()
    local data = SpawnChunk.getData()
    if not data or not data.isInitialized or data.isComplete then return end

    local pl = getPlayer()
    if not pl then return end

    -- Count zombies currently in loaded cells
    local nearbyZeds = getCell():getZombieList()
    local count = 0
    for i = 0, nearbyZeds:size() - 1 do
        local z = nearbyZeds:get(i)
        if z and not z:isDead() then
            count = count + 1
        end
    end

    -- Get minimum zombies from sandbox options
    local minZeds = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.MinZombies) or 3
    if count >= minZeds then return end

    local needed = minZeds - count
    local spawnX, spawnY = data.spawnX, data.spawnY
    local size = data.boundarySize

    for i = 1, needed do
        local x, y

        if size <= 10 then
            -- Fallback: spawn within 30x30 centered on spawn (safe in small chunks)
            x = spawnX + ZombRand(-15, 16)
            y = spawnY + ZombRand(-15, 16)
        else
            -- Prefer spawning just outside the boundary so players can lure them in
            if ZombRand(2) == 0 then
                -- outside left/right edges
                x = spawnX + (size + 1) * (ZombRand(2) == 0 and -1 or 1)
                y = spawnY + ZombRand(-size, size + 1)
            else
                -- outside top/bottom edges
                x = spawnX + ZombRand(-size, size + 1)
                y = spawnY + (size + 1) * (ZombRand(2) == 0 and -1 or 1)
            end
        end

        addZombiesInOutfit(x, y, pl:getZ(), 1, nil, nil)
        print(string.format("SpawnChunk_Spawner: Spawned zombie at (%d,%d)", x, y))
    end

    print("SpawnChunk_Spawner: Ensured minimum zombies, spawned " .. needed)
end

-- Run check every in-game minute (non-invasive, respects existing init/death/reset flows)
Events.EveryOneMinute.Add(SpawnChunk.ensureMinimumZombies)
