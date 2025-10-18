# SpawnChunk Challenges - Development Roadmap

**Roadmap Version**: 3.0  
**Last Updated**: 2025-10-18  
**Status**: Phase 0 - Initial Setup & Pipeline Validation

---

## Overview
This roadmap outlines the development phases for the SpawnChunk Challenges mod for Project Zomboid Build 42. The mod implements a chunk-based challenge system where players must complete objectives to progressively unlock territory.

**Current Status**: Phase 0 - Initial Setup & Pipeline Validation

---

## Phase 0: Initial Setup & Pipeline Validation

**Goal**: Establish stable foundation and validate mod loading pipeline

### Tasks
1. **Update roadmap** ✅
   - Document all planned phases
   - Capture design decisions
   - Establish development workflow

2. **Pipeline validation**
   - 2.1: Validate loading mod in Steam Workshop (hidden mode for testing)
   - 2.2: Validate loading mod in-game via Workshop

3. **Test basic functionality**
   - Fresh spawn initialization
   - Boundary enforcement (50x50 tile teleportation)
   - Kill tracking and counting
   - Victory condition trigger
   - Reward system
   - Visual feedback (HUD, markers)
   - Save/load persistence

4. **Identify missing basic components** (if any)
   - Compare against previous working mod shell
   - Document any Build 42 API changes
   - List broken or missing features

5. **Add missing basic components** that were working before
   - Restore functionality one component at a time
   - Test each restoration independently

6. **Improve code** (optimization, error handling)
   - Fix victory function override conflict (Visual.lua vs Kills.lua)
   - Fix event handler removal patterns (anonymous functions)
   - Add missing respawn handler
   - Consolidate initialization timers
   - Add defensive nil checks
   - Improve debug logging
   - Optimize OnTick handlers for performance

7. **Test code optimization**
   - Validate no loss in functionality
   - Check for performance regression
   - Monitor console.txt for errors
   - Test edge cases (death during teleport, etc.)

### Success Criteria
- [ ] Mod loads successfully via Steam Workshop
- [ ] All basic functionality working in-game
- [ ] No console errors
- [ ] Code follows project standards
- [ ] Performance acceptable (minimal FPS impact)

---

## Phase 1: Boundary Visibility

**Goal**: Players can clearly see their confined area in both game world and map

### Tasks
1. **Improve in-game boundary visibility**
   - Ground markers render properly at all boundary edges
   - Boundary lines visible in game world (not just on teleport)
   - Visual feedback clear and intuitive
   - Performance acceptable with visual elements

2. **Improve map boundary visibility**
   - Map overlay clearly shows restricted zone
   - Boundary markers visible on in-game map
   - Color coding intuitive for locked areas
   - Map symbols persist correctly

### Success Criteria
- [ ] Boundary properly visible in game world
- [ ] Boundary properly visible on map
- [ ] Visual elements don't cause performance issues
- [ ] No visual glitches or missing markers
- [ ] Victory sound effect plays correctly ✅ (Already implemented)

---

## Phase 2: Sandbox Configuration

**Goal**: Players can customize challenge difficulty and parameters

### Tasks

#### 2.1: Chunk Size Options (Research & Testing)
- Test 50x50 (current, proven stable)
- Test 100x100 (2x2 chunks, single cell)
- Test 150x150 (3x3 chunks, single cell)
- Test 300x300 (full cell boundary) - recommended maximum
- Research feasibility of multi-cell chunks (>300x300)

**Important Notes:**
- Zombie population is managed at cell level (300x300 tiles)
- Multi-cell chunks add complexity for population tracking
- Recommended maximum: 300x300 (single cell boundary)
- Larger chunks may cause issues with zombie spawn/despawn behavior

#### 2.2: Kill Count Customization
- Add Sandbox option for kill count multiplier
- Maintain default: population / 9 (based on chunk being 1/9 of cell)
- Add minimum kill threshold (currently 10)
- Implement safety unlock: If zombie count = 0 AND respawn disabled → auto-unlock

**Critical Safety Feature:**
Prevent player softlock when zombie respawn is disabled and all zombies are killed before reaching goal.

### Sandbox Variables to Implement
```
ChunkSize = 50              (50, 100, 150, 300)
KillMultiplier = 1.0        (0.5 to 5.0)
MinimumKills = 10           (safety floor)
AutoUnlockIfNoZombies = true (prevent softlock)
```

### Success Criteria
- [ ] Chunk size options tested and working
- [ ] Kill multiplier configurable in Sandbox
- [ ] Softlock prevention working correctly
- [ ] All options save/load properly

---

## Phase 3: Progressive Chunk Unlocking

**Goal**: Players expand territory by completing challenges in adjacent chunks

### Core Mechanics
1. **Chunk expansion system**
   - When player completes challenge, can move beyond current boundary
   - Moving past boundary unlocks new 50x50 chunk in that direction
   - New chunks align with existing chunks (no zig-zagging)
   - Example: Original 50x50 + North unlock = 50x100 total area

2. **Direction-based unlocking**
   - Detect which boundary edge player crosses
   - Unlock new chunk in that direction (North, South, East, West)
   - Align new chunk to existing territory grid
   - Support expansion in all four directions

3. **Multi-direction expansion**
   - Players can expand territory in any direction
   - Ultimate goal: Progressive unlocking of entire map
   - Track all unlocked chunks in persistent data

### Design Decisions

#### Unlock Mode: Cumulative Tracking
- **Kill tracking**: Cumulative across all unlocked chunks
- **Target calculation**: Each new chunk adds its (population/9) to total
- **Progress display**: Show both current chunk progress AND total progress
- **Sandbox option**: Support alternative modes (per-chunk reset, free expansion)

**Example Progression:**
```
Start:     Chunk A | Kills: 0/10  | Total: 0/10   → Complete & Unlock
Expand:    Chunk B | Kills: 0/12  | Total: 10/22  → Complete & Unlock  
Expand:    Chunk C | Kills: 0/15  | Total: 22/37  → Complete & Unlock
```

#### Free Expansion Option
- Sandbox setting: `FreeExpansionAfter = X`
- After X unlocks, no more challenges required (free expansion)
- Default: -1 (never, always challenge mode)
- Options: 0 (immediate), 3, 5, 10, -1 (never)

#### Multi-Cell Zombie Population
When chunk spans multiple cells:
- Sample all four corners of chunk
- Identify which cells the chunk overlaps
- Average zombie population across all cells
- Use averaged population for kill target calculation

**Possible scenarios:**
- Chunk in single cell (most common)
- Chunk spans 2 cells (edge of cell boundary)
- Chunk spans 4 cells (corner of cell boundaries)

### Data Structure
```lua
unlockedChunks = {
    {minX, maxX, minY, maxY, killTarget, killsInChunk},
    -- Additional unlocked chunks...
}
totalKills = cumulative count
totalKillTarget = cumulative target
currentChunkIndex = active chunk
freeExpansionUnlocked = boolean
```

### Success Criteria
- [ ] New chunks unlock in correct direction
- [ ] Chunks align properly (no overlaps or gaps)
- [ ] Kill tracking works across multiple chunks
- [ ] Multi-cell population calculation accurate
- [ ] Progress persists across save/load
- [ ] Free expansion option working

---

## Phase 4: Challenge Refinement & Polish

**Goal**: Improve player experience and address feedback from Phases 1-3

### Tasks
1. **UI/UX improvements**
   - Refine progress display clarity
   - Improve feedback for boundary approaches
   - Add tutorial/help text for first-time players
   - Polish visual elements based on testing

2. **Balance adjustments**
   - Fine-tune kill requirements based on playtesting
   - Adjust default Sandbox values
   - Optimize difficulty curve for progression

3. **Bug fixes and edge cases**
   - Address issues discovered during Phase 1-3 testing
   - Fix any save/load issues with multi-chunk system
   - Resolve performance bottlenecks

4. **Code cleanup**
   - Refactor for maintainability
   - Improve code documentation
   - Optimize performance-critical sections

### Success Criteria
- [ ] No known critical bugs
- [ ] Positive player feedback on difficulty balance
- [ ] UI intuitive for new players
- [ ] Code well-documented and maintainable

---

## Phase 5: Challenge Option 2 - Time-Based

**Goal**: Add time-based survival challenge as alternative/additional unlock condition

### Tasks
1. **Time tracking system**
   - Track hours survived in current chunk
   - Handle game pause correctly
   - Persist time across save/load
   - Display time remaining/elapsed in UI

2. **Sandbox configuration**
   - Add option to enable time challenge
   - Configurable required hours (1-168 hours = 1 week)
   - Option: Count time while paused (true/false)

### Sandbox Variables to Implement
```
TimeChallengeEnabled = false
RequiredHours = 24
CountWhilePaused = false
```

### Success Criteria
- [ ] Time tracks accurately across sessions
- [ ] UI clearly shows time progress
- [ ] Sandbox options working correctly
- [ ] No time-tracking bugs on save/load

---

## Phase 6: Multi-Challenge Logic (OR/AND)

**Goal**: Allow combining Kill and Time challenges with OR/AND logic

### Tasks
1. **Implement OR logic**
   - Complete EITHER Kill Count OR Time requirement
   - UI shows both progress bars
   - Clear indication of "complete either" mode

2. **Implement AND logic**
   - Complete BOTH Kill Count AND Time requirements
   - UI shows both progress bars
   - Clear indication of "complete both" mode

### Challenge Modes
```
KILLS_ONLY      - Only kill requirement (current behavior)
TIME_ONLY       - Only time requirement
KILLS_OR_TIME   - Complete either challenge
KILLS_AND_TIME  - Complete both challenges
```

### Success Criteria
- [ ] Both challenge types work together
- [ ] OR logic triggers unlock correctly
- [ ] AND logic requires both conditions
- [ ] UI clearly indicates mode and progress

---

## Phase 7: Economy System (PZ Tycoon Mode)

**Goal**: Allow players to buy chunk unlocks with currency - implementing the "PZ Tycoon" concept

### Core Concept
Players can purchase chunks with in-game money instead of completing kill/time challenges. This transforms the mod into an economic progression system.

### Tasks
1. **Choose implementation approach**
   - Option A: NPC Vendor (interactive character)
   - Option B: Selling Terminal (interactive object)
   - Reference existing economy mods for best practices

2. **Currency system**
   - Define currency (vanilla items, custom token, configurable)
   - Implement item → currency conversion
   - Set chunk purchase prices

3. **Purchasing mechanics**
   - Interface for buying chunks
   - Price scaling based on zombie population
   - Base price inspiration: ~$16 (1993 Kentucky land values)
   - Higher population = higher price
   - Integration with existing unlock system

4. **Pricing formula**
   - Chunk price = zombie population × multiplier
   - Sandbox option for price multiplier
   - Optional: Bulk purchase discounts
   - Optional: Price fluctuations

### Design Questions (To Be Resolved)
- Which economy mods to use as reference/inspiration?
- What currency to use (cigarettes, custom, player choice)?
- Price scaling strategy (flat, exponential, configurable)?
- Multiplayer considerations (per-player or shared economy)?

### Success Criteria
- [ ] Players can earn currency by selling items
- [ ] Players can purchase chunk unlocks
- [ ] Prices balanced with other challenge types
- [ ] Economy system persists across save/load
- [ ] Pricing formula makes economic sense

---

## Phase 8: Advanced Multi-Challenge Options

**Goal**: Support any combination of Time, Kills, and Economy challenges with OR/AND logic

### Challenge Combinations to Support
```
Single Challenges:
- KILLS_ONLY
- TIME_ONLY
- ECONOMY_ONLY

Two-Challenge Combinations:
- KILLS_OR_TIME
- KILLS_OR_ECONOMY
- TIME_OR_ECONOMY
- KILLS_AND_TIME
- KILLS_AND_ECONOMY
- TIME_AND_ECONOMY

Three-Challenge Combinations:
- KILLS_OR_TIME_OR_ECONOMY (complete any one)
- KILLS_AND_TIME_AND_ECONOMY (complete all three)
- (KILLS_AND_TIME) OR ECONOMY (both first two, or economy)
- (KILLS_OR_TIME) AND ECONOMY (one of first two, plus economy)
```

### Tasks
1. **Implement flexible logic system**
   - Support any combination of three challenge types
   - Handle complex AND/OR nested logic
   - Validate combinations (prevent impossible challenges)

2. **Sandbox UI design**
   - Present options clearly to players
   - Consider preset modes ("Easy", "Hard", "Balanced")
   - Support custom configuration for advanced users

3. **Testing matrix**
   - Test all major combinations
   - Verify unlock logic correctness
   - Ensure UI accurately reflects requirements

### Success Criteria
- [ ] All challenge combinations working correctly
- [ ] UI clearly indicates requirements
- [ ] No logic bugs in complex AND/OR combinations
- [ ] Sandbox configuration user-friendly

---

## Phase 9: Compatibility Testing

**Goal**: Ensure mod works well with other popular mods

### Testing Priority
1. **Economy mods**
   - Test item interactions with Phase 7/8 economy features
   - Verify no currency conflicts
   - Test item selling/buying compatibility

2. **Zombie behavior mods**
   - Mods that alter zombie population
   - Mods that change zombie spawn/respawn
   - Verify kill tracking still accurate

3. **Map mods**
   - Custom spawn points
   - Altered cell structures
   - Verify boundary system works on modded maps

4. **UI mods**
   - Check for HUD conflicts
   - Verify visual elements don't overlap
   - Test keybind conflicts

5. **Popular mod combinations**
   - Test realistic player mod setups
   - Document known incompatibilities
   - Consider compatibility patches if needed

### Testing Approach
- One mod at a time (isolate conflicts)
- Common combinations (realistic scenarios)
- Document all findings
- Create compatibility list for players

### Success Criteria
- [ ] No critical conflicts with popular mods
- [ ] Known incompatibilities documented
- [ ] Compatibility patches implemented (if needed)
- [ ] Players informed of limitations

---

## Phase 10: Multiplayer Support

**Status**: Waiting for Build 42 multiplayer release

**Goal**: Ensure mod works correctly in multiplayer environments

### Known Challenges to Address
1. **Chunk boundaries**
   - Per-player boundaries or server-wide?
   - How to handle players in different chunks?

2. **Challenge progress**
   - Individual tracking or shared team progress?
   - How to handle players joining/leaving?

3. **Economy system**
   - Separate currency per player or pooled?
   - Trading between players?

4. **Visual elements**
   - Synchronize markers across clients
   - Handle client-server state differences

5. **Admin controls**
   - Commands to unlock chunks
   - Commands to reset challenges
   - Server configuration options

### Pre-Multiplayer Preparation
- Design data structures with MP in mind
- Avoid client-only assumptions in code
- Plan server/client separation
- Document MP requirements

### Success Criteria
- [ ] Mod functions in multiplayer environment
- [ ] No desync issues
- [ ] Admin commands working
- [ ] Server configuration options available
- [ ] Performance acceptable with multiple players

---

## Future Ideas (Parking Lot)

**Not prioritized - ideas for post-v1.0 consideration:**

### Additional Challenge Types
- **Zero to Hero (Skill Challenge)**: Unlock chunks by leveling skills
  - Each skill level increase unlocks one chunk
  - Sandbox option: Configure levels required per unlock
  - Challenge: Handle multiple skills leveling before player selects which chunk to unlock
  - Ultimate goal: Free exploration when all skills maxed
  - Data structure needed: Queue/store multiple pending unlocks
- **Resource Challenge**: Special rare items grant free unlocks
  - Concept: Very rare items (like Spiffo plushies) can be traded/consumed for instant chunk unlock
  - Function as "golden tickets" - bypass normal challenge requirements
  - Optional task list UI: "Rare Items Found: 2/10" (separate from main challenge)
  - Can be given to vendor (Phase 7 economy) or consumed directly
  - Gives additional function to decorative collectibles beyond aesthetics
  - Implementation note: Must be location-independent (some items impossible to find in certain areas)
  - Sandbox options: Enable/disable, configure which items count, set unlock cost per item
  - Examples: Spiffo plushies, rare toys, collector items, special magazines
  - Balance: Should be genuinely rare so they don't trivialize progression
- ~~Base Challenge~~: (Dropped - too complex to track progress reliably)

### Challenge Variations
- **Challenge Streaks**: Randomized or predefined rotation of challenge types
  - Example: Kill → Economy → Time → Kill (repeating pattern)
  - Random mode: Each unlock triggers different random challenge
  - Predefined mode: Set sequence in Sandbox options
- **Boss Zombies**: Special powerful zombies in chunks (requires integration with other mods)
- **Curve Balls/Environmental Hazards**: Warnings of upcoming changes
  - Zombie stat modifications (strength, toughness, speed, memory)
  - Integration with special zombie mods
  - Environmental dangers (sunlight damage, darkness effects)
  - Requires other mods as dependencies

### Meta-Progression & Rewards
- **Achievement System**: Track accomplishments beyond chunk unlocks
- **Prestige System**: Reset with permanent bonuses
- **Leaderboards**: Fastest completions, fewest deaths (local tracking)

### UI & Polish
- **In-Game Configuration UI**: Separate from Sandbox menu for mid-game adjustments
- **Particle Effects**: Visual flair on victory, unlock events
- **Tutorial System**: Interactive onboarding for new players
- **Challenge Mutators**: Special conditions/modifiers for chunks

### Advanced Features
- Challenge difficulty tiers (Easy/Normal/Hard per chunk)
- Timed events (survive horde, rescue missions)
- Custom chunk shapes (beyond square boundaries)
- Chunk biomes/themes with unique challenges
- NPC interaction challenges

---

## Performance Targets

### Optimization Goals
- **OnTick handlers**: < 3 active simultaneously
- **Marker count**: < 200 visible at once
- **Memory usage**: < 50MB for mod data
- **Save file size**: < 100KB per player
- **Frame rate impact**: < 5 FPS drop with all features active
- **Load time**: < 2 seconds for mod initialization

### Performance Testing Checklist
- [ ] Monitor FPS with all visual elements enabled
- [ ] Test with maximum unlocked chunks (50+ chunks)
- [ ] Profile memory usage over long sessions (10+ hours)
- [ ] Verify save/load times remain acceptable
- [ ] Check for memory leaks (run memory profiler)
- [ ] Test performance on low-end systems

### Known Performance Considerations
- OnTick handlers are expensive - minimize usage
- Ground markers add rendering overhead - cap total count
- Zombie population queries should be cached (5-minute intervals)
- Boundary checks should only run near chunk edges
- Visual elements should lazy-load (only render nearby chunks)

---

## Development Standards & Best Practices

### Code Organization
- One responsibility per file
- SpawnChunk namespace for all functions
- ModData only for persistent state
- Named functions for event handlers (enables proper removal)
- Defensive coding with nil checks
- Clear debug output with file/function prefixes

### Testing Checklist (Every Code Change)
- [ ] Fresh spawn initialization
- [ ] Player death/respawn cycle
- [ ] Save game / load game
- [ ] Victory condition trigger
- [ ] Visual elements persist correctly
- [ ] No console errors
- [ ] Performance acceptable (especially OnTick handlers)

### File Modification Rules
When providing code changes:
1. Always show complete files (no truncation)
2. Include all existing code
3. Add comments explaining PZ-specific API usage
4. Note integration points with other files
5. Preserve existing functionality unless specifically changing it

---

## Version History

| Version | Phase | Status | Notes |
|---------|-------|--------|-------|
| 0.1.0 | Phase 0 | In Progress | Initial development, pipeline validation |
| 0.2.0 | Phase 1 | Planned | Boundary visibility improvements |
| 0.3.0 | Phase 2 | Planned | Sandbox configuration |
| 0.4.0 | Phase 3 | Planned | Progressive chunk unlocking |
| 0.5.0 | Phase 4 | Planned | Refinement and polish |
| 0.6.0 | Phase 5 | Planned | Time-based challenges |
| 0.7.0 | Phase 6 | Planned | Multi-challenge OR/AND logic |
| 0.8.0 | Phase 7 | Planned | Economy system |
| 0.9.0 | Phase 8 | Planned | Advanced multi-challenge |
| 0.9.5 | Phase 9 | Planned | Compatibility testing |
| 1.0.0 | Phase 10 | Planned | Multiplayer support (post-B42 MP release) |

---

## Notes

**Roadmap Version**: 3.0  
**Last Updated**: 2025-10-18  
**Current Phase**: Phase 0 - Initial Setup & Pipeline Validation  
**Build Target**: Project Zomboid Build 42

**Build 42 Testing Note**: Local mod loading appears unavailable in Build 42. Testing requires uploading to Steam Workshop (hidden mode) and loading via Workshop subscription.

---

## Roadmap Version History

### Version 3.0 (2025-10-18) - Current
- Restructured into 10 distinct phases (0-10)
- Added Phase 0: Initial Setup & Pipeline Validation
- Added Phase 4: Challenge Refinement & Polish
- Clarified Phase 7 as PZ Tycoon Mode (economy system)
- Expanded Future Ideas with detailed concepts:
  - Zero to Hero skill challenge
  - Resource Challenge as "golden ticket" system
  - Challenge Streaks and Boss Zombies
  - Environmental Hazards/Curve Balls
- Restored Performance Targets section
- Dropped Base Challenge (too complex to implement)
- Noted victory sound effect already implemented

### Version 2.0 (Previous)
- Original GitHub version
- 6 phases with different structure
- Included all challenge types and advanced features in main phases

### Version 1.0 (Initial)
- First draft roadmap
- Basic phase structure