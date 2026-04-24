#!/bin/bash

# Extract deployment configuration from JSON file
# Usage: extract-config.sh <config_path>

CONFIG_PATH="$1"

if [ -z "$CONFIG_PATH" ]; then
    echo "Error: Config path is required"
    exit 1
fi

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Error: Config file not found: $CONFIG_PATH"
    exit 1
fi

# Extract basic attributes
NAME=$(jq -r ".name" "$CONFIG_PATH")
TAG=$(jq -r ".tag" "$CONFIG_PATH")
VERSION=$(jq -r ".version" "$CONFIG_PATH")
URL=$(jq -r ".url" "$CONFIG_PATH")
INFORM_DISCORD=$(jq -r ".informDiscord" "$CONFIG_PATH")

# Build the clean container name
CONTAINER_NAME_CLEAN="${NAME//[^[:alnum:]]/_}"
DEPLOYMENT_DIR="/deployments/$CONTAINER_NAME_CLEAN"

# Output all variables for GitHub Actions
echo "name=$NAME"
echo "tag=$TAG"
echo "version=$VERSION"
echo "url=$URL"
echo "inform_discord=$INFORM_DISCORD"
echo "deployment_dir=$DEPLOYMENT_DIR"
