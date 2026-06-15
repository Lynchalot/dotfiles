#!/bin/bash

# Fetch a random quote for the fastfetch splash and cache it.
# Only overwrites the cached quote on a SUCCESSFUL fetch, so a network/API
# blip (or a zenquotes rate-limit reply) can't blank the splash.

# Safe minimal PATH
export PATH="/usr/bin:/bin:/usr/local/bin"

CACHE_DIR="/home/Lynchalot/.cache/splash"
QUOTE_FILE="$CACHE_DIR/quote.txt"
LOG_FILE="$CACHE_DIR/cron.log"
mkdir -p "$CACHE_DIR"

# -f: fail on HTTP errors, -sS: quiet but show real errors, bounded time
RESP=$(/usr/bin/curl -fsS --max-time 10 "https://zenquotes.io/api/random" 2>/dev/null)

# Build the quote only if the response is a real quote:
#   - valid array with a non-empty .q
#   - author is NOT "zenquotes.io" (that's their rate-limit / error payload)
QUOTE=$(printf '%s' "$RESP" | /usr/bin/jq -r '
  if type=="array" and (.[0].q // "") != "" and (.[0].a // "") != "zenquotes.io"
  then .[0].q + " — " + .[0].a
  else empty end' 2>/dev/null)

if [ -n "$QUOTE" ]; then
    printf '%s\n' "$QUOTE" > "$QUOTE_FILE"
    echo "$(date): $QUOTE" >> "$LOG_FILE"
else
    echo "$(date): FETCH FAILED — kept previous quote" >> "$LOG_FILE"
fi
