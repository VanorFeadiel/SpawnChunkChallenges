#!/bin/bash
# FILENAME: quick-update.sh
# Quick update script for SpawnChunk mod development
# Usage: ./quick-update.sh <filename> "commit message"

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if filename provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No filename provided${NC}"
    echo "Usage: ./quick-update.sh <filename> \"commit message\""
    echo "Example: ./quick-update.sh media/lua/client/SpawnChunk_Kills.lua \"Fix victory condition\""
    exit 1
fi

FILENAME=$1
COMMIT_MSG=${2:-"Update $FILENAME"}

# Validate file exists
if [ ! -f "$FILENAME" ]; then
    echo -e "${RED}Error: File $FILENAME not found${NC}"
    exit 1
fi

echo -e "${BLUE}📝 Updating $FILENAME...${NC}"

# Git operations
git add "$FILENAME"
git commit -m "$COMMIT_MSG"
git push origin main

echo -e "${GREEN}✅ Successfully pushed $FILENAME${NC}"
echo -e "${BLUE}🔗 GitHub raw URL:${NC}"
echo "https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main/$FILENAME"

# Update CLAUDE_ACCESS_URLS.md timestamp
if [ -f "CLAUDE_ACCESS_URLS.md" ]; then
    echo -e "${BLUE}📅 Updating CLAUDE_ACCESS_URLS.md timestamp...${NC}"
    sed -i "s/## Last Updated.*/## Last Updated\n$(date +%Y-%m-%d)/" CLAUDE_ACCESS_URLS.md
    git add CLAUDE_ACCESS_URLS.md
    git commit -m "Update access URLs timestamp"
    git push origin main
fi

echo -e "${GREEN}✅ All done! Ready for Claude to fetch.${NC}"