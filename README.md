## Created: 20240221 0101

Ido Haber
Last update: March 27, 2024

This is an adaptation (simplified version) of https://github.com/josean-dev/dev-environment-files by josean.

Disclosure: This environment is in working development and far from perfect, so clone at your own discretion.

---

## Housekeeping (see requirements & references at the bottom)

#### Step 1: Install Homebrew & add to path

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installing, add it to the path (replace ”[username]” with your actual username):

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/[username]/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

##### For XCode Command Line Tools do:

```bash
xcode-select --install
```

#### Step2: Main programs

```bash
brew install --cask iterm2
brew install --cask rectangle
brew tap homebrew/cask-fonts
brew install tmux
brew install git
brew install neovim
brew install font-hack-nerd-font
brew install ripgrep
brew install node
brew install jq
```

### step3: clone this repo and run the bash script to create symlinks

#### 4: install ohmyzsh:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

#### step 5: install extra plugins for command line

1. Install zsh-autosuggestions:

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

2. Install zsh-syntax-highlighting:

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

Open the ”~/.zshrc” file in your desired editor and modify the plugins line to what you see below.

```
plugins=(git zsh-autosuggestions zsh-syntax-highlighting web-search)
```

### Make sure from now on you work with iTerm or full color terminal of your choice.

##### To reflect changes on your terminal, restart it or run this command:

```bash
source ~/.zshrc
```

## This conculdes the important installations. From here continue to configure as you wish.

---

[nerd fonts](https://github.com/ryanoasis/nerd-fonts)

---

### from josean:

Terminal Setup + Relevant files:

https://www.youtube.com/watch?v=CF1tMjvHDRA&list=PLnu5gT9QrFg36OehOdECFvxFFeMHhb_07&index=2&t=479s

[.zshrc](.zshrc) - Zsh Shell Configuration

#### Tmux Setup + Relevant files:

https://youtu.be/U-omALWIBos

[.tmux.conf](.tmux.conf) - Tmux Configuration File

#### Neovim Setup + Relevant files:

https://youtu.be/6mxWayq-s9I
[.config/nvim](.config/nvim)

### from others:

https://www.youtube.com/watch?v=zIGJ8NTHF4k
