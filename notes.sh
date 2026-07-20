#!/usr/bin/env bash
# Apple Notes Skill Root Wrapper (v0.3.0)
# Automatically locates and executes the distribution script relatively.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/skills/apple-notes/notes.sh" "$@"
