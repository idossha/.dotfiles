


### Ubunto lazygit:
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/

### Linux lazydocker:
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# make sure kitty is the default terminal in linux:
gsettings set org.gnome.desktop.default-applications.terminal exec kitty
gsettings set org.gnome.desktop.default-applications.terminal exec-arg "-e"

# NVIM Version
# Consider using cmake and all that nonsense to install most updated version on linux



