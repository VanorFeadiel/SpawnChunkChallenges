# Testing Handoff - Challenge System v0.3.2.002

## Context for Claude

I've just implemented a 3-challenge system for the SpawnChunk Challenges mod. This is ready for testing.

---

## What Was Implemented

Three challenge types that can be selected via sandbox options:

1. **Purge Challenge** (Default) - Kill zombies to unlock chunks
2. **Time Challenge** - Survive X in-game hours to unlock chunks  
3. **Zero to Hero** - Level up skills to unlock chunks, all 6 at level 10 = victory

---

## Current Status

✅ **Code Complete** - All 3 challenges implemented
✅ **No Linting Errors** - All files pass validation
✅ **Documentation Updated** - CLAUDE_ACCESS_URLS.md and CHALLENGE_SYSTEM_SUMMARY.md
⏳ **Ready for Testing** - Needs in-game verification

---

## What Needs Testing

### Basic Functionality
1. **Purge Challenge** (Challenge Type = 1)
   - Verify kill counting still works
   - Chunk unlocks after target reached
   - HUD shows kill progress

2. **Time Challenge** (Challenge Type = 2)
   - Set duration to 1 hour for quick testing
   - Verify time counting works (`pl:getHoursSurvived()`)
   - HUD shows: `"Time: X.X / 1 hours"`
   - Chunk unlocks when time reached

3. **Zero to Hero** (Challenge Type = 3)
   - Level up a skill (e.g., Aiming)
   - Verify skill level-up is banked
   - Enter available chunk - should consume 1 banked unlock
   - HUD shows skill progress + banked count
   - All 6 skills at level 10 = victory + boundaries removed

### Cross-Save Testing
- Create 3 different save files with different challenge types
- Verify each save maintains its own challenge type
- Switching between saves should work correctly

---

## Key Files Modified

**New:**
- `SpawnChunk_Challenges.lua` - Challenge system core logic

**Modified:**
- `SpawnChunk_Data.lua` - Added challenge type data structures
- `SpawnChunk_Init.lua` - Initialize challenge type from sandbox
- `SpawnChunk_Kills.lua` - Use `isChunkCompleted()` for all challenges
- `SpawnChunk_ChunkEntry.lua` - Handle Zero to Hero skill unlock consumption
- `SpawnChunk_Visual.lua` - Challenge-specific HUD display
- `SpawnChunk_Boundary.lua` - Skip boundaries for completed Zero to Hero
- `sandbox-options.txt` - Added ChallengeType, TimeChallengeDuration, TimeInAnyChunk
- `Sandbox_EN.txt` - Translations

---

## If You Find Issues

### Common Test Scenarios

**Issue: Challenge type not changing**
- Check: Is it a NEW save? Challenge type is set on initialization only
- Check: Sandbox options saved correctly?

**Issue: HUD not showing correct progress**
- Check: `getChallengeProgressText()` function in SpawnChunk_Challenges.lua
- Check: HUD calls to `SpawnChunk.getChallengeProgressText()`

**Issue: Time Challenge not counting**
- Check: `updateTimeProgress()` being called in OnTick
- Check: Uses `pl:getHoursSurvived()` - verify player exists

**Issue: Zero to Hero not banking**
- Check: `updateSkillProgress()` being called in OnTick
- Check: `pendingSkillUnlocks` array being populated
- Check: Skill level detection working correctly

**Issue: Chunk not unlocking (Zero to Hero)**
- Check: Has `pendingSkillUnlocks` items?
- Check: `ChunkEntry.lua` consuming unlocks correctly

### Debug Commands

Print current challenge state:
```lua
local data = SpawnChunk.getData()
print("Challenge Type: " .. data.challengeType)
print("Time Hours: " .. (data.timeHours or 0))
print("Banked Unlocks: " .. #(data.pendingSkillUnlocks or {}))
```

---

## Implementation Notes for Claude

- **Challenge selection** happens in `SpawnChunk_Init.lua` (lines 39-75)
- **Progress tracking** happens in `SpawnChunk_Challenges.lua` OnTick handlers
- **Completion checks** use `isChunkCompleted()` which delegates to challenge-specific logic
- **Zero to Hero banking** uses queue system (`pendingSkillUnlocks` array)
- **Boundary enforcement** skips for `isComplete = true` in Zero to Hero

---

## Sandbox Option Reference

When testing, use these sandbox settings:

**Purge:**
- Challenge Type = 1
- (All other Purge options work as before)

**Time:**
- Challenge Type = 2
- Time Challenge Duration = 1 (for quick testing) or 12 (default)
- Time in Any Chunk = false (only count in new chunk) or true

**Zero to Hero:**
- Challenge Type = 3
- (No additional options yet)

---

## Questions to Resolve During Testing

1. Does Time Challenge properly track in-game hours?
2. Does skill banking work correctly when leveling multiple skills?
3. Does chunk unlock consume banked skills properly?
4. Does all 6 skills at level 10 remove boundaries correctly?
5. Can we switch between different challenge types in different saves?

---

## Success Criteria

✅ All 3 challenges work independently
✅ Challenge type persists across saves
✅ HUD shows correct progress for each challenge
✅ Completion logic triggers correctly
✅ Victory conditions work as expected
✅ No console errors or crashes

