#!/bin/bash

# Safe minimal PATH
export PATH="/usr/bin:/bin:/usr/local/bin"

# Always use full path instead of ~
mkdir -p /home/Lynchalot/.cache/splash

QUOTE=$(/usr/bin/curl -s "https://zenquotes.io/api/random" | /usr/bin/jq -r '.[0].q + " — " + .[0].a')

echo "$(date): $QUOTE" >> /home/Lynchalot/.cache/splash/cron.log
echo "$QUOTE" > /home/Lynchalot/.cache/splash/quote.txt
