#!/bin/bash
if op whoami 2>/dev/null 1>/dev/null; then
    echo "status=unlocked"
else
    echo "status=locked"
fi
