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

# 4. Restore the fastfetch splash-quote cron job (new quote daily)
crontab ~/.config/dotfiles/crontab.txt
sudo systemctl enable --now cronie.service   # crontab won't fire without this
~/.local/bin/update-splash.sh                # seed the first quote now
```

# 5. Refresh the quote on resume-from-suspend (cron doesn't run while asleep)
sudo install -Dm755 ~/.config/dotfiles/system-sleep-refresh-splash-quote \
    /etc/systemd/system-sleep/refresh-splash-quote
```

## Fastfetch splash quote
`~/.local/bin/update-splash.sh` curls a random quote from zenquotes.io (needs
`curl` + `jq`) and writes `~/.cache/splash/quote.txt`; `fastfetch/config.jsonc`
`cat`s that file on every shell start. It's refreshed by the `@daily` cron job
above and by the Hyprland `exec-once` in `hypr/userprefs.conf`. The fastfetch
logo is a random PNG from `fastfetch/logo/` (tracked). Note: `update-splash.sh`
and `fastfetch-logo.sh` hard-code `/home/Lynchalot/` paths — edit if the new
machine uses a different username.

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
