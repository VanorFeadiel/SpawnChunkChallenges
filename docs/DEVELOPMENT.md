# Development Guide

## Project Structure
```
YourModName/
├── mod.info                    # Mod metadata
├── README.md                   # Main documentation
├── .git/                       # Git repository
├── media/
│   ├── lua/
│   │   ├── client/            # Client-side scripts
│   │   ├── server/            # Server-side scripts
│   │   └── shared/            # Shared scripts
│   └── textures/              # Image assets
├── scripts/                    # Additional scripts
└── docs/                      # Documentation and notes
```

## Git Workflow
1. **Always commit your changes frequently**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

2. **Push to remote regularly**
   ```bash
   git push origin main
   ```

3. **Create branches for features**
   ```bash
   git checkout -b feature/new-feature
   ```

## Best Practices
- Commit small, logical changes
- Write descriptive commit messages
- Test your mod before committing
- Keep documentation updated
- Use meaningful variable and function names

## Backup Strategy
- Git repository (primary)
- Cloud storage backup
- Local backup copies
