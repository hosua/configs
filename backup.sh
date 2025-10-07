#!/bin/bash

CONF=~/.config

CONF="$HOME/.config"
DEST_CONF=".config"

rsync -a --exclude='.git' \
  "$CONF/.aliasrc" \
  "$CONF/awesome" \
  "$CONF/bashtop" \
  "$CONF/cava" \
  "$CONF/kitty" \
  "$CONF/nvim" \
  "$CONF/ranger" \
  "$CONF/Thunar" \
  "$DEST_CONF"

rsync -a --exclude='.git' \
    "$HOME/.xinitrc" \
    "$HOME/.tmux" \
    "$HOME/.tmux.conf" \
    .
