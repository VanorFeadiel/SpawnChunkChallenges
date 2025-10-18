#!/bin/bash
# FILENAME: get-claude-urls.sh
# Generate formatted URLs for Claude to fetch
# Usage: ./get-claude-urls.sh [file1] [file2]...
# If no files specified, shows file index URL

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

BASE_URL="https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/main"

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📋 URLs for Claude to Fetch${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

if [ $# -eq 0 ]; then
    # No arguments - show file index URL
    echo -e "${BLUE}File Index:${NC}"
    echo "https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/refs/heads/main/CLAUDE_ACCESS_URLS.md"
    echo ""
    echo -e "${GREEN}💡 Tip: Copy this message to Claude:${NC}"
    echo ""
    echo "Please review the current mod files."
    echo ""
    echo "File index: https://raw.githubusercontent.com/VanorFeadiel/SpawnChunkChallenges/refs/heads/main/CLAUDE_ACCESS_URLS.md"
    echo ""
else
    # Arguments provided - generate URLs for specific files
    echo -e "${BLUE}Specific Files:${NC}"
    for FILE in "$@"; do
        if [ -f "$FILE" ]; then
            echo "$BASE_URL/$FILE"
        else
            echo -e "${RED}Warning: $FILE not found${NC}" >&2
        fi
    done
    echo ""
    echo -e "${GREEN}💡 Copy this message to Claude:${NC}"
    echo ""
    echo "Please review these files:"
    echo ""
    for FILE in "$@"; do
        if [ -f "$FILE" ]; then
            echo "$BASE_URL/$FILE"
        fi
    done
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"