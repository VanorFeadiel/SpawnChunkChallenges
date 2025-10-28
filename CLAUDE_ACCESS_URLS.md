# Claude Access URLs - SpawnChunkChallenges

This file contains direct GitHub URLs to all files in the SpawnChunkChallenges repository for Claude to access.

## Repository Information
- **Repository**: https://github.com/VanorFeadiel/SpawnChunkChallenges
- **Main Branch**: main
- **Description**: Project Zomboid mod that traps players in chunks area until they accomplish certain conditions to leave their chunk based on the selected challenges and options.

## File URLs for Claude Access

### Core Mod Files (Workshop Structure)

**Root Level (Steam Workshop):**
- **mod.info**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/mod.info?v=20251028
- **icon.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/icon.png?v=20251028
- **poster.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/poster.png?v=20251028
- **workshop.txt**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/workshop.txt?v=20251028

**Mod Level (PZ Recognition):**
- **mod.info**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/mod.info?v=20251028
- **icon.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/icon.png?v=20251028
- **poster.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/poster.png?v=20251028

**Build 42 Level (Build-specific):**
- **mod.info**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/mod.info?v=20251028
- **icon.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/icon.png?v=20251028
- **poster.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/poster.png?v=20251028
- **README.md**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/README.md?v=20251028
### Sandbox Configuration
- **Sandbox Options**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/sandbox-options.txt?v=20251028
- **English Translation**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/shared/Translate/EN/Sandbox_EN.txt?v=20251028

### Documentation
- **Challenge System Summary**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/CHALLENGE_SYSTEM_SUMMARY.md?v=20251028
- **Development Roadmap**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/DEVELOPMENT_ROADMAP.md?v=20251028
- **Template for Cursor**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/CURSOR_CHAT_TEMPLATE.md?v=20251028
### LUA Scripts (Client-side) - RAW URLs FOR CLAUDE

**Use these RAW URLs (Claude can access these):**
- **SpawnChunk_Boundary.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Boundary.lua?v=20251028
- **SpawnChunk_Challenges.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Challenges.lua?v=20251028 (NEW - Challenge system)
- **SpawnChunk_ChunkEntry.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_ChunkEntry.lua?v=20251028
- **SpawnChunk_Data.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Data.lua?v=20251028
- **SpawnChunk_Init.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Init.lua?v=20251028
- **SpawnChunk_Kills.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Kills.lua?v=20251028
- **SpawnChunk_Spawner.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Spawner.lua?v=20251028
- **SpawnChunk_Visual.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Visual.lua?v=20251028

### Development Automation Scripts
- **quick-update.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/quick-update.sh?v=20251028
- **batch-update.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/batch-update.sh?v=20251028
- **new-file.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/new-file.sh?v=20251028
- **get-claude-urls.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/get-claude-urls.sh?v=20251028
- **review-template.txt**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/review-template.txt?v=20251028

## Usage Instructions for Claude

**IMPORTANT**: Claude needs to use the RAW URLs (raw.githubusercontent.com) - NOT the blob URLs (github.com/blob). 

The RAW URLs above will give Claude direct access to the file content for analysis and planning.

## Mod Structure Overview

```
ProjectZomboidMod/                           # Git repo root / Workshop folder
├── mod.info                                 # For Steam Workshop
├── icon.png                                 # For Steam Workshop  
├── poster.png                               # For Steam Workshop
├── workshop.txt                             # Steam Workshop metadata (auto-generated)
├── contents/
│   └── mods/
│       └── SpawnChunkChallenges/
│           ├── mod.info                     # For PZ to load mod
│           ├── icon.png                     # For PZ to load mod
│           ├── poster.png                   # For PZ to load mod
│           └── 42.0/                        # Build 42 version folder
│               ├── mod.info                 # For Build 42 recognition
│               ├── icon.png                 # For Build 42 recognition
│               ├── poster.png               # For Build 42 recognition
│               ├── README.md                # Documentation
│               └── media/
│                   └── lua/
│                       ├── client/          # Client-side LUA scripts
│                       │   ├── SpawnChunk_Boundary.lua
│                       │   ├── SpawnChunk_Data.lua
│                       │   ├── SpawnChunk_Init.lua
│                       │   ├── SpawnChunk_Kills.lua
│                       │   ├── SpawnChunk_Spawner.lua
│                       │   └── SpawnChunk_Visual.lua
│                       ├── server/          # Server-side LUA scripts
│                       ├── shared/          # Shared LUA scripts and components
│                       │   └── Translate/
│                       │       └──EN/
│                       │          └──Sandbox_EN.txt #Contains text describing sandbox option
│                       └── common/          # Common scripts (required, even if empty)
│                       └── sandbox-options  # Code for Sandbox options
├── DEVELOPMENT_ROADMAP.md                   # Development plan
├── CLAUDE_ACCESS_URLS.md                    # This file
└── Development Scripts/                     # Automation scripts (root level)
    ├── quick-update.sh
    ├── batch-update.sh
    ├── new-file.sh
    ├── get-claude-urls.sh
    └── review-template.txt
```

**Note:** The mod.info, icon.png, and poster.png files must be present at THREE levels:
1. **Root** - Required by Steam Workshop uploader
2. **SpawnChunkChallenges/** - Required by Project Zomboid to recognize the mod
3. **42.0/** - Required by Build 42 to display mod correctly in mod list

## Current Mod Features

- **Boundary Enforcement**: Players are teleported back to spawn if they try to leave the 50x50 tile area
- **Dynamic Kill Target**: Kill requirement based on local zombie population (minimum 10)
- **Visual Feedback**: Ground markers, map symbols, and HUD display
- **Progress Tracking**: Real-time kill counter and boundary distance warnings
- **Rewards**: Items awarded upon completion of the challenge
- **Persistence**: Progress saves across game sessions

## Future Development Plans

This mod is designed with an additive approach where only one chunk is unlocked at a time. Players progressively unlock chunks based on completing different types of challenges, creating a structured progression system.

## Development Scripts

The repository includes automation scripts to streamline the development workflow:

- **quick-update.sh** - Quickly commit and push a single file change
  - Usage: `./quick-update.sh <filename> "commit message"`
  
- **batch-update.sh** - Commit and push multiple files at once
  - Usage: `./batch-update.sh "commit message" file1 file2 file3...`
  
- **new-file.sh** - Create a new mod file with boilerplate and add to Git
  - Usage: `./new-file.sh <filepath> "Description"`
  
- **get-claude-urls.sh** - Generate GitHub raw URLs for Claude to fetch
  - Usage: `./get-claude-urls.sh [file1] [file2]...`
  
- **review-template.txt** - Template messages for requesting code reviews from Claude

## Last Updated
2025-01-15 (Current: v0.3.2.002 - Challenge System Implementation)

## Current Development Status

### ✅ Completed Features
- **Purge Challenge** (Kill zombies to unlock chunks) - Fully functional
- HUD toggle hotkey (comma ',' key)
- Character-specific data and visual isolation
- Boundary enforcement with visual markers
- Additive chunk mode with progression system
- Debug mode with comprehensive stats

### 🔄 In Progress - Challenge System (v0.3.2)
**Goal**: Add Time Challenge and Zero to Hero Challenge alongside existing Purge Challenge

**Current Status**:
- ✅ Data structure created for Time and Zero to Hero challenges
- ✅ Sandbox options added for challenge type selection
- ✅ Challenge tracking functions created in `SpawnChunk_Challenges.lua`
- ⏳ Implementation in progress (Time Challenge first)

### 🎯 Challenge System Overview

#### 1. Purge Challenge (Current/Default)
- **Objective**: Kill zombies to unlock chunks
- **Mechanic**: Classic zombie kill counting per chunk
- **Target**: Based on zombie population in area

#### 2. Time Challenge (Next to Implement)
- **Objective**: Survive for X in-game hours to unlock chunks
- **Settings**:
  - Duration: 1-720 in-game hours (default: 12)
  - Option: Count time in ANY unlocked chunk OR only in NEW chunk
- **Implementation Tasks**:
  - Initialize challenge type from sandbox
  - Call `updateTimeProgress()` on game ticks
  - Track completion and unlock logic
  - Update HUD to show time progress

#### 3. Zero to Hero Challenge (After Time)
- **Objective**: Level up skills to unlock chunks
- **Skills Required**: Aiming, Fitness, Strength, Sprinting, Lightfoot, Sneak
- **Mechanic**: 
  - Each skill level up banks one chunk unlock
  - Multiple skill ups before entering new chunk = multiple unlocks stored
  - All 6 skills at level 10 = free exploration (boundaries removed)
- **Implementation Tasks**:
  - Call `updateSkillProgress()` on game ticks
  - Track skill level ups
  - Handle pending unlocks queue
  - Process skill unlocks when entering new chunk

### 📋 Files Modified/Added in Current Session

**New Files**:
- `contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Challenges.lua` - Challenge tracking system

**Modified Files**:
- `contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Data.lua` - Added challenge type data structures
- `contents/mods/SpawnChunkChallenges/42.0/media/sandbox-options.txt` - Added ChallengeType, TimeChallengeDuration, TimeInAnyChunk
- `contents/mods/SpawnChunkChallenges/42.0/media/lua/shared/Translate/EN/Sandbox_EN.txt` - Added translations
- `contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Visual.lua` - HUD toggle hotkey (comma key, code 51)
- `contents/mods/SpawnChunkChallenges/42.0/mod.info` - Updated version to 0.3.2.002

**Next Files to Update**:
- `SpawnChunk_Init.lua` - Set challengeType from sandbox options on initialization
- `SpawnChunk_Visual.lua` - Add event handlers to call time/skill update functions and show challenge-specific HUD
- `SpawnChunk_Challenges.lua` - Add event registration for OnTick handlers
- `SpawnChunk_ChunkEntry.lua` - Handle Time and ZeroToHero completion logic

### 🎮 Testing Approach
1. **Test Time Challenge** first with sandbox options
2. Verify: Time tracking works, chunk unlocks after duration
3. Test both "time in any chunk" true/false modes
4. Move to Zero to Hero if Time works
5. Later: Convert to Challenge menu entries (better UX)

### 📁 Updated File URLs for Claude
- **Testing Handoff**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/TESTING_HANDOFF_v0.3.2.md?v=20251028
- **Challenge System Summary**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/CHALLENGE_SYSTEM_SUMMARY.md?v=20251028
- **SpawnChunk_Challenges.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Challenges.lua?v=20251028