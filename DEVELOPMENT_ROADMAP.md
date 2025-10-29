# SpawnChunk Challenges - Development Roadmap

**Current Version:** v0.3.2.026  
**Last Updated:** 2025-10-29

---

## Phase 1: Foundation ✅ COMPLETE
**Goal**: Stable single-chunk challenge system

### Completed ✅
- [x] Basic ModData persistence (character-specific)
- [x] Player spawn initialization
- [x] Kill tracking system
- [x] Boundary enforcement (classic & chunk mode)
- [x] Victory condition
- [x] Ground markers (color-coded by chunk state)
- [x] Map symbols (continuous boundary lines)
- [x] HUD display (collapsible, draggable, positioned at 75, 0)
- [x] Respawn handler (recreates visuals after death)
- [x] Event handler patterns (named functions for removal)
- [x] Character-specific visual tracking

---

## Phase 2: Configuration & Polish ✅ COMPLETE
**Goal**: Configurable, user-friendly experience

### Completed ✅
- [x] Sandbox options menu
  - [x] Kill multiplier setting
  - [x] Boundary size options (50-200 tiles)
  - [x] Challenge type selection (Purge/Time/ZeroToHero)
  - [x] Chunk unlock pattern (Cardinal/All Adjacent)
  - [x] Enable/disable visual elements (markers, symbols, HUD)
  - [x] Debug mode toggle
  - [x] Time challenge target configuration
- [x] HUD keybinding (toggle with comma key)
- [x] Visual feedback (halo notes, color-coded chunks)
- [x] Sound effects (level up, wall hit)
- [x] Optimized OnTick handlers (counter-based checks)
- [x] Efficient marker system (character-specific storage)

### Removed from Phase 2 (not needed for initial release)
- ❌ Reward system (code errors, not core gameplay)
- ❌ In-game UI (beyond Sandbox menu)
- ❌ Tutorial system (moved to Phase 6)
- ❌ Particle effects on victory (sound + color change sufficient)
- ❌ Reward customization

---

## Phase 3: Chunk Progression System ✅ COMPLETE
**Goal**: Multi-chunk unlocking progression

### Completed ✅
- [x] Adjacent chunk detection (4 cardinal directions)
- [x] Chunk unlocking algorithm (Pattern 1: Cardinal, Pattern 2: All Adjacent)
- [x] Progressive challenge targets per chunk
- [x] Chunk boundary visualization (color-coded: yellow/green/blue)
- [x] Map overview showing locked/unlocked chunks
- [x] **Blue chunks beside ALL completed chunks** (prevents stuck situations)
- [x] Track multiple chunks in ModData
- [x] Current chunk pointer
- [x] Chunk state tracking (unlocked/completed/available)
- [x] UI shows current chunk status
- [x] Total chunks unlocked display
- [x] Chunk change detection

---

## Phase 4: Challenge Improvements 🔧 IN PROGRESS
**Goal**: Refine and expand challenge types

### Completed ✅
- [x] **Purge Challenge** - Kill X zombies to unlock chunk
- [x] **Time Challenge** - Spend X hours in chunk
- [x] **Zero to Hero Challenge** - Level up skills to unlock chunks
  - [x] Skill tracking (Build 42 XP system)
  - [x] Unlock banking system
  - [x] Settlement timer (1 hour after entering blue chunk)
  - [x] Ready-to-unlock flag system
  - [x] Auto-completion when timer expires

### In Progress 🔧
- [ ] **Purge Challenge Variants** (kill location options)
  - [ ] Option 1: Kill counts only when player is in yellow chunk (CURRENT DEFAULT)
  - [ ] Option 2: Kill counts only when zombie is in yellow chunk
  - [ ] Option 3: Kill counts if either player OR zombie in yellow chunk
  - [ ] Option 4: Kill anywhere counts toward current chunk
- [ ] **Zero to Hero Testing**
  - [ ] Test with modded skills to validate auto-detection works

---

## Phase 5: Testing for Initial Release 🧪 NEXT
**Goal**: Quality assurance before first public release

### Testing Checklist
- [x] Fresh spawn → initialization
- [x] Death/respawn cycle
- [x] Save/load game
- [ ] Long session stability (8+ hour sessions)
- [ ] Performance with many visual markers
- [x] All three challenge types
- [ ] Purge challenge variants (once implemented)
- [ ] Zero to Hero with modded skills
- [ ] Chunk progression to 50+ chunks
- [ ] Memory usage monitoring
- [ ] Save file size with large chunk counts
- [ ] Edge cases (stuck situations, boundary issues)
- [ ] HUD functionality (drag, resize, collapse, keybind)
- [ ] Visual markers (persistence, color accuracy, performance)

---

## Phase 6: Wrapping for Initial Release 📦 UPCOMING
**Goal**: Polish and prepare for Steam Workshop

### Tasks
- [ ] Find/create mod icon (preview.png)
- [ ] Move challenge selection from Sandbox to dedicated Challenge Menu
- [ ] Create tutorial/onboarding system
  - [ ] First-time player guidance
  - [ ] Challenge explanation tooltips
  - [ ] Controls reminder
- [ ] Write comprehensive README
- [ ] Create Steam Workshop description
- [ ] Add license information
- [ ] Final code cleanup pass

---

## Phase 7: Initial Release 🚀 GOAL
**Target:** First public release on Steam Workshop

### Release Checklist
- [ ] All Phase 5 testing complete
- [ ] All Phase 6 tasks complete
- [ ] Version number finalized (v1.0.0)
- [ ] Workshop listing prepared
- [ ] Upload to Steam Workshop
- [ ] Monitor initial feedback
- [ ] Address critical bugs quickly

---

## Phase 8: New Challenge Types 🎮 POST-RELEASE
**Goal**: Add Resource and Kitchen Sink challenges

### Resource Challenge
**Concept**: Turn in specific resources to gain points for unlock

**Implementation Ideas:**
- Trash can placed near spawn (empty tile check)
- Destroy items in trash can to count them
- Point system: different items = different values
- Track cumulative points per chunk
- Foundation for PZ Tycoon mode

**Technical Considerations:**
- Item tracking (OnObjectAdded/OnObjectRemoved events)
- Trash can spawning logic (find empty tile)
- Point value configuration (Sandbox options)
- Visual feedback (item count, point progress)

### Kitchen Sink Challenge
**Concept**: Complete ALL requirements to unlock chunk

**Requirements:**
- Kill X zombies AND
- Spend X hours AND  
- Level up X skills AND
- Collect X resource points

**Special Rule**: When all skills are maxed (level 10), skill requirement disappears

**Technical Considerations:**
- Multi-condition tracking
- Progressive difficulty (requirements scale with chunks unlocked)
- UI showing all progress bars
- Configuration options for each requirement type

### Testing
- [ ] Resource challenge basic functionality
- [ ] Trash can spawning (empty tile detection)
- [ ] Point system accuracy
- [ ] Kitchen Sink multi-condition tracking
- [ ] Kitchen Sink UI (multiple progress bars)
- [ ] Save/load with new challenge types

---

## Phase 9: Release New Challenges 🚀
**Target:** v2.0.0 - Feature expansion release

### Release Checklist
- [ ] Resource Challenge tested and stable
- [ ] Kitchen Sink Challenge tested and stable
- [ ] Updated documentation
- [ ] Steam Workshop update
- [ ] Changelog published

---

## Phase 10: PZ Tycoon Version 1 💰
**Goal**: Money-based chunk unlocking system

### Core Concept
Buy chunks with in-game money instead of completing challenges.

### Features
**Pricing System:**
- Chunk price = zombie population × multiplier
- Base price: ~$16 per zombie (1993 Kentucky land values)
- Scaling: Higher population = higher price
- Example: 100 zombies in chunk = $1,600 to unlock

**Economy Integration:**
- Use vanilla trading system values
- Item selling for money
- Price fluctuations (optional)
- Bulk purchase discounts (unlock multiple chunks)

**Configuration:**
- Price multiplier (Sandbox option)
- Base price per zombie
- Enable/disable price scaling
- Discount thresholds

### Technical Considerations
- Money tracking (player:getMoney())
- Transaction system (deduct money, unlock chunk)
- Price calculation based on zombie count
- UI showing chunk prices before purchase
- "Shop" menu for chunk purchases

### Testing
- [ ] Money deduction works correctly
- [ ] Chunk prices calculated accurately
- [ ] Price scaling functions properly
- [ ] Save/load preserves purchases
- [ ] Economy balance testing

---

## Phase 11: PZ Tycoon Version 2 🏪 (LONG SHOT)
**Goal**: NPC vendor system for chunk unlocking

**Note:** Will likely work on **Nutrition Tweak** mod before this phase.

### Core Concept
Vendor NPCs that need to be fed and protected to buy chunk unlocks.

### Features
**NPC Vendors:**
- Spawn at designated location
- Require food to stay alive
- Can be killed (challenge fails if all die)
- Sell chunk unlocks for money

**NPC Behavior:**
- Hunger system (must be fed regularly)
- Health system (can be attacked by zombies)
- Death handling (respawn after milestone?)
- Trading interface (buy chunks)

**Milestone System:**
- Respawn vendor after X chunks unlocked
- Multiple vendors possible
- Vendor upgrades (better prices, bulk deals)

### Technical Considerations
- Use NPCs from existing mods as reference:
  - Bandits mod
  - Day One mod
  - Week One mod
- NPC AI integration
- Food consumption mechanics
- Death/respawn logic
- Trading UI adaptation

### Challenges
- High complexity (NPC AI)
- Balance issues (keeping NPCs alive)
- Multiplayer implications
- Performance with multiple NPCs

---

## Phase 12: Multiplayer Support (IF READY) 👥
**Goal**: Full multiplayer compatibility

**Note:** May only implement for all challenges MINUS PZ Tycoon variants

### Requirements
- [ ] Server-side state synchronization
- [ ] Per-player challenge tracking (already character-specific!)
- [ ] Shared vs separate chunk unlocking decision
- [ ] Multiplayer testing
- [ ] Admin commands
- [ ] Server configuration options

### Testing Needed
- [ ] 2-player testing
- [ ] 4+ player testing
- [ ] Server restart recovery
- [ ] Player join/leave handling
- [ ] Chunk state sync accuracy
- [ ] Performance with multiple active challenges

### Implementation Approach
**Option A: Shared Chunks**
- All players work together on same chunks
- Kills/time/resources pool together
- Faster progression, cooperative gameplay

**Option B: Separate Chunks**
- Each player has own chunk progression
- Independent challenges
- Slower progression, individual gameplay

**Option C: Hybrid**
- Sandbox option to choose mode
- Server admin decides

---

## Spawner System (Ongoing Improvements) 🧟
**Goal**: Intelligent zombie spawning with minimal frustration

### Completed ✅
- [x] Basic zombie spawner (spawns outside chunk)
- [x] Sound wave system (attracts zombies)
- [x] Stuck detection (non-approaching waves counter)
- [x] Backup spawn when zombie stuck (10 waves)
- [x] Directional spawn tracking (prevents repeated stuck directions)
- [x] Attack detection (zombie attacking structure vs approaching player)
- [x] Spawn delay system (30-min cooldown after chunk entry)
- [x] HUD debug info (closest zombie, spawn stats, stuck tracking)

### Planned Improvements 🎯
- [ ] **Dynamic Spawn Distance** (NEW - HIGH PRIORITY)
  - [ ] Start spawning zombies FAR from chunk (e.g., 100+ tiles)
  - [ ] Only move spawn point CLOSER if zombie gets stuck
  - [ ] Gradually reduce distance on each stuck spawn (100 → 90 → 80 → ...)
  - [ ] Minimum distance threshold (never closer than 30 tiles)
  - [ ] Reset to far distance when entering new chunk
  - [ ] Benefits: Makes early chunks feel safer, only spawns close when needed
- [ ] Improved pathfinding check before spawn
- [ ] Structure destruction tracking (health monitoring)
- [ ] Functionally indestructible structure detection (1 hour no damage)
- [ ] Smart spawn location selection (avoid known stuck spots)

---

## Technical Debt & Known Issues

### High Priority 🔴
- [ ] Remove reward system code (currently has errors)
- [ ] Implement dynamic spawn distance system

### Medium Priority 🟡
- [ ] Further OnTick optimization (reduce check frequency where possible)
- [ ] Marker count optimization for large chunk counts
- [ ] Save file size monitoring (test with 50+ chunks)
- [ ] Long session testing (8+ hours)

### Low Priority 🟢
- [ ] Code style consistency pass
- [ ] Additional inline documentation
- [ ] Function naming review

### Build 42 Compatibility ✅
- [x] Replaced deprecated `getPerks()` with XP system
- [x] Tested teleportation method (Build 42 pattern)
- [x] Verified all API calls work in Build 42

---

## Performance Metrics

### Current Status ✅
- OnTick handlers: 3 active (boundary check, time tracking, skill tracking)
- Marker count: ~200-400 per character (depends on unlocked chunks)
- Memory usage: Unknown (needs testing)
- Save file size: Unknown (needs testing)

### Targets
- OnTick handlers: < 5 active simultaneously
- Marker count: < 500 visible at once
- Memory usage: < 100MB for mod
- Save file size: < 200KB per player (50+ chunks)

---

## Version History

### v0.3.2.026 (Current) - 2025-10-29
- HUD position moved to (75, 0)
- Roadmap restructured for initial release
- Removed reward system (temporary)

### v0.3.2.025 - 2025-10-29
- Blue chunk expansion (beside ALL green chunks)
- Prevents stuck situations in chunk mode
- All three challenge types tested and working

### v0.3.2.024 - 2025-10-29
- Zero to Hero challenge fully implemented
- Settlement timer system
- Ready-to-unlock flag system
- Skill tracking with Build 42 XP system
- Unlock banking system

### v0.3.2.002 - 2025-10-XX
- Chunk progression system implemented
- Time challenge implemented
- Chunk mode functional

### v0.1-alpha
- Initial prototype
- Single chunk system
- Basic kill tracking (Purge only)
- Boundary enforcement
- Visual feedback

---

## Planned Release Schedule

- **v0.4.0** (Phase 4 complete): Purge variants + ZtH testing → ~1-2 weeks
- **v1.0.0** (Phases 5-7 complete): Initial public release → ~2-4 weeks
- **v2.0.0** (Phases 8-9 complete): Resource + Kitchen Sink challenges → ~2-3 months
- **v3.0.0** (Phase 10 complete): PZ Tycoon v1 → ~4-6 months
- **v4.0.0** (Phase 12 complete): Multiplayer support → TBD

---

## Development Notes

### Architecture Decisions
- **Character-specific data**: Prevents conflicts in multiplayer, allows per-player progression
- **ModData persistence**: Reliable save system, automatic with player saves
- **Named event handlers**: Allows proper removal, prevents memory leaks
- **Flag-based unlock system** (ZtH): Single source of truth, prevents timer bypasses
- **Chunk scanning** (blue expansion): Prevents stuck situations, scales well

### Lessons Learned
- Build 42 API changes require XP system instead of getPerks()
- Teleportation needs setLastX/Y/Z for stability
- Visual markers need character-specific storage for multiplayer
- Timer-based checks should use counters to reduce OnTick load
- Chunk mode requires careful boundary calculation for non-square layouts
- Reward system adds complexity without improving core gameplay loop

### Future Considerations
- Chunk size flexibility (currently hardcoded to boundarySize)
- Diagonal chunk unlocking (currently cardinal only)
- Chunk difficulty scaling formula
- Save file compression for large chunk counts
- Integration with base game progression systems
- Challenge menu UI (better than Sandbox for selection)
