#!/bin/bash

# The directory where the dotfiles are located
DOTFILES_DIR="$HOME/.dotfiles"

# The home directory where the symlinks will be created
HOME_DIR="$HOME"

# Loop through all files and directories in the .dotfiles directory
for file in "$DOTFILES_DIR"/.*; do
    # Get the base filename
    filename=$(basename "$file")
    # Skip the . and .. directories
    if [ "$filename" == "." ] || [ "$filename" == ".." ] || [ "$filename" == ".git" ]; then
        continue
    fi
    # Create a symlink in the home directory, forcing overwrite if necessary
    ln -sf "$file" "$HOME_DIR/$filename"
done

echo "Symlinks created successfully."

