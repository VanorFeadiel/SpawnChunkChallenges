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

-- Get boundary edge squares for a specific chunk
function SpawnChunk.getChunkBoundaryEdges(chunkKey, data)
    local centerX, centerY = SpawnChunk.getChunkCenter(chunkKey, data)
    if not centerX then return {} end
    
    local size = data.boundarySize
    local edgeSquares = {}
    
    -- Top and bottom edges
    for x = centerX - size, centerX + size do
        table.insert(edgeSquares, {x = x, y = centerY - size})  -- Top
        table.insert(edgeSquares, {x = x, y = centerY + size})  -- Bottom
    end
    
    -- Left and right edges (skip corners already added)
    for y = centerY - size + 1, centerY + size - 1 do
        table.insert(edgeSquares, {x = centerX - size, y = y})  -- Left
        table.insert(edgeSquares, {x = centerX + size, y = y})  -- Right
    end
    
    return edgeSquares
end

-- Get all boundary edge squares (supports both classic and chunk mode)
function SpawnChunk.getBoundaryEdgeSquares()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return {} end
    
    local allEdgeSquares = {}
    
    if data.chunkMode then
        -- Get boundaries for all unlocked chunks
        local unlockedChunks = SpawnChunk.getUnlockedChunks()
        for _, chunkKey in ipairs(unlockedChunks) do
            local chunkEdges = SpawnChunk.getChunkBoundaryEdges(chunkKey, data)
            for _, edge in ipairs(chunkEdges) do
                table.insert(allEdgeSquares, edge)
            end
        end
        
        -- Also get boundaries for available (not yet unlocked) chunks
        if data.chunks then
            for chunkKey, chunkData in pairs(data.chunks) do
                if chunkData.available and not chunkData.unlocked then
                    local chunkEdges = SpawnChunk.getChunkBoundaryEdges(chunkKey, data)
                    for _, edge in ipairs(chunkEdges) do
                        table.insert(allEdgeSquares, edge)
                    end
                end
            end
        end
    else
        -- Classic mode: single boundary
        local spawnX = data.spawnX
        local spawnY = data.spawnY
        local size = data.boundarySize
        
        -- Top and bottom edges
        for x = spawnX - size, spawnX + size do
            table.insert(allEdgeSquares, {x = x, y = spawnY - size})  -- Top
            table.insert(allEdgeSquares, {x = x, y = spawnY + size})  -- Bottom
        end
        
        -- Left and right edges (skip corners already added)
        for y = spawnY - size + 1, spawnY + size - 1 do
            table.insert(allEdgeSquares, {x = spawnX - size, y = y})  -- Left
            table.insert(allEdgeSquares, {x = spawnX + size, y = y})  -- Right
        end
    end
    
    return allEdgeSquares
end

function SpawnChunk.createGroundMarkers()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    -- In classic mode only, skip if complete
    if not data.chunkMode and data.isComplete then return end
    
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
    
    -- In chunk mode, we'll color-code chunks
    -- For now, just use yellow for all boundaries
    -- (Future enhancement: different colors for completed vs active chunks)
    
    -- Add markers on EVERY boundary tile (no skipping)
    for i, eSq in ipairs(edgeSquares) do
        local sq = getCell():getOrCreateGridSquare(eSq.x, eSq.y, data.spawnZ)
        if sq then
            -- Determine color based on mode and chunk status
            local r, g, b = 1, 1, 0  -- Yellow default
            
            -- In chunk mode, check if this position is in current or completed chunk
            if data.chunkMode then
                -- Find which chunk this edge belongs to
                local chunkKey = SpawnChunk.getChunkKeyFromPosition(eSq.x, eSq.y, data)
                local chunkData = SpawnChunk.getChunkData(chunkKey)
                
                if chunkData then
                    if chunkData.completed then
                        r, g, b = 0, 1, 0  -- Green for completed chunks
                    elseif chunkData.available and not chunkData.unlocked then
                        r, g, b = 0.5, 0.5, 1  -- Blue for available (not yet unlocked)
                    elseif chunkKey == data.currentChunk then
                        r, g, b = 1, 1, 0  -- Yellow for current chunk
                    else
                        r, g, b = 1, 0.5, 0  -- Orange for other unlocked chunks
                    end
                end
            end
            
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
    
    local scale = 0.1  -- Small scale for thin lines
    
    -- Draw boundaries based on mode
    if data.chunkMode then
        -- CHUNK MODE: Draw boundaries for all unlocked chunks
        local unlockedChunks = SpawnChunk.getUnlockedChunks()
        
        -- Draw unlocked chunks
        for _, chunkKey in ipairs(unlockedChunks) do
            local chunkData = SpawnChunk.getChunkData(chunkKey)
            local minX, minY, maxX, maxY = SpawnChunk.getChunkBounds(chunkKey, data)
            
            if minX then
                -- Determine color based on chunk status
                local r, g, b
                if chunkData and chunkData.completed then
                    r, g, b = 0, 1, 0  -- Green for completed
                elseif chunkKey == data.currentChunk then
                    r, g, b = 1, 1, 0  -- Yellow for current
                else
                    r, g, b = 1, 0.5, 0  -- Orange for other unlocked
                end
                
                -- Draw 4 boundary lines for this chunk
                local success, err = pcall(function()
                    -- Top edge
                    SpawnChunk.drawMapLine(symAPI, minX, minY, maxX, minY, r, g, b, scale)
                    -- Right edge
                    SpawnChunk.drawMapLine(symAPI, maxX, minY, maxX, maxY, r, g, b, scale)
                    -- Bottom edge
                    SpawnChunk.drawMapLine(symAPI, maxX, maxY, minX, maxY, r, g, b, scale)
                    -- Left edge
                    SpawnChunk.drawMapLine(symAPI, minX, maxY, minX, minY, r, g, b, scale)
                end)
                
                if not success then
                    print("[" .. username .. "] ERROR drawing map lines for " .. chunkKey .. ": " .. tostring(err))
                end
            end
        end
        
        -- Also draw available (not yet unlocked) chunks
        if data.chunks then
            for chunkKey, chunkData in pairs(data.chunks) do
                if chunkData.available and not chunkData.unlocked then
                    local minX, minY, maxX, maxY = SpawnChunk.getChunkBounds(chunkKey, data)
                    
                    if minX then
                        -- Blue for available chunks
                        local r, g, b = 0.5, 0.5, 1
                        
                        -- Draw 4 boundary lines for this chunk
                        local success, err = pcall(function()
                            -- Top edge
                            SpawnChunk.drawMapLine(symAPI, minX, minY, maxX, minY, r, g, b, scale)
                            -- Right edge
                            SpawnChunk.drawMapLine(symAPI, maxX, minY, maxX, maxY, r, g, b, scale)
                            -- Bottom edge
                            SpawnChunk.drawMapLine(symAPI, maxX, maxY, minX, maxY, r, g, b, scale)
                            -- Left edge
                            SpawnChunk.drawMapLine(symAPI, minX, maxY, minX, minY, r, g, b, scale)
                        end)
                        
                        if not success then
                            print("[" .. username .. "] ERROR drawing map lines for available chunk " .. chunkKey .. ": " .. tostring(err))
                        end
                    end
                end
            end
        end
    else
        -- CLASSIC MODE: Single boundary
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
    end
    
    -- Add spawn point marker (small green dot) with error handling
    success, err = pcall(function()
        local spawnSym = symAPI:addTexture("media/ui/Moodle_Icon_Windchill.png", data.spawnX, data.spawnY)
        if spawnSym then
            spawnSym:setAnchor(0.5, 0.5)
            spawnSym:setRGBA(0, 1, 0, 1)  -- Green
            spawnSym:setScale(0.1)
            
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

require "ISUI/ISCollapsableWindow"

SpawnChunkHUD = ISCollapsableWindow:derive("SpawnChunkHUD")

function SpawnChunkHUD:createChildren()
    -- Title handled by ISCollapsableWindow
    ISCollapsableWindow.createChildren(self)
end

function SpawnChunkHUD:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o:setTitle("SpawnChunk HUD")
    o:setResizable(true)
    
    return o
end

function SpawnChunkHUD:render()
    ISCollapsableWindow.render(self)
    
    -- Don't render content if collapsed
    if self.collapsed then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    local pl = getPlayer()
    if not pl then return end
    
    -- Content starts below title bar (25px)
    local TITLE_BAR_HEIGHT = 25
    local contentYOffset = TITLE_BAR_HEIGHT
    
    -- Draw progress based on mode
    local progressText
    local currentY = contentYOffset + 5  -- Track current Y position for drawing
    local chunkCompleted = false
    
    if data.chunkMode then
        -- Detect which chunk player is currently standing in
        local playerX = math.floor(pl:getX())
        local playerY = math.floor(pl:getY())
        local playerChunkKey = SpawnChunk.getChunkKeyFromPosition(playerX, playerY, data)
        local playerChunkData = data.chunks and data.chunks[playerChunkKey]
        
        if playerChunkData and playerChunkData.unlocked then
            -- Player is in an unlocked chunk
            if playerChunkData.completed then
                progressText = "Chunk " .. playerChunkKey .. " Complete!"
                self:drawText(progressText, 10, currentY, 0, 1, 0, 1, UIFont.Medium)
                chunkCompleted = true
                currentY = currentY + 25
                
                -- For Zero to Hero, show unlock count even when completed
                if data.challengeType == "ZeroToHero" then
                    local unlocksAvailable = #(data.pendingSkillUnlocks or {})
                    local unlockText = "Unlocks Available: " .. unlocksAvailable
                    self:drawText(unlockText, 10, currentY, 1, 1, 1, 1, UIFont.Small)
                    currentY = currentY + 20
                end
            else
                -- Use challenge-specific progress text
                progressText = "Chunk " .. playerChunkKey .. " - " .. SpawnChunk.getChallengeProgressText()
                self:drawText(progressText, 10, currentY, 1, 1, 1, 1, UIFont.Medium)
                currentY = currentY + 25
            end
        else
            -- Player is in a locked or invalid chunk
            progressText = "In locked chunk: " .. playerChunkKey
            self:drawText(progressText, 10, currentY, 1, 0.5, 0.5, 1, UIFont.Medium)
            currentY = currentY + 25
        end
        
        -- Show spawn delay status or paused status (currentY already incremented above)
        local spawnDelayActive = false
        local remainingMinutes = 0
        
        if data.spawnDelayUntil then
            local gameTime = getGameTime()
            local currentMinutes = gameTime:getWorldAgeHours() * 60
            spawnDelayActive = currentMinutes < data.spawnDelayUntil
            if spawnDelayActive then
                remainingMinutes = math.ceil(data.spawnDelayUntil - currentMinutes)
            end
        end
        
        if chunkCompleted then
            -- Show spawning paused message
            self:drawText("⏸ Spawning PAUSED - Enter new chunk to continue", 10, currentY, 1, 1, 0, 1, UIFont.Small)
            currentY = currentY + 20
        elseif spawnDelayActive then
            local delayText = string.format("⏳ Spawn Delay: %d in-game min remaining", remainingMinutes)
            self:drawText(delayText, 10, currentY, 0.5, 1, 1, 1, UIFont.Small)
            currentY = currentY + 20
        end
        
        -- Show unlocked chunks count
        local unlockedCount = #SpawnChunk.getUnlockedChunks()
        local chunksText = "Unlocked Chunks: " .. unlockedCount
        self:drawText(chunksText, 10, currentY, 0.7, 1, 0.7, 1, UIFont.Small)
        currentY = currentY + 20
    else
        if data.isComplete then
            self:drawText("Challenge Complete!", 10, currentY, 0, 1, 0, 1, UIFont.Medium)
            return
        end
        -- Use challenge-specific progress text
        progressText = SpawnChunk.getChallengeProgressText()
        self:drawText(progressText, 10, currentY, 1, 1, 1, 1, UIFont.Medium)
        currentY = currentY + 25
    end
    
    -- Draw distance to boundary
    local yOffset = currentY
    
    -- Calculate distance to boundary of all allowed chunks
    local distToBoundary = SpawnChunk.getDistanceToAllowedBoundary(pl:getX(), pl:getY())
    
    local distText = "Distance to boundary: " .. math.floor(distToBoundary) .. " tiles"
    local color = distToBoundary < 10 and {r=1, g=0, b=0} or {r=1, g=1, b=1}
    self:drawText(distText, 10, yOffset, color.r, color.g, color.b, 1, UIFont.Small)
    
    -- Update currentY to track position for debug info
    currentY = yOffset + 20
    
    -- Debug information (only if debug mode is enabled)
    local debugMode = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.DebugMode) or false
    if debugMode then
        -- Count zombies in loaded cells
        local nearbyZeds = getCell():getZombieList()
        local zombieCount = 0
        local closestZombie = nil
        local closestDistance = 999999
        
        if nearbyZeds then
            -- Get reference point for distance calculation (same as boundary check)
            local debugRefX, debugRefY
            if data.chunkMode and data.currentChunk then
                debugRefX, debugRefY = SpawnChunk.getChunkCenter(data.currentChunk, data)
                if not debugRefX then
                    debugRefX, debugRefY = data.spawnX, data.spawnY
                end
            else
                debugRefX, debugRefY = data.spawnX, data.spawnY
            end
            
            for i = 0, nearbyZeds:size() - 1 do
                local z = nearbyZeds:get(i)
                if z and not z:isDead() then
                    zombieCount = zombieCount + 1
                    
                    -- Calculate distance to this zombie from current chunk center (or spawn in classic)
                    local zx = z:getX()
                    local zy = z:getY()
                    local dx = math.abs(zx - debugRefX)
                    local dy = math.abs(zy - debugRefY)
                    local distance = math.sqrt(dx * dx + dy * dy)
                    
                    if distance < closestDistance then
                        closestDistance = distance
                        closestZombie = z
                    end
                end
            end
        end
        
        -- Debug info with spawn/sound tracking
        local yPos = currentY
        self:drawText("=== DEBUG INFO ===", 10, yPos, 1, 1, 0, 1, UIFont.Small)
        yPos = yPos + 15
        
        -- Show mod version
        self:drawText("Mod Version: " .. (SpawnChunk.MOD_VERSION or "Unknown"), 10, yPos, 0.7, 0.7, 0.7, 1, UIFont.Small)
        yPos = yPos + 15
        
        self:drawText("Zombie Population: " .. zombieCount, 10, yPos, 1, 1, 1, 1, UIFont.Small)
        yPos = yPos + 15
        
        -- Always show attacking structure status
        local attackingStatus = data.zombieAttackingStructure and "YES" or "NO"
        local asr, asg, asb = data.zombieAttackingStructure and 1 or 0.5, data.zombieAttackingStructure and 0.5 or 0.5, 0
        self:drawText("Attacking Structure: " .. attackingStatus, 10, yPos, asr, asg, asb, 1, UIFont.Small)
        yPos = yPos + 15
        
        -- Show closest zombie distance
        if closestZombie then
            -- Distance from chunk center (used for spawner logic)
            local distText = string.format("Closest Zombie (from center): %.1f tiles", closestDistance)
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
            
            -- Distance from player (more useful for player awareness)
            local distFromPlayer = data.closestZombieFromPlayer or 0
            local playerDistText = string.format("Closest Zombie (from you): %.1f tiles", distFromPlayer)
            local pr, pg, pb = 1, 1, 1  -- White default
            if distFromPlayer < 20 then
                pr, pg, pb = 1, 0, 0  -- Red - very close!
            elseif distFromPlayer < 40 then
                pr, pg, pb = 1, 1, 0  -- Yellow - nearby
            else
                pr, pg, pb = 0, 1, 0  -- Green - far away
            end
            self:drawText(playerDistText, 10, yPos, pr, pg, pb, 1, UIFont.Small)
            yPos = yPos + 15
            
            -- Show if zombie is approaching
            if data.lastClosestZombieDistance then
                local isApproaching = closestDistance < data.lastClosestZombieDistance
                local attackingStructure = data.zombieAttackingStructure or false
                
                local statusText
                if attackingStructure then
                    statusText = "ATTACKING STRUCTURE"
                    self:drawText("Status: " .. statusText, 10, yPos, 1, 0.5, 0, 1, UIFont.Small)  -- Orange
                    yPos = yPos + 15
                    
                    -- Show attack target details
                    if data.attackTargetName then
                        -- Show target name with opacity status
                        local opaqueStatus = data.attackTargetOpaque and "(Opaque)" or "(Transparent)"
                        local targetText = "→ Target: " .. data.attackTargetName .. " " .. opaqueStatus
                        self:drawText(targetText, 10, yPos, 0.7, 0.7, 0.7, 1, UIFont.Small)
                        yPos = yPos + 15
                        
                        -- Show damage status (if known)
                        if data.damageThisCycle == true then
                            self:drawText("→ Damage: ⚔ DEALING DAMAGE!", 10, yPos, 1, 0, 0, 1, UIFont.Small)  -- Red - damage happening!
                            yPos = yPos + 15
                        elseif data.damageThisCycle == false then
                            self:drawText("→ Damage: No damage (hitting but not breaking)", 10, yPos, 1, 1, 0, 1, UIFont.Small)  -- Yellow - no damage
                            yPos = yPos + 15
                            
                            -- Show attack duration if tracking
                            if data.attackStartTime then
                                local gameTime = getGameTime()
                                local currentMinutes = gameTime:getWorldAgeHours() * 60
                                local attackDuration = math.floor(currentMinutes - data.attackStartTime)
                                local durationText = string.format("   Attack duration: %d in-game min (stuck at 1 hr)", attackDuration)
                                
                                -- Color based on how close to threshold
                                local dr, dg, db = 1, 1, 0  -- Yellow default
                                if attackDuration >= 60 then
                                    dr, dg, db = 1, 0, 0  -- Red - threshold reached!
                                elseif attackDuration >= 45 then
                                    dr, dg, db = 1, 0.5, 0  -- Orange - getting close
                                end
                                
                                self:drawText(durationText, 10, yPos, dr, dg, db, 1, UIFont.Small)
                                yPos = yPos + 15
                            end
                        else
                            -- Unknown damage status or functionally indestructible
                            if data.attackTargetFunctionallyIndestructible then
                                self:drawText("→ Damage: FUNCTIONALLY INDESTRUCTIBLE", 10, yPos, 1, 0, 0, 1, UIFont.Small)  -- Red
                                yPos = yPos + 15
                                self:drawText("   (No damage after 1 in-game hour)", 10, yPos, 0.7, 0.7, 0.7, 1, UIFont.Small)
                                yPos = yPos + 15
                            else
                                self:drawText("→ Damage: Unknown (no health data)", 10, yPos, 0.5, 0.5, 0.5, 1, UIFont.Small)  -- Gray
                                yPos = yPos + 15
                            end
                            
                            -- Warn about indestructible structure
                            self:drawText("⚠ Structure INDESTRUCTIBLE!", 10, yPos, 1, 0.5, 0, 1, UIFont.Small)  -- Orange warning
                            yPos = yPos + 15
                            self:drawText("   (Zombie is stuck, backup will spawn)", 10, yPos, 0.7, 0.7, 0.7, 1, UIFont.Small)  -- Gray info
                            yPos = yPos + 15
                        end
                        
                        -- Show health bar if available
                        if data.attackTargetHealth and data.attackTargetMaxHealth then
                            local healthPercent = (data.attackTargetHealth / data.attackTargetMaxHealth) * 100
                            local healthText = string.format("→ Health: %.0f / %.0f (%.0f%%)", 
                                data.attackTargetHealth, data.attackTargetMaxHealth, healthPercent)
                            
                            -- Color code based on health percentage
                            local hr, hg, hb
                            if healthPercent > 66 then
                                hr, hg, hb = 0, 1, 0  -- Green - high health
                            elseif healthPercent > 33 then
                                hr, hg, hb = 1, 1, 0  -- Yellow - medium health
                            else
                                hr, hg, hb = 1, 0, 0  -- Red - low health, about to break!
                            end
                            
                            self:drawText(healthText, 10, yPos, hr, hg, hb, 1, UIFont.Small)
                            yPos = yPos + 15
                            
                            -- Show visual health bar
                            local barWidth = 100
                            local barHeight = 8
                            local barX = 15
                            local barY = yPos
                            
                            -- Draw background (black)
                            self:drawRect(barX, barY, barWidth, barHeight, 1, 0, 0, 0)
                            
                            -- Draw health bar (color coded)
                            local healthBarWidth = math.floor((barWidth - 2) * (healthPercent / 100))
                            self:drawRect(barX + 1, barY + 1, healthBarWidth, barHeight - 2, 1, hr, hg, hb)
                            
                            -- Draw border (white)
                            self:drawRectBorder(barX, barY, barWidth, barHeight, 1, 1, 1, 1)
                            
                            yPos = yPos + barHeight + 5
                        elseif data.attackTargetHealth then
                            -- Health available but no max health
                            local healthText = string.format("→ Health: %.0f", data.attackTargetHealth)
                            self:drawText(healthText, 10, yPos, 1, 1, 0, 1, UIFont.Small)
                            yPos = yPos + 15
                        else
                            -- No health info available
                            self:drawText("→ Health: Unknown", 10, yPos, 0.5, 0.5, 0.5, 1, UIFont.Small)
                            yPos = yPos + 15
                        end
                    end
                elseif isApproaching then
                    statusText = "APPROACHING"
                    self:drawText("Status: " .. statusText, 10, yPos, 0, 1, 0, 1, UIFont.Small)  -- Green
                    yPos = yPos + 15
                else
                    statusText = "NOT APPROACHING"
                    self:drawText("Status: " .. statusText, 10, yPos, 1, 0.5, 0, 1, UIFont.Small)  -- Orange
                    yPos = yPos + 15
                end
            end
        else
            self:drawText("Closest Zombie: N/A", 10, yPos, 0.5, 0.5, 0.5, 1, UIFont.Small)
            yPos = yPos + 15
        end
        
        self:drawText("Boundary Size: " .. data.boundarySize .. " tiles", 10, yPos, 1, 1, 1, 1, UIFont.Small)
        yPos = yPos + 15
        
        self:drawText("Position: (" .. math.floor(pl:getX()) .. ", " .. math.floor(pl:getY()) .. ")", 10, yPos, 1, 1, 1, 1, UIFont.Small)
        yPos = yPos + 15
        
		-- Show HUD window position for adjustment
        self:drawText("HUD Position: (" .. self:getX() .. ", " .. self:getY() .. ")", 10, yPos, 0.7, 1, 1, 1, UIFont.Small)
        yPos = yPos + 15
		
        self:drawText("Spawn: (" .. data.spawnX .. ", " .. data.spawnY .. ")", 10, yPos, 1, 1, 1, 1, UIFont.Small)
        yPos = yPos + 15
        
        -- Show current reference point (chunk center in chunk mode)
        if data.chunkMode and data.currentChunk then
            local currentRefX, currentRefY = SpawnChunk.getChunkCenter(data.currentChunk, data)
            if currentRefX then
                self:drawText(string.format("Current Chunk Center: (%d, %d)", currentRefX, currentRefY), 10, yPos, 0.5, 1, 0.5, 1, UIFont.Small)
                yPos = yPos + 15
            end
            
            -- Show bounding box of all allowed chunks
            local minChunkX, maxChunkX, minChunkY, maxChunkY = nil, nil, nil, nil
            if data.chunks then
                for chunkKey, chunkData in pairs(data.chunks) do
                    if chunkData.unlocked or chunkData.available then
                        local coords = SpawnChunk.parseChunkKey(chunkKey)
                        if coords then
                            if not minChunkX or coords.chunkX < minChunkX then minChunkX = coords.chunkX end
                            if not maxChunkX or coords.chunkX > maxChunkX then maxChunkX = coords.chunkX end
                            if not minChunkY or coords.chunkY < minChunkY then minChunkY = coords.chunkY end
                            if not maxChunkY or coords.chunkY > maxChunkY then maxChunkY = coords.chunkY end
                        end
                    end
                end
            end
            
            if minChunkX then
                local boundarySize = data.boundarySize
                local chunkSize = (boundarySize * 2) + 1
                local minCenterX = data.spawnX + (minChunkX * chunkSize)
                local maxCenterX = data.spawnX + (maxChunkX * chunkSize)
                local minCenterY = data.spawnY + (minChunkY * chunkSize)
                local maxCenterY = data.spawnY + (maxChunkY * chunkSize)
                local westBoundary = minCenterX - boundarySize
                local eastBoundary = maxCenterX + boundarySize
                local northBoundary = minCenterY - boundarySize
                local southBoundary = maxCenterY + boundarySize
                
                self:drawText(string.format("Allowed Area: X[%d to %d] Y[%d to %d]", 
                    westBoundary, eastBoundary, northBoundary, southBoundary), 
                    10, yPos, 0.7, 0.7, 1, 1, UIFont.Small)
                yPos = yPos + 15
                
                local width = eastBoundary - westBoundary
                local height = southBoundary - northBoundary
                self:drawText(string.format("Allowed Size: %d x %d tiles", width, height), 
                    10, yPos, 0.7, 0.7, 1, 1, UIFont.Small)
                yPos = yPos + 15
            end
        end
        
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
        
        -- Show stuck detection status (always show if there's a zombie)
        local consecutiveNonApproaching = data.consecutiveNonApproachingWaves or 0
        if closestZombie then
            local stuckWarning = string.format("Non-Progress Waves: %d / 10", consecutiveNonApproaching)
            local r = consecutiveNonApproaching >= 8 and 1 or 1  -- Red if close to threshold
            local g = consecutiveNonApproaching >= 8 and 0 or 0.7  -- Orange/Red gradient
            
            -- Color code based on severity
            if consecutiveNonApproaching == 0 then
                r, g = 0, 1  -- Green - making progress
            elseif consecutiveNonApproaching < 5 then
                r, g = 1, 1  -- Yellow - minor concern
            elseif consecutiveNonApproaching < 8 then
                r, g = 1, 0.7  -- Orange - getting stuck
            else
                r, g = 1, 0  -- Red - very stuck
            end
            
            self:drawText(stuckWarning, 10, yPos, r, g, 0, 1, UIFont.Small)
            yPos = yPos + 15
            
            if consecutiveNonApproaching >= 10 then
                self:drawText("🆘 Spawning backup zombie!", 10, yPos, 1, 0, 0, 1, UIFont.Small)
                yPos = yPos + 15
            elseif consecutiveNonApproaching >= 8 then
                self:drawText("⚠ Zombie stuck! Backup will spawn at 10", 10, yPos, 1, 0, 0, 1, UIFont.Small)
                yPos = yPos + 15
            end
        end
        
        -- Show directional spawn tracking
        local stuckCount = 0
        local stuckDirections = {}
        for dir, stuckInfo in pairs(data.stuckZombiesByDirection or {}) do
            if stuckInfo.isStuck then
                stuckCount = stuckCount + 1
                table.insert(stuckDirections, dir)
            end
        end
        
        if stuckCount > 0 then
            self:drawText("--- Stuck Zombie Tracking ---", 10, yPos, 1, 1, 0, 1, UIFont.Small)
            yPos = yPos + 15
            
            local stuckText = string.format("Stuck Directions: %d / 4", stuckCount)
            local sr, sg, sb = 1, 1, 1
            if stuckCount >= 4 then
                sr, sg, sb = 1, 0, 0  -- Red - all directions stuck!
            elseif stuckCount >= 2 then
                sr, sg, sb = 1, 0.7, 0  -- Orange - multiple stuck
            else
                sr, sg, sb = 1, 1, 0  -- Yellow - one stuck
            end
            
            self:drawText(stuckText, 10, yPos, sr, sg, sb, 1, UIFont.Small)
            yPos = yPos + 15
            
            -- List stuck directions with position info
            for _, dir in ipairs(stuckDirections) do
                local dirInfo = data.stuckZombiesByDirection[dir]
                local statusText = dirInfo.targetOpaque and "(Opaque-Despawned)" or "(Transparent-Active)"
                local dirText = string.format("  %s: %s %s", 
                    dir:upper(), 
                    dirInfo.targetName or "Unknown",
                    statusText)
                self:drawText(dirText, 10, yPos, 0.7, 0.7, 0.7, 1, UIFont.Small)
                yPos = yPos + 15
                
                -- Show stuck position if available
                if dirInfo.stuckX and dirInfo.stuckY then
                    local posText = string.format("    Stuck at: (%d, %d)", dirInfo.stuckX, dirInfo.stuckY)
                    self:drawText(posText, 10, yPos, 0.5, 0.5, 0.5, 1, UIFont.Small)
                    yPos = yPos + 15
                end
            end
            
            -- Show next spawn direction
            if data.lastSpawnDirection then
                local nextDir = SpawnChunk.getNextSpawnDirection(data)
                self:drawText("Next Spawn Direction: " .. nextDir:upper(), 10, yPos, 0.5, 1, 0.5, 1, UIFont.Small)
                yPos = yPos + 15
            end
        end
        
        -- Challenge stuck flag
        if data.challengeStuckFlag then
            self:drawText("⚠️ CHALLENGE STUCK FLAG ACTIVE!", 10, yPos, 1, 0, 0, 1, UIFont.Small)
            yPos = yPos + 15
            self:drawText("All 4 directions have stuck zombies!", 10, yPos, 1, 0, 0, 1, UIFont.Small)
            yPos = yPos + 15
        end
        
        -- Show if debug close spawn is active
        local debugCloseSpawn = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.DebugCloseSpawn) or false
        if debugCloseSpawn then
            self:drawText("DEBUG: Close Spawn Active", 10, yPos, 1, 0.5, 0, 1, UIFont.Small)
        end
    end
end

function SpawnChunkHUD:onResize()
    ISCollapsableWindow.onResize(self)
    
    local data = SpawnChunk.getData()
    data.hudWindowWidth = self.width
    data.hudWindowHeight = self.height
end

function SpawnChunkHUD:onMove()
    ISCollapsableWindow.onMove(self)
    
    local data = SpawnChunk.getData()
    data.hudWindowX = self:getX()
    data.hudWindowY = self:getY()
end

function SpawnChunkHUD:onToggleCollapse()
    ISCollapsableWindow.onToggleCollapse(self)
    
    local data = SpawnChunk.getData()
    data.hudMinimized = self.collapsed
end

-- Global reference to HUD window
SpawnChunk.hudWindow = nil

-- Create and add HUD
local function createHUD()
    -- Check if HUD is enabled in sandbox options
    local showHUD = (SandboxVars.SpawnChunkChallenge and SandboxVars.SpawnChunkChallenge.ShowHUD) ~= false
    if not showHUD then return end
    
    local data = SpawnChunk.getData()
    
    -- Use saved position/size or defaults
    local x = data.hudWindowX or 180
    local y = data.hudWindowY or 30
    local width = data.hudWindowWidth or 450
    local height = data.hudWindowHeight or 500
    
    local hud = SpawnChunkHUD:new(x, y, width, height)
    hud:initialise()
    hud:addToUIManager()
    hud:setVisible(true)
    
    -- Store global reference
    SpawnChunk.hudWindow = hud
    
    -- Restore collapsed state
    if data.hudMinimized then
        hud.collapsed = true
    end
end

-- Toggle HUD visibility
function SpawnChunk.toggleHUD()
    if SpawnChunk.hudWindow then
        if SpawnChunk.hudWindow:getIsVisible() then
            SpawnChunk.hudWindow:setVisible(false)
        else
            SpawnChunk.hudWindow:setVisible(true)
        end
    end
end

-- Register keybinding for HUD toggle immediately when file loads (following eggonsHotkeys pattern)
-- Add section header
local mybind = {}
mybind.value = "[SpawnChunk]"
table.insert(keyBinding, mybind)

-- Add toggle HUD keybinding
mybind = {}
mybind.value = "ToggleHUD"  -- Simple key name (will show in [SpawnChunk] section)
mybind.key = 51  -- Default: comma (,) key - from Project Zomboid key code reference
table.insert(keyBinding, mybind)

-- Simple hotkey handler for HUD toggle
-- Use OnCustomUIKey which is specifically for custom keybindings
Events.OnCustomUIKey.Add(function(key)
    local player = getPlayer()
    if not player then return end
    
    -- Check if this is our toggle HUD keybinding
    local hudToggleKey = getCore():getKey("ToggleHUD")
    if tonumber(key) == tonumber(hudToggleKey) then
        SpawnChunk.toggleHUD()
    end
end)

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
