SpawnChunk Challenges - Development Roadmap
🎯 Current Status: Phase 1 Complete ✅
Latest Update: 2025-10-20
Roadmap Version: 4.0
Mod Version: v0.1-alpha
Build: Project Zomboid Build 42.0

Phase 1: Foundation ✅ COMPLETE
Goal: Stable single-chunk challenge system
Core Mechanics ✅

 Spawn position capture and chunk definition
 Boundary enforcement via teleportation
 Kill tracking for zombie elimination
 Progressive targets (population/9 zombies)
 Victory condition with free exploration unlock
 Persistence through saves & respawns

Visual Feedback ✅

 Ground markers for boundary visualization (yellow "X" on every boundary tile)
 Map symbols showing challenge zone (continuous yellow rectangle boundary)
 Small green spawn point marker
 HUD showing progress and boundaries (kills, distance to boundary)
 Warning system for approaching edges (synchronized at <10 tiles)
 Color-coded feedback (green safe → red danger)
 Victory notifications and effects
 Victory celebration sound

Victory & Cleanup ✅

 Victory removes mod symbols
 Player symbols preserved on victory
 Death reset recreates ground markers
 Map symbols persist through death
 Visual synchronization (warning + red text at same distance)
 Reward system (customizable items) - NOT IMPLEMENTED (future feature)

Known Issues - Fixed ✅

 Victory function override conflict → Removed Visual.lua victory
 Anonymous event handler removal → Named functions implemented
 Missing respawn handler → Added in Init.lua
 Multiple timers → Consolidated initialization

Testing Results ✅

 Fresh spawn → kill tracking → victory
 Death/respawn cycle
 Save/load game
 Visual elements persist correctly
 Victory cleanup preserves player symbols
 Death reset with proper visual recreation


Phase 2: Configuration & Polish 🔄 NEXT
Goal: Make system configurable and user-friendly
Phase 2.1: Sandbox Options 🎯 PRIORITY
Estimated Time: 2-4 hours (CoPilot + Claude planning)
Files to Create:
media/lua/shared/
└── SpawnChunk_Sandbox.lua   # SandboxVars definitions
```

**Files to Modify**:
```
SpawnChunk_Init.lua    # Read sandbox settings
SpawnChunk_Kills.lua   # Use configurable targets
SpawnChunk_Visual.lua  # Configurable visuals
Sandbox Options to Add:

 Challenge type selection

 Kill zombies (current)
 Survive X days (future)
 Gather resources (future)


 Boundary size (10-100 tiles)

 Default: 50x50
 Min: 10x10 (tight!)
 Max: 100x100 (easy mode)


 Kill target multiplier (0.5-2.0x)

 Default: 1.0 (population/9)
 Easy: 0.5x (fewer kills)
 Hard: 2.0x (more kills)


 Respawn behavior

 Full reset (current)
 Soft reset (keep some progress)
 No reset (persistent)


 Visual options

 Show/hide ground markers
 Show/hide map symbols
 Show/hide HUD
 Warning distance (5-15 tiles)



Testing Checklist:

 Options appear in world setup menu
 Values persist in saves
 Changing options affects behavior correctly
 Edge cases handled (min/max values)

CoPilot Implementation Notes:

Start with SpawnChunk_Sandbox.lua (definitions)
Add getter functions in Init.lua
Update Kills.lua calculations
Adjust Visual.lua displays
Test each option individually


Phase 2.2: Enhanced Feedback 🎨 TODO
Goal: Better visual feedback and player experience

 Progress milestones (25%, 50%, 75% notifications)
 Sound effects

 Victory celebration sound - COMPLETED
 Boundary warning sounds


 Better tutorial/onboarding (first-time tips)
 Map legend/key explaining boundary colors

Testing Focus: User experience and clarity

Phase 2.3: Performance & Polish ⚡ TODO
Goal: Optimize and stabilize

 Optimize OnTick handlers (reduce frequency if possible)
 Reduce marker count options
 Memory leak testing
 Long session stability testing
 Error handling improvements

Performance Targets:

OnTick handlers: < 3 active simultaneously
Marker count: < 400 visible at once (current: ~404)
Memory usage: < 50MB for mod
Save file size: < 100KB per player

Testing: Stress test with extended play sessions

Phase 3: Chunk Progression System 🚀 FUTURE
Goal: Multi-chunk unlocking progression (Core Vision)
Phase 3.1: Data & Logic 🏗️ TODO
Goal: Infrastructure for tracking multiple chunks

 Data structure for multiple chunks

 Track chunk states (locked/unlocked/completed)
 Current active chunk pointer
 Chunk completion history
 Total kills across all chunks


 Adjacent chunk detection algorithm
 Chunk unlocking logic (complete → unlock adjacent)
 Progressive kill targets per chunk
 Directional progression options (N/S/E/W priority)

Data Structure:
unlockedChunks = {
  {minX, maxX, minY, maxY, killTarget, killsInChunk},
  -- Additional unlocked chunks...
}
totalKills = cumulative count
totalKillTarget = cumulative target
currentChunkIndex = active chunk
freeExpansionUnlocked = boolean
```

---

### Phase 3.2: Visual System 🎨 TODO
**Goal**: Clear visual representation of progression

**Design Clarification** (Updated from previous versions):
- [ ] **Single yellow boundary** for entire unlocked area
- [ ] Boundary expands outward as chunks unlock
- [ ] Walls between chunks get removed automatically
- [ ] Kill target = zombie population from most recently unlocked chunk
- [ ] Kills anywhere in unlocked area count toward unlocking new chunk
- [ ] Ground markers reflect current boundary state
- [ ] Map legend for progression status
- [ ] Smooth visual transitions on unlock

**NOT doing**: ~~Multiple color coding per chunk state~~ (too complex)

---

### Phase 3.3: UI Updates 📊 TODO
**Goal**: Clear progression tracking

- [ ] Show current chunk number (e.g., "Chunk 5 of 42")
- [ ] Display total chunks unlocked
- [ ] Progression percentage (% of map unlocked)
- [ ] Chunk history viewer
- [ ] Statistics dashboard

---

## Phase 4: Challenge Varieties 🎮 FUTURE
**Goal**: Multiple challenge types for variety

### Phase 4.1: Challenge Framework 🏗️ TODO
- [ ] Challenge type enum/system
- [ ] Per-challenge configuration storage
- [ ] Challenge selection UI
- [ ] Challenge-specific data structures

---

### Phase 4.2: Challenge Types 🎯 TODO
- [ ] **Kill Challenge** ✅ (current/default)
- [ ] **Survival Challenge** - Survive X days in chunk
- [ ] **Resource Challenge** - Gather specific items
- [ ] **Base Challenge** - Build structures meeting requirements
- [ ] **Skill Challenge** - Reach skill levels
- [ ] **Time Trial** - Complete objectives within time limit
- [ ] **Combo Challenge** - Multiple requirements

---

### Phase 4.3: Challenge Rewards 🎁 TODO
- [ ] Challenge-specific reward tables
- [ ] Reward scaling based on difficulty
- [ ] Rare/unique items for harder challenges
- [ ] Random challenge generator
- [ ] Challenge difficulty scaling system

---

## Phase 5: Multiplayer Support 🌐 FUTURE
**Goal**: Full multiplayer compatibility

**Status**: Waiting for Build 42 multiplayer release

### Phase 5.1: Core Multiplayer 🔧 TODO
- [ ] Server-side state synchronization
- [ ] Per-player challenge tracking
- [ ] Player-specific visual markers
- [ ] Shared vs separate chunk unlocking decision
- [ ] Server restart recovery

---

### Phase 5.2: Multiplayer Features 👥 TODO
- [ ] Admin commands (reset, unlock, complete)
- [ ] Server configuration options
- [ ] Player join/leave handling
- [ ] Spectator mode for completed players

---

### Phase 5.3: Testing 🧪 TODO
- [ ] 2-player testing
- [ ] 4+ player testing
- [ ] Stress testing (10+ players)
- [ ] Network latency handling

---

## Future Ideas (Parking Lot) 💡
**Not prioritized - ideas for post-v1.0 consideration**

### Additional Challenge Types

#### Zero to Hero (Skill Challenge)
- Unlock chunks by leveling skills
- Each skill level increase unlocks one chunk
- Sandbox option: Configure levels required per unlock
- **Challenge**: Handle multiple skills leveling before player selects which chunk to unlock
- Ultimate goal: Free exploration when all skills maxed
- Data structure needed: Queue/store multiple pending unlocks

#### Resource Challenge (Golden Tickets)
- **Concept**: Very rare items (like Spiffo plushies) can be traded/consumed for instant chunk unlock
- Function as "golden tickets" - bypass normal challenge requirements
- Optional task list UI: "Rare Items Found: 2/10" (separate from main challenge)
- Can be given to vendor (Phase 7 economy) or consumed directly
- Gives additional function to decorative collectibles beyond aesthetics
- **Implementation note**: Must be location-independent (some items impossible to find in certain areas)
- Sandbox options: Enable/disable, configure which items count, set unlock cost per item
- Examples: Spiffo plushies, rare toys, collector items, special magazines
- Balance: Should be genuinely rare so they don't trivialize progression

#### Economy System (PZ Tycoon Mode)
- Buy chunks with in-game money instead of killing zombies
- Chunk price = zombie population × multiplier
- Base price: ~$16 (1993 Kentucky land values)
- Scaling: Higher population = higher price
- Trading system integration
- Item selling values
- Price fluctuations
- Bulk purchase discounts

---

### Challenge Variations

#### Challenge Streaks
- Randomized or predefined rotation of challenge types
- Example: Kill → Economy → Time → Kill (repeating pattern)
- Random mode: Each unlock triggers different random challenge
- Predefined mode: Set sequence in Sandbox options

#### Boss Zombies
- Special powerful zombies in chunks (requires integration with other mods)

#### Curve Balls/Environmental Hazards
- Warnings of upcoming changes
- Zombie stat modifications (strength, toughness, speed, memory)
- Integration with special zombie mods
- Environmental dangers (sunlight damage, darkness effects)
- Requires other mods as dependencies

---

### Meta-Progression & Rewards
- **Achievement System**: Track accomplishments beyond chunk unlocks
- **Prestige System**: Reset with permanent bonuses
- **Leaderboards**: Fastest completions, fewest deaths (local tracking)

---

### UI & Polish
- **In-Game Configuration UI**: Separate from Sandbox menu for mid-game adjustments
- **Particle Effects**: Visual flair on victory, unlock events
- **Tutorial System**: Interactive onboarding for new players
- **Challenge Mutators**: Special conditions/modifiers for chunks

---

### Advanced Features
- Challenge difficulty tiers (Easy/Normal/Hard per chunk)
- Timed events (survive horde, rescue missions)
- Custom chunk shapes (beyond square boundaries)
- Chunk biomes/themes with unique challenges
- NPC interaction challenges

---

## Performance Targets ⚡

### Optimization Goals
- **OnTick handlers**: < 3 active simultaneously
- **Marker count**: < 400 visible at once
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

## Development Standards & Best Practices 📋

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

## File Structure Reference 📁
```
SpawnChunkChallenges/42.0/media/lua/client/
├── SpawnChunk_Data.lua      # ModData persistence
├── SpawnChunk_Init.lua      # Initialization & death reset
├── SpawnChunk_Kills.lua     # Kill tracking & victory
├── SpawnChunk_Boundary.lua  # Teleportation enforcement
└── SpawnChunk_Visual.lua    # UI, markers, HUD
```

**Design Principle**: One responsibility per file, SpawnChunk namespace for all functions

---

## Version History 📜

### v0.1-alpha ✅ (Current - 2025-10-20)
**Phase 1 Complete**
- Single chunk challenge system
- Kill tracking with dynamic targets
- Boundary enforcement with teleportation
- Visual feedback (ground + map + HUD)
- Victory celebration and cleanup
- Death reset with visual recreation
- Player symbol preservation

### Planned Versions
- **v0.2-alpha**: Phase 2.1-2.2 (Sandbox options, enhanced feedback)
- **v0.3-alpha**: Phase 2.3 + 3.1 (Polish + chunk progression foundation)
- **v0.4-alpha**: Phase 3.2-3.3 (Full chunk progression system)
- **v0.5-beta**: Phase 4 (Challenge varieties)
- **v0.9-beta**: Phase 5 (Multiplayer support)
- **v1.0-release**: Stable, polished, fully tested

---

## Roadmap Version History 📝

### Version 4.0 (2025-10-20) - **CURRENT**
**Major Changes**:
- ✅ Marked Phase 1 as COMPLETE
- ✅ Updated Phase 1 with actual completion status
- ✅ Clarified victory rewards NOT implemented (just free exploration)
- ✅ Removed kill notification sounds from Phase 2.2 (base game sufficient)
- ✅ Clarified Phase 3.2 visual system: single yellow boundary (no multi-color chunks)
- ✅ Marked victory celebration sound as complete
- ✅ Preserved all Future Ideas from v3.0
- ✅ Maintained 10-phase structure
- ✅ Kept performance targets and development standards

### Version 3.0 (2025-10-18)
- Restructured into 10 distinct phases (0-10)
- Added Phase 0: Initial Setup & Pipeline Validation
- Added Phase 4: Challenge Refinement & Polish
- Clarified Phase 7 as PZ Tycoon Mode (economy system)
- Expanded Future Ideas with detailed concepts
- Restored Performance Targets section
- Dropped Base Challenge (too complex to implement)

### Version 2.0 (Previous)
- Original GitHub version
- 6 phases with different structure
- Included all challenge types in main phases

### Version 1.0 (Initial)
- First draft roadmap
- Basic phase structure

---

## Development Workflow 🔄

### Tools Used
1. **GitHub CoPilot** (Cursor IDE) - Primary code generation
2. **Claude** (Claude.ai Pro) - Planning, architecture, debugging walls
3. **Cursor AI** - Last resort for complex debugging

### Workflow Pattern
```
Planning → CoPilot (code) → Test → Hit Wall?
 ↓
 Yes → Claude (debug) → Still stuck? → Cursor AI
 ↓
 No → Commit & Continue
```

### For Claude Sessions
When returning to Claude after CoPilot work:

**Template**:
```
Working on [feature].

File index: https://raw.githubusercontent.com/.../CLAUDE_ACCESS_URLS.md?cache-bust=YYYYMMDD

CoPilot Changes:
- [file1]: [description of changes]
- [file2]: [description of changes]

Status: [working / has issues / need review]
Next: [what you want to accomplish]