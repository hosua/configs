
/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int gappx     = 4;        /* gaps between windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayonleft = 0;   	/* 0: systray in the right corner, >0: systray on left of status text */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray        = 1;     /* 0 means no systray */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[] = {"Liberation Mono:size=10:antialias=true:autohint=true",
                                  "Hack:size=9:antialias=true:autohint=true",
                                  "JoyPixels:size=10:antialias=true:autohint=true"};
static const char dmenufont[]       = "monospace:size=10";

/* Color scheme */
static const char col_1[]  = "#282A36"; /* background color of bar */
static const char col_2[]  = "#282A36"; /* border color unfocused windows */
static const char col_3[]  = "#F8F8F2";
static const char col_4[]  = "#2D59A6"; /* border color focused windows and tags */
/* Colors I like 
#66000 - Blood Red 
#2A72BF - Blue 1
#2D59A6 - Blue 2
#712DA6 - Purple
*/

static const char *colors[][3]        = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_3, col_1, col_2 },
	[SchemeSel]  = { col_3, col_4, col_4 },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           -1 },
	{ "Firefox",  NULL,       NULL,       1 << 8,       0,           -1 },
};


/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ NULL,       NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[]    = { "dmenu_run", "-p", "Run: ", NULL };
static const char *termcmd[]  = { "st", NULL };

/* Added functions */
static const char *screenshot[] = {"escrotum", "/home/hoswoo/Pictures/Screenshots/IMG.jpg", "-s", NULL };
static const char *powermenu[] = { "/home/hoswoo/Scripts/powermenu.sh", NULL };
static const char *gamemenu[] = { "/home/hoswoo/Scripts/gamemenu.sh", NULL };
#define CMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }


static Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY|ShiftMask,             XK_Return, spawn,          {.v = dmenucmd} },
	{ MODKEY, 			            XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY|ShiftMask,             XK_j,      rotatestack,    {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_k,      rotatestack,    {.i = -1 } },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },

	/* Layout manipulation */
	{ MODKEY,                       XK_Tab,    cyclelayout,    {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_Tab,    cyclelayout,    {.i = +1 } },
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },

	/* Monitor navigation */
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_period,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_comma, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_period,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_comma, tagmon,         {.i = +1 } },
	/* Workspace selection */
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)

	/* Quit and restart */
	{ MODKEY|ShiftMask,             XK_minus,      quit,           {0} },
	{ MODKEY|ShiftMask, 			XK_r,      quit,           {1} }, 

	/* Keybinds for specific programs and dmenus (All use SUPER + ALT + "key") */
	{ MODKEY|Mod1Mask,              XK_f,      spawn,          CMD("pcmanfm") },	
	{ MODKEY|Mod1Mask,              XK_n,      spawn,          CMD("nm-connection-editor") },
	{ 0,							XK_Print,	spawn,	{.v = screenshot } },
	//{ MODKEY|Mod1Mask,			XK_c,		spawn,	CMD("qalculate-gtk") },
	{ MODKEY|Mod1Mask,			XK_c,		spawn,	CMD("qalculate-qt") },
	{ MODKEY|Mod1Mask,          XK_b,      spawn,          CMD("firefox") },
	{ MODKEY|Mod1Mask,			XK_p,	spawn,		{.v = powermenu } },
	{ MODKEY|Mod1Mask,			XK_g,	spawn,		{.v = gamemenu } },
	{ MODKEY|Mod1Mask,			XK_d,	spawn,		CMD("discord") },
	{ MODKEY|Mod1Mask,			XK_r,	spawn,		CMD("runelite") },
	{ MODKEY|Mod1Mask,			XK_o,	spawn,		CMD("libreoffice") },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
 
