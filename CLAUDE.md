# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **docs-builder** repository within the 40docs platform ecosystem. It's a specialized container builder that creates Docker images for documentation websites using MkDocs and nginx.

### Purpose and Architecture

The docs-builder serves as the containerization layer for documentation sites:

- **Container Base**: Uses `nginxinc/nginx-unprivileged:latest` for secure, non-root web serving
- **Build Process**: Automated GitHub Actions workflow that builds MkDocs documentation sites
- **Multi-Repository Integration**: Combines content from `theme` and `landing-page` repositories 
- **Output**: Creates containerized documentation sites ready for Kubernetes deployment
- **Health Checks**: Includes `/healthz` endpoint for container orchestration

### Build Workflow Architecture

The repository implements a sophisticated GitOps build process:

1. **Version Management**: Automatic semantic versioning with ACR registry coordination
2. **Content Aggregation**: Combines theme and landing-page repositories during build
3. **Multi-Format Output**: Generates both HTML sites and PDF documentation
4. **Container Registry**: Pushes built images to Azure Container Registry (ACR)
5. **GitOps Integration**: Triggers downstream manifest updates for deployment

## Common Development Commands

### Claude Orchestrator with Tmux Sessions
```bash
# ORCHESTRATOR WORKFLOW: Start tmux with Claude orchestrator first
./claude-tmux                    # Creates orchestrator session with main Claude in window 0

# Orchestrator commands (in window 0)
/spawn-all                       # Create Claude instances for all submodules
/status-all                      # Get status from all sub-instances
/health-check                    # Verify all systems operational
/sync-submodules                 # Update all Git submodules
/execute-distributed "command"   # Run command across repositories
/coordinate-workflow "task"      # Orchestrate multi-repo workflows

# Session management (these survive terminal disconnection)
tmux attach-session -t 40docs-claude  # Attach to existing session
tmux list-sessions               # List all tmux sessions
tmux detach                      # Detach from session (Ctrl+b + d)

# Manual operations
~/.tmux/40docs-orchestrator-startup.sh # Run orchestrator startup directly
tmux kill-session -t 40docs-claude     # Terminate entire session

# Tmux navigation shortcuts (use these INSIDE tmux)
# Ctrl+b + 0 : Orchestrator window (main controller)
# Ctrl+b + 1-9 : Sub-instance windows (individual repositories)
# Ctrl+b + n : Next window
# Ctrl+b + p : Previous window  
# Ctrl+b + d : Detach from session (keeps all Claude instances running!)
# Ctrl+b + r : Reload tmux config
```

### Container Development Commands

```bash
# Local Docker testing (manual build simulation)
docker build -t docs-builder-test .

# Test container locally (requires site/ directory)
mkdir -p site/
echo "<h1>Test</h1>" > site/index.html
docker run --rm -p 8080:8080 docs-builder-test

# GitHub Actions workflow testing
gh workflow run docs-builder.yml
gh workflow list
gh run list --workflow=docs-builder.yml

# Version checking (requires Azure CLI)
az acr repository show-tags --name <registry> --repository docs --orderby time_desc
```

### Build Validation Commands

```bash
# Validate Dockerfile syntax
docker build --dry-run .

# Check GitHub Actions workflow syntax
gh workflow view docs-builder.yml

# Validate workflow file locally
act --workflows .github/workflows/docs-builder.yml --dry-run
```

## Architecture Details

### Build Process Flow

The docs-builder implements a multi-stage GitOps build process:

1. **Init Stage**: Validates ACR registry availability and DNS resolution
2. **Version Management**: Intelligent semantic versioning with registry coordination
3. **Content Aggregation**: Clones and combines theme + landing-page repositories
4. **Multi-Format Build**: 
   - HTML build using MkDocs container with theme integration
   - PDF generation for hands-on labs content
5. **Container Creation**: Builds nginx-based container with generated content
6. **Registry Push**: Tags and pushes to ACR with version + latest tags
7. **GitOps Integration**: Updates version variables and triggers manifest updates

### Key GitHub Actions Features

- **Repository Dispatch**: Can be triggered by other repositories in the ecosystem
- **Conditional Execution**: Skips builds when ACR registry is unavailable
- **Secure Authentication**: Uses Azure service principal with OIDC
- **Version Coordination**: Compares GitHub variables with registry tags
- **Multi-Repository Cloning**: Securely clones theme and content repositories
- **Docker BuildKit**: Uses advanced Docker features for optimized builds
- **Cross-Repository Updates**: Updates manifests-applications repository

### Container Security Features

- **Non-Root Execution**: Uses unprivileged nginx (user 101)
- **Temporary Root**: Only uses root temporarily to create healthcheck directory
- **Health Endpoint**: `/healthz/` endpoint returns 'OK' for orchestration
- **Minimal Image**: Based on official nginx-unprivileged for security

## Important Development Guidelines

### Multi-Repository Coordination
- **Separate Repositories**: This builds containers from content in other repositories
- **Content Sources**: Theme from `40docs/theme`, content from configurable upstream repo
- **No Direct Content**: This repository contains no documentation content itself
- **GitOps Integration**: Built containers trigger updates in manifests-applications

### Container Standards
- **Base Image**: Always use `nginxinc/nginx-unprivileged:latest`
- **Security First**: Maintain non-root execution pattern
- **Health Checks**: Include `/healthz/` endpoint for Kubernetes readiness/liveness probes
- **Minimal Layers**: Keep Dockerfile simple and efficient

### GitHub Actions Best Practices
- **Azure Authentication**: Uses OIDC with Azure service principals
- **Secret Management**: Never commit secrets, use GitHub secrets/variables
- **Version Management**: Automated semantic versioning with registry coordination
- **Conditional Logic**: Skip builds when infrastructure unavailable
- **Cross-Repo Updates**: Maintain GitOps workflow integrity

### Build Process Considerations
- **Content Freshness**: Always clones latest theme and content during build
- **PDF Generation**: Handles both HTML and PDF output formats
- **Docker Context**: Uses temporary directory for clean build context
- **Registry Coordination**: Intelligent version management with existing registry tags

## Integration Points

### Upstream Dependencies
- **Theme Repository**: Provides MkDocs theme and styling
- **Landing-Page Repository**: Provides documentation content (configurable via UPSTREAM_REPO)
- **Azure Container Registry**: Target for built container images
- **MkDocs Container**: External container used for content generation

### Downstream Integration
- **manifests-applications**: Receives version updates for deployment
- **GitOps Workflow**: Triggers deployment pipeline updates
- **Kubernetes Deployment**: Built containers deployed via Flux GitOps

### Environment Variables and Secrets Required
- **ACR_LOGIN_SERVER**: Azure Container Registry hostname
- **AZURE_CREDENTIALS**: Azure service principal credentials
- **ARM_CLIENT_ID/ARM_CLIENT_SECRET**: Azure authentication
- **PAT**: GitHub Personal Access Token for cross-repo updates
- **DNS_ZONE**: Target domain for documentation site
- **MKDOCS_REPO_NAME**: MkDocs container image name
- **UPSTREAM_REPO**: Source repository for content (defaults to landing-page)

## Troubleshooting

### Build Failures
```bash
# Check workflow logs
gh run list --workflow=docs-builder.yml
gh run view <run-id> --log

# Validate registry connectivity
dig $ACR_LOGIN_SERVER +short
az acr check-health --name <registry-name>

# Check repository access
gh repo view $UPSTREAM_REPO
gh repo view 40docs/theme
```

### Container Issues
```bash
# Test container locally
docker run --rm -p 8080:8080 <registry>/docs:latest
curl http://localhost:8080/healthz/

# Debug container content
docker run --rm -it <registry>/docs:latest sh
ls -la /www/
```

### Version Management Issues
```bash
# Check current versions
gh variable list
az acr repository show-tags --name <registry> --repository docs

# Manual version update (if needed)
gh variable set VERSION --body "1.0.0"
```