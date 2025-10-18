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

### Development Automation Scripts
- **quick-update.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/quick-update.sh
- **batch-update.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/batch-update.sh
- **new-file.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/new-file.sh
- **get-claude-urls.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/get-claude-urls.sh
- **review-template.txt**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/review-template.txt

### Documentation
- **Development Guide**: https://github.com/VanorFeadiel/SpawnChunkChallenges/blob/main/docs/DEVELOPMENT.md
- **PZ API Cheat Sheet**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/PZ_API_CHEATSHEET.md
- **Development Roadmap**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/DEVELOPMENT_ROADMAP.md

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
2025-10-18
