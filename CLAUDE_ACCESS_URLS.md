# Claude Access URLs - SpawnChunkChallenges

This file contains direct GitHub URLs to all files in the SpawnChunkChallenges repository for Claude to access.

## Repository Information
- **Repository**: https://github.com/VanorFeadiel/SpawnChunkChallenges
- **Main Branch**: main
- **Description**: Project Zomboid mod that traps players in chunks area until they accomplish certain conditions to leave their chunk based on the selected challenges and options.

## File URLs for Claude Access

### Core Mod Files
- **mod.info**: https://github.com/VanorFeadiel/SpawnChunkChallenges/blob/main/mod.info
- **icon.png**: https://github.com/VanorFeadiel/SpawnChunkChallenges/blob/main/icon.png
- **preview.png**: https://github.com/VanorFeadiel/SpawnChunkChallenges/blob/main/preview.png
- **README.md**: https://github.com/VanorFeadiel/SpawnChunkChallenges/blob/main/README.md

### Documentation
- **Development Guide**: https://github.com/VanorFeadiel/SpawnChunkChallenges/blob/main/docs/DEVELOPMENT.md

### LUA Scripts (Client-side) - RAW URLs FOR CLAUDE

**Use these RAW URLs (Claude can access these):**
- **SpawnChunk_Boundary.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/media/lua/client/SpawnChunk_Boundary.lua
- **SpawnChunk_Data.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/media/lua/client/SpawnChunk_Data.lua
- **SpawnChunk_Init.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/media/lua/client/SpawnChunk_Init.lua
- **SpawnChunk_Kills.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/media/lua/client/SpawnChunk_Kills.lua
- **SpawnChunk_Visual.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/media/lua/client/SpawnChunk_Visual.lua

## Usage Instructions for Claude

**IMPORTANT**: Claude needs to use the RAW URLs (raw.githubusercontent.com) - NOT the blob URLs (github.com/blob). 

The RAW URLs above will give Claude direct access to the file content for analysis and planning.

## Mod Structure Overview

```
SpawnChunkChallenges/
├── mod.info                    # Mod metadata
├── icon.png                    # Workshop icon
├── preview.png                 # Workshop preview image
├── README.md                   # Main documentation
├── docs/
│   └── DEVELOPMENT.md          # Development guide
└── media/
    └── lua/
        └── client/             # Client-side LUA scripts
            ├── SpawnChunk_Boundary.lua    # Boundary enforcement
            ├── SpawnChunk_Data.lua        # Data management
            ├── SpawnChunk_Init.lua        # Initialization
            ├── SpawnChunk_Kills.lua       # Kill tracking
            └── SpawnChunk_Visual.lua      # Visual feedback & UI
```

## Current Mod Features

- **Boundary Enforcement**: Players are teleported back to spawn if they try to leave the 50x50 tile area
- **Dynamic Kill Target**: Kill requirement based on local zombie population (minimum 10)
- **Visual Feedback**: Ground markers, map symbols, and HUD display
- **Progress Tracking**: Real-time kill counter and boundary distance warnings
- **Rewards**: Items awarded upon completion of the challenge
- **Persistence**: Progress saves across game sessions

## Future Development Plans

This mod is designed with an additive approach where only one chunk is unlocked at a time. Players progressively unlock chunks based on completing different types of challenges, creating a structured progression system.

## Last Updated
2025-10-18
