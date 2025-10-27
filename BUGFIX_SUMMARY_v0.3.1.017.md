# Bug Fix Summary - Version 0.3.1.017

## 🔴 CRITICAL BUG FIXED: Attack Detection Not Working

### The Problem
You reported that zombie attacking door wasn't showing up in HUD. Root cause discovered:

**Attack detection code was inside spawn logic that returned early when 1+ zombies existed in chunk.**

This meant:
- ❌ Attack detection NEVER ran when zombies were present
- ❌ Only ran when spawning was needed (rare)
- ❌ Your zombie at the door was never detected

### The Solution
**Separated attack detection into independent function:**

```lua
-- NEW: Runs BEFORE early return
SpawnChunk.checkZombieAttacking(closestZombie, data)

-- OLD: This early return was blocking detection
if zombiesInChunk >= minZeds then 
    return 
end
```

**Result:** Attack detection now runs EVERY minute regardless of zombie count! ✅

---

## ✨ New Features Added

### 1. **Mod Version Display**
- Shows in debug HUD: `Mod Version: 0.3.1.017`
- Helps verify you're running correct code
- Update in 2 places:
  - `mod.info` line 11: `modversion=0.3.1.017`
  - `SpawnChunk_Data.lua` line 8: `SpawnChunk.MOD_VERSION = "0.3.1.017"`

### 2. **Always-Visible Attack Flag**
- New line: `Attacking Structure: YES/NO`
- Always shows (not just when attacking)
- 🟠 **Orange "YES"** when attacking
- ⚪ **Gray "NO"** when not attacking

### 3. **Enhanced Console Logging**
Now properly logs:
```
[Username] Zombie attacking: Wooden Fence (health: 45 / 50) - Damage: YES
[Username] ⚔ DAMAGE DEALT! Wooden Fence took 5.2 damage (39.8 / 50.0 remaining)
```

---

## 📝 Files Modified

1. **SpawnChunk_Data.lua**
   - Added `SpawnChunk.MOD_VERSION = "0.3.1.017"`

2. **SpawnChunk_Spawner.lua**
   - Created new function: `checkZombieAttacking()`
   - Moved all attack detection logic into it
   - Calls it BEFORE early return (critical fix!)

3. **SpawnChunk_Visual.lua**
   - Added version display to HUD
   - Added always-visible "Attacking Structure" flag
   - Enhanced damage status display

---

## 🧪 Testing Instructions

### To Verify Fix Works:

1. **Enable Debug Mode** in sandbox options
2. Start game and look at debug HUD
3. Verify version shows: `Mod Version: 0.3.1.017`
4. You should see: `Attacking Structure: NO`

### To Test Attack Detection:

**Easy Test:**
1. Find a building with window/door
2. Break window or stand outside closed door
3. Make noise (shout)
4. Wait for zombie to approach and attack
5. Within 1 minute, HUD should show:
   - `Attacking Structure: YES` (orange)
   - `Status: ATTACKING STRUCTURE`
   - Target name, damage status, health bar

**If zombie attacking door and nothing shows:**
- Wait up to 1 minute (detection runs every 60 seconds)
- Check that Debug Mode is enabled
- Check version number matches 0.3.1.017

---

## 🎯 Expected HUD Display

```
=== DEBUG INFO ===
Mod Version: 0.3.1.017              ✅ NEW
Zombie Population: 1
Attacking Structure: YES            ✅ NEW - Always visible
Closest Zombie (from center): 15.3 tiles
Closest Zombie (from you): 4.2 tiles
Status: ATTACKING STRUCTURE
→ Target: Wooden Door
→ Damage: ⚔ DEALING DAMAGE!
→ Health: 78 / 100 (78%)
[███████████░░░] 
```

---

## ⚠️ Known Limitations

- Attack detection updates every 60 seconds (via EveryOneMinute event)
- Only tracks CLOSEST zombie (not all zombies)
- Some objects may not report health correctly (game limitation)
- Detection range: All loaded cells (not limited to chunk)

---

## 📋 Version Update Checklist

When making future changes:

- [ ] Update `mod.info` line 11: `modversion=0.3.1.XXX`
- [ ] Update `SpawnChunk_Data.lua` line 8: `SpawnChunk.MOD_VERSION = "0.3.1.XXX"`
- [ ] Test in-game to see version in HUD
- [ ] Verify functionality works as expected

---

## 🐛 If Still Not Working

If attack detection still doesn't work after this fix:

1. Verify version shows `0.3.1.017` in HUD
2. Check console (~) for error messages
3. Ensure zombie is within loaded cells (near player)
4. Wait full 60 seconds for update cycle
5. Check that `DebugMode` sandbox option is `true`

If problem persists, the zombie might be:
- In unloaded cell (too far away)
- Not actually attacking (just standing near structure)
- Game API not reporting attack state correctly

