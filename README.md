# SSH Docker Deployment Workflow

A reusable GitHub Actions workflow for building and deploying Docker applications to remote servers via SSH. This workflow provides a complete CI/CD pipeline with container management, deployment locking, and Discord notifications.

## How It Works

The workflow follows a structured deployment process:

1. **Build Phase**
   - Extracts deployment configuration from deployment.json
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
   workflow_dispatch:
   push:
      branches: [ 'master' ]
      paths: [ 'deployment.json' ]

jobs:
   deploy:
      uses: mbuelowdev/ssh-docker-deployment/.github/workflows/build-and-deploy.yml@master
      with:
         config_path: './deployment.json'
         build_commit_sha: 'main'
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

### 3. SSH host keys

The reusable workflow runs `ssh-keyscan` against `deployment_host` at the start of each job, so when your server’s IP changes (same hostname, new A/AAAA record) you do not need to edit any fingerprint in the repo.

Use a stable hostname (dynamic DNS or similar) as `deployment_host`, not a raw IP you expect to change without DNS updates.

If you replace the server and its SSH host keys change, the next run still succeeds because the job refreshes `known_hosts` from `ssh-keyscan`. That is more convenient than a pinned key but slightly weaker if an attacker could MITM the scan; for stricter pinning, fork the workflow and set `known_hosts` to a fixed key line instead.

## Required Software on Deployment Host

The deployment server must have the following tools installed:

| Tool | Purpose | Installation |
|------|--------|--------------|
| **Docker** | Container runtime | `apt install docker.io` or `yum install docker` |
| **unzip** | Extract repository archives | `apt install unzip` or `yum install unzip` |
| **curl** | Discord notifications | `apt install curl` or `yum install curl` |
| **SSH** | Remote access | Usually pre-installed |

