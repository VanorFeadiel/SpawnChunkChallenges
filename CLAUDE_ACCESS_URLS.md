# Claude Access URLs - SpawnChunkChallenges

This file contains direct GitHub URLs to all files in the SpawnChunkChallenges repository for Claude to access.

## Repository Information
- **Repository**: https://github.com/VanorFeadiel/SpawnChunkChallenges
- **Main Branch**: main
- **Description**: Project Zomboid mod that traps players in chunks area until they accomplish certain conditions to leave their chunk based on the selected challenges and options.

## File URLs for Claude Access

### Core Mod Files (Workshop Structure)

**Root Level (Steam Workshop):**
- **mod.info**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/mod.info
- **icon.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/icon.png
- **poster.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/poster.png
- **workshop.txt**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/workshop.txt

**Mod Level (PZ Recognition):**
- **mod.info**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/mod.info
- **icon.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/icon.png
- **poster.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/poster.png

**Build 42 Level (Build-specific):**
- **mod.info**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/mod.info
- **icon.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/icon.png
- **poster.png**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/poster.png
- **README.md**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/README.md
### Sandbox Configuration
- **Sandbox Options**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/sandbox-options.txt
- **English Translation**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/shared/Translate/EN/Sandbox_EN.txt

### Documentation
- **Development Roadmap**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/DEVELOPMENT_ROADMAP.md
- **Template for Cursor**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/CURSOR_CHAT_TEMPLATE.md
### LUA Scripts (Client-side) - RAW URLs FOR CLAUDE

**Use these RAW URLs (Claude can access these):**
- **SpawnChunk_Boundary.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Boundary.lua
- **SpawnChunk_Data.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Data.lua
- **SpawnChunk_Init.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Init.lua
- **SpawnChunk_Kills.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Kills.lua
- **SpawnChunk_Visual.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/client/SpawnChunk_Visual.lua
- **SpawnChunk_Spawner.lua**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/contents/mods/SpawnChunkChallenges/42.0/media/lua/shared/SpawnChunk_Spawner.lua

### Development Automation Scripts
- **quick-update.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/quick-update.sh
- **batch-update.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/batch-update.sh
- **new-file.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/new-file.sh
- **get-claude-urls.sh**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/get-claude-urls.sh
- **review-template.txt**: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/review-template.txt

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
2025-10-19
2025-10-19