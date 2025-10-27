-- SpawnChunk_Visual.lua (CONTINUOUS BOUNDARY LINES - CHARACTER SPECIFIC)
-- Ground markers, map boundary lines, and HUD
-- Each character maintains their own visual elements

SpawnChunk = SpawnChunk or {}

-- Character-specific marker storage
SpawnChunk.characterMarkers = SpawnChunk.characterMarkers or {}
SpawnChunk.characterMapSymbols = SpawnChunk.characterMapSymbols or {}

-----------------------  CHARACTER-SPECIFIC VISUAL TRACKING  ---------------------------

function SpawnChunk.getMarkerStorage()
    local username = SpawnChunk.getUsername()
    if not username then return {} end
    
    SpawnChunk.characterMarkers[username] = SpawnChunk.characterMarkers[username] or {}
    return SpawnChunk.characterMarkers[username]
end

function SpawnChunk.getMapSymbolStorage()
    local username = SpawnChunk.getUsername()
    if not username then return {} end
    
    SpawnChunk.characterMapSymbols[username] = SpawnChunk.characterMapSymbols[username] or {}
    return SpawnChunk.characterMapSymbols[username]
end

-----------------------  GROUND BOUNDARY MARKERS  ---------------------------

function SpawnChunk.getBoundaryEdgeSquares()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return {} end
    
    local spawnX = data.spawnX
    local spawnY = data.spawnY
    local size = data.boundarySize
    
    local edgeSquares = {}
    
    -- Top and bottom edges
    for x = spawnX - size, spawnX + size do
        table.insert(edgeSquares, {x = x, y = spawnY - size})  -- Top
        table.insert(edgeSquares, {x = x, y = spawnY + size})  -- Bottom
    end
    
    -- Left and right edges (skip corners already added)
    for y = spawnY - size + 1, spawnY + size - 1 do
        table.insert(edgeSquares, {x = spawnX - size, y = y})  -- Left
        table.insert(edgeSquares, {x = spawnX + size, y = y})  -- Right
    end
    
    return edgeSquares
end

function SpawnChunk.createGroundMarkers()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    if data.isComplete then return end
    
    -- Check if ground markers are enabled in sandbox options
    local showMarkers = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ShowGroundMarkers) ~= false
    if not showMarkers then return end
    
    -- Remove old markers for this character first
    SpawnChunk.removeGroundMarkers()
    
    local username = SpawnChunk.getUsername()
    print("[" .. username .. "] Creating boundary markers...")
    
    local edgeSquares = SpawnChunk.getBoundaryEdgeSquares()
    local wm = getWorldMarkers()
    if not wm then 
        print("[" .. username .. "] ERROR: WorldMarkers not available")
        return 
    end
    
    local markerStorage = SpawnChunk.getMarkerStorage()
    
    -- Color: Yellow for active challenge
    local r, g, b = 1, 1, 0
    
    -- Add markers on EVERY boundary tile (no skipping)
    for i, eSq in ipairs(edgeSquares) do
        local sq = getCell():getOrCreateGridSquare(eSq.x, eSq.y, data.spawnZ)
        if sq then
            local marker = wm:addGridSquareMarker(nil, "X", sq, r, g, b, true, 0.3)
            if marker then
                table.insert(markerStorage, marker)
            end
        end
    end
    
    -- Add spawn point marker (green, larger)
    local spawnSq = getCell():getOrCreateGridSquare(data.spawnX, data.spawnY, data.spawnZ)
    if spawnSq then
        local spawnMarker = wm:addGridSquareMarker(nil, "SPAWN", spawnSq, 0, 1, 0, true, 1)
        if spawnMarker then
            table.insert(markerStorage, spawnMarker)
        end
    end
    
    print("[" .. username .. "] Created " .. #markerStorage .. " boundary markers")
    data.markersCreated = true
end

function SpawnChunk.removeGroundMarkers()
    local username = SpawnChunk.getUsername()
    local markerStorage = SpawnChunk.getMarkerStorage()
    
    if markerStorage then
        for _, marker in ipairs(markerStorage) do
            if marker and marker.remove then
                marker:remove()
            end
        end
        -- Clear the storage
        SpawnChunk.characterMarkers[username] = {}
    end
end

-- Create markers after initialization
Events.OnGameStart.Add(function()
    local timer = 0
    local function checkInit()
        timer = timer + 1
        if timer >= 120 then -- ~2 seconds
            local data = SpawnChunk.getData()
            if data.isInitialized and not data.markersCreated then
                SpawnChunk.createGroundMarkers()
            end
            Events.OnTick.Remove(checkInit)
        end
    end
    Events.OnTick.Add(checkInit)
end)

-- Also recreate ground markers after respawn (not just on game start)
Events.OnCreatePlayer.Add(function(playerIndex, player)
    -- Wait for initialization after respawn
    local timer = 0
    local function checkRespawnInit()
        timer = timer + 1
        if timer >= 180 then -- ~3 seconds (more time after respawn)
            local data = SpawnChunk.getData()
            if data.isInitialized and not data.markersCreated then
                SpawnChunk.createGroundMarkers()
                local username = SpawnChunk.getUsername()
                print("[" .. username .. "] Recreated ground markers after respawn")
            end
            Events.OnTick.Remove(checkRespawnInit)
        end
    end
    Events.OnTick.Add(checkRespawnInit)
end)

-- Remove markers on completion
local oldOnVictory = SpawnChunk.onVictory
function SpawnChunk.onVictory()
    if oldOnVictory then oldOnVictory() end
    SpawnChunk.removeGroundMarkers()
    SpawnChunk.removeMapSymbol()
    local username = SpawnChunk.getUsername()
    print("[" .. username .. "] Cleaned up all visual markers on victory")
end

-----------------------  MAP SYMBOLS & BOUNDARY LINES  ---------------------------

-- Draw a line on the map between two points using densely placed symbols
function SpawnChunk.drawMapLine(symbolsAPI, startX, startY, endX, endY, r, g, b, scale)
    -- Calculate distance and steps needed
    local dx = endX - startX
    local dy = endY - startY
    local distance = math.sqrt(dx*dx + dy*dy)
    
    -- Place symbols every ~0.5 world units for smooth line
    local steps = math.max(1, math.floor(distance / 0.5))
    
    local stepX = dx / steps
    local stepY = dy / steps
    
    -- Get storage for this character
    local symbolStorage = SpawnChunk.getMapSymbolStorage()
    
    -- Draw line by placing many small symbols
    for i = 0, steps do
        local worldX = startX + stepX * i
        local worldY = startY + stepY * i
        
        -- Use tiny circle texture "c" (same as Draw On Map mod uses)
        local sym = symbolsAPI:addTexture("c", worldX, worldY)
        if sym then
            sym:setRGBA(r, g, b, 1.0)
            sym:setAnchor(0.5, 0.5)
            sym:setScale(scale)
            -- Store reference to our symbol
            table.insert(symbolStorage, sym)
        end
    end
end

function SpawnChunk.addMapSymbol()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    local username = SpawnChunk.getUsername()
    
    -- Check if map symbols are enabled in sandbox options
    local showSymbols = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ShowMapSymbols) ~= false
    if not showSymbols then return end
    
    -- Try to initialize map if not ready
    if not ISWorldMap_instance then
        -- Map not initialized yet, try opening it
        local success, err = pcall(function()
            ISWorldMap.ShowWorldMap(0)
            if ISWorldMap_instance then
                ISWorldMap_instance:close()
            end
        end)
        if not success then
            print("[" .. username .. "] Map not ready yet, will retry later")
            return
        end
    end
    
    -- Verify ISWorldMap_instance exists and has javaObject
    if not ISWorldMap_instance or not ISWorldMap_instance.javaObject then 
        print("[" .. username .. "] ISWorldMap not ready, skipping map symbols")
        return 
    end
    
    -- Get map API with error checking
    local mapAPI = ISWorldMap_instance.javaObject:getAPIv1()
    if not mapAPI then 
        print("[" .. username .. "] Map API not available, skipping map symbols")
        return 
    end
    
    -- Get symbols API with error checking
    local symAPI = mapAPI:getSymbolsAPI()
    if not symAPI then 
        print("[" .. username .. "] Symbol API not available, skipping map symbols")
        return 
    end
    
    -- Remove old symbols for this character if they exist
    SpawnChunk.removeMapSymbol()
    
    -- Initialize storage for this character's map symbols
    SpawnChunk.characterMapSymbols[username] = {}
    
    print("[" .. username .. "] Drawing boundary lines on map...")
    
    -- Calculate boundary corners
    local size = data.boundarySize
    local topLeftX = data.spawnX - size
    local topLeftY = data.spawnY - size
    local topRightX = data.spawnX + size
    local topRightY = data.spawnY - size
    local bottomLeftX = data.spawnX - size
    local bottomLeftY = data.spawnY + size
    local bottomRightX = data.spawnX + size
    local bottomRightY = data.spawnY + size
    
    -- Draw 4 boundary lines (yellow)
    local scale = 0.15  -- Small scale for thin lines
    local r, g, b = 1, 1, 0  -- Yellow
    
    -- Draw lines with error handling
    local success, err = pcall(function()
        -- Top edge
        SpawnChunk.drawMapLine(symAPI, topLeftX, topLeftY, topRightX, topRightY, r, g, b, scale)
        -- Right edge
        SpawnChunk.drawMapLine(symAPI, topRightX, topRightY, bottomRightX, bottomRightY, r, g, b, scale)
        -- Bottom edge
        SpawnChunk.drawMapLine(symAPI, bottomRightX, bottomRightY, bottomLeftX, bottomLeftY, r, g, b, scale)
        -- Left edge
        SpawnChunk.drawMapLine(symAPI, bottomLeftX, bottomLeftY, topLeftX, topLeftY, r, g, b, scale)
    end)
    
    if not success then
        print("[" .. username .. "] ERROR drawing map lines: " .. tostring(err))
        return
    end
    
    -- Add spawn point marker (small green dot) with error handling
    success, err = pcall(function()
        local spawnSym = symAPI:addTexture("media/ui/Moodle_Icon_Windchill.png", data.spawnX, data.spawnY)
        if spawnSym then
            spawnSym:setAnchor(0.5, 0.5)
            spawnSym:setRGBA(0, 1, 0, 1)  -- Green
            spawnSym:setScale(0.15)
            
            local symbolStorage = SpawnChunk.getMapSymbolStorage()
            table.insert(symbolStorage, spawnSym)
            print("[" .. username .. "] Map symbols added - boundary rectangle and spawn point")
        else
            print("[" .. username .. "] WARNING: Failed to create spawn point symbol")
        end
    end)
    
    if not success then
        print("[" .. username .. "] ERROR adding spawn marker: " .. tostring(err))
    end
end

function SpawnChunk.removeMapSymbol()
    if not ISWorldMap_instance then return end
    
    local username = SpawnChunk.getUsername()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    local mapAPI = ISWorldMap_instance.javaObject:getAPIv1()
    if not mapAPI then return end
    
    local symAPI = mapAPI:getSymbolsAPI()
    if not symAPI then return end
    
    -- Only remove symbols we created for this character
    local symbolStorage = SpawnChunk.getMapSymbolStorage()
    if symbolStorage then
        local removedCount = 0
        for _, sym in ipairs(symbolStorage) do
            if sym then
                -- Find and remove this specific symbol
                for i = symAPI:getSymbolCount() - 1, 0, -1 do
                    if symAPI:getSymbolByIndex(i) == sym then
                        symAPI:removeSymbolByIndex(i)
                        removedCount = removedCount + 1
                        break
                    end
                end
            end
        end
        SpawnChunk.characterMapSymbols[username] = {}
        print("[" .. username .. "] Removed " .. removedCount .. " map symbols (other characters' symbols preserved)")
    end
end

-- Add map symbol after initialization
Events.OnGameStart.Add(function()
    local timer = 0
    local function checkInit()
        timer = timer + 1
        if timer >= 300 then -- ~5 seconds (more time for map init)
            local data = SpawnChunk.getData()
            if data.isInitialized and not data.mapSymbolCreated then
                SpawnChunk.addMapSymbol()
                data.mapSymbolCreated = true
            end
            Events.OnTick.Remove(checkInit)
        end
    end
    Events.OnTick.Add(checkInit)
end)

-- Also recreate map symbols after respawn (not just on game start)
Events.OnCreatePlayer.Add(function(playerIndex, player)
    -- Wait longer after respawn to ensure map is ready
    local timer = 0
    local function checkRespawnInit()
        timer = timer + 1
        if timer >= 360 then -- ~6 seconds (even more time after respawn)
            local data = SpawnChunk.getData()
            if data.isInitialized and not data.mapSymbolCreated then
                SpawnChunk.addMapSymbol()
                data.mapSymbolCreated = true
                local username = SpawnChunk.getUsername()
                print("[" .. username .. "] Recreated map symbols after respawn")
            end
            Events.OnTick.Remove(checkRespawnInit)
        end
    end
    Events.OnTick.Add(checkRespawnInit)
end)

-----------------------  ON-SCREEN HUD  ---------------------------

require "ISUI/ISPanel"

SpawnChunkHUD = ISPanel:derive("SpawnChunkHUD")

function SpawnChunkHUD:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    return o
end

function SpawnChunkHUD:initialise()
    ISPanel.initialise(self)
end

function SpawnChunkHUD:render()
    ISPanel.render(self)
    
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    if data.isComplete then
        self:drawText("Challenge Complete!", 10, 10, 0, 1, 0, 1, UIFont.Medium)
        return
    end
    
    local pl = getPlayer()
    if not pl then return end
    
    -- Draw progress
    local progressText = "Kills: " .. data.killCount .. " / " .. data.killTarget
    self:drawText(progressText, 10, 10, 1, 1, 1, 1, UIFont.Medium)
    
    -- Draw distance to boundary
    local dx = math.abs(pl:getX() - data.spawnX)
    local dy = math.abs(pl:getY() - data.spawnY)
    local distToBoundary = data.boundarySize - math.max(dx, dy)
    
    local distText = "Distance to boundary: " .. math.floor(distToBoundary) .. " tiles"
    local color = distToBoundary < 10 and {r=1, g=0, b=0} or {r=1, g=1, b=1}
    self:drawText(distText, 10, 35, color.r, color.g, color.b, 1, UIFont.Small)
    
    -- Debug information (only if debug mode is enabled)
    local debugMode = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.DebugMode) or false
    if debugMode then
        -- Count zombies in loaded cells
        local nearbyZeds = getCell():getZombieList()
        local zombieCount = 0
        local closestZombie = nil
        local closestDistance = 999999
        
        if nearbyZeds then
            for i = 0, nearbyZeds:size() - 1 do
                local z = nearbyZeds:get(i)
                if z and not z:isDead() then
                    zombieCount = zombieCount + 1
                    
                    -- Calculate distance to this zombie from spawn point
                    local zx = z:getX()
                    local zy = z:getY()
                    local dx = math.abs(zx - data.spawnX)
                    local dy = math.abs(zy - data.spawnY)
                    local distance = math.sqrt(dx * dx + dy * dy)
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestZombie = z
                    end
                end
            end
        end
        
        -- Debug info with spawn/sound tracking
        local yPos = 60
        self:drawText("=== DEBUG INFO ===", 10, yPos, 1, 1, 0, 1, UIFont.Small)
        yPos = yPos + 15
        
        self:drawText("Zombie Population: " .. zombieCount, 10, yPos, 1, 1, 1, 1, UIFont.Small)
        yPos = yPos + 15
        
        -- Show closest zombie distance
        if closestZombie then
            local distText = string.format("Closest Zombie: %.1f tiles", closestDistance)
            -- Color code based on distance
            local r, g, b = 1, 1, 1  -- White default
            if closestDistance < data.boundarySize then
                r, g, b = 0, 1, 0  -- Green - inside boundary
            elseif closestDistance < data.boundarySize + 50 then
                r, g, b = 1, 1, 0  -- Yellow - nearby
            else
                r, g, b = 1, 0.5, 0  -- Orange - far away
            end
            self:drawText(distText, 10, yPos, r, g, b, 1, UIFont.Small)
            yPos = yPos + 15
            
            -- Show if zombie is approaching
            if data.lastClosestZombieDistance then
                local isApproaching = closestDistance < data.lastClosestZombieDistance
                local approachText = isApproaching and "APPROACHING" or "NOT APPROACHING"
                local ar, ag, ab = isApproaching and 0 or 1, isApproaching and 1 or 0.5, 0
                self:drawText("Status: " .. approachText, 10, yPos, ar, ag, ab, 1, UIFont.Small)
                yPos = yPos + 15
            end
        else
            self:drawText("Closest Zombie: N/A", 10, yPos, 0.5, 0.5, 0.5, 1, UIFont.Small)
            yPos = yPos + 15
        end
        
        self:drawText("Boundary Size: " .. data.boundarySize .. " tiles", 10, yPos, 1, 1, 1, 1, UIFont.Small)
        yPos = yPos + 15
        
        self:drawText("Position: (" .. math.floor(pl:getX()) .. ", " .. math.floor(pl:getY()) .. ")", 10, yPos, 1, 1, 1, 1, UIFont.Small)
        yPos = yPos + 15
        
        self:drawText("Spawn: (" .. data.spawnX .. ", " .. data.spawnY .. ")", 10, yPos, 1, 1, 1, 1, UIFont.Small)
        yPos = yPos + 15
        
        -- Spawn/Sound tracking stats
        self:drawText("--- Spawner Stats ---", 10, yPos, 1, 1, 0, 1, UIFont.Small)
        yPos = yPos + 15
        
        local totalSpawned = data.totalSpawned or 0
        self:drawText("Zombies Spawned: " .. totalSpawned, 10, yPos, 0.5, 1, 0.5, 1, UIFont.Small)
        yPos = yPos + 15
        
        local totalWaves = data.totalSoundWaves or 0
        self:drawText("Sound Waves: " .. totalWaves, 10, yPos, 0.5, 1, 0.5, 1, UIFont.Small)
        yPos = yPos + 15
        
        local maxRadius = data.maxSoundRadius or 0
        self:drawText("Max Sound Radius: " .. maxRadius .. " tiles", 10, yPos, 0.5, 1, 0.5, 1, UIFont.Small)
        yPos = yPos + 15
        
        -- Show current sound wave reach (if waves have been emitted)
        if totalWaves > 0 then
            local currentReach = data.currentSoundRadius or 0
            self:drawText("Current Sound Reach: " .. currentReach .. " tiles", 10, yPos, 0.5, 1, 0.5, 1, UIFont.Small)
            yPos = yPos + 15
        end
        
        -- Show if debug close spawn is active
        local debugCloseSpawn = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.DebugCloseSpawn) or false
        if debugCloseSpawn then
            self:drawText("DEBUG: Close Spawn Active", 10, yPos, 1, 0.5, 0, 1, UIFont.Small)
        end
    end
end

-- Create and add HUD
local function createHUD()
    -- Check if HUD is enabled in sandbox options
    local showHUD = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ShowHUD) ~= false
    if not showHUD then return end
    
    local hud = SpawnChunkHUD:new(10, 100, 300, 80)
    hud:initialise()
    hud:addToUIManager()
    hud:setVisible(true)
end

Events.OnGameStart.Add(function()
    local timer = 0
    local function checkUI()
        timer = timer + 1
        if timer >= 60 then -- ~1 second
            createHUD()
            Events.OnTick.Remove(checkUI)
        end
    end
    Events.OnTick.Add(checkUI)
end)

-----------------------  WARNING TEXT  ---------------------------

require "ISUI/ISUIElement"

SpawnChunkBoundaryRenderer = ISUIElement:derive("SpawnChunkBoundaryRenderer")

function SpawnChunkBoundaryRenderer:new()
    local o = ISUIElement:new(0, 0, 0, 0)
    setmetatable(o, self)
    self.__index = self
    return o
end

function SpawnChunkBoundaryRenderer:render()
    local pl = getPlayer()
    if not pl then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized or data.isComplete then return end
    
    -- Check if HUD is enabled in sandbox options
    local showHUD = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ShowHUD) ~= false
    if not showHUD then return end
    
    local dx = math.abs(pl:getX() - data.spawnX)
    local dy = math.abs(pl:getY() - data.spawnY)
    local size = data.boundarySize
    
    -- Calculate distance to boundary (same as HUD uses)
    local distToBoundary = size - math.max(dx, dy)
    
    -- Show warning when getting close (matches red text threshold exactly)
    if distToBoundary < 10 then
        self:drawTextCentre("WARNING: Approaching boundary!", 
            getCore():getScreenWidth() / 2, 
            50, 
            1, 0, 0, 1, 
            UIFont.Large)
    end
end

-- Add boundary renderer
Events.OnGameStart.Add(function()
    local renderer = SpawnChunkBoundaryRenderer:new()
    renderer:initialise()
    renderer:addToUIManager()
end)
