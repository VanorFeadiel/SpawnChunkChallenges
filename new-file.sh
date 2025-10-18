#!/bin/bash
# FILENAME: new-file.sh
# Create new mod file and add to Git/CLAUDE_ACCESS_URLS.md
# Usage: ./new-file.sh <filepath> "Description"

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Error: No filepath provided${NC}"
    echo "Usage: ./new-file.sh <filepath> \"Description\""
    echo "Example: ./new-file.sh media/lua/client/SpawnChunk_Economy.lua \"Economy system\""
    exit 1
fi

FILEPATH=$1
DESCRIPTION=${2:-"New file"}
FILENAME=$(basename "$FILEPATH")

# Create file if it doesn't exist
if [ -f "$FILEPATH" ]; then
    echo -e "${RED}Error: File $FILEPATH already exists${NC}"
    exit 1
fi

# Create directories if needed
mkdir -p "$(dirname "$FILEPATH")"

# Create file with basic header
cat > "$FILEPATH" << EOF
-- $FILENAME
-- SpawnChunk Challenges Mod
-- $DESCRIPTION

-- Namespace
SpawnChunk = SpawnChunk or {}

-- TODO: Implement functionality

print("[SpawnChunk] $FILENAME loaded")
EOF

echo -e "${GREEN}✅ Created $FILEPATH${NC}"

# Add to CLAUDE_ACCESS_URLS.md
RAW_URL="https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/$FILEPATH"
echo "- **$FILENAME**: $RAW_URL" >> CLAUDE_ACCESS_URLS.md

echo -e "${GREEN}✅ Added to CLAUDE_ACCESS_URLS.md${NC}"

# Git operations
git add "$FILEPATH" CLAUDE_ACCESS_URLS.md
git commit -m "Add new file: $FILENAME - $DESCRIPTION"
git push origin main

echo -e "${BLUE}🔗 Raw URL:${NC}"
echo "$RAW_URL"

echo -e "${GREEN}✅ File ready for development!${NC}"