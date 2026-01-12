# Basic Ubuntu Dockerfile for testing dotfiles installation
FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root

# Install basic dependencies required for the installation scripts
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository universe \
    && apt-get update && apt-get install -y \
    git \
    curl \
    sudo \
    locales \
    stow \
    && rm -rf /var/lib/apt/lists/*

# Generate locales for proper UTF-8 support
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create workspace directory
RUN mkdir -p /workspace
WORKDIR /workspace

# Copy dotfiles into the container
COPY . /workspace/

# Make installation scripts executable
RUN chmod +x /workspace/*.sh

# Set the default shell to bash (though the scripts will install zsh)
SHELL ["/bin/bash", "-c"]

# Default command - start bash for interactive testing
CMD ["/bin/bash"]