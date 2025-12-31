#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "🔍 Scanning project for potential git issues..."

# 1. Check for nested .git repositories
# This is the main cause of the "missing package" issue.
# If a folder has .git inside, the parent git repo ignores its contents.

NESTED_GITS=$(find . -name ".git" -type d -not -path "./.git" -not -path "./.git/*" -not -path "*/.build/*" -not -path "*/DerivedData/*")

if [ -n "$NESTED_GITS" ]; then
    echo -e "${RED}❌ ERROR: Nested git repositories found!${NC}"
    echo "This will cause 'empty folders' when others clone your repo."
    echo "Found at:"
    echo "$NESTED_GITS"
    echo ""
    echo -e "${YELLOW}💡 FIX:${NC} Remove the .git folder from those directories (e.g., 'rm -rf path/to/nested/.git') and then 'git add' the files."
    exit 1
else
    echo -e "${GREEN}✅ No nested git repositories found.${NC}"
fi

# 2. Check for missing .gitignore
if [ ! -f ".gitignore" ]; then
    echo -e "${YELLOW}⚠️ WARNING: No .gitignore file found!${NC}"
    echo "It is highly recommended to have a .gitignore to avoid committing system files."
else
    echo -e "${GREEN}✅ .gitignore exists.${NC}"
fi

echo -e "${GREEN}🎉 Sanity check passed! Your repo looks healthy.${NC}"
exit 0
