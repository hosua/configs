//Modify this file to change what commands output to your statusbar, and recompile using the make command.


static const Block blocks[] = {
	/*Icon*/	/*Command*/		/*Update Interval*/	/*Update Signal*/
	//{"🔋 ", "cat /sys/class/power_supply/BAT[0-9]/capacity | awk '{print $1\"%\"}'", 	10, 	0},
	{"", "echo ''", 1, 0},
	{"RAM:", "free -h | awk '/^Mem/ { print $3\"/\"$2 }' | sed s/i//g",	1,		0},
	{"CPU:", "top -bn1 | grep Cpu | awk '{print $2\"%\"}'", 	1, 		0},
	{"STO:", "df -h /home | tail -n 1 | awk '{print $3\"/\"$2}'",		5,		0},
	{"", "/home/hoswoo/Scripts/weather.sh",					10,		0},
	// {"☀️ ", "xbacklight -get | awk '{print $1\"%\"}'", 1, 	0},
	// {"", "/home/hoswoo/Scripts/battery.sh", 	1, 	0},
	{"", "/home/hoswoo/Scripts/vol.sh", 1, 0},
	// {"", "/home/hoswoo/Scripts/wifisignal.sh", 	1, 	0}, 
	{"📆 ", "date '+%b %d, %Y (%a) 🕒 %I:%M %p'",		5,		0},
	// Blank block to add a delimiter between systray and the previous block
	{"", "echo ''", 1, 0},

};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = " | ";
static unsigned int delimLen = 5;
