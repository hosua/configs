#!/bin/bash

CONF="$HOME/.config"
DEST_CONF=".config"

rsync -a --exclude='.git' \
  "$CONF"/gtk-* \
  "$CONF"/qt*ct \
  "$CONF/Thunar" \
  "$CONF/awesome" \
  "$CONF/btop" \
  "$CONF/dmenu" \
  "$CONF/dolphinrc" \
  "$CONF/fastfetch" \
  "$CONF/hypr" \
  "$CONF/kdedefaults" \
  "$CONF/kitty" \
  "$CONF/lazydocker" \
  "$CONF/mimeapps.list" \
  "$CONF/neovide" \
  "$CONF/nvim" \
  "$CONF/picom" \
  "$CONF/pipewire" \
  "$CONF/ranger" \
  "$CONF/suckless" \
  "$CONF/tmux" \
  "$CONF/tmux-powerline" \
  "$CONF/vlc" \
  "$CONF/zathura" \
  "$DEST_CONF"

# "$CONF/nitrogen" \ # I forget what this is for... something with bgs

rsync -a --exclude='.git' \
  "$HOME/.bash_aliases" \
  "$HOME/.bash_functions" \
  "$HOME/.claude_aliases" \
  "$HOME/.xinitrc" \
  .

git add . && git commit && git push origin HEAD
