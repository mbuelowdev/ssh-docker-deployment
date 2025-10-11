#!/bin/bash

# Manage Docker containers with different actions
# Usage: manage-containers.sh <action> <config_path> <deployment_name> <deployment_dir> <ssh_host> <ssh_user>
# Actions: stop, prune, start

ACTION="$1"
CONFIG_PATH="$2"
DEPLOYMENT_NAME="$3"
DEPLOYMENT_DIR="$4"
SSH_HOST="$5"
SSH_USER="$6"

if [ -z "$ACTION" ] || [ -z "$CONFIG_PATH" ] || [ -z "$DEPLOYMENT_NAME" ] || [ -z "$DEPLOYMENT_DIR" ] || [ -z "$SSH_HOST" ] || [ -z "$SSH_USER" ]; then
    echo "Usage: manage-containers.sh <action> <config_path> <deployment_name> <deployment_dir> <ssh_host> <ssh_user>"
    echo "Actions: stop, prune, start"
    exit 1
fi

# Function to get clean container name
get_clean_name() {
    local image_name="$1"
    local clean_name="${image_name//[^[:alnum:]]/_}"
    
    if [ "$image_name" != "$DEPLOYMENT_NAME" ]; then
        clean_name="${DEPLOYMENT_NAME}_${image_name}"
        clean_name="${clean_name//[^[:alnum:]]/_}"
    fi
    
    echo "$clean_name"
}

case "$ACTION" in
    "stop")
        echo "Stopping existing containers..."
        IMAGE_COUNT=$(jq '.deployImages | length' "$CONFIG_PATH")
        for ((i = 0; i < IMAGE_COUNT; i++)); do
            IMAGE_NAME=$(jq -r ".deployImages[$i].name" "$CONFIG_PATH")
            CONTAINER_NAME=$(get_clean_name "$IMAGE_NAME")
            
            echo "Stopping container: $CONTAINER_NAME"
            ssh "$SSH_USER"@"$SSH_HOST" "docker stop -t 10 $CONTAINER_NAME || true"
        done
        echo "Container stopping completed"
        ;;
    "prune")
        echo "Cleaning up unused Docker resources..."
        ssh "$SSH_USER"@"$SSH_HOST" "docker system prune -a -f"
        echo "Docker pruning completed"
        ;;
    "start")
        echo "Starting new containers..."
        IMAGE_COUNT=$(jq '.deployImages | length' "$CONFIG_PATH")
        for ((i = 0; i < IMAGE_COUNT; i++)); do
            IMAGE_NAME=$(jq -r ".deployImages[$i].name" "$CONFIG_PATH")
            IMAGE_TAG=$(jq -r ".deployImages[$i].tag" "$CONFIG_PATH")
            IMAGE_PORTS=$(jq -r ".deployImages[$i].argPorts" "$CONFIG_PATH")
            IMAGE_VOLUMES=$(jq -r ".deployImages[$i].argVolumes" "$CONFIG_PATH")
            IMAGE_EXTRA=$(jq -r ".deployImages[$i].argExtra" "$CONFIG_PATH")
            IMAGE_ARGS=$(jq -r ".deployImages[$i].argImageArgs" "$CONFIG_PATH")

            [ "$IMAGE_ARGS" = "null" ] && IMAGE_ARGS=""

            CONTAINER_NAME=$(get_clean_name "$IMAGE_NAME")
            
            echo "Starting container: $CONTAINER_NAME"
            ssh "$SSH_USER"@"$SSH_HOST" \
                "docker run --restart=unless-stopped --detach --add-host host.docker.internal:host-gateway --name $CONTAINER_NAME $IMAGE_PORTS $IMAGE_VOLUMES $IMAGE_EXTRA $IMAGE_NAME:$IMAGE_TAG $IMAGE_ARGS"
        done
        echo "Container starting completed"
        ;;
    *)
        echo "Error: Invalid action '$ACTION'. Use 'stop', 'prune', or 'start'"
        exit 1
        ;;
esac
