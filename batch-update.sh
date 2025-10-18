#!/bin/bash
# FILENAME: batch-update.sh
# Batch update script for multiple file changes
# Usage: ./batch-update.sh "commit message" file1 file2 file3...

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Insufficient arguments${NC}"
    echo "Usage: ./batch-update.sh \"commit message\" file1 [file2] [file3]..."
    echo "Example: ./batch-update.sh \"Phase 0 fixes\" media/lua/client/SpawnChunk_Kills.lua media/lua/client/SpawnChunk_Visual.lua"
    exit 1
fi

COMMIT_MSG=$1
shift  # Remove first argument, leaving only filenames

echo -e "${BLUE}📝 Batch updating ${#@} file(s)...${NC}"

# Add all specified files
ADDED_COUNT=0
for FILE in "$@"; do
    if [ ! -f "$FILE" ]; then
        echo -e "${RED}Warning: $FILE not found, skipping${NC}"
        continue
    fi
    echo -e "  Adding $FILE"
    git add "$FILE"
    ADDED_COUNT=$((ADDED_COUNT + 1))
done

if [ $ADDED_COUNT -eq 0 ]; then
    echo -e "${RED}Error: No valid files to commit${NC}"
    exit 1
fi

# Commit and push
git commit -m "$COMMIT_MSG"
git push origin main

echo -e "${GREEN}✅ Successfully pushed all files${NC}"
echo -e "${BLUE}📋 Updated files:${NC}"
for FILE in "$@"; do
    if [ -f "$FILE" ]; then
        echo "  - $FILE"
    fi
done

# Update timestamp
if [ -f "CLAUDE_ACCESS_URLS.md" ]; then
    sed -i "s/## Last Updated.*/## Last Updated\n$(date +%Y-%m-%d)/" CLAUDE_ACCESS_URLS.md
    git add CLAUDE_ACCESS_URLS.md
    git commit -m "Update access URLs timestamp"
    git push origin main
fi

echo -e "${GREEN}✅ Ready for Claude to review!${NC}"