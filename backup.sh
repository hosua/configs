#!/bin/bash

CONF="$HOME/.config"
DEST_CONF=".config"

rsync -a --exclude='.git' \
  "$CONF/.aliasrc" \
  "$CONF/Thunar" \
  "$CONF/awesome" \
  "$CONF/bashtop" \
  "$CONF/btop" \
  "$CONF/cava" \
  "$CONF/dmenu" \
  "$CONF/kitty" \
  "$CONF/nvim" \
  "$CONF/picom" \
  "$CONF/ranger" \
  "$CONF/tmux-powerline" \
  "$DEST_CONF"

rsync -a --exclude='.git' \
  "$HOME/.xinitrc" \
  "$HOME/.tmux" \
  "$HOME/.tmux.conf" \
  .
