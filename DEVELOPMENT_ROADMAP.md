# SpawnChunk Challenges - Development Roadmap

## Phase 1: Foundation (Current)
**Goal**: Stable single-chunk challenge system

### Completed ✅
- [x] Basic ModData persistence
- [x] Player spawn initialization
- [x] Kill tracking system
- [x] Boundary enforcement
- [x] Victory condition
- [x] Reward system
- [x] Ground markers
- [x] Map symbols
- [x] HUD display

### In Progress 🔧
- [ ] Fix victory function override conflict
- [ ] Fix event handler removal patterns
- [ ] Add respawn handler
- [ ] Consolidate initialization timers

### Testing Needed 🧪
- [ ] Fresh spawn → kill tracking → victory
- [ ] Death/respawn cycle
- [ ] Save/load game
- [ ] Long session stability
- [ ] Visual elements persist correctly

---

## Phase 2: Configuration & Polish
**Goal**: Configurable, user-friendly experience

### Features
- [ ] Sandbox options menu
  - [ ] Kill multiplier setting
  - [ ] Boundary size options
  - [ ] Reward customization
  - [ ] Enable/disable visual elements
- [ ] In-game configuration UI
- [ ] Better tutorial/onboarding
- [ ] Improved visual feedback
- [ ] Sound effects
- [ ] Particle effects on victory

### Performance
- [ ] Optimize OnTick handlers
- [ ] Reduce marker count options
- [ ] Memory leak testing

---

## Phase 3: Chunk Progression System
**Goal**: Multi-chunk unlocking progression

### Core Mechanics
- [ ] Adjacent chunk detection
- [ ] Chunk unlocking algorithm
- [ ] Progressive kill targets per chunk
- [ ] Chunk boundary visualization
- [ ] Map overview showing locked/unlocked chunks

### Data Structure
- [ ] Track multiple chunks in ModData
- [ ] Current chunk pointer
- [ ] Chunk history/stats
- [ ] Total kills across all chunks

### UI Updates
- [ ] Show current chunk number
- [ ] Display total chunks unlocked
- [ ] Map legend for chunk status

---

## Phase 4: Challenge Varieties
**Goal**: Multiple challenge types for variety

### Challenge Types
- [ ] **Kill Challenge** (current) - Kill X zombies
- [ ] **Survival Challenge** - Survive X days in chunk
- [ ] **Resource Challenge** - Gather specific items
- [ ] **Base Challenge** - Build structures meeting requirements
- [ ] **Skill Challenge** - Reach skill levels
- [ ] **Combo Challenge** - Multiple requirements

### Implementation
- [ ] Challenge selection system
- [ ] Challenge-specific UI
- [ ] Challenge-specific rewards
- [ ] Random challenge generator
- [ ] Challenge difficulty scaling

---

## Phase 5: Multiplayer Support
**Goal**: Full multiplayer compatibility

### Requirements
- [ ] Server-side state synchronization
- [ ] Per-player challenge tracking
- [ ] Shared chunk unlocking (or separate?)
- [ ] Multiplayer testing
- [ ] Admin commands
- [ ] Server configuration options

### Testing
- [ ] 2-player testing
- [ ] 4+ player testing
- [ ] Server restart recovery
- [ ] Player join/leave handling

---

## Phase 6: Advanced Features
**Goal**: Deep, replayable systems

### Features
- [ ] Prestige system (reset with bonuses)
- [ ] Achievement system
- [ ] Leaderboards (local)
- [ ] Challenge streaks
- [ ] Special events (timed challenges)
- [ ] Boss zombies in chunks
- [ ] Chunk biomes/themes

### Meta-Progression
- [ ] Permanent unlock system
- [ ] Starting bonuses
- [ ] Difficulty tiers

---

## Future Mod: PZ Tycoon Mode
**Separate mod using same chunk system**

### Core Concept
Buy chunks with in-game money instead of killing zombies.

### Pricing System
- Chunk price = zombie population × multiplier
- Base price: ~$16 (1993 Kentucky land values)
- Scaling: Higher population = higher price

### Economy
- Trading system integration
- Item selling values
- Price fluctuations
- Bulk purchase discounts

---

## Technical Debt Tracking

### High Priority
- Victory function override (Visual.lua line 109)
- Event handler removal patterns
- Missing respawn handler

### Medium Priority
- Consolidate initialization timers
- ModData structure optimization
- Error handling improvements

### Low Priority
- Code style consistency
- Comment improvements
- Function naming conventions

---

## Performance Targets

- OnTick handlers: < 3 active simultaneously
- Marker count: < 200 visible at once
- Memory usage: < 50MB for mod
- Save file size: < 100KB per player

---

## Community Feedback

*Track user requests and issues here*

### Requested Features
- [ ] Configurable boundary shapes (circle, custom)
- [ ] Chunk themes/biomes
- [ ] Custom reward packs
- [ ] Integration with other mods

### Reported Issues
- [ ] None yet (unreleased)

---

## Version History

### v0.1-alpha (Current)
- Initial prototype
- Single chunk system
- Basic kill tracking
- Boundary enforcement
- Visual feedback

### Planned Versions
- v0.2-alpha: Bug fixes, Sandbox options
- v0.3-alpha: Chunk progression
- v0.4-beta: Challenge varieties
- v1.0-release: Stable, polished, tested
