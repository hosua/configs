# Copy output from a command (pipe with another command using |)
alias ls="ls --color=auto" 
alias tmux="tmux -2" 
alias untar="tar -zxvf" 
alias rm="rm -v" 
alias mv="mv -iv"
alias cp="cp -iv" # -i = interactive. Prompt user yes/no if overwriting a file.
alias sxiv="sxiv -a" # Automatically animate gifs
alias vimdiff="nvim -d"
alias ppt2pdf="libreoffice --headless --convert-to pdf"
alias zzz="systemctl suspend" # sleep
alias nano="nvim -p" # nano not allowed on my system
alias vi="nvim -p"
alias vim="nvim -p" 
alias nvim="nvim -p"
alias py="python"
kill-port() {
    if [ -z "$1" ]; then
        echo "Usage: kill-port <port>"
        return 1
    fi
    pid=$(lsof -t -i:"$1")
    if [ -z "$pid" ]; then
        echo "No process found on port $1"
        return 1
    fi
    echo "Killing process $pid on port $1"
    kill "$pid"
}

# Easy clipboard
alias c="xclip"
alias v="xclip -o"

# Start commands, because I don't want these always enabled
# tor
alias torstart="sudo -u tor /usr/bin/tor"

# vpn
alias vpnup="sudo surfshark-vpn attack"
alias vpndown="sudo surfshark-vpn down"

# Pacman aliases
alias upac="sudo pacman -Syu" # sys update, can also pass an argument to get a package instead
alias clearpac="sudo pacman -Sc" # clear cache
alias killorphans="sudo pacman -Qtdq | sudo pacman -Rns -" # remove orphans
alias listpac='pacman -Qe'
alias listaur='pacman -Qm'

# Mirror rater
alias ua-drop-caches='sudo paccache -rk3; yay -Sc --aur --noconfirm'
alias ua-update-all='export TMPFILE="$(mktemp)"; \
    sudo true; \
    rate-mirrors --save=$TMPFILE arch --max-delay=21600 \
      && sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup \
      && sudo mv $TMPFILE /etc/pacman.d/mirrorlist \
      && ua-drop-caches \
      && yay -Syyu --noconfirm'

alias rustdocs="rustup docs --book"
alias wr="~/.cargo/bin/wr"

alias rbtree="eval $HOME/Desktop/Programming/ruby/rbtree/rbtree"

alias krestart="kquitapp5 plasmashell && kstart plasmashell"

alias aws-venv="source $HOME/python-venvs/aws/bin/activate"

kill_port_process() {
    if [ -z "$1" ]; then
        echo "Usage: kill_port_process <port>"
        return 1
    fi

    PIDS=$(sudo lsof -t -i :"$1")
    
    if [ -z "$PIDS" ]; then
        echo "No process found on port $1"
        return 0
    fi

    echo "Killing process(es) on port $1: $PIDS"
    sudo kill -9 $PIDS
}
