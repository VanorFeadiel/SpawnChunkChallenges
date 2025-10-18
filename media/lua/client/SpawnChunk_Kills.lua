-- SpawnChunk_Kills.lua
-- Track zombie kills and check for victory

SpawnChunk = SpawnChunk or {}

-----------------------  KILL TRACKING  ---------------------------

function SpawnChunk.onZombieDead(zombie)
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    if data.isComplete then return end
    
    -- Increment kill counter
    data.killCount = data.killCount + 1
    
    print("Kill " .. data.killCount .. " / " .. data.killTarget)
    
    -- Show progress notification every 5 kills
    if data.killCount % 5 == 0 then
        pl:setHaloNote("Kills: " .. data.killCount .. " / " .. data.killTarget, 100, 255, 100, 150)
    end
    
    -- Check for victory
    if data.killCount >= data.killTarget then
        SpawnChunk.onVictory()
    end
end

-- Hook into zombie death event
Events.OnZombieDead.Add(SpawnChunk.onZombieDead)

-----------------------  VICTORY CONDITION  ---------------------------

function SpawnChunk.onVictory()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if data.isComplete then return end -- Already won
    
    print("=== VICTORY! ===")
    
    -- Mark as complete
    data.isComplete = true
    
    -- Play victory sound
    pl:playSound("LevelUp")
    
    -- Show victory message
    pl:setHaloNote("CHALLENGE COMPLETE! You are free to explore!", 100, 255, 100, 500)
    
    -- Give victory item (a note)
    local inv = pl:getInventory()
    local item = inv:AddItem("Base.Book") -- Using vanilla book as placeholder
    if item then
        item:setName("Purge Completion Certificate")
        -- Note: Custom items would require items.txt definition
        print("Victory item awarded")
    end
    
    -- Optional: Give reward items
    inv:AddItem("Base.Axe")
    inv:AddItem("Base.Antibiotics")
    inv:AddItem("Base.WaterBottleFull")
    
    print("You can now leave the spawn area!")
end

-----------------------  UI DISPLAY  ---------------------------

function SpawnChunk.getProgressString()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return "" end
    if data.isComplete then return "Challenge Complete!" end
    
    return "Kills: " .. data.killCount .. " / " .. data.killTarget
end

-- Optional: Add UI display (would need ISUIElement implementation)
-- For now, progress shown via periodic notifications