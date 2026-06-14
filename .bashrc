
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

fastfetch

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"
export INPUT_METHOD=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus


# Add HyDE scripts and local bin to PATH
export scrPath="$HOME/.local/lib/hyde"
export PATH="$HOME/.local/bin:$scrPath:$PATH"

# Load waifu command aliases
if [ -f ~/.waifu/aliases.sh ]; then
  source ~/.waifu/aliases.sh
fi
alias waifu='python3 /home/Lynchalot/.waifu/waifu.py'

export PATH=$PATH:/home/Lynchalot/.spicetify
eval "$(~/.local/bin/mise activate bash)"
eval "$(~/.local/bin/mise activate bash)"

# dotfiles bare repo
alias dots='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
