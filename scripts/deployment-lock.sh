#!/bin/bash

# Deployment lock management script
# Usage: 
#   deployment-lock.sh lock <ssh_host> <ssh_user> [timeout_minutes]
#   deployment-lock.sh release <ssh_host> <ssh_user>

ACTION="$1"
SSH_HOST="$2"
SSH_USER="$3"

if [ -z "$ACTION" ] || [ -z "$SSH_HOST" ] || [ -z "$SSH_USER" ]; then
    echo "Usage: deployment-lock.sh <lock|release> <ssh_host> <ssh_user> [timeout_minutes]"
    exit 1
fi

LOCK_FILE="/tmp/deployment.Ar3jG48tr.lock"

case "$ACTION" in
    "lock")
        echo "Waiting for deployment lock (max 5 minutes)..."
        # Wait for lock to be released
        ssh "$SSH_USER"@"$SSH_HOST" "while [ -e $LOCK_FILE ]; do sleep 1; done; touch $LOCK_FILE"
        echo "Deployment lock acquired"
        ;;
    "release")
        echo "Releasing deployment lock..."
        ssh "$SSH_USER"@"$SSH_HOST" "rm -f $LOCK_FILE"
        echo "Deployment lock released"
        ;;
    *)
        echo "Error: Invalid action '$ACTION'. Use 'lock' or 'release'"
        exit 1
        ;;
esac
