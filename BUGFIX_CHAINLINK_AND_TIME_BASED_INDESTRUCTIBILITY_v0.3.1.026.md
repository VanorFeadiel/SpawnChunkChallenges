# Bug Fixes - Chainlink Detection + Time-Based Indestructibility v0.3.1.026

## 🔴 Critical Issues Fixed

### **Issue 1: Chainlink Fence Misclassified**
User reported: "Zombie attacking chainlink fence 100/100 hp, target marked as opaque even though see-through"

### **Issue 2: No Damage Detection**
User reported: "Zombie making no damage for long time, should be considered indestructible"

---

## ✅ Solution 1: Enhanced Transparency Detection

### **Problem:**
Chainlink fences were being classified as **opaque** when they're clearly see-through!

```lua
// OLD CODE - INCOMPLETE
local transparentKeywords = {
    "chainlink", "chain link", "wire", "metal fence", ...
}

// Simple string.find() wasn't catching all variations
```

**Why It Failed:**
- Inconsistent keyword matching
- Missing underscore variations ("chain_link")
- Didn't check sprite patterns for fencing
- Case-sensitive matching issues

### **Fix:**
Enhanced keyword list + pattern-based sprite detection:

```lua
// NEW CODE - COMPREHENSIVE
local transparentKeywords = {
    "chainlink", "chain link", "chain_link", "chainlink fence",
    "wire", "wire fence", "metal fence", "fence metal", "metal_fence",
    "window", "glass", "bars", "iron bars", "iron_bars", "metal bars",
    "railing", "rail", "mesh", "lattice", "grid"
}

// Case-insensitive, plain text search
for _, keyword in ipairs(transparentKeywords) do
    if string.find(lowerName, keyword, 1, true) or 
       string.find(lowerSprite, keyword, 1, true) then
        return false  -- Transparent!
    end
end

// ALSO check sprite patterns
if string.find(lowerSprite, "fencing") and (
   string.find(lowerSprite, "metal") or 
   string.find(lowerSprite, "wire") or
   string.find(lowerSprite, "chain")) then
    return false  -- Metal/wire/chain fencing = transparent
end
```

---

## ✅ Solution 2: Time-Based Indestructibility Detection

### **Problem:**
Some structures have health values but **never take damage**:
- High-tier construction materials
- Reinforced fences
- Certain building components
- Modded indestructible objects

**Result:** Zombie attacks for hours, no progress, no backup spawn!

### **Fix:**
Track attack duration in **in-game time**, mark as functionally indestructible after 1 hour:

```lua
// Start tracking when attack begins
if not data.lastAttackTargetHealth then
    data.attackStartTime = gameTime:getWorldAgeHours() * 60  // In-game minutes
    data.initialAttackTargetHealth = targetHealth
end

// Check duration every cycle
if health hasn't changed then
    local attackDuration = currentMinutes - data.attackStartTime
    
    if attackDuration >= 60 then  // 1 in-game hour
        // No damage after 1 hour = functionally indestructible!
        data.attackTargetFunctionallyIndestructible = true
        data.damageThisCycle = nil  // Treat as indestructible
    end
end

// Reset timer if damage IS dealt
if health decreased then
    data.attackStartTime = currentMinutes  // Reset timer
end
```

---

## 🎯 How It Works

### **Scenario: Chainlink Fence (100/100 HP)**

```
Minute 0: Zombie starts attacking chainlink fence
         → Object detected: "Chainlink Fence"
         → Enhanced detection: TRANSPARENT ✓
         → Health: 100/100
         → Start tracking: attackStartTime = 0
         
Minute 5: Still attacking, no damage
         → Health: 100/100 (same)
         → Attack duration: 5 in-game minutes
         → Status: Hitting but not breaking (Yellow)
         
Minute 30: Still no damage
         → Health: 100/100 (same)
         → Attack duration: 30 in-game minutes
         → Status: Attack duration showing (Orange)
         
Minute 60: 1 in-game hour passed!
         → Health: 100/100 (still same!)
         → Attack duration: 60 in-game minutes
         → MARK AS FUNCTIONALLY INDESTRUCTIBLE
         → Status: Red "FUNCTIONALLY INDESTRUCTIBLE"
         → Trigger stuck zombie logic
         
Minute 70: Stuck threshold reached (10 min after marked)
         → Zombie NOT making progress
         → Keep zombie (transparent fence - visible)
         → Spawn backup from different direction
```

---

## 📺 HUD Display Evolution

### **Phase 1: Initial Attack (0-44 min)**
```
Status: ATTACKING STRUCTURE
→ Target: Chainlink Fence (Transparent)  ← Now correct!
→ Damage: No damage (hitting but not breaking)
   Attack duration: 30 in-game min (stuck at 1 hr)  ← Yellow
→ Health: 100 / 100 (100%)
[██████████████]
```

### **Phase 2: Approaching Threshold (45-59 min)**
```
Status: ATTACKING STRUCTURE
→ Target: Chainlink Fence (Transparent)
→ Damage: No damage (hitting but not breaking)
   Attack duration: 52 in-game min (stuck at 1 hr)  ← Orange
→ Health: 100 / 100 (100%)
[██████████████]
```

### **Phase 3: Functionally Indestructible (60+ min)**
```
Status: ATTACKING STRUCTURE
→ Target: Chainlink Fence (Transparent)
→ Damage: FUNCTIONALLY INDESTRUCTIBLE  ← Red
   (No damage after 1 in-game hour)
⚠ Structure INDESTRUCTIBLE!
   (Zombie is stuck, backup will spawn)
→ Health: 100 / 100 (100%)
[██████████████]
```

---

## 📝 Console Messages

### **Start Tracking:**
```
[Username] Started tracking damage on Chainlink Fence (health: 100)
```

### **During Attack (Every 10 minutes):**
```
[Username] Zombie attacking: Chainlink Fence (health: 100 / 100) - Damage: NO
```

### **Threshold Reached:**
```
[Username] ⚠️ Structure appears INDESTRUCTIBLE: No damage after 60 in-game minutes
[Username] Zombie attacking functionally indestructible structure (no damage after 1 hour)
```

### **Stuck Logic Triggered:**
```
[Username] Zombie appears stuck after 10 sound waves (distance: 25.3)
[Username] Keeping stuck zombie (transparent Chainlink Fence - visible)
[Username] Spawning backup zombie from north direction
```

---

## 🔄 State Machine

```
┌─────────────────┐
│  Start Attack   │
│  trackingStart  │
└────────┬────────┘
         │
    Health check
         │
    ┌────▼────┐
    │ Damage? │
    └────┬────┘
         │
    ┌────▼────────────┬─────────────────┐
    │                 │                 │
    YES               NO                NO (60+ min)
    │                 │                 │
    ▼                 ▼                 ▼
┌─────────┐    ┌──────────┐    ┌──────────────────┐
│ DEALING │    │ NO DAMAGE│    │   FUNCTIONALLY   │
│ DAMAGE  │    │ (Yellow) │    │ INDESTRUCTIBLE   │
│ (Green) │    │          │    │     (Red)        │
│         │    │ Show     │    │                  │
│ Reset   │    │ Duration │    │ Trigger Stuck    │
│ Timer   │    │          │    │ Logic            │
└─────────┘    └──────────┘    └──────────────────┘
    │                                    │
    └────────────────┬───────────────────┘
                     │
              Next Minute Check
```

---

## ⏱️ Time Tracking Details

### **In-Game Time Usage:**
```lua
local gameTime = getGameTime()
local currentMinutes = gameTime:getWorldAgeHours() * 60

// At normal speed:
// 1 in-game hour = ~7.5 real minutes
// 60 in-game minutes = ~7.5 real minutes
```

### **Real-World Wait Times:**

```
Threshold: 60 in-game minutes

Game Speed:
  Normal (1x): ~7.5 real minutes
  Fast (2x):   ~3.75 real minutes
  Slow (0.5x): ~15 real minutes
```

**Why 60 Minutes?**
- Gives reasonable time for zombie to potentially break through
- Not so short that temporary pathfinding issues trigger it
- Not so long that player waits forever
- Matches spawn delay timing (both 60 min)

---

## 🎨 Color Coding

### **Attack Duration Display:**
```
0-44 minutes:   Yellow  (Normal, waiting)
45-59 minutes:  Orange  (Getting close to threshold)
60+ minutes:    Red     (Functionally indestructible!)
```

### **Damage Status:**
```
DEALING DAMAGE:               Green  (Making progress)
No damage:                    Yellow (Not breaking)
FUNCTIONALLY INDESTRUCTIBLE:  Red    (Threshold reached)
Unknown (no health data):     Gray   (Truly indestructible)
```

---

## 🔍 Detection Improvements

### **Transparent Object Keywords (Enhanced):**

**Base Keywords:**
- chainlink, chain link, chain_link, chainlink fence
- wire, wire fence
- metal fence, fence metal, metal_fence
- window, glass
- bars, iron bars, iron_bars, metal bars
- railing, rail
- mesh, lattice, grid

**Sprite Pattern Detection:**
- Any sprite with "fencing" AND ("metal" OR "wire" OR "chain")
- Catches modded fences with standard naming

**Case Insensitive:**
- All comparisons use `string.lower()`
- Plain text search (no pattern matching issues)

---

## 🧪 Testing Scenarios

### **Test 1: Chainlink Fence**

1. Find chainlink fence
2. Lure zombie to attack it
3. **Expected:**
   - HUD: "Chainlink Fence (Transparent)"
   - Zombie kept visible
   - Attack duration counter appears
   - After ~7-8 real minutes (60 in-game min):
     - Marked as functionally indestructible
     - Stuck logic triggers
     - Backup spawns from different direction

### **Test 2: High-Tier Wall**

1. Build reinforced concrete wall
2. Zombie attacks it
3. **Expected:**
   - HUD: "Concrete Wall (Opaque)"
   - Shows "No damage" status
   - Attack duration appears
   - After 60 in-game minutes:
     - Functionally indestructible
     - Zombie despawned (opaque)
     - Backup spawns

### **Test 3: Actually Breakable Structure**

1. Wooden door (health: 200/200)
2. Zombie attacks
3. **Expected:**
   - Damage dealt: 198/200, 195/200, etc.
   - Timer resets on each damage
   - Never reaches functionally indestructible
   - Eventually breaks through

---

## 📊 Data Tracking

### **New Fields:**

```lua
data.attackStartTime = <in-game minutes>
  // When zombie first started attacking
  
data.initialAttackTargetHealth = <number>
  // Health when tracking started
  
data.attackTargetFunctionallyIndestructible = <boolean>
  // True if 60+ min with no damage
```

### **Clearing Logic:**

Tracking cleared when:
- Zombie stops attacking
- Zombie switches targets
- Zombie dies
- Damage is dealt (timer resets, not cleared)

---

## 🎯 Benefits

### **Chainlink Fix:**
✅ **Accurate classification** - See-through fences properly detected
✅ **Zombie kept visible** - No mysterious despawning
✅ **Immersion maintained** - Can see zombie stuck at fence

### **Time-Based Detection:**
✅ **Detects "tough" structures** - Not just truly indestructible
✅ **Automatic recovery** - System handles edge cases
✅ **Visual feedback** - Clear progression from yellow → orange → red
✅ **No infinite waits** - Max 60 in-game min + 10 min stuck = backup
✅ **Respects game speed** - Uses in-game time

---

## 📝 Files Modified

1. **SpawnChunk_Spawner.lua**
   - Enhanced `isObjectOpaque()` with more keywords
   - Added pattern-based sprite detection
   - Added time-based tracking (attackStartTime)
   - Threshold check (60 in-game minutes)
   - Functionally indestructible flag
   - Timer reset on damage
   - Clear tracking on target change

2. **SpawnChunk_Visual.lua**
   - Display attack duration countdown
   - Color-coded by proximity to threshold
   - "FUNCTIONALLY INDESTRUCTIBLE" status
   - Duration text with warning

3. **SpawnChunk_Data.lua**
   - Updated version to `0.3.1.026`

4. **mod.info**
   - Updated version to `0.3.1.026`

---

## 💡 Edge Cases Handled

### **Case 1: Zombie Switches Targets**
```
Attack fence (30 min) → Switch to door
→ Tracking cleared, fresh start on door
```

### **Case 2: Damage After Long Time**
```
No damage for 55 min → 1 damage dealt
→ Timer resets to 0, start tracking again
```

### **Case 3: Multiple Zombies**
```
Zombie 1 stuck → Backup spawns
→ Backup is tracked separately
→ Each has own 60-minute window
```

### **Case 4: Speed Changes Mid-Attack**
```
Normal speed (30 min) → Change to 2x speed
→ Uses in-game time, so remaining time adapts
→ No issues with speed changes
```

---

## 🔍 Version Verification

In-game debug HUD should show:
```
Mod Version: 0.3.1.026
```

When zombie attacking structure with no damage:
```
→ Damage: No damage (hitting but not breaking)
   Attack duration: 35 in-game min (stuck at 1 hr)
```

After 60 in-game minutes:
```
→ Damage: FUNCTIONALLY INDESTRUCTIBLE
   (No damage after 1 in-game hour)
```

If you see attack duration and functionally indestructible status, fixes are active! ✅

---

## 🎮 Player Experience

### **Before:**
```
Zombie hits chainlink fence forever
HUD: "(Opaque)" - Wrong!
Zombie eventually despawns (opaque logic)
Player: "Why did it vanish? I could see it!"
Backup spawns, gets stuck again
Infinite loop with no resolution
```

### **After:**
```
Zombie hits chainlink fence
HUD: "(Transparent)" - Correct!
HUD: Attack duration counting up
After ~7-8 real minutes:
  HUD: "FUNCTIONALLY INDESTRUCTIBLE"
  Zombie stays visible (transparent)
  Backup spawns from different direction
  New zombie tries alternate route
Player: "System is working smart!"
```

---

## 📈 Success Metrics

✅ **Chainlink fences** properly classified as transparent
✅ **No-damage structures** detected within 60 in-game minutes
✅ **Zombie visibility** maintained for see-through objects
✅ **Automatic recovery** from truly tough structures
✅ **Clear feedback** via HUD duration counter
✅ **No infinite loops** - backup spawns eventually

Your scenario (chainlink fence, 100/100 hp, no damage) will now be properly detected and handled! 🎯

