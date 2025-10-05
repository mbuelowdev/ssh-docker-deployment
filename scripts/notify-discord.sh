#!/bin/bash

# Send Discord notification about deployment
# Usage: notify-discord.sh <discord_channel_id> <discord_bot_token> <app_name> <app_version> <app_url> <repo_url> <commit_message> <build_time_minutes> <image_size_mb>

DISCORD_CHANNEL_ID="$1"
DISCORD_BOT_TOKEN="$2"
APP_NAME="$3"
APP_VERSION="$4"
APP_URL="$5"
REPO_URL="$6"
COMMIT_MESSAGE="$7"
BUILD_TIME_MINUTES="$8"
IMAGE_SIZE_MB="$9"

if [ -z "$DISCORD_CHANNEL_ID" ] || [ -z "$DISCORD_BOT_TOKEN" ]; then
    echo "Discord notification skipped: missing required parameters"
    exit 0
fi

# Clean commit message (remove quotes)
CLEAN_COMMIT=$(echo "$COMMIT_MESSAGE" | tr -d '"')

# Build message
MSG="**✅ Successfully deployed: ${APP_NAME}**
- **Source code**: <${REPO_URL}>
- **Deployed to**: <${APP_URL}>
- **Metadata**: Version ${APP_VERSION}, ${IMAGE_SIZE_MB} MB image, built in ~${BUILD_TIME_MINUTES}min.
- **Commit**: ${CLEAN_COMMIT}"

echo "Sending Discord notification..."

curl \
    --location "https://discordapp.com/api/v6/channels/$DISCORD_CHANNEL_ID/messages" \
    --header "Authorization: Bot $DISCORD_BOT_TOKEN" \
    --header "Content-Type: application/json" \
    --data "{\"content\":\"${MSG//$'\n'/\\n}\"}" \
    || echo "Discord notification failed"
