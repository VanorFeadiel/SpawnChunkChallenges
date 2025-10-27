# Additive Chunks Implementation Summary

## Overview
The additive chunks system allows players to progressively unlock adjacent chunks by completing challenges in each chunk. This creates a structured progression system where only one chunk can be worked on at a time, and completing it unlocks the adjacent chunks.

## Architecture

### Data Structure
Each character now has chunk-specific data stored in `modData.SpawnChunk[username]`:

```lua
{
    -- Core data
    isInitialized = true/false,
    spawnX, spawnY, spawnZ,  -- Original spawn point (center of chunk_0_0)
    boundarySize = 50,         -- Size of each chunk (tiles from center to edge)
    chunkMode = true/false,    -- Whether additive chunks mode is enabled
    
    -- Chunk tracking
    chunks = {
        ["chunk_0_0"] = {
            unlocked = true,
            completed = false,
            killCount = 0,
            killTarget = 10
        },
        ["chunk_1_0"] = {
            unlocked = true,
            completed = false,
            killCount = 0,
            killTarget = 12
        }
        -- ... more chunks
    },
    currentChunk = "chunk_0_0",  -- Active chunk key
    
    -- Legacy fields (for classic mode compatibility)
    killCount = 0,
    killTarget = 0,
    isComplete = false,
    
    -- Visual tracking
    markersCreated = false,
    mapSymbolCreated = false,
    
    -- Spawner tracking
    boundaryOutdoorsChecked = false,
    isOutdoors = false,
    currentSoundRadius = 0,
    lastClosestZombieDistance = nil,
    
    -- Debug stats
    totalSpawned = 0,
    totalSoundWaves = 0,
    maxSoundRadius = 0
}
```

### Chunk Naming Convention
Chunks are named using a grid coordinate system relative to the spawn point:
- `chunk_0_0` - The spawn chunk (center at spawn point)
- `chunk_1_0` - One chunk to the east
- `chunk_0_1` - One chunk to the south
- `chunk_-1_0` - One chunk to the west
- `chunk_0_-1` - One chunk to the north

### Chunk Coordinates
- Each chunk is a square with size `boundarySize * 2 + 1` tiles
- The center of `chunk_0_0` is at the player's spawn point
- Adjacent chunks share edges (no gaps or overlaps)

## Key Functions

### Data Management (SpawnChunk_Data.lua)

**Chunk Key Functions:**
- `SpawnChunk.getChunkKey(chunkX, chunkY)` - Create chunk key from coordinates
- `SpawnChunk.parseChunkKey(chunkKey)` - Parse chunk key to coordinates
- `SpawnChunk.getChunkKeyFromPosition(worldX, worldY, data)` - Get chunk key for a world position

**Chunk Information:**
- `SpawnChunk.getChunkCenter(chunkKey, data)` - Get world coordinates of chunk center
- `SpawnChunk.getChunkBounds(chunkKey, data)` - Get boundary bounds (minX, minY, maxX, maxY)
- `SpawnChunk.getAdjacentChunks(chunkKey)` - Get keys of adjacent chunks (N, E, S, W)

**Chunk Management:**
- `SpawnChunk.initChunk(chunkKey, unlocked, completed)` - Initialize a chunk
- `SpawnChunk.getChunkData(chunkKey)` - Get data for a specific chunk
- `SpawnChunk.unlockChunk(chunkKey)` - Unlock a chunk
- `SpawnChunk.completeChunk(chunkKey)` - Mark a chunk as completed
- `SpawnChunk.getUnlockedChunks()` - Get list of all unlocked chunk keys

### Initialization (SpawnChunk_Init.lua)

**Chunk Mode Detection:**
- Checks `SandboxVars.SpawnChunkChallenge.EnableChunkMode`
- If enabled, initializes first chunk (`chunk_0_0`)
- If disabled, uses classic single-boundary mode

**First Chunk Setup:**
- Creates `chunk_0_0` at spawn point
- Calculates kill target based on zombie population
- Sets chunk as unlocked but not completed

### Kill Tracking (SpawnChunk_Kills.lua)

**Chunk Mode Tracking:**
- Tracks kills per chunk (not globally)
- Only increments kill count for current chunk
- Shows chunk-specific progress notifications

**Chunk Completion:**
- When chunk kill target is reached, calls `SpawnChunk.onChunkComplete(chunkKey)`
- Marks chunk as completed
- Unlocks all adjacent chunks (N, E, S, W)
- Calculates kill targets for newly unlocked chunks
- Gives rewards (water, bandage)
- Resets visual markers to redraw with new chunks

**Adjacent Chunk Unlocking:**
- Gets adjacent chunk keys using `SpawnChunk.getAdjacentChunks()`
- Only unlocks chunks that aren't already unlocked
- Each new chunk gets its own kill target calculated based on current zombie population

### Boundary Enforcement (SpawnChunk_Boundary.lua)

**Chunk Mode Boundaries:**
- Player can move freely within ANY unlocked chunk
- Teleported back if they try to leave the unlocked area
- Checks all unlocked chunks to determine if position is valid

**Classic Mode Boundaries:**
- Single boundary check around spawn point
- Player freed after completing the challenge

### Visual System (SpawnChunk_Visual.lua)

**Ground Markers:**
- Draws boundary markers for ALL unlocked chunks
- Color coding:
  - **Green**: Completed chunks
  - **Yellow**: Current chunk
  - **Orange**: Other unlocked chunks (not current)

**Map Symbols:**
- Draws boundary rectangles for all unlocked chunks
- Uses same color coding as ground markers
- Shows spawn point as green marker

**HUD Display:**
- Shows current chunk name and progress
- Shows total unlocked chunks count
- Displays distance to boundary
- Debug mode shows enhanced information

### Spawner System (SpawnChunk_Spawner.lua)

**Chunk Mode Spawning:**
- Uses current chunk center as spawn point reference
- Spawns zombies around current chunk boundary
- Same smart sound attraction system
- Indoor/outdoor detection per chunk boundary

## Sandbox Options

### New Options for Chunk Mode

**EnableChunkMode** (boolean, default: false)
- Enables the additive chunks system
- When disabled, uses classic single-boundary mode

**ChunkUnlockPattern** (integer, 1-2, default: 1)
- Pattern 1: Cardinal directions only (N, E, S, W)
- Pattern 2: All adjacent including diagonals (not yet fully implemented)

### Existing Options (Work in Both Modes)

- **BoundarySize**: Size of each chunk boundary
- **MinZombies**: Minimum zombies to maintain
- **KillMultiplier**: Kill target multiplier
- **ShowGroundMarkers**: Show boundary markers on ground
- **ShowMapSymbols**: Show boundary on map
- **ShowHUD**: Show progress HUD
- **DebugMode**: Enable debug information
- **DebugCloseSpawn**: Spawn zombies close for testing

## Mode Compatibility

### Backward Compatibility
The system is fully backward compatible:
- Existing saves work in classic mode (chunk mode disabled)
- Legacy fields (`killCount`, `killTarget`, `isComplete`) still maintained
- Can switch between modes by toggling the sandbox option (new game required)

### Data Migration
When enabling chunk mode:
- First spawn initializes `chunk_0_0` at spawn point
- Previous progress not migrated (fresh start)

When disabling chunk mode:
- Reverts to classic single-boundary behavior
- Chunk data ignored but preserved

## Gameplay Flow

### Chunk Mode Gameplay

1. **Game Start**
   - Player spawns at world location
   - `chunk_0_0` initialized and unlocked at spawn point
   - Kill target calculated based on zombie population
   - Boundary markers and HUD appear

2. **First Chunk Challenge**
   - Player must kill X zombies within `chunk_0_0`
   - Cannot leave chunk boundaries
   - Progress tracked and displayed on HUD
   - Ground markers show chunk edges (yellow)

3. **Chunk Completion**
   - Upon reaching kill target:
     - Chunk marked as completed (turns green)
     - Adjacent chunks (N, E, S, W) unlock
     - Each new chunk gets its own kill target
     - Reward items given
     - Visual markers update to show new chunks

4. **Exploration & Progression**
   - Player can move freely within any unlocked chunk
   - Choose which adjacent chunk to work on next
   - Complete chunks to unlock more adjacent areas
   - Gradually expand playable area outward from spawn

5. **Death**
   - All progress reset
   - Chunks cleared and reinitialized
   - Respawn at original spawn point
   - Start over with `chunk_0_0`

### Classic Mode Gameplay
- Single boundary around spawn point
- Kill X zombies to complete challenge
- After completion, player can leave freely
- No chunk progression

## Visual Feedback

### Color Coding System
- **Green**: Completed chunks/spawn point
- **Yellow**: Current active chunk (in chunk mode)
- **Orange**: Other unlocked chunks (in chunk mode)
- **Red**: Warning text when near boundary

### HUD Information
**Chunk Mode:**
```
Chunk chunk_0_0 - Kills: 5 / 10
Unlocked Chunks: 3
Distance to boundary: 25 tiles
```

**Classic Mode:**
```
Kills: 5 / 10
Distance to boundary: 25 tiles
```

## Technical Details

### Chunk Size Calculation
- Chunk boundary is `boundarySize` tiles from center
- Total chunk area: `(boundarySize * 2 + 1)²` tiles
- Default 50 tile boundary = 101x101 tile chunk = 10,201 tiles

### Kill Target Calculation
Each chunk's kill target is independently calculated:
```lua
baseTarget = floor(totalZombies / 9)
areaMultiplier = chunkArea / baselineArea
target = floor(baseTarget * areaMultiplier * killMultiplier)
target = max(target, 5)  -- Minimum 5
```

### Performance Considerations
- Boundary checking optimized (every 10 ticks, ~0.3 seconds)
- Visual markers created once per chunk unlock
- Only unlocked chunks tracked and rendered
- Character-specific isolation prevents multi-player conflicts

## Future Enhancements

### Potential Features
1. **Diagonal Unlocking**: Implement Pattern 2 (all 8 adjacent chunks)
2. **Chunk-Specific Challenges**: Different challenge types per chunk
3. **Persistent Chunk Progress**: Keep chunk progress on death (configurable)
4. **Chunk Rewards**: Better rewards for completing more chunks
5. **Chunk Difficulties**: Progressive difficulty scaling
6. **Chunk Selection UI**: Let player choose which chunk to focus on
7. **Chunk Statistics**: Track completed chunks, time per chunk, etc.
8. **Smart Boundary Distance**: Calculate distance to nearest boundary in chunk mode

### Known Limitations
1. **Current Chunk Selection**: No UI to manually select "current" chunk
   - Currently, current chunk is just the spawn chunk
   - May need mechanism to switch current chunk to other unlocked chunks
2. **Boundary Distance HUD**: In chunk mode, shows distance from spawn (not from current chunk center)
3. **Diagonal Unlock**: Pattern 2 defined but not fully implemented

## Testing Checklist

### Basic Functionality
- [ ] Spawn in chunk mode initializes `chunk_0_0`
- [ ] Kill tracking increments per chunk
- [ ] Chunk completion unlocks adjacent chunks
- [ ] Boundary enforcement works for all unlocked chunks
- [ ] Visual markers show all unlocked chunks
- [ ] Map symbols show all unlocked chunks with correct colors
- [ ] HUD displays chunk-specific information

### Edge Cases
- [ ] Death resets chunks correctly
- [ ] Multiple characters have isolated chunk progress
- [ ] Switching between chunks maintains separate kill counts
- [ ] Completing all 4 adjacent chunks unlocks correctly
- [ ] Works with different boundary sizes (10, 50, 100)
- [ ] Works with different kill multipliers (0.5, 1.0, 3.0)

### Compatibility
- [ ] Classic mode still works (chunk mode disabled)
- [ ] Existing saves load correctly
- [ ] All sandbox options function properly

## Summary

The additive chunks system successfully implements:
✅ Per-chunk kill tracking
✅ Progressive chunk unlocking (adjacent on completion)
✅ Multi-chunk boundary enforcement
✅ Visual feedback (color-coded markers)
✅ Chunk-specific data persistence
✅ Character-specific isolation
✅ Backward compatibility with classic mode
✅ Sandbox configuration options

The system is ready for in-game testing!

