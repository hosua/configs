export VISUAL="nvim"
export EDITOR="nvim"
export MANPAGER="nvim +Man!"
# Requires yay -S nvimpager
export PAGER="nvimpager"

# Easy clipboard
alias c="xclip"
alias v="xclip -o"
# Copy output from a command (pipe with another command using |)
alias ls="ls --color=auto"
alias la="ls -lah"
alias tmux="tmux -2"
alias untar="tar -zxvf"
alias rm="rm -v"
alias mv="mv -iv"
alias cp="cp -iv"    # -i = interactive. Prompt user yes/no if overwriting a file.
alias sxiv="sxiv -a" # Automatically animate gifs
alias vimdiff="nvim -d"
alias ppt2pdf="libreoffice --headless --convert-to pdf"
alias zzz="systemctl suspend" # sleep
alias nano="nvim -p"          # nano not allowed on my system
alias vi="nvim -p"
alias vim="nvim -p"
alias nvim="nvim -p"
alias py="python"
alias neofetch="fastfetch"
alias monerod="monerod --detach"

alias lsblk='lsblk -o +MODEL'

###A ARCHLINUX SPECFIC
alias pac-clearcache="sudo pacman -Scc"
alias pac-killorphans="sudo pacman -Qtdq | sudo pacman -Rns -" # remove orphans
alias pac-listofficial='pacman -Qe'
alias pac-listaur='pacman -Qm'

alias pac-mirror-clearcache='sudo paccache -rk5; yay -Sc --aur --noconfirm'

# broken
pac-mirror-updateall() {
    sudo true
    MAX_MIRROR_DELAY=21600
    TMPFILE="$(mktemp)"
    rate-mirrors --save="$TMPFILE" arch --max-delay=$MAX_MIRROR_DELAY
    sudo sh -c "mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup"
    sudo sh -c "cp $TMPFILE /etc/pacman.d/mirrorlist && chmod 644 /etc/pacman.d/mirrorlist"
    yay -Syyu --noconfirm
}

alias rustdocs="rustup docs --book"
alias wr="~/.cargo/bin/wr"
alias krestart="kquitapp5 plasmashell && kstart plasmashell"
alias aws-venv="source ~//python-venvs/aws/bin/activate"

# vpn (surfshark sucks, we kill this soon) mullvad all the way
# alias surf-vpnup="sudo surfshark-vpn attack"
# alias surf-vpndown="sudo surfshark-vpn down"

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
