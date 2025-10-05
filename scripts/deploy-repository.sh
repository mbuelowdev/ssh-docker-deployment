#!/bin/bash

# Deploy repository to remote server
# Usage: deploy-repository.sh <deployment_dir> <ssh_host> <ssh_user> <workspace_path>

DEPLOYMENT_DIR="$1"
SSH_HOST="$2"
SSH_USER="$3"
WORKSPACE_PATH="$4"

if [ -z "$DEPLOYMENT_DIR" ] || [ -z "$SSH_HOST" ] || [ -z "$SSH_USER" ] || [ -z "$WORKSPACE_PATH" ]; then
    echo "Error: All parameters are required"
    exit 1
fi

echo "Deploying repository to $SSH_USER@$SSH_HOST:$DEPLOYMENT_DIR"

# Clean and create deployment directory
ssh "$SSH_USER"@"$SSH_HOST" "rm -rf $DEPLOYMENT_DIR"
ssh "$SSH_USER"@"$SSH_HOST" "mkdir -p $DEPLOYMENT_DIR"

# Create repository archive
cd "$WORKSPACE_PATH"
zip -r repo.zip . -x '*.git*' -x 'repo.zip' -x 'ssh-docker-deployment/*'

# Transfer and extract archive
scp "$WORKSPACE_PATH/repo.zip" "$SSH_USER@$SSH_HOST:$DEPLOYMENT_DIR/repo.zip"
ssh "$SSH_USER"@"$SSH_HOST" "unzip $DEPLOYMENT_DIR/repo.zip -d $DEPLOYMENT_DIR"

echo "Repository deployment completed"
