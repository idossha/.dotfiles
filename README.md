## Created: 20240221 0101

Ido Haber
Last update: May 17, 2024

Disclosure: This environment is in working development and far from perfect, so clone at your own discretion.

---

to keep in mind. when installing oh-my-zsh it often creates a new .zshrc -> make sure you use the old one from repo.

make sure there is no .config that is created when opening the terminal that is conflicted with the .config created by symlink.

last update included changes to installtion script that could possibly break. so install with caution.

---

for .vscode as of now only an extension.txt file.

you call always pull the list of extenions by: - going to your terminal - running `code --list-extensions`

---

## Housekeeping (see requirements & references at the bottom)

---

The process has been streamlined to running a single file.

1. Clone the repo
2. run install.sh

---

#### Make sure from now on you work with iTerm or full color terminal of your choice.

##### To reflect changes on your terminal, restart it or run this command:

```bash
source ~/.zshrc
```

## This conculdes the important installations. From here continue to configure as you wish.

---

[nerd fonts](https://github.com/ryanoasis/nerd-fonts)

---

#### Neovim Setup + Relevant files:

The neovim configuration is an adaptation (simplified version) of https://github.com/josean-dev/dev-environment-files by josean.

https://youtu.be/6mxWayq-s9I
[.config/nvim](.config/nvim)

### from others:

https://www.youtube.com/watch?v=zIGJ8NTHF4k
