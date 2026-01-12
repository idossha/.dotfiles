#!/bin/bash
# Usage: ./init_github_repo.sh <repo_name> [description] [visibility]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

check_dependencies() {
    if ! command -v git &> /dev/null; then print_error "Git not installed"; exit 1; fi
    if ! command -v gh &> /dev/null; then print_error "GitHub CLI not installed. Run './install_gh.sh'"; exit 1; fi
    if ! gh --version &> /dev/null; then print_error "GitHub CLI broken. Run: rm ~/bin/gh && ./install_gh.sh"; exit 1; fi
    if ! gh auth status &> /dev/null; then print_error "GitHub CLI not authenticated. Run 'gh auth login'"; exit 1; fi
}

# Parse arguments
parse_arguments() {
    [ $# -lt 1 ] && { echo "Usage: $0 <repo_name> [description] [visibility]"; exit 1; }
    REPO_NAME="$1"; DESCRIPTION="${2:-}"; VISIBILITY="${3:-public}"
    [[ "$VISIBILITY" != "public" && "$VISIBILITY" != "private" ]] && { print_error "Visibility must be public or private"; exit 1; }
}

check_git_status() {
    if [ -d ".git" ]; then
        git remote get-url origin &> /dev/null && { print_error "Repository already has remote origin"; exit 1; }
        git rev-parse --verify HEAD &> /dev/null && print_status "Repository has commits" || print_warning "Repository exists but no commits"
        # Ensure we're on main branch
        git branch --show-current | grep -q "main" || git branch -m master main 2>/dev/null || true
    else
        git init
        # Set default branch to main
        git branch -m main 2>/dev/null || true
    fi
}

create_github_repo() {
    CMD="gh repo create $REPO_NAME --$VISIBILITY"
    [ -n "$DESCRIPTION" ] && CMD="$CMD --description \"$DESCRIPTION\""
    CMD="$CMD --source=. --remote=origin --push"
    eval "$CMD" || { print_error "Failed to create repository"; exit 1; }
}

add_and_commit_files() {
    [ -z "$(find . -type f -not -path './.git/*' | head -1)" ] && [ ! -f "README.md" ] && { echo "# $REPO_NAME${DESCRIPTION:+$'\n\n'$DESCRIPTION}" > README.md; }
    git add . && git diff --cached --quiet || git commit -m "Initial commit"
}

main() {
    check_dependencies
    parse_arguments "$@"
    check_git_status

    if git remote get-url origin &> /dev/null 2>&1; then
        git push -u origin main || { print_error "Push failed"; exit 1; }
    else
        ! git rev-parse --verify HEAD &> /dev/null && add_and_commit_files
        create_github_repo
    fi

    echo "Repository: https://github.com/$(gh api user --jq .login)/$REPO_NAME"
}

main "$@"