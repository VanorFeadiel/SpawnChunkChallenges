# Bug Fix - Indestructible Structure Detection v0.3.1.018

## 🎯 Issues Fixed

### Issue 1: Indestructible Structures = Zombie Stuck Forever
**Problem:** When a zombie attacks an indestructible structure (e.g., some walls, terrain objects), it would be considered "making progress" because it was attacking, even though it could never break through.

**Result:** 
- ❌ Wave counter reset to 0 (considered making progress)
- ❌ No backup zombie spawned
- ❌ Challenge stuck forever

### Issue 2: Wave Counter Disappeared After First Spawn
**Problem:** After spawning a backup zombie for a stuck zombie, the `consecutiveNonApproachingWaves` counter was reset to 0, so it never showed up again for subsequent zombies.

**Result:**
- ❌ Counter showed "1/10" for first zombie
- ❌ After spawn, counter disappeared
- ❌ Never accumulated again for new zombies

---

## ✅ Solutions Implemented

### Solution 1: Smart Progress Detection

**OLD CODE - BROKEN:**
```lua
if not zombieApproaching and not zombieAttackingStructure then
    data.consecutiveNonApproachingWaves = data.consecutiveNonApproachingWaves + 1
else
    -- Reset if approaching OR attacking (WRONG!)
    data.consecutiveNonApproachingWaves = 0
end
```

**NEW CODE - FIXED:**
```lua
local zombieMakingProgress = false

if zombieApproaching then
    -- Zombie getting closer = making progress
    zombieMakingProgress = true
elseif zombieAttackingStructure and data.damageThisCycle == true then
    -- Zombie attacking AND dealing damage = making progress
    zombieMakingProgress = true
elseif zombieAttackingStructure and data.damageThisCycle == nil then
    -- Attacking but no health data (INDESTRUCTIBLE) = STUCK!
    print("Zombie attacking indestructible structure")
end

if not zombieMakingProgress then
    data.consecutiveNonApproachingWaves = data.consecutiveNonApproachingWaves + 1
else
    data.consecutiveNonApproachingWaves = 0
end
```

**Key Changes:**
- ✅ Only count as progress if zombie is **approaching** OR **dealing actual damage**
- ✅ Attacking alone is NOT progress (might be indestructible)
- ✅ Detects indestructible structures via `damageThisCycle == nil`

### Solution 2: Persistent Wave Counter

**OLD CODE - BROKEN:**
```lua
if data.consecutiveNonApproachingWaves >= STUCK_THRESHOLD then
    SpawnChunk.spawnZombies(needed, data, pl)
    
    // Reset everything (WRONG!)
    data.consecutiveNonApproachingWaves = 0
    data.currentSoundRadius = 0
    data.lastClosestZombieDistance = nil
end
```

**NEW CODE - FIXED:**
```lua
if data.consecutiveNonApproachingWaves >= STUCK_THRESHOLD then
    SpawnChunk.spawnZombies(needed, data, pl)
    
    // DON'T reset counter - keep tracking for new zombie!
    // Only reset sound system
    data.currentSoundRadius = 0
    data.lastClosestZombieDistance = nil
end
```

**Key Changes:**
- ✅ Counter persists after spawning backup zombie
- ✅ Continues tracking if new zombie also gets stuck
- ✅ Only resets when zombie actually makes progress

---

## 📊 Enhanced HUD Display

### New Indestructible Structure Warning
When zombie attacks structure with no health data:

```
Status: ATTACKING STRUCTURE
→ Target: Concrete Wall
→ Damage: Unknown (no health data)
⚠ Structure may be INDESTRUCTIBLE!
   (Zombie is stuck, backup will spawn)
```

### Always-Visible Wave Counter
Now shows for ANY zombie (not just stuck ones):

```
Non-Progress Waves: 0 / 10    ← Green (making progress)
Non-Progress Waves: 3 / 10    ← Yellow (minor concern)
Non-Progress Waves: 7 / 10    ← Orange (getting stuck)
Non-Progress Waves: 9 / 10    ← Red (very stuck)
⚠ Zombie stuck! Backup will spawn at 10
```

At 10 waves:
```
Non-Progress Waves: 10 / 10
🆘 Spawning backup zombie!
```

---

## 🎨 Color Coding

### Wave Counter Colors
- 🟢 **Green (0):** Making progress
- 🟡 **Yellow (1-4):** Minor concern
- 🟠 **Orange (5-7):** Getting stuck
- 🔴 **Red (8-10):** Very stuck / spawning backup

### Damage Status
- 🔴 **Red:** "⚔ DEALING DAMAGE!" - Actively breaking structure
- 🟡 **Yellow:** "No damage (hitting but not breaking)" - Can't damage it
- ⚪ **Gray + 🟠 Warning:** "Unknown (no health data)" + Indestructible warning

---

## 🧪 Testing Scenarios

### Test 1: Indestructible Structure
1. Find an indestructible wall/object (e.g., concrete building exterior)
2. Lure zombie to attack it
3. Wait and watch HUD
4. **Expected Result:**
   - Shows "Attacking Structure: YES"
   - Shows "Unknown (no health data)"
   - Shows "⚠ Structure may be INDESTRUCTIBLE!"
   - Wave counter increases: 1/10, 2/10, 3/10...
   - At 10/10: Backup zombie spawns
   - Counter continues tracking

### Test 2: Destructible Structure
1. Find wooden fence or door
2. Lure zombie to attack it
3. **Expected Result:**
   - Shows "⚔ DEALING DAMAGE!"
   - Health bar decreases
   - Wave counter stays at 0 (making progress)
   - No backup spawn needed

### Test 3: Multiple Stuck Zombies
1. Get zombie stuck on indestructible wall
2. Wait for counter to reach 10/10
3. Backup zombie spawns
4. If backup ALSO gets stuck, counter continues
5. At 10/10 again: Another backup spawns

---

## 📝 Files Modified

1. **SpawnChunk_Spawner.lua**
   - Enhanced progress detection logic
   - Don't reset counter after spawning backup
   - Detect indestructible structures

2. **SpawnChunk_Visual.lua**
   - Added indestructible structure warning
   - Always show wave counter (not just when > 0)
   - Enhanced color coding
   - Better progress indicators

3. **SpawnChunk_Data.lua**
   - Updated version to `0.3.1.018`

4. **mod.info**
   - Updated version to `0.3.1.018`

---

## ⚙️ Technical Details

### Progress Detection Logic

A zombie is considered "making progress" if:
1. **Approaching:** `closestZombieDistance < lastClosestZombieDistance`
2. **Dealing Damage:** `zombieAttackingStructure == true AND damageThisCycle == true`

A zombie is considered "stuck" if:
1. Not approaching AND not dealing damage
2. Attacking structure with `damageThisCycle == nil` (no health data = indestructible)
3. Not within effective yell range (still far away)

### Wave Counter Persistence

The counter now:
- ✅ Increments every minute when zombie not making progress
- ✅ Persists across backup zombie spawns
- ✅ Only resets when zombie makes actual progress
- ✅ Displays continuously (not just when > 0)

---

## 🎯 Expected Behavior

### Scenario: Zombie Attacking Indestructible Wall
```
Minute 1: Non-Progress Waves: 1 / 10 (Yellow)
Minute 2: Non-Progress Waves: 2 / 10 (Yellow)
Minute 3: Non-Progress Waves: 3 / 10 (Yellow)
...
Minute 8: Non-Progress Waves: 8 / 10 (Red)
         ⚠ Zombie stuck! Backup will spawn at 10
Minute 9: Non-Progress Waves: 9 / 10 (Red)
Minute 10: Non-Progress Waves: 10 / 10 (Red)
          🆘 Spawning backup zombie!
          [Backup zombie spawns]
Minute 11: Non-Progress Waves: 11 / 10 (Red)
          [If backup also stuck, counter continues]
```

### Scenario: Zombie Breaking Through Fence
```
Minute 1: Non-Progress Waves: 0 / 10 (Green)
         ⚔ DEALING DAMAGE!
         Health: 45 / 50
[Zombie makes progress, counter stays at 0]
```

---

## ✅ Benefits

- ✅ No more infinite stuck zombies on indestructible structures
- ✅ Automatic backup spawning when needed
- ✅ Clear visual feedback about zombie progress
- ✅ Wave counter always visible for tracking
- ✅ Distinguishes between "can't damage" vs "indestructible"
- ✅ Persistent tracking across multiple stuck zombies

---

## 🔍 Version Verification

In-game debug HUD should show:
```
Mod Version: 0.3.1.018
```

If you see this version, all fixes are active! ✅

