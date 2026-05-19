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

ARCHIVE_FILE="$OUTPUT_DIR/downloaded.txt"
FAILED_FILE="$OUTPUT_DIR/failed.txt"
LOG_FILE="$OUTPUT_DIR/run.log"
QUEUE_FILE="$OUTPUT_DIR/queue.txt"

: > "$FAILED_FILE"
: > "$LOG_FILE"
: > "$QUEUE_FILE"

echo "Building playlist queue..." | tee -a "$LOG_FILE"

if ! yt-dlp \
  --yes-playlist \
  --flat-playlist \
  --print "%(playlist_index)03d	https://www.youtube.com/watch?v=%(id)s" \
  "$PLAYLIST_URL" > "$QUEUE_FILE" 2>> "$LOG_FILE"; then

  echo "FAILED: could not read playlist: $PLAYLIST_URL" | tee -a "$FAILED_FILE" "$LOG_FILE"
  exit 1
fi

TOTAL="$(wc -l < "$QUEUE_FILE" | tr -d ' ')"
FAILED_COUNT=0
OK_COUNT=0

echo "Found $TOTAL playlist items." | tee -a "$LOG_FILE"

while IFS=$'\t' read -r INDEX VIDEO_URL; do
  [[ -z "${VIDEO_URL:-}" ]] && continue

  echo ""
  echo "Downloading $INDEX of $TOTAL: $VIDEO_URL" | tee -a "$LOG_FILE"

  if yt-dlp \
    --no-playlist \
    --continue \
    --no-overwrites \
    --download-archive "$ARCHIVE_FILE" \
    -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best[ext=mp4]/best" \
    --merge-output-format mp4 \
    --remux-video mp4 \
    -o "$OUTPUT_DIR/$INDEX - %(title).200B [%(id)s].%(ext)s" \
    "$VIDEO_URL" 2>&1 | tee -a "$LOG_FILE"; then

    OK_COUNT=$((OK_COUNT + 1))
    echo "OK: $INDEX $VIDEO_URL" | tee -a "$LOG_FILE"
  else
    FAILED_COUNT=$((FAILED_COUNT + 1))
    echo "$INDEX $VIDEO_URL" | tee -a "$FAILED_FILE" "$LOG_FILE"
  fi
done < "$QUEUE_FILE"

echo ""
echo "Done." | tee -a "$LOG_FILE"
echo "Successful or already archived: $OK_COUNT" | tee -a "$LOG_FILE"
echo "Failed: $FAILED_COUNT" | tee -a "$LOG_FILE"
echo "Failure list: $FAILED_FILE" | tee -a "$LOG_FILE"
echo "Full log: $LOG_FILE" | tee -a "$LOG_FILE"

if [[ "$FAILED_COUNT" -gt 0 ]]; then
  exit 1
fi