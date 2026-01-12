# GitHub Repository Setup

## Quick Start
```bash
./install_gh.sh     # Install GitHub CLI locally
gh auth login       # Authenticate
./init_github_repo.sh "repo-name" "description"
```

## Troubleshooting

### "GitHub CLI not installed"
```bash
./install_gh.sh
```

### "exec format error"
Wrong architecture downloaded. Script detects macOS/Linux automatically.

### "Authentication failed"
```bash
gh auth login
```

### Repository exists
Script handles existing git repos and pushes to new remote.
