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
  -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best[ext=mp4]/best" \
  --merge-output-format mp4 \
  --remux-video mp4 \
  -o "$OUTPUT_DIR/%(title).200B [%(id)s].%(ext)s" \
  "$VIDEO_URL"