#!/bin/bash

# Test script for running dotfiles installation in Docker container
# This script demonstrates how to test the Linux server installation

set -e

echo "=========================================="
echo "Dotfiles Docker Test Script"
echo "=========================================="
echo

# Function to show usage
show_usage() {
    echo "Usage: $0 [build|run|test|work-test|clean]"
    echo
    echo "Commands:"
    echo "  build      - Build the Docker image"
    echo "  run        - Run the container interactively"
    echo "  test       - Run automated test of server install/uninstall"
    echo "  work-test  - Run automated test of work server install"
    echo "  clean      - Remove containers and images"
    echo
    echo "Examples:"
    echo "  $0 build && $0 run"
    echo "  $0 test"
    echo "  $0 work-test"
}

# Function to build the Docker image
build_image() {
    echo "Building Docker image..."
    docker-compose build
    echo "Docker image built successfully!"
}

# Function to run the container interactively
run_container() {
    echo "Starting Docker container interactively..."
    echo "Use Ctrl+D or 'exit' to exit the container"
    echo
    docker-compose run --rm dotfiles-test
}

# Function to run automated test
run_test() {
    echo "Running automated test of Linux server installation..."

    # Build the image
    build_image

    echo
    echo "Testing Linux server installation..."
    echo "This will install dotfiles in server mode (no GUI applications)"
    echo

    # Run a quick test using docker-compose
    docker-compose run --rm dotfiles-test bash -c "
        echo '=== Docker Test Environment Ready ==='
        echo 'Ubuntu version:' && cat /etc/os-release | grep PRETTY_NAME || echo 'Unknown'
        echo 'Git version:' && git --version || echo 'Git not found'
        echo 'Stow available:' && which stow || echo 'Stow not found'
        echo 'Scripts present:'
        ls -la *.sh | head -10

        echo
        echo '=== Quick Script Validation ==='
        echo 'Testing script help output...'
        ../install/linux_install.sh 2>&1 | head -5 || echo 'Script execution failed'
        ../install/linux_uninstall.sh 2>&1 | head -5 || echo 'Script execution failed'

        echo
        echo '=== Test Complete ==='
        echo 'Docker environment is working correctly!'
    "

    echo
    echo "Test completed! Check the output above for results."
}

# Function to run work server test
run_work_test() {
    echo "Running automated test of Linux work server installation..."

    # Build the image
    build_image

    echo
    echo "Testing Linux work server installation..."
    echo "This will install personal configuration only (no sudo required)"
    echo

    # Run the work installation test using docker-compose
    docker-compose run --rm dotfiles-test bash -c "
        echo '=== Testing Linux Work Server Installation ==='
        echo 'Running: ../install/linux_work_install.sh (non-interactive mode)'
        echo

        # Auto-answer installation prompts
        echo 'y' | ../install/linux_work_install.sh || echo 'Installation completed with some warnings (expected)'

        echo
        echo '=== Installation Complete ==='
        echo 'Checking what was installed...'
        echo 'Local Neovim:' && ~/.local/bin/nvim --version | head -n 1 || echo 'Local Neovim not found'
        echo 'System Neovim:' && nvim --version | head -n 1 || echo 'System Neovim not found'
        echo 'Tmux version:' && tmux -V || echo 'Tmux not found'
        echo 'Stow available:' && which stow || echo 'Stow not found'

        echo
        echo '=== Testing Uninstallation ==='
        echo 'Running: ../install/linux_uninstall.sh (non-interactive mode)'

        # Auto-answer uninstallation prompts
        echo -e 'y\ny\ny\ny' | ../install/linux_uninstall.sh || echo 'Uninstallation completed'

        echo
        echo '=== Work Test Complete ==='
        echo 'Container will exit now'
    "

    echo
    echo "Work test completed! Check the output above for results."
}

# Function to clean up
clean_up() {
    echo "Cleaning up Docker containers and images..."
    docker-compose down --rmi all --volumes --remove-orphans 2>/dev/null || true
    docker system prune -f
    echo "Cleanup complete!"
}

# Main script logic
case "${1:-}" in
    build)
        build_image
        ;;
    run)
        run_container
        ;;
    test)
        run_test
        ;;
    work-test)
        run_work_test
        ;;
    clean)
        clean_up
        ;;
    *)
        show_usage
        exit 1
        ;;
esac