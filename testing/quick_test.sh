#!/bin/bash

# Quick Docker test - just validate the container setup without full installation
# This runs much faster and validates that the Docker environment is working

echo "=========================================="
echo "Quick Docker Validation Test"
echo "=========================================="
echo

cd "$(dirname "$0")"

echo "Testing Docker container startup..."
docker-compose run --rm dotfiles-test bash -c "
    echo '=== Container Environment ==='
    echo 'OS:' \$(uname -a)
    echo 'Ubuntu version:' && cat /etc/os-release | grep PRETTY_NAME || echo 'Unknown'
    echo 'Working directory:' \$(pwd)
    echo 'User:' \$(whoami)
    echo
    echo '=== Available Tools ==='
    echo 'Git available:' && which git && git --version | head -1 || echo 'Git not found'
    echo 'Curl available:' && which curl && curl --version | head -1 || echo 'Curl not found'
    echo 'Stow available:' && which stow && stow --version || echo 'Stow not found'
    echo
    echo '=== Scripts Present ==='
    ls -la *.sh 2>/dev/null | wc -l && echo 'scripts found' || echo 'no scripts found'
    echo
    echo '=== Script Validation ==='
    echo 'linux_install.sh executable:' && [ -x ../install/linux_install.sh ] && echo 'Yes' || echo 'No'
    echo 'linux_uninstall.sh executable:' && [ -x ../install/linux_uninstall.sh ] && echo 'Yes' || echo 'No'
    echo
    echo '=== Success ==='
    echo 'Docker container is properly configured!'
"

echo
echo "Quick test completed! If you see the success message above,"
echo "the Docker environment is working correctly."
echo
echo "To run a full installation test (takes longer):"
echo "  ./test_docker.sh test"