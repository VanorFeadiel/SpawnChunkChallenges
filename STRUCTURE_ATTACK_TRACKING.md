# Enhanced Structure Attack Tracking v2

## Summary
Enhanced debug HUD to show detailed information when zombies are attacking structures (fences, doors, windows, walls, etc.). 

**CRITICAL FIX:** Attack detection now runs ALWAYS (even when enough zombies exist), fixing the bug where attacks weren't being detected.

## What Changed

### 🔧 CRITICAL BUG FIX
**Problem:** Attack detection was inside the spawn logic and would return early if enough zombies existed, meaning it NEVER detected attacks when 1+ zombies were in the chunk.

**Solution:** Separated attack detection into its own function `checkZombieAttacking()` that runs BEFORE the early return, ensuring it ALWAYS checks for attacks every minute.

### New Features Added
1. **Mod Version Display** - Shows current mod version in debug HUD (from `SpawnChunk.MOD_VERSION`)
2. **Always-Visible Attack Flag** - Shows "Attacking Structure: YES/NO" at all times (not just when attacking)
3. **Separated Attack Detection** - Attack checking now independent of spawn logic

### Enhanced Attack Detection (`SpawnChunk_Spawner.lua`)
Now uses **3 detection methods** for maximum reliability:

1. **METHOD 1: Direct Target Check**
   - Checks `zombie:getTarget()` for non-player/zombie targets
   - Gets object name and health information

2. **METHOD 2: Thumping State Detection** (NEW)
   - Detects when zombie is in `ThumpState` (attacking animation)
   - Gets thump target via `zombie:getThumpTarget()`
   - Fallback if direct target not available

3. **METHOD 3: Proximity Detection** (NEW)
   - Checks for thumpable objects in adjacent squares
   - Useful when zombie has blocked path
   - Verifies object can be damaged via `canBeDamaged()`

### Damage Tracking System
- **Health Monitoring**: Tracks structure health every cycle (1 minute)
- **Damage Detection**: Compares health values to detect actual damage
- **Damage Logging**: Console messages when damage is dealt:
  ```
  ⚔ DAMAGE DEALT! Wooden Fence took 5.2 damage (44.8 / 50.0 remaining)
  ```
- **Periodic Updates**: Logs attack status every 10 cycles to avoid spam

### Enhanced HUD Display (`SpawnChunk_Visual.lua`)
Debug HUD now shows (when Debug Mode enabled):

```
=== DEBUG INFO ===
Mod Version: 0.3.1.017              ← NEW: Version tracking
Zombie Population: 1
Attacking Structure: YES            ← NEW: Always visible (orange when YES, gray when NO)
Closest Zombie (from center): 45.2 tiles
Closest Zombie (from you): 4.3 tiles
Status: ATTACKING STRUCTURE         ← Only shows when attacking
→ Target: Wooden Fence
→ Damage: ⚔ DEALING DAMAGE!        (Red - actively breaking)
   OR
→ Damage: No damage (hitting but not breaking)  (Yellow - can't damage)
   OR  
→ Damage: Unknown (no health data)  (Gray - no health info)

→ Health: 45 / 50 (90%)
[████████████░░] ← Visual health bar (color-coded)
```

## Color Coding

### Damage Status
- 🔴 **Red**: "⚔ DEALING DAMAGE!" - Zombie is successfully damaging the structure
- 🟡 **Yellow**: "No damage" - Zombie is hitting but can't break it
- ⚪ **Gray**: "Unknown" - No health information available

### Health Bar
- 🟢 **Green**: 67-100% health (structure mostly intact)
- 🟡 **Yellow**: 34-66% health (structure damaged)
- 🔴 **Red**: 0-33% health (structure about to break!)

## Technical Details

### Data Stored (in `data` object)
- `attackTargetName`: Name of structure being attacked
- `attackTargetHealth`: Current health value
- `attackTargetMaxHealth`: Maximum health value
- `attackTargetObject`: Reference to the object
- `lastAttackTargetHealth`: Previous health (for damage detection)
- `damageThisCycle`: Boolean indicating if damage was dealt this cycle
- `attackLogCounter`: Counter for periodic logging

### Update Frequency
- Attack detection: Every 1 minute (via `EveryOneMinute` event)
- HUD refresh: Every frame (real-time display)
- Console logging: Every 10 minutes (when attacking)

## Testing Scenario
Your exact scenario (zombie 4 tiles away hitting wooden fence):
1. HUD will show "Attacking Structure: YES" (always visible now!)
2. HUD will show "Status: ATTACKING STRUCTURE"
3. Shows target name "Wooden Fence" (or whatever the object is called)
4. Shows damage status with color-coded indicator
5. Health bar updates in real-time as zombie damages fence
6. Console logs when damage is actually dealt

## Updating Version Number

**When you make changes:**
1. Update `modversion` in `mod.info` (e.g., `0.3.1.018`)
2. Update `SpawnChunk.MOD_VERSION` in `SpawnChunk_Data.lua` (line 8)
3. Version will now display in debug HUD for verification

This ensures you can always confirm you're running the correct code version!

## Benefits
✅ Know immediately if zombie is making progress
✅ See exact structure health and damage rate  
✅ Distinguish between attacking vs. stuck zombie
✅ No more guessing if fence/door/wall is being damaged
✅ Better decision-making (do I reinforce? Do I fight?)
✅ Version tracking to verify code updates
✅ Always-visible attack flag (don't have to wait for details)

