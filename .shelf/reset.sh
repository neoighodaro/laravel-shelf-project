#!/usr/bin/env bash

TARGET_DIR=$(dirname "$0")/../

# Files and directories to keep (space-separated list)
KEEP=(".git" ".devcontainer.json" ".github" ".shelf" "docker" ".dockerignore" ".php-cs-fixer.dist.php" "LICENSE.md" "phpstan.neon.dist" "README.md")

# Convert the keep array to a pattern for the find command
KEEP_PATTERN=$(printf " -name %s -o" "${KEEP[@]}")
KEEP_PATTERN=${KEEP_PATTERN% -o} # Remove the trailing -o

# Use find to delete all files and directories except the ones to keep
find "$TARGET_DIR" -mindepth 1 \( $KEEP_PATTERN \) -prune -o -exec rm -rf {} +

echo "Cleanup completed, kept files and directories: ${KEEP[@]}"
