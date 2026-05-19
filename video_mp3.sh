#!/usr/bin/env bash
set -euo pipefail

set -a
source .env
set +a

if [[ -z "${VIDEO_URL:-}" ]]; then
  echo "VIDEO_URL is missing in .env"
  exit 1
fi

OUTPUT_DIR="${OUTPUT_DIR:-downloads}"
mkdir -p "$OUTPUT_DIR"

yt-dlp \
  --no-playlist \
  --continue \
  --no-overwrites \
  -f "bestaudio/best" \
  -x \
  --audio-format mp3 \
  --audio-quality 0 \
  -o "$OUTPUT_DIR/%(title).200B [%(id)s].%(ext)s" \
  "$VIDEO_URL"