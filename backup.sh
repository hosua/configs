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
  "$CONF/tmux" \
  "$CONF/tmux-powerline" \
  "$CONF/vlc" \
  "$CONF/zathura" \
  "$CONF/dolphinrc" \
  "$DEST_CONF"

# "$CONF/nitrogen" \ # I forget what this is for... something with bgs

rsync -a --exclude='.git' \
  "$HOME/.bash_aliases" \
  "$HOME/.xinitrc" \
  .
