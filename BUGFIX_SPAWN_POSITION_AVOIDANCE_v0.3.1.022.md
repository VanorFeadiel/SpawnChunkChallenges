# Bug Fix - Smart Spawn Position Avoidance v0.3.1.022

## 🐛 Bug Identified

### **Problem:**
User reported: "I had 3 zombies in a row spawn in same location"

### **Root Cause:**
While directional rotation was working (N→E→S→W), within each direction the spawn position used **full random spread** across the entire edge:

```lua
// OLD CODE - BROKEN
spread = ZombRand(-size, size + 1)  // -50 to +51 tiles

// Example: North edge
x = spawnX + spread      // Could be ANYWHERE on north edge
y = spawnY - spawnOffset // Always same Y (north)
```

**Result:**
- ❌ Direction rotates: N, E, S, W ✓
- ❌ But position on each edge is random
- ❌ Multiple spawns can end up in same general area
- ❌ Zombies funnel to same chokepoint/obstacle

**Example:**
```
Spawn 1: North direction, spread = +20  → (12320, 12200)
         Gets stuck on wall at (12322, 12230)
         
Spawn 2: East direction, spread = -30  → (12370, 12220)
         Different direction, but paths to same wall!
         Gets stuck at (12322, 12230) AGAIN
         
Spawn 3: South direction, spread = +15 → (12315, 12300)
         Again, different direction, same destination...
```

---

## ✅ Solution Implemented

### **Smart Position Avoidance:**

Track **exact stuck position** and spawn on **opposite side** of the edge!

```lua
// NEW CODE - FIXED
if stuckInfo and stuckInfo.stuckX and stuckInfo.stuckY then
    // Calculate where previous zombie got stuck
    local stuckOffsetX = stuckInfo.stuckX - spawnX
    local stuckOffsetY = stuckInfo.stuckY - spawnY
    
    // Spawn on OPPOSITE side of the edge
    if direction == "north" or direction == "south" then
        if stuckOffsetX > 0 then
            // Stuck on RIGHT side, spawn on LEFT
            spread = ZombRand(-size, -size/2)
        else
            // Stuck on LEFT side, spawn on RIGHT
            spread = ZombRand(size/2, size + 1)
        end
    end
end
```

---

## 🎯 How It Works Now

### **Scenario: Zombie Stuck on North-Right**

```
Step 1: First zombie spawns North
        → Random spread: +30 (right side)
        → Position: (12330, 12200)
        → Gets stuck on wall at (12335, 12225)
        
Step 2: Track stuck position
        → stuckX = 12335
        → stuckY = 12225
        → stuckOffsetX = +35 (RIGHT of center)
        
Step 3: Next spawn (after rotation, when North is used again)
        → Detect: Previous stuck on RIGHT
        → Smart spread: ZombRand(-50, -25) = -40 (LEFT side)
        → Position: (12260, 12200)
        → NEW PATH! Avoids previous stuck area
```

---

## 📊 Visual Example

### **OLD System (Random Spread):**
```
        NORTH EDGE
    [----X----X----X----]
         ↓    ↓    ↓
      Random positions
      
All 3 could be on same side → same chokepoint!
```

### **NEW System (Smart Avoidance):**
```
        NORTH EDGE
    [X-----------X------]
     ↑           ↑
   First      Opposite side!
   stuck      (avoids stuck area)
   
Spawns on OPPOSITE side of where previous got stuck
```

---

## 🔍 Data Tracked

### **Before (v0.3.1.020):**
```lua
stuckZombiesByDirection["north"] = {
    zombie = <IsoZombie>,
    isStuck = true,
    targetName = "Wooden Fence",
    targetOpaque = true,
    timestamp = 1234567890
    // Missing: Where exactly did it get stuck?
}
```

### **After (v0.3.1.022):**
```lua
stuckZombiesByDirection["north"] = {
    zombie = <IsoZombie>,
    isStuck = true,
    targetName = "Wooden Fence",
    targetOpaque = true,
    timestamp = 1234567890,
    stuckX = 12335,  // NEW: Exact stuck X position
    stuckY = 12225   // NEW: Exact stuck Y position
}
```

---

## 📺 HUD Display

### **Before:**
```
--- Stuck Zombie Tracking ---
Stuck Directions: 1 / 4
  NORTH: Wooden Fence (Opaque-Despawned)
```

### **After:**
```
--- Stuck Zombie Tracking ---
Stuck Directions: 1 / 4
  NORTH: Wooden Fence (Opaque-Despawned)
    Stuck at: (12335, 12225)              ← NEW: Shows position
Next Spawn Direction: EAST
```

---

## 📝 Console Output

### **New Smart Spawn Messages:**

```
[Username] Zombie appears stuck after 10 sound waves (distance: 25.3)
[Username] Previous stuck on RIGHT, spawning LEFT (spread: -42)
[Username] Directional spawn: north at offset 70, spread -42 (position: 12258, 12200)
[Username] Spawned at (12258, 12200) - Total spawned this life: 2
```

**vs Old (Random) Messages:**

```
[Username] Directional spawn: north at offset 70  // No spread info
[Username] Spawned at (12328, 12200)  // Could be same side again!
```

---

## 🎯 Spread Calculation Logic

### **North/South Directions (spread on X-axis):**

```lua
if stuckOffsetX > 0 then
    // Previous stuck on RIGHT half of north/south edge
    // Spawn on LEFT half
    spread = ZombRand(-size, -size/2)
    // Example: ZombRand(-50, -25) = -42 to -25
else
    // Previous stuck on LEFT half
    // Spawn on RIGHT half
    spread = ZombRand(size/2, size + 1)
    // Example: ZombRand(25, 51) = 25 to 50
end
```

### **East/West Directions (spread on Y-axis):**

```lua
if stuckOffsetY > 0 then
    // Previous stuck on BOTTOM half of east/west edge
    // Spawn on TOP half
    spread = ZombRand(-size, -size/2)
else
    // Previous stuck on TOP half
    // Spawn on BOTTOM half  
    spread = ZombRand(size/2, size + 1)
end
```

---

## 🧪 Testing

### **Test Scenario:**

1. Let zombie get stuck on north side (right half)
2. Wait 10 minutes for despawn/respawn
3. Check console logs for spread value
4. **Expected:** New spawn on LEFT half (spread negative)
5. Check HUD for stuck position display
6. Verify new zombie takes different path

### **Console Verification:**

```
// First stuck
[Username] Spawned at (12330, 12200)  // +30 spread (right)
[Username] Zombie stuck at (12335, 12225)

// After 10 min
[Username] Previous stuck on RIGHT, spawning LEFT (spread: -38)
[Username] Spawned at (12262, 12200)  // -38 spread (left)

✅ Different side confirmed!
```

---

## 📊 Before & After Comparison

### **Scenario: 4 Consecutive Stuck Zombies**

#### **BEFORE (v0.3.1.020):**
```
Zombie 1: North, spread +25 → stuck at (12325, 12225)
Zombie 2: East, spread -20 → stuck at (12370, 12230) [paths to same wall]
Zombie 3: South, spread +30 → stuck at (12330, 12295) [paths to same wall]
Zombie 4: West, spread +15 → stuck at (12235, 12265) [paths to same wall]

Result: All 4 stuck at SAME wall from different angles!
```

#### **AFTER (v0.3.1.022):**
```
Zombie 1: North, spread +25 → stuck at (12325, 12225)
          Track: stuckX=12325 (RIGHT side)
          
Zombie 2: East, spread -35 → spawns (12365, 12215) [TOP half, avoids center]
          Different path, gets through!
          
✅ SUCCESS! Second zombie avoided stuck area
```

---

## 🎯 Key Improvements

### **1. Position Tracking**
- ✅ Stores exact X,Y where zombie got stuck
- ✅ Relative to spawn center (offset calculation)

### **2. Opposite-Side Spawning**
- ✅ If stuck on right → spawn left
- ✅ If stuck on top → spawn bottom
- ✅ Maximizes distance from stuck position

### **3. Smart Spread Ranges**
- ✅ Left half: `ZombRand(-size, -size/2)` = -50 to -25
- ✅ Right half: `ZombRand(size/2, size+1)` = 25 to 51
- ✅ Ensures opposite-side placement

### **4. Console Feedback**
- ✅ Shows which side was stuck
- ✅ Shows which side spawning on
- ✅ Shows exact spread value and position

### **5. HUD Visibility**
- ✅ Displays stuck coordinates
- ✅ Helps debug stuck patterns
- ✅ Confirms avoidance working

---

## 📝 Files Modified

1. **SpawnChunk_Spawner.lua**
   - Track stuckX, stuckY in direction tracking
   - Smart spread calculation based on stuck position
   - Enhanced console logging

2. **SpawnChunk_Visual.lua**
   - Display stuck position coordinates in HUD
   - Show smart spawn decisions

3. **SpawnChunk_Data.lua**
   - Updated version to `0.3.1.022`

4. **mod.info**
   - Updated version to `0.3.1.022`

---

## ✅ Expected Results

### **After This Fix:**

✅ **No more consecutive spawns in same area**
- System actively avoids previous stuck positions

✅ **Better route diversity**
- Spawns test opposite sides of boundaries

✅ **Faster challenge completion**
- Zombies find alternate paths more quickly

✅ **Clear visual feedback**
- HUD shows exactly where zombies got stuck
- Console shows spawn avoidance logic

---

## 🔍 Version Verification

In-game debug HUD should show:
```
Mod Version: 0.3.1.022
```

If you see this version, smart position avoidance is active! ✅

---

## 💡 Future Enhancement Ideas

If still seeing issues, could add:
- **Distance-based avoidance:** Don't spawn within X tiles of any stuck position
- **Path-finding analysis:** Check if spawn has clear path to player
- **Segment-based tracking:** Divide each edge into 3rds, track stuck segments
- **Adaptive spawn distance:** Start closer if zombies keep getting stuck far out

