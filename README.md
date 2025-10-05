# SSH Docker Deployment Workflow

A reusable GitHub Actions workflow for building and deploying Docker applications to remote servers via SSH. This workflow provides a complete CI/CD pipeline with container management, deployment locking, and Discord notifications.

## How It Works

The workflow follows a structured deployment process:

1. **Build Phase**
   - Extracts deployment configuration from JSON
   - Builds Docker image and exports as tarball
   - Sets up Docker Buildx for advanced build features

2. **Deployment Phase**
   - Acquires deployment lock to prevent concurrent deployments
   - Stops existing containers gracefully
   - Prunes unused Docker resources
   - Deploys repository code to remote server
   - Loads new Docker image
   - Starts updated containers
   - Releases deployment lock

3. **Notification Phase**
   - Sends Discord notification with deployment details

## Workflow Steps

| Step | Description |
|------|-------------|
| **Get start time** | Records timing for build duration calculation |
| **Checkout repository** | Downloads source code |
| **Checkout workflow repository** | Downloads deployment scripts |
| **Setup SSH** | Configures SSH key and known hosts |
| **Extract configuration** | Parses deployment.json for parameters |
| **Build Docker image** | Creates and exports Docker image as tarball |
| **Setup deployment lock** | Acquires exclusive deployment access |
| **Stop existing containers** | Gracefully stops running containers |
| **Prune Docker resources** | Cleans up unused images/containers |
| **Deploy repository** | Transfers and extracts application code |
| **Load Docker image** | Loads new Docker image on remote server |
| **Start new containers** | Launches updated containers |
| **Release deployment lock** | Unlocks deployment machine |
| **Notify Discord** | Sends deployment success notification |

## Deployment Configuration

### deployment.json Structure

Create a `deployment.json` file in your project root with the following structure:

```json
{
   "version": "1.0.0",
   "name": "your-app/image-name",
   "tag": "latest",
   "url": "https://your-app.example.com",
   "informDiscord": true,
   "deployImages": [
      {
         "name": "your-app/image-name",
         "tag": "latest",
         "argPorts": "-p 172.17.0.1:8080:80",
         "argVolumes": "-v /data:/app/data",
         "argExtra": "-e ENV_VAR=value"
      },
      {
         "name": "postgres",
         "tag": "15",
         "argPorts": "-p 172.17.0.1:5432:5432",
         "argVolumes": "-v postgres_data:/var/lib/postgresql/data",
         "argExtra": "-e POSTGRES_PASSWORD=secret"
      }
   ]
}
```

### Configuration Fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Application version for notifications |
| `name` | string | Main Docker image name |
| `tag` | string | Docker image tag |
| `url` | string | Application URL for notifications |
| `informDiscord` | boolean | Whether to send Discord notifications |
| `deployImages` | array | List of containers to deploy |

### deployImages Configuration

Each container in `deployImages` supports:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Docker image name |
| `tag` | string | Docker image tag |
| `argPorts` | string | Docker port mappings (e.g., `-p 80:80`) |
| `argVolumes` | string | Docker volume mounts |
| `argExtra` | string | Additional Docker run arguments |

## Using This Workflow

### 1. Add Workflow to Your Repository

Create `.github/workflows/deploy.yml` in your repository:

```yaml
name: Deploy Application

on:
   push:
      branches: [main]
   workflow_dispatch:

jobs:
   deploy:
      uses: mbuelowdev/ssh-docker-deployment/.github/workflows/build-and-deploy.yml@master
      with:
         config_path: './deployment.json'
         discord_channel_id: 'YOUR_DISCORD_CHANNEL_ID'
         deployment_host: 'your-server.com'
         deployment_user: 'deploy'
      secrets:
         deployment_ssh_key: ${{ secrets.DEPLOYMENT_SSH_KEY }}
         discord_bot_token: ${{ secrets.DISCORD_BOT_TOKEN }}
```

### 2. Set Up Secrets

Configure these secrets in your repository:

| Secret | Description |
|--------|-------------|
| `DEPLOYMENT_SSH_KEY` | SSH private key for deployment server access |
| `DISCORD_BOT_TOKEN` | Discord bot token for notifications |

### 3. Update Known Hosts (If Needed)

If your deployment server changes, update the SSH fingerprint in the workflow:

```yaml
- name: Setup known_hosts
  run: echo "YOUR_SERVER_IP YOUR_SSH_FINGERPRINT" > ~/.ssh/known_hosts
```

To get your server's SSH fingerprint:
```bash
ssh-keyscan -t ecdsa your-server.com
```

## Required Software on Deployment Host

The deployment server must have the following tools installed:

| Tool | Purpose | Installation |
|------|--------|--------------|
| **Docker** | Container runtime | `apt install docker.io` or `yum install docker` |
| **unzip** | Extract repository archives | `apt install unzip` or `yum install unzip` |
| **curl** | Discord notifications | `apt install curl` or `yum install curl` |
| **SSH** | Remote access | Usually pre-installed |

