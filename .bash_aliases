export VISUAL="nvim"
export EDITOR="nvim"
export MANPAGER="nvim +Man!"
# Requires yay -S nvimpager
export PAGER="nvimpager"

# Easy clipboard
alias c="xclip"
alias v="xclip -o"
# Copy ohttps://linear.app/wellstat/issue/PMH-34utput rom a command (pipe with another command using |)
alias ls="ls --color=auto"
alias ll="ls -lh"
alias la="ls -lAh"
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
alias rsync="rsync --stats --progress"

alias lsblk='lsblk -o +MODEL,name,rota'

###A ARCHLINUX SPECFIC
alias pac-clearcache="sudo pacman -Scc"
alias pac-killorphans="sudo pacman -Qtdq | sudo pacman -Rns -" # remove orphans
alias pac-listofficial='pacman -Qe'
alias pac-listaur='pacman -Qm'

alias pac-mirror-clearcache='sudo paccache -rk5; yay -Sc --aur --noconfirm'

alias rustdocs="rustup docs --book"
alias wr="~/.cargo/bin/wr"
alias krestart="kquitapp5 plasmashell && kstart plasmashell"
alias aws-venv="source ~/python-venvs/aws/bin/activate"
