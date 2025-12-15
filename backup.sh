#!/bin/bash

CONF="$HOME/.config"
DEST_CONF=".config"

rsync -a --exclude='.git' \
  "$CONF/Thunar" \
  "$CONF/awesome" \
  "$CONF/btop" \
  "$CONF/dmenu" \
  "$CONF/hypr" \
  "$CONF/kitty" \
  "$CONF/nvim" \
  "$CONF/picom" \
  "$CONF/ranger" \
  "$CONF/tmux" \
  "$DEST_CONF"

rsync -a --exclude='.git' \
  "$HOME/.bash_aliases" \
  "$HOME/.xinitrc" \
  .
