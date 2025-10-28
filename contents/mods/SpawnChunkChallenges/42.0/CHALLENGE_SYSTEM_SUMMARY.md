# Challenge System Summary - v0.3.2.002

## Overview
The mod now supports 3 challenge types that can be selected via sandbox options:

1. **Purge Challenge** (Default) - Kill zombies to unlock chunks
2. **Time Challenge** - Survive for X hours to unlock chunks
3. **Zero to Hero Challenge** - Level skills to unlock chunks, all 6 at level 10 = free exploration

---

## How to Use

### Sandbox Options:
- **Challenge Type**: 1 = Purge, 2 = Time, 3 = Zero to Hero
- **Time Challenge Duration**: 1-720 in-game hours (default: 12)
- **Time in Any Chunk**: Check to count time in any unlocked chunk, uncheck to only count in new chunks

### Testing Each Challenge:

#### Purge Challenge (Default)
1. Set Challenge Type = 1
2. Kill zombies to unlock chunks
3. Works exactly as before

#### Time Challenge
1. Set Challenge Type = 2
2. Set Time Challenge Duration (test with 1 hour for quick testing)
3. Survive for the duration
4. HUD shows: `"Time: X.X / X hours"`
5. Chunk unlocks when time reached

#### Zero to Hero Challenge
1. Set Challenge Type = 3
2. Level up 6 skills: Aiming, Fitness, Strength, Sprinting, Lightfoot, Sneak
3. Each skill level-up banks one chunk unlock
4. Entering new chunk consumes one banked unlock
5. Multiple skill ups = multiple unlocks stored
6. HUD shows: `"Skills: Aiming: 5/10, Fitness: 3/10..." + (X banked)`
7. All 6 skills at level 10 = Victory! Boundaries removed completely

---

## Files Modified

**SpawnChunk_Data.lua**: Added challenge type, timeHours, timeTarget, pendingSkillUnlocks, completedSkills
**SpawnChunk_Init.lua**: Initialize challenge type from sandbox options
**SpawnChunk_Challenges.lua**: NEW - Challenge system with progress tracking and completion logic
**SpawnChunk_Kills.lua**: Updated completion checks to use challenge system
**SpawnChunk_ChunkEntry.lua**: Handle Zero to Hero skill unlock consumption
**SpawnChunk_Boundary.lua**: Skip boundary enforcement for completed Zero to Hero
**SpawnChunk_Visual.lua**: Challenge-specific HUD display
**sandbox-options.txt**: Added ChallengeType, TimeChallengeDuration, TimeInAnyChunk
**Sandbox_EN.txt**: Translations for new options
**mod.info**: Updated to 0.3.2.002

---

## Zero to Hero Mechanics

- **Banking System**: Each skill level-up adds to `pendingSkillUnlocks` queue
- **Unlock Consumption**: Entering an available chunk consumes 1 banked unlock
- **Multiple Banking**: Level up 3 skills before entering chunk = 3 unlocks available
- **Victory Condition**: All 6 skills at level 10 removes ALL boundaries permanently
- **Skill Tracking**: Monitors Aiming, Fitness, Strength, Sprinting, Lightfoot, Sneak

---

## Current Status

✅ All 3 challenges implemented
✅ Challenge system infrastructure complete
✅ HUD shows challenge-specific progress
✅ Sandbox options working
⏳ Ready for testing

---

## Testing Tomorrow

1. Test Purge Challenge (should work as before)
2. Test Time Challenge with 1-hour duration (quick test)
3. Test Zero to Hero skill banking
4. Verify all 3 can run in separate save files
5. Test chunk unlocks for each challenge type

