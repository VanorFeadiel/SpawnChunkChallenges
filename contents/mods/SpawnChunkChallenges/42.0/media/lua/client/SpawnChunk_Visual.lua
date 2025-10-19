-- SpawnChunk_Visual.lua (CONTINUOUS BOUNDARY LINES)
-- Ground markers, map boundary lines, and HUD

SpawnChunk = SpawnChunk or {}

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
    
    -- Remove old markers first
    SpawnChunk.removeGroundMarkers()
    
    print("Creating boundary markers...")
    
    local edgeSquares = SpawnChunk.getBoundaryEdgeSquares()
    local wm = getWorldMarkers()
    if not wm then 
        print("ERROR: WorldMarkers not available")
        return 
    end
    
    SpawnChunk.boundaryMarkers = {}
    
    -- Color: Yellow for active challenge
    local r, g, b = 1, 1, 0
    
    -- Add markers on EVERY boundary tile (no skipping)
    for i, eSq in ipairs(edgeSquares) do
        local sq = getCell():getOrCreateGridSquare(eSq.x, eSq.y, data.spawnZ)
        if sq then
            local marker = wm:addGridSquareMarker(nil, "X", sq, r, g, b, true, 0.3)
            if marker then
                table.insert(SpawnChunk.boundaryMarkers, marker)
            end
        end
    end
    
    -- Add spawn point marker (green, larger)
    local spawnSq = getCell():getOrCreateGridSquare(data.spawnX, data.spawnY, data.spawnZ)
    if spawnSq then
        local spawnMarker = wm:addGridSquareMarker(nil, "SPAWN", spawnSq, 0, 1, 0, true, 1)
        if spawnMarker then
            table.insert(SpawnChunk.boundaryMarkers, spawnMarker)
        end
    end
    
    print("Created " .. #SpawnChunk.boundaryMarkers .. " boundary markers")
    data.markersCreated = true
end

function SpawnChunk.removeGroundMarkers()
    if SpawnChunk.boundaryMarkers then
        for _, marker in ipairs(SpawnChunk.boundaryMarkers) do
            if marker and marker.remove then
                marker:remove()
            end
        end
        SpawnChunk.boundaryMarkers = {}
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
                print("SpawnChunk_Visual: Recreated ground markers after respawn")
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
    SpawnChunk.removeMapSymbol()  -- FIX: Also remove map boundary lines
    print("SpawnChunk_Visual: Cleaned up all visual markers on victory")
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
    
    -- Initialize storage for our symbols if needed
    if not SpawnChunk.mapLineSymbols then
        SpawnChunk.mapLineSymbols = {}
    end
    
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
            table.insert(SpawnChunk.mapLineSymbols, sym)
        end
    end
end

function SpawnChunk.addMapSymbol()
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    -- Open and close map to initialize ISWorldMap_instance
    if not ISWorldMap_instance then
        ISWorldMap.ShowWorldMap(0)
        ISWorldMap_instance:close()
    end
    
    if not ISWorldMap_instance or not ISWorldMap_instance.javaObject then 
        print("ERROR: ISWorldMap not available")
        return 
    end
    
    local mapAPI = ISWorldMap_instance.javaObject:getAPIv1()
    if not mapAPI then 
        print("ERROR: Map API not available")
        return 
    end
    
    local symAPI = mapAPI:getSymbolsAPI()
    if not symAPI then 
        print("ERROR: Symbol API not available")
        return 
    end
    
    -- Remove old symbols if exists
    SpawnChunk.removeMapSymbol()
    
    -- Initialize storage for our map symbols
    SpawnChunk.mapLineSymbols = {}
    
    print("Drawing boundary lines on map...")
    
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
    
    -- Top edge
    SpawnChunk.drawMapLine(symAPI, topLeftX, topLeftY, topRightX, topRightY, r, g, b, scale)
    -- Right edge
    SpawnChunk.drawMapLine(symAPI, topRightX, topRightY, bottomRightX, bottomRightY, r, g, b, scale)
    -- Bottom edge
    SpawnChunk.drawMapLine(symAPI, bottomRightX, bottomRightY, bottomLeftX, bottomLeftY, r, g, b, scale)
    -- Left edge
    SpawnChunk.drawMapLine(symAPI, bottomLeftX, bottomLeftY, topLeftX, topLeftY, r, g, b, scale)
    
    -- Add spawn point marker (small green dot)
    local spawnSym = symAPI:addTexture("media/ui/Moodle_Icon_Windchill.png", data.spawnX, data.spawnY)
    if spawnSym then
        spawnSym:setAnchor(0.5, 0.5)
        spawnSym:setRGBA(0, 1, 0, 1)  -- Green
        spawnSym:setScale(0.15)  -- Much smaller than before
        SpawnChunk.mapSymbol = spawnSym
        -- Also store in our tracked symbols list
        table.insert(SpawnChunk.mapLineSymbols, spawnSym)
        print("Map symbols added - boundary rectangle and spawn point")
    end
end

function SpawnChunk.removeMapSymbol()
    if not ISWorldMap_instance then return end
    
    local data = SpawnChunk.getData()
    if not data.isInitialized then return end
    
    local mapAPI = ISWorldMap_instance.javaObject:getAPIv1()
    if not mapAPI then return end
    
    local symAPI = mapAPI:getSymbolsAPI()
    if not symAPI then return end
    
    -- Only remove symbols we created (stored in our list)
    if SpawnChunk.mapLineSymbols then
        local removedCount = 0
        for _, sym in ipairs(SpawnChunk.mapLineSymbols) do
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
        SpawnChunk.mapLineSymbols = {}
        print("SpawnChunk_Visual: Removed " .. removedCount .. " map symbols (player symbols preserved)")
    end
end

-- Add map symbol after initialization
Events.OnGameStart.Add(function()
    local timer = 0
    local function checkInit()
        timer = timer + 1
        if timer >= 180 then -- ~3 seconds (allow time for map init)
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
    -- Wait a bit longer after respawn to ensure map is ready
    local timer = 0
    local function checkRespawnInit()
        timer = timer + 1
        if timer >= 240 then -- ~4 seconds (more time after respawn)
            local data = SpawnChunk.getData()
            if data.isInitialized and not data.mapSymbolCreated then
                SpawnChunk.addMapSymbol()
                data.mapSymbolCreated = true
                print("SpawnChunk_Visual: Recreated map symbols after respawn")
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
end

-- Create and add HUD
local function createHUD()
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

-----------------------  DEATH RESET HANDLER  ---------------------------

-- Clean up visual markers on player death so they can be recreated at new spawn
Events.OnPlayerDeath.Add(function(player)
    print("SpawnChunk_Visual: Player died, cleaning up visual markers")
    
    -- Remove ground markers
    SpawnChunk.removeGroundMarkers()
    
    -- DO NOT remove map symbols on death - only on victory
    -- Map symbols will persist and be useful for navigation
    
    -- Reset creation flags so visuals will be recreated at new spawn
    local data = SpawnChunk.getData()
    data.markersCreated = false
    -- Keep mapSymbolCreated as true so map isn't recreated
end)