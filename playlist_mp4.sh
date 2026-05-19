#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing .env file"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ -z "${PLAYLIST_URL:-}" ]]; then
  echo "PLAYLIST_URL is missing in .env"
  exit 1
fi

OUTPUT_DIR="${OUTPUT_DIR:-youtube_playlist_downloads}"

mkdir -p "$OUTPUT_DIR"

yt-dlp \
  --yes-playlist \
  --ignore-errors \
  --continue \
  --no-overwrites \
  --download-archive "$OUTPUT_DIR/downloaded.txt" \
  -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best[ext=mp4]/best" \
  --merge-output-format mp4 \
  --remux-video mp4 \
  -o "$OUTPUT_DIR/%(playlist_index)03d - %(title).200B [%(id)s].%(ext)s" \
  "$PLAYLIST_URL"