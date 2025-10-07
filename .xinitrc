#!/bin/sh

# dwm, kde, cinnamon
# environment=dwm
environment=kde

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
	xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
	xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
	for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
	[ -x "$f" ] && . "$f"
	done
	unset f
fi

# keyboard layout
setxkbmap us &

# Display resolution
# xrandr --output HDMI-0 --off --output DP-0 --mode 1920x1080 --rate 144 --output DP-2 --mode 1920x1080 --rate 144 --right-of DP-0 --output DP-4 --mode 1920x1080 --rate 144 --right-of DP-2 &
# xrandr --output HDMI-0 --off --output DP-4 --mode 1920x1080 --rate 144 --output DP-2 --mode 1920x1080 --rate 144 --right-of DP-4 --output DP-0 --mode 1920x1080 --rate 144 --right-of DP-2 &
# xrandr --output HDMI-0 --off --output DP-2 --mode 1920x1080 --rate 144 --output DP-4 --mode 1920x1080 --rate 144 --right-of DP-2 --output DP-0 --mode 1920x1080 --rate 144 --right-of DP-4 &
# xrandr --output DP-2 --mode 1920x1080 --rate 144 --output DP-4 --mode 1920x1080 --rate 144 --right-of DP-2 --output DP-0 --mode 1920x1080 --rate 144 --right-of DP-4 &
# xrandr --output DP-4 --mode 1920x1080 --rate 144 --output DP-0 --mode 1920x1080 --rate 144 --right-of DP-2 --output DP-2 --mode 1920x1080 --rate 144 --right-of DP-4 &
xrandr --output DP-2 --mode 1920x1080 --rate 144 --output DP-0 --mode 1920x1080 --rate 144 --right-of DP-2 --output DP-4 --mode 1920x1080 --rate 144 --right-of DP-0 &
# Needed to use JDownloader for some reason
export _JAVA_AWT_WM_NONREPARENTING=1

killall -9 dwm_bar.sh 
killall -9 dwmblocks
# Volume bindings 
xbindkeys &

# Different desktop environments and window managers
if [[ $environment == dwm ]]; then
	# Notification daemon
	dunst &
	glava --desktop &
	# Start trayer (if not running dwm systray patch)
	# trayer --transparent true --alpha 204 --monitor "secondary" --heighttype percent --height 15 --widthtype percent --width 15 --edge bottom --distance 0 --distancefrom left --distance 814 &
	# trayer --transparent true --alpha 204 --monitor "secondary" --heighttype percent --height 20 --widthtype percent --width 15 --edge top --distance 20 &

	# Start dwmblocks
	#/home/hoswoo/Sources/dwm-bar/dwm_bar.sh &
	~/Sources/dwmblocks/dwmblocks &

	# Compositor
	# picom -f &
	xcompmgr rofi &

	# Wallpaper
	feh '/home/hoswoo/Pictures/Wallpapers/aurian.jpg' --bg-fill --no-xinerama &

	# Fancy conky stuff
	# conky -c ~/Accuweather_conky_script/.conkyrc_acc_images_2016 &  # Broke this somehow
	conky -c ~/Scripts/Conky/SysMonScript/SweetDarkConky1.rc &
	conky -c ~/Scripts/Conky/SysMonScript/SweetDarkConky2.rc &
	/home/hoswoo/Scripts/Conky/now-clocking/start.sh &

	exec dwm
fi

if [[ $environment == kde ]]; then
	# Both of these lines are needed for KDE-plasma
	export DESKTOP_SESSION=plasma
	exec startplasma-x11
fi

if [[ $environment == cinnamon ]]; then
	exec cinnamon-session
fi




