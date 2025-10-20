# AI Development Workflow Guide

## Overview

This project uses a **three-tier AI development workflow** to maximize efficiency while managing Claude's weekly usage limits.

---

## Tool Hierarchy

### 1. GitHub CoPilot (Primary - Cursor IDE) 💻
**Use for**: Day-to-day coding, basic implementations

**Strengths:**
- Unlimited usage (no weekly limits)
- Fast code generation
- Context-aware suggestions
- Line-by-line assistance
- Can fetch/analyze GitHub files

**Best For:**
- Implementing planned features
- Routine bug fixes
- Code completion and refactoring
- Following established patterns

**Limitations:**
- Limited architectural planning
- Struggles with complex debugging
- No project-wide analysis

---

### 2. Claude (Planning & Debugging) 🧠
**Use for**: Architecture, planning, complex debugging

**Strengths:**
- Project-wide analysis via GitHub URLs
- Excellent at architectural decisions
- Can fetch and analyze multiple files
- Superior debugging of complex issues
- Creates comprehensive documentation

**Best For:**
- Project planning and roadmaps
- Reviewing CoPilot-generated code
- Debugging walls that CoPilot can't solve
- File structure decisions
- Integration between multiple files

**Limitations:**
- Weekly message limit (Pro tier)
- Cannot directly commit code
- Slower than CoPilot for simple tasks

---

### 3. Cursor AI (Last Resort) 🚨
**Use for**: When both CoPilot and Claude are stuck

**Strengths:**
- Multiple AI models combined
- Deep codebase integration
- Can handle very complex scenarios

**Best For:**
- Extremely complex bugs
- When Claude and CoPilot disagree
- Critical production issues

**Limitations:**
- Slowest of the three
- Can be overkill for simple issues

---

## Recommended Workflow

```
┌─────────────────────────────────────────────┐
│ 1. PLANNING (Claude)                        │
│    - Architecture decisions                 │
│    - Feature breakdown                      │
│    - File structure                         │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ 2. IMPLEMENTATION (CoPilot)                 │
│    - Write code based on plan              │
│    - Follow established patterns           │
│    - Basic testing                         │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│ 3. TESTING (You)                            │
│    - Run in-game                           │
│    - Check console for errors             │
│    - Verify functionality                  │
└─────────────────┬───────────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
    ✅ Works           ❌ Issues
        │                   │
        │                   ▼
        │     ┌─────────────────────────────────┐
        │     │ 4a. SIMPLE FIX? (CoPilot)       │
        │     │    - Syntax errors              │
        │     │    - Missing nil checks         │
        │     │    - Typos                      │
        │     └─────────────┬───────────────────┘
        │                   │
        │                   ▼
        │     ┌─────────────────────────────────┐
        │     │ 4b. STUCK? (Claude)             │
        │     │    - Logic errors               │
        │     │    - Integration issues         │
        │     │    - Complex debugging          │
        │     └─────────────┬───────────────────┘
        │                   │
        │                   ▼
        │     ┌─────────────────────────────────┐
        │     │ 4c. STILL STUCK? (Cursor AI)    │
        │     │    - Very complex bugs          │
        │     │    - Multi-file issues          │
        │     └─────────────────────────────────┘
        │
        ▼
   COMPLETE
```

---

## When to Use Each Tool

### Use CoPilot When:
✅ Implementing a well-defined feature  
✅ Following existing code patterns  
✅ Writing boilerplate code  
✅ Adding similar functionality to existing code  
✅ Making small, localized changes  

### Use Claude When:
✅ Planning a new phase of development  
✅ Reviewing code structure  
✅ Debugging errors you can't solve with CoPilot  
✅ Need to analyze multiple files at once  
✅ Making architectural decisions  
✅ Creating documentation  
✅ Understanding PZ API behavior  

### Use Cursor AI When:
✅ Both CoPilot and Claude couldn't solve it  
✅ The bug involves complex interactions  
✅ You've been stuck for 30+ minutes  
✅ Need multiple AI perspectives  

---

## Returning to Claude After CoPilot Work

### Required Information:

1. **File Index URL** (with cache-bust)
```
File index: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/refs/heads/main/CLAUDE_ACCESS_URLS.md?cache-bust=YYYYMMDD
```

2. **What You Implemented**
```
CoPilot Changes:
- SpawnChunk_Visual.lua: Added marker cleanup on victory
- SpawnChunk_Kills.lua: Fixed kill counter not incrementing
- SpawnChunk_Boundary.lua: Optimized boundary check frequency
```

3. **Current Status**
```
Status: [working / has issues / need review]
```

4. **What You Need**
```
Next: Review the boundary optimization - performance concerns
OR
Next: Debug why markers don't appear after respawn
OR
Next: Plan Phase 2.1 Sandbox options implementation
```

### Full Template:

```
Working on [feature/phase].

File index: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/refs/heads/main/CLAUDE_ACCESS_URLS.md?cache-bust=YYYYMMDD

CoPilot Implementation:
- [file1]: [what changed]
- [file2]: [what changed]

Testing Results:
- ✅ [what works]
- ❌ [what doesn't work]
- ⚠️ [concerns/questions]

Console Errors (if any):
[paste error]

Status: [working / broken / need review]
Next: [what you want Claude to do]
```

---

## Best Practices

### Maximize CoPilot Usage
- Break down Claude's plans into small tasks
- Implement one function at a time
- Use CoPilot for all routine coding
- Test frequently in small increments

### Preserve Claude Usage
- Don't ask Claude for simple code generation
- Batch questions when possible
- Come prepared with specific issues
- Use Claude's artifacts for reference

### Efficient Handoffs
- Always commit CoPilot changes before asking Claude
- Push to GitHub so Claude can fetch latest
- Use cache-bust parameter to force fresh fetch
- Be specific about what you need help with

---

## Git Workflow Integration

### After CoPilot Changes:

1. **Test in-game** first
2. **If working:** Commit and push
   ```bash
   git add [files]
   git commit -m "Implemented [feature] via CoPilot"
   git push
   ```
3. **If broken:** Debug with CoPilot first, then Claude if stuck
4. **Before Claude session:** Ensure all changes are pushed

### Cache-Busting:
Always add date to force GitHub CDN refresh:
```
?cache-bust=20251020
?cache-bust=20251020v2  (if fetching multiple times same day)
```

---

## Troubleshooting

### CoPilot Not Understanding Context?
→ Add comments explaining what you need:
```lua
-- COPILOT: Create a function that removes only our mod's map symbols
-- It should loop through SpawnChunk.mapLineSymbols and remove each one
-- Make sure to preserve player-added symbols
```

### Claude Can't Access Files?
→ Check URL format:
- ✅ `raw.githubusercontent.com/...`
- ❌ `github.com/blob/...`

### Cursor AI Suggested Code Conflicts?
→ Review with Claude to determine best approach

---

## Example Session

### Day 1: Planning (Claude)
```
"Plan Phase 2.1: Sandbox options implementation.
What options should we add?
How should they be structured?
Which files need changes?"
```
→ Claude provides architecture plan

### Day 2-3: Implementation (CoPilot)
- Use Claude's plan as blueprint
- Implement with CoPilot assistance
- Test each option as you add it

### Day 4: Review (Claude)
```
"Implemented Sandbox options via CoPilot.

File index: [URL with cache-bust]

Changes:
- mod.info: Added SandboxVars
- SpawnChunk_Init.lua: Read options on init
- SpawnChunk_Visual.lua: Respect enable/disable option

Status: Working but need review for edge cases
Next: Review option interaction logic"
```
→ Claude reviews and suggests improvements

### Day 5: Final Polish (CoPilot)
- Implement Claude's suggestions
- Final testing
- Ship it! 🚀

---

## Weekly Usage Strategy

**Goal**: Make Claude usage last all week

**Monday-Thursday**: Heavy CoPilot usage (planning → implement → test)  
**Friday**: Claude review session (batch all questions)  
**Weekend**: Polish with CoPilot

**Emergency Reserve**: Keep 20% Claude messages for critical bugs

---

## Roadmap Synchronization

### After Each Feature Completion:

1. Update DEVELOPMENT_ROADMAP.md checkboxes
2. Commit changes
3. On next Claude session, start with:
   ```
   "Update: Completed [feature] via CoPilot.
   Please verify roadmap alignment."
   ```

### Monthly Sync:
- Review roadmap with Claude
- Adjust priorities based on progress
- Update phase estimates

---

## Quick Reference Card

| Task | Tool | Why |
|------|------|-----|
| Plan new feature | Claude | Architecture |
| Write the code | CoPilot | Fast & unlimited |
| Simple bug fix | CoPilot | Quick iteration |
| Complex debugging | Claude | Deep analysis |
| Review code quality | Claude | Project-wide view |
| Impossible bug | Cursor AI | Multiple AI models |
| Update docs | CoPilot | Routine writing |
| Roadmap planning | Claude | Strategic thinking |

---

**Remember**: Claude is your architect and senior developer. CoPilot is your coding assistant. Use each for what they do best!

**Last Updated**: 2025-10-20