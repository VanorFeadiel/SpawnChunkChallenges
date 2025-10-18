# Project Zomboid API Cheat Sheet

## Most Common Patterns

### Getting the Player
```lua
local player = getPlayer()
if not player then return end  -- Always check!
```

### Persistent Data (ModData)
```lua
-- Store data
local modData = player:getModData()
modData.MyMod = modData.MyMod or { initialized = false }

-- Access data
local data = modData.MyMod
data.killCount = data.killCount + 1  -- Auto-saves!
```

### Events
```lua
-- Game lifecycle
Events.OnGameStart.Add(callback)
Events.OnLoad.Add(callback)
Events.OnSave.Add(callback)

-- Player
Events.OnPlayerDeath.Add(function(player) end)
Events.OnCreatePlayer.Add(function(playerNum, player) end)

-- Zombies
Events.OnZombieDead.Add(function(zombie) end)

-- Time-based
Events.OnTick.Add(callback)  -- EVERY FRAME - use sparingly!
Events.EveryOneMinute.Add(callback)
Events.EveryTenMinutes.Add(callback)
Events.EveryHours.Add(callback)
```

### World Access
```lua
local cell = getCell()
local zombies = cell:getZombieList()  -- Returns Java ArrayList
local zombieCount = zombies:size()

-- Get specific square
local square = cell:getGridSquare(x, y, z)
local square = cell:getOrCreateGridSquare(x, y, z)  -- Creates if missing
```

### Ground Markers
```lua
local wm = getWorldMarkers()
local marker = wm:addGridSquareMarker(
    "X",              -- texture (builtin stamps: "X", "flag", etc)
    "Label",          -- text overlay
    gridSquare,       -- IsoGridSquare object
    1, 0, 0,          -- RGB color (0-1 range)
    true,             -- allow text override
    1.0               -- scale
)

-- Remove marker
marker:remove()
```

### Map Symbols
```lua
-- Initialize map (required first!)
if not ISWorldMap_instance then
    ISWorldMap.ShowWorldMap(0)
    ISWorldMap_instance:close()
end

-- Access Symbol API
local mapAPI = ISWorldMap_instance.javaObject:getAPIv1()
local symAPI = mapAPI:getSymbolsAPI()

-- Add symbol
local symbol = symAPI:addTexture("media/ui/LootableMaps/map_flag.png", worldX, worldY)
symbol:setRGBA(r, g, b, a)  -- 0-1 range
symbol:setAnchor(0.5, 0.5)  -- Center the symbol

-- Remove symbol
symAPI:removeSymbolByIndex(index)
```

### UI Elements
```lua
require "ISUI/ISPanel"

MyUI = ISPanel:derive("MyUI")

function MyUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function MyUI:render()
    ISPanel.render(self)
    self:drawText("Hello", 10, 10, 1, 1, 1, 1, UIFont.Medium)
end

-- Create and add
local ui = MyUI:new(x, y, w, h)
ui:initialise()
ui:addToUIManager()
```

### Inventory
```lua
local inv = player:getInventory()

-- Add item
local item = inv:AddItem("Base.Axe")
local item = inv:AddItem("Base.WaterBottleFull")

-- Find items
local items = inv:getItemsFromType("Base.Bandage")
```

### Sounds
```lua
player:playSound("LevelUp")
player:playSound("WallHit")
-- See: media/sound/ for available sounds
```

### Teleportation
```lua
player:setX(x)
player:setY(y)
player:setZ(z)
-- OR
player:setLocation(x, y, z)
```

### Notifications
```lua
-- Halo note (above player head)
player:setHaloNote(text, r, g, b, duration)
-- RGB: 0-255, duration: ticks (60 = 1 second)
```

## Common Gotchas

### 1. Event Handler Removal
```lua
-- WRONG - can't remove anonymous function
Events.OnTick.Add(function()
    Events.OnTick.Remove(???)  -- No reference!
end)

-- CORRECT - use named function
local function myTick()
    -- work
    Events.OnTick.Remove(myTick)
end
Events.OnTick.Add(myTick)
```

### 2. Java ArrayList vs Lua Table
```lua
local zombies = cell:getZombieList()  -- Java ArrayList!

-- Use :size() not #
local count = zombies:size()  -- ✓ Correct
local count = #zombies        -- ✗ Wrong! Returns 0

-- Iterate with get(index) starting at 0
for i = 0, zombies:size() - 1 do
    local zombie = zombies:get(i)
end
```

### 3. Coordinate Systems
```lua
-- World coordinates (player position)
player:getX()  -- Returns float (decimal)

-- Grid coordinates (tile-based)
math.floor(player:getX())  -- Convert to tile coords

-- GridSquare requires integers!
local sq = cell:getGridSquare(
    math.floor(x),
    math.floor(y),
    math.floor(z)
)
```

### 4. UI Initialization Timing
```lua
-- UI elements need delay after OnGameStart
Events.OnGameStart.Add(function()
    -- Wait before creating UI
    Events.OnTick.Add(function()
        createUI()
        Events.OnTick.Remove(createUI)
    end)
end)
```

### 5. ModData Auto-Saves
```lua
-- ModData saves automatically when changed
local data = player:getModData().MyMod
data.value = newValue  -- Saved immediately!

-- No need to call saveData() unless forcing immediate write
```

## Performance Tips

### 1. Avoid OnTick When Possible
```lua
-- BAD: Runs 60 times per second!
Events.OnTick.Add(function()
    checkSomething()
end)

-- GOOD: Runs once per minute
Events.EveryOneMinute.Add(function()
    checkSomething()
end)
```

### 2. Use Tick Counters
```lua
local tickCounter = 0
local CHECK_INTERVAL = 60  -- Once per second

Events.OnTick.Add(function()
    tickCounter = tickCounter + 1
    if tickCounter >= CHECK_INTERVAL then
        tickCounter = 0
        doWork()
    end
end)
```

### 3. Early Returns
```lua
function myFunction()
    if not initialized then return end
    if isComplete then return end
    -- Expensive work only runs if needed
end
```

## Debugging

### Console Output
```lua
print("Debug: " .. tostring(value))

-- Format with context
print("SpawnChunk_Kills: Kill count = " .. data.killCount)
```

### Type Checking
```lua
print(type(value))              -- "number", "string", "table", etc
print(tostring(value))          -- Safe conversion to string
print(value ~= nil)             -- Check existence
```

### Stack Traces
```lua
-- On error, PZ console shows:
-- error: [file]:[line]: [message]
```

## Useful Constants

### UI Fonts
```lua
UIFont.Small
UIFont.Medium
UIFont.Large
UIFont.Massive
```

### Colors (0-1 range)
```lua
-- Red
r, g, b = 1, 0, 0

-- Green  
r, g, b = 0, 1, 0

-- Blue
r, g, b = 0, 0, 1

-- Yellow
r, g, b = 1, 1, 0

-- White
r, g, b = 1, 1, 1
```

## Full API Documentation
https://demiurgequantified.github.io/ProjectZomboidJavaDocs/
