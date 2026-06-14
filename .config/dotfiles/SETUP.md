# Dotfiles — reproduce this desktop on a fresh Arch box

HyDE-based Hyprland setup (Nvidia, ultrawide). Tracked with a **bare git repo** at `~/.dotfiles`.

## Restore on a new machine

```sh
# 1. Base: install Arch + HyDE first (https://github.com/HyDE-Project/HyDE), then:

# 2. Clone this repo as a bare repo and check it out over $HOME
git clone --bare git@github.com:Lynchalot/dotfiles.git "$HOME/.dotfiles"
alias dots='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
dots checkout                       # may warn about files HyDE already placed; back them up or `dots checkout -f`
dots config status.showUntrackedFiles no

# 3. Reinstall packages
sudo pacman -S --needed - < ~/.config/dotfiles/packages-pacman-native.txt
yay  -S --needed - < ~/.config/dotfiles/packages-aur.txt   # or paru
```

## Day-to-day use

```sh
dots status                 # see changed tracked files
dots add ~/.config/foo/bar  # track a new/changed file
dots commit -m "tweak foo"
dots push
```

`status.showUntrackedFiles no` keeps `dots status` quiet about the thousands of
untracked files in `$HOME` — only files you've explicitly `dots add`ed are tracked.

## What's tracked
WM / shell / terminal / theming configs only — **no app data, browser profiles,
tokens, or shell history** (see `~/.gitignore` for the protective excludes).
