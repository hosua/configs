# dwmblocks
Modular status bar for dwm written in c.
# usage
To use dwmblocks first run 'make' and then install it with 'sudo make install'.
After that you can put dwmblocks in your xinitrc or other startup script to have it start with dwm.
# modifying blocks
The statusbar is made from text output from commandline programs.
Blocks are added and removed by editing the blocks.h header file.
By default the blocks.h header file is created the first time you run make which copies the default config from blocks.def.h.
This is so you can edit your status bar commands and they will not get overwritten in a future update.



# Notes from hoswoo
In order for these scripts to work, you must put my Scripts folder in some directory and modify the paths in the source code.

You will need to install ``nerd-fonts-complete`` and an emoji package such as ``ttf-joypixels`` for everything to display properly. 

For arch users, you can nerd-fonts from the AUR [here](https://aur.archlinux.org/packages/nerd-fonts-complete/). And download ``ttf-joypixels`` by simply running ``sudo pacman-S ttf-joypixels``.
