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

if [[ -z "${VIDEO_URL:-}" ]]; then
  echo "VIDEO_URL is missing in .env"
  exit 1
fi

OUTPUT_DIR="${OUTPUT_DIR:-downloads}"
mkdir -p "$OUTPUT_DIR"

FAILED_FILE="$OUTPUT_DIR/failed_mp3.txt"
LOG_FILE="$OUTPUT_DIR/video_mp3.log"

: > "$FAILED_FILE"
: > "$LOG_FILE"

echo "Downloading MP3: $VIDEO_URL" | tee -a "$LOG_FILE"

if yt-dlp \
  --no-playlist \
  --continue \
  --no-overwrites \
  -f "bestaudio/best" \
  -x \
  --audio-format mp3 \
  --audio-quality 0 \
  -o "$OUTPUT_DIR/%(title).200B [%(id)s].%(ext)s" \
  "$VIDEO_URL" 2>&1 | tee -a "$LOG_FILE"; then

  echo "OK: $VIDEO_URL" | tee -a "$LOG_FILE"
else
  echo "$VIDEO_URL" | tee -a "$FAILED_FILE" "$LOG_FILE"
  echo "FAILED. See: $FAILED_FILE and $LOG_FILE"
  exit 1
fi