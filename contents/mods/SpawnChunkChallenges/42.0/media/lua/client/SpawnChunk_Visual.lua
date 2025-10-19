-- SpawnChunk_Visual.lua (WORKING VERSION - Based on Enclosure Challenge)
-- Ground markers and map symbols that actually work!

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
    if data.isComplete then return end -- Don't show after completion
    
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
    local alpha = 0.8
    
    -- Add markers every 5 squares to reduce clutter
    for i, eSq in ipairs(edgeSquares) do
        if i % 5 == 0 then  -- Every 5th square
            local sq = getCell():getOrCreateGridSquare(eSq.x, eSq.y, data.spawnZ)
            if sq then
                -- Use "X" stamp (builtin) - size 0.3 for subtle markers
                local marker = wm:addGridSquareMarker("X", "X", sq, r, g, b, true, 0.3)
                table.insert(SpawnChunk.boundaryMarkers, marker)
            end
        end
    end
    
    -- Add spawn point marker (green, larger)
    local spawnSq = getCell():getOrCreateGridSquare(data.spawnX, data.spawnY, data.spawnZ)
    if spawnSq then
        local spawnMarker = wm:addGridSquareMarker("X", "X", spawnSq, 0, 1, 0, true, 1)
        table.insert(SpawnChunk.boundaryMarkers, spawnMarker)
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

-- Remove markers on completion
local oldOnVictory = SpawnChunk.onVictory
function SpawnChunk.onVictory()
    if oldOnVictory then oldOnVictory() end
    SpawnChunk.removeGroundMarkers()
end

-----------------------  MAP SYMBOLS  ---------------------------

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
    
    -- Remove old symbol if exists
    SpawnChunk.removeMapSymbol()
    
    -- Add symbol at spawn point
    local sym = symAPI:addTexture("X", data.spawnX, data.spawnY)
    if sym then
        sym:setAnchor(0.5, 0.5)
        -- Green for spawn point
        sym:setRGBA(0, 1, 0, 1)
        SpawnChunk.mapSymbol = sym
        print("Map symbol added at spawn: " .. data.spawnX .. ", " .. data.spawnY)
    else
        print("ERROR: Failed to create map symbol")
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
    
    -- Remove symbol at spawn coordinates
    for i = symAPI:getSymbolCount() - 1, 0, -1 do
        local sym = symAPI:getSymbolByIndex(i)
        if sym:getWorldX() == data.spawnX and sym:getWorldY() == data.spawnY then
            symAPI:removeSymbolByIndex(i)
        end
    end
end

-- Add map symbol after initialization
Events.OnGameStart.Add(function()
    local timer = 0
    local function checkInit()
        timer = timer + 1
        if timer >= 180 then -- ~3 seconds (allow more time for map init)
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

-----------------------  ON-SCREEN HUD (Keep existing)  ---------------------------

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

-----------------------  WARNING TEXT (Keep existing)  ---------------------------

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
    
    -- Show warning when getting close (within 20 tiles)
    if dx > size - 20 or dy > size - 20 then
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