# Directional Spawning & Challenge Stuck Detection v0.3.1.020

## 🎯 Major Features Added

### 1. **Directional Spawn Rotation**
Backup zombies spawn from different cardinal directions (N → E → S → W → N...)

### 2. **Object Type Detection**
Distinguishes between opaque (wooden fence) vs transparent (chainlink fence) structures

### 3. **Smart Zombie Despawning**
Stuck zombies on OPAQUE objects are despawned before spawning backup

### 4. **Stuck Direction Tracking**
Tracks which directions have stuck zombies (max 4)

### 5. **Challenge Stuck Detection**
Flags when ALL 4 cardinal directions have stuck zombies (impossible situation)

---

## 🔄 How It Works

### **First Stuck Zombie (After 10 minutes)**

```
Minute 10: Zombie stuck on Wooden Fence
          
Step 1: Detect stuck zombie
        → Non-Progress Waves: 10 / 10

Step 2: Analyze object type
        → Target: Wooden Fence (Opaque)
        
Step 3: Rotate spawn direction
        → Last direction: None
        → Next direction: NORTH
        
Step 4: Despawn stuck zombie (opaque)
        → "Despawned stuck zombie on opaque Wooden Fence"
        
Step 5: Spawn backup from NORTH
        → Spawns 20 tiles north of spawn point
        
Step 6: Track direction
        → stuckZombiesByDirection["north"] = stuck
        → challengeStuckFlag = false (only 1/4 directions)
```

### **Second Stuck Zombie (Different Direction)**

```
Minute 20: New zombie also gets stuck
          
Step 1: Detect stuck
        → Non-Progress Waves: still 10+
        
Step 2: Analyze object
        → Target: Chainlink Fence (Transparent)
        
Step 3: Rotate direction
        → Last direction: north
        → Next direction: EAST
        
Step 4: Keep zombie (transparent - can see through)
        → "Keeping stuck zombie (transparent Chainlink Fence - visible)"
        
Step 5: Spawn backup from EAST
        
Step 6: Track direction
        → stuckZombiesByDirection["east"] = stuck
        → challengeStuckFlag = false (2/4 directions)
```

### **All 4 Directions Stuck**

```
After trying all directions:

stuckZombiesByDirection:
  north: Wooden Fence (Opaque-Despawned)
  east: Chainlink Fence (Transparent-Active)
  south: Metal Bars (Transparent-Active)
  west: Concrete Wall (Opaque-Despawned)
  
challengeStuckFlag = TRUE
  
⚠️ WARNING: All 4 cardinal directions have stuck zombies!
          Challenge may be impossible!
```

---

## 🎨 HUD Display

### **When Zombie Attacking Structure:**

```
Status: ATTACKING STRUCTURE
→ Target: Wooden Fence (Opaque)     ← NEW: Shows object type
→ Damage: Unknown (no health data)
⚠ Structure may be INDESTRUCTIBLE!
   (Zombie is stuck, backup will spawn)
```

### **Stuck Direction Tracking:**

```
--- Stuck Zombie Tracking ---
Stuck Directions: 2 / 4           ← Orange (multiple stuck)
  NORTH: Wooden Fence (Opaque-Despawned)
  EAST: Chainlink Fence (Transparent-Active)
Next Spawn Direction: SOUTH
```

### **Challenge Stuck Flag:**

```
⚠️ CHALLENGE STUCK FLAG ACTIVE!
All 4 directions have stuck zombies!
```

---

## 📊 Object Type Detection

### **Transparent Objects** (NOT despawned)
- Chainlink fences
- Metal fences  
- Wire fences
- Windows
- Glass doors
- Iron bars
- Railings

**Why Keep?** Player can see zombie through structure, maintains immersion

### **Opaque Objects** (Despawned)
- Wooden fences
- Walls (brick, concrete, etc.)
- Wooden doors
- Barricades
- Any solid structure

**Why Despawn?** Can't see zombie through structure, prevents invisible zombie pile-up

---

## 🔄 Spawn Direction Rotation

### **Sequence:**
```
Spawn 1 (stuck): NORTH → despawn if opaque
Spawn 2 (stuck): EAST  → despawn if opaque
Spawn 3 (stuck): SOUTH → despawn if opaque
Spawn 4 (stuck): WEST  → despawn if opaque
Spawn 5 (stuck): NORTH → (wraps around)
```

### **Advantages:**
- ✅ Tries all 4 directions systematically
- ✅ Prevents all zombies stuck in same spot
- ✅ Finds alternate routes around obstacles
- ✅ Detects when challenge is truly impossible

---

## 🧠 Progress Tracking Logic

### **Zombie Makes Progress:**
```
if zombieApproaching or (attacking and damageThisCycle == true) then
    consecutiveNonApproachingWaves = 0
    
    // Clear stuck tracking for THIS zombie
    for dir, stuckInfo in pairs(stuckZombiesByDirection) do
        if stuckInfo.zombie == closestZombie then
            clearStuckZombie(dir, data)
            challengeStuckFlag = checkChallengeStuck(data)
        end
    end
end
```

### **When Stuck Zombie Dies:**
- Stuck tracking cleared for that direction
- Challenge stuck flag rechecked
- New zombie can spawn from that direction

---

## 🎯 Example Scenarios

### **Scenario 1: Spawn Inside Wooden Fenced Yard**

```
Minute 10: Zombie stuck on wooden fence
          → Direction: NORTH
          → Fence is OPAQUE
          → Despawn stuck zombie
          → Spawn backup from EAST
          
Minute 12: Backup zombie gets through!
          → Makes progress (approaching)
          → Clear NORTH stuck tracking
          → challengeStuckFlag = false
          → NORTH available again
```

### **Scenario 2: Spawn in Building Surrounded by Barriers**

```
Minute 10: NORTH stuck (wooden wall) - despawned
Minute 20: EAST stuck (concrete wall) - despawned  
Minute 30: SOUTH stuck (wooden door) - despawned
Minute 40: WEST stuck (barricade) - despawned

⚠️ CHALLENGE STUCK FLAG ACTIVE!

Result: All 4 directions blocked
        Challenge may be impossible
        Player should consider:
        - Moving to different location
        - Breaking down barriers
        - Restarting spawn
```

### **Scenario 3: Mixed Opaque/Transparent**

```
Minute 10: NORTH stuck (wooden fence - opaque)
          → Despawned
          
Minute 20: EAST stuck (chainlink fence - transparent)
          → Kept visible (immersion maintained)
          
Minute 30: SOUTH zombie gets through!
          → Success!
          
HUD Shows:
Stuck Directions: 2 / 4
  NORTH: Wooden Fence (Opaque-Despawned)
  EAST: Chainlink Fence (Transparent-Active)
```

---

## 📋 New Data Structures

### **stuckZombiesByDirection**
```lua
{
    north = {
        zombie = <IsoZombie>,
        isStuck = true,
        targetName = "Wooden Fence",
        targetOpaque = true,
        timestamp = 1234567890
    },
    east = {
        zombie = <IsoZombie>,
        isStuck = true,
        targetName = "Chainlink Fence",
        targetOpaque = false,
        timestamp = 1234567900
    }
}
```

### **Object Detection**
```lua
-- Example object analysis
objectInfo = {
    name = "Wooden Fence",
    sprite = "fencing_01_12",
    opaque = true,
    displayName = "Wooden Fence (Opaque)"
}
```

---

## 🔧 New Functions

### **SpawnChunk.isObjectOpaque(obj)**
- Analyzes object name and sprite
- Checks against transparent keywords
- Returns true if opaque, false if transparent

### **SpawnChunk.getObjectInfo(obj)**
- Gets object name, sprite, opacity
- Returns formatted info table

### **SpawnChunk.getNextSpawnDirection(data)**
- Rotates through N → E → S → W
- Returns next direction string

### **SpawnChunk.checkChallengeStuck(data)**
- Counts stuck zombies by direction
- Returns true if all 4 stuck

### **SpawnChunk.clearStuckZombie(direction, data)**
- Clears stuck tracking for direction
- Rechecks challenge stuck flag

### **SpawnChunk.despawnZombie(zombie, reason, data)**
- Removes zombie from world
- Logs despawn reason

### **SpawnChunk.spawnZombies(count, data, pl, preferredDirection)**
- Added directional spawning parameter
- Spawns in specific cardinal direction if specified

---

## 🎯 Color Coding

### **Stuck Direction Count:**
- 🟡 **Yellow:** 1 direction stuck
- 🟠 **Orange:** 2-3 directions stuck
- 🔴 **Red:** 4 directions stuck (impossible!)

### **Object Type:**
- **(Opaque):** Solid, can't see through → will despawn
- **(Transparent):** See-through → keeps visible

### **Stuck Status:**
- **(Opaque-Despawned):** Zombie removed, direction clear
- **(Transparent-Active):** Zombie still visible, direction occupied

---

## ⚙️ Console Output

### **Directional Spawn:**
```
[Username] Zombie appears stuck after 10 sound waves (distance: 45.2)
[Username] Spawning backup zombie from north direction
[Username] Directional spawn: north at offset 70
[Username] Spawned at (12345, 12275) - Total spawned this life: 2
```

### **Opaque Despawn:**
```
[Username] Despawning zombie at (12345, 12300) - Reason: Stuck on opaque object: Wooden Fence
[Username] Despawned stuck zombie on opaque Wooden Fence
```

### **Transparent Keep:**
```
[Username] Keeping stuck zombie (transparent Chainlink Fence - visible)
```

### **Challenge Stuck:**
```
[Username] ⚠️ WARNING: All 4 cardinal directions have stuck zombies! Challenge may be impossible!
```

---

## 🧪 Testing

### **Test 1: Opaque Object**
1. Spawn in area with wooden fence
2. Let zombie get stuck (10 min)
3. **Expected:**
   - Zombie despawned
   - New zombie from different direction
   - HUD shows "(Opaque-Despawned)"

### **Test 2: Transparent Object**
1. Spawn in area with chainlink fence
2. Let zombie get stuck (10 min)
3. **Expected:**
   - Zombie kept visible
   - New zombie from different direction
   - HUD shows "(Transparent-Active)"

### **Test 3: All Directions Blocked**
1. Spawn in small wooden building
2. Wait for all 4 directions to get stuck (40 min)
3. **Expected:**
   - HUD shows "Stuck Directions: 4 / 4"
   - Challenge stuck flag active
   - Warning message displayed

---

## 📝 Files Modified

1. **SpawnChunk_Data.lua**
   - Added `stuckZombiesByDirection` tracking
   - Added `lastSpawnDirection` tracking
   - Added `challengeStuckFlag`
   - Updated version to `0.3.1.020`

2. **SpawnChunk_Spawner.lua**
   - Added object type detection functions
   - Added directional spawn helpers
   - Added zombie despawning
   - Modified spawn logic for directional spawning
   - Enhanced stuck zombie handling

3. **SpawnChunk_Visual.lua**
   - Shows object type (opaque/transparent)
   - Shows stuck direction tracking
   - Shows challenge stuck flag
   - Enhanced attack target display

4. **mod.info**
   - Updated version to `0.3.1.020`

---

## ✅ Benefits

✅ **No invisible zombie pile-ups** (opaque objects despawned)
✅ **Maintains immersion** (transparent objects kept visible)
✅ **Systematic obstacle testing** (4 cardinal directions)
✅ **Impossible situation detection** (challenge stuck flag)
✅ **Clear visual feedback** (HUD shows all stuck directions)
✅ **Smart route finding** (tries all directions automatically)
✅ **Progress tracking** (clears stuck when zombie succeeds)

---

## 🔍 Version Verification

In-game debug HUD should show:
```
Mod Version: 0.3.1.020
```

If you see this version, all directional spawning features are active! ✅

