#!/usr/bin/env bash
# install.sh — wire the claude-nestjs-hexagonal plugin into a project
#
# Usage (from project root, after adding the submodule):
#   bash .claude/plugins/hexagonal/install.sh
#
# What it does:
#   1. Creates symlinks in .claude/rules/ and .claude/skills/ pointing to the plugin files
#   2. Prints the @include line to add to your .claude/CLAUDE.md

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(pwd)/.claude"
RULES_DIR="$CLAUDE_DIR/rules"
SKILLS_DIR="$CLAUDE_DIR/skills"

mkdir -p "$RULES_DIR" "$SKILLS_DIR"

echo "Linking rules..."
for f in "$PLUGIN_DIR/rules/"*.md; do
  name="$(basename "$f")"
  ln -sf "$f" "$RULES_DIR/$name"
  echo "  .claude/rules/$name"
done

echo "Linking skills..."
for d in "$PLUGIN_DIR/skills/"/*/; do
  name="$(basename "$d")"
  ln -sfn "$d" "$SKILLS_DIR/$name"
  echo "  .claude/skills/$name"
done

echo ""
echo "Done. Add this line to .claude/CLAUDE.md:"
echo ""
echo "  @plugins/hexagonal/CLAUDE.md"
echo ""
