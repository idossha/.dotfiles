# Docker configuration for Linux
export DOCKER_HOST_IP=localhost
# export DISPLAY=:0  # Uncomment if using X11

# Atuin shell history
if [ -f "$HOME/.atuin/bin/env" ]; then
    . "$HOME/.atuin/bin/env"
fi

# Local bin path
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
