# docs-builder

A specialized Docker container builder for the 40docs platform that creates documentation websites using MkDocs and nginx.

## Overview

The docs-builder serves as the containerization layer for documentation sites within the 40docs ecosystem. It automatically builds Docker images containing MkDocs-generated documentation sites, ready for deployment to Kubernetes clusters.

## Architecture

### Build Process

1. **Content Aggregation**: Combines theme from `40docs/theme` and content from configurable source repository (default: `40docs/landing-page`)
2. **Multi-Format Generation**: 
   - HTML documentation sites using MkDocs
   - PDF generation for hands-on labs content
3. **Container Creation**: Packages content into nginx-unprivileged containers
4. **Registry Management**: Pushes to Azure Container Registry with semantic versioning
5. **GitOps Integration**: Triggers downstream deployment manifests updates

### Container Features

- **Base**: `nginxinc/nginx-unprivileged:latest` for security
- **Health Check**: `/healthz/` endpoint for Kubernetes probes
- **Non-Root**: Runs as unprivileged user (101)
- **Minimal**: Contains only generated documentation content

## Workflow Triggers

The build process can be triggered by:

- **Push to main branch**: Automatic builds on code changes
- **Repository dispatch**: External repositories can trigger builds via `docs-builder` event type
- **Manual workflow**: GitHub Actions workflow_dispatch

## Configuration

### Required Secrets

- `ACR_LOGIN_SERVER`: Azure Container Registry hostname
- `AZURE_CREDENTIALS`: Azure service principal credentials  
- `ARM_CLIENT_ID` / `ARM_CLIENT_SECRET`: Azure authentication
- `PAT`: GitHub Personal Access Token for cross-repo operations

### Required Variables

- `DNS_ZONE`: Target domain for documentation site
- `MKDOCS_REPO_NAME`: MkDocs container image reference
- `MANIFESTS_APPLICATIONS_REPO_NAME`: Target repository for deployment manifests
- `VERSION`: Current version (managed automatically)

### Optional Configuration

- `UPSTREAM_REPO`: Source repository for content (defaults to `{owner}/landing-page`)

## Usage

### Automatic Builds

Builds are triggered automatically when:
- Content is pushed to the main branch
- External repositories dispatch the `docs-builder` event
- Dependencies (theme, landing-page) are updated

### Manual Builds

```bash
# Trigger via GitHub CLI
gh workflow run docs-builder.yml

# Check build status  
gh workflow list
gh run list --workflow=docs-builder.yml
```

### Local Testing

```bash
# Build container locally (requires site/ directory with content)
mkdir -p site/
echo "<h1>Test Documentation</h1>" > site/index.html  
docker build -t docs-builder-test .
docker run --rm -p 8080:8080 docs-builder-test

# Test health endpoint
curl http://localhost:8080/healthz/
```

## Integration

### Upstream Dependencies

- **Theme Repository** (`40docs/theme`): Provides MkDocs theme and styling
- **Content Repository** (configurable): Source documentation content
- **MkDocs Container**: External container for content generation

### Downstream Integration

- **manifests-applications**: Receives version updates
- **GitOps Pipeline**: Flux deployment triggered by manifest updates
- **Kubernetes Cluster**: Final deployment target

## Version Management

The builder implements intelligent semantic versioning:

1. **Registry Check**: Queries Azure Container Registry for existing tags
2. **Variable Comparison**: Compares with GitHub repository variables
3. **Version Selection**: Uses higher of registry version or variable version
4. **Auto-Increment**: Increments patch version automatically
5. **Cross-Repo Update**: Updates deployment manifests with new version

## Development

### Project Structure

```
.
├── Dockerfile              # Container definition
├── .github/
│   ├── workflows/
│   │   └── docs-builder.yml # Build automation
│   └── copilot.instructions.md
└── README.md
```

### Contributing

1. Changes to the Dockerfile require testing with sample content
2. Workflow modifications should be tested in a fork environment
3. Version changes are handled automatically - do not manually edit VERSION variables
4. All builds must maintain security posture (non-root, unprivileged nginx)

### Troubleshooting

#### Build Failures

```bash
# Check workflow logs
gh run view <run-id> --log

# Validate registry connectivity  
dig $ACR_LOGIN_SERVER +short
az acr check-health --name <registry-name>
```

#### Container Issues

```bash
# Debug running container
docker run --rm -it <registry>/docs:latest sh
ls -la /www/

# Check health endpoint
curl -f http://localhost:8080/healthz/ || echo "Health check failed"
```

#### Version Conflicts

```bash
# Check current versions
gh variable list | grep VERSION
az acr repository show-tags --name <registry> --repository docs --orderby time_desc
```

## Security

- Uses official nginx-unprivileged base image
- Runs as non-root user (101) 
- Minimal attack surface with only documentation content
- Secure Azure authentication via OIDC
- No secrets stored in container or repository

## License

Part of the 40docs platform ecosystem. See individual component licenses for details.