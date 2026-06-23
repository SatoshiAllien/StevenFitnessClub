#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCODEPROJ="$PROJECT_DIR/app/StevenFitnessClub.xcodeproj"

if [ ! -d "$XCODEPROJ" ]; then
  osascript -e "display alert \"File non trovato\" message \"Non trovo:\n$XCODEPROJ\n\nAspetta che iCloud finisca di sincronizzare.\""
  exit 1
fi

open "$XCODEPROJ"