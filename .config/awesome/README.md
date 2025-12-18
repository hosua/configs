# Awesome WM Configuration

## Layouts

This document provides comprehensive descriptions of all available layouts in AwesomeWM, including both the built-in `awful.layout.suit` layouts and the additional layouts provided by the `lain` library.

### Switching Between Layouts

- **Next layout**: `Mod4 + Space`
- **Previous layout**: `Mod4 + Shift + Space`

Layouts are defined in `rc.lua` in the `awful.layout.layouts` array. You can cycle through all enabled layouts using the keybindings above.

---

## Awful Layouts (`awful.layout.suit`)

### Tile Layouts

Tile layouts divide the screen into a main area (master) and a stacking area (slaves). The master area typically contains one or more windows, while new windows are placed in the stacking area.

#### `awful.layout.suit.tile`
**Default tile layout** - Main area on the left, stacking area on the right.

- Master window(s) occupy the left side
- New windows are stacked vertically on the right
- Adjust master width with `Mod4 + Alt + h/l`
- Adjust number of master clients with `Mod4 + Shift + h/l`

#### `awful.layout.suit.tile.left`
**Left tile layout** - Similar to default tile, with main area on the left.

- Master window(s) on the left
- Slaves stacked on the right
- Useful for workflows where the primary window should be on the left side

#### `awful.layout.suit.tile.bottom`
**Bottom tile layout** - Main area at the bottom, stacking area at the top.

- Master window(s) occupy the bottom portion
- Slaves are stacked horizontally at the top
- Good for terminal-heavy workflows where you want the main window at the bottom

#### `awful.layout.suit.tile.top`
**Top tile layout** - Main area at the top, stacking area at the bottom.

- Master window(s) occupy the top portion
- Slaves are stacked horizontally at the bottom
- Useful when you want the primary window at the top

### Floating Layout

#### `awful.layout.suit.floating`
**Floating layout** - All windows float and can be moved/resized freely.

- Windows are not tiled and can overlap
- Each window can be positioned and sized independently
- Similar to traditional window managers
- **Note**: This layout can cause windows to stack on top of each other, which may be undesirable. Consider removing it from your layouts array if you prefer tiling behavior.

### Fair Layouts

Fair layouts distribute windows to give them equal space, making efficient use of screen real estate.

#### `awful.layout.suit.fair`
**Fair layout** - Distributes windows equally in a grid-like pattern.

- All windows get approximately equal space
- Windows are arranged in a balanced grid
- Automatically adjusts as windows are added or removed
- Good for when you want all windows to have equal importance

#### `awful.layout.suit.fair.horizontal`
**Horizontal fair layout** - Similar to fair, but arranges windows horizontally.

- Windows are distributed horizontally with equal space
- Better for wide screens or when you prefer horizontal arrangement
- Useful for comparing multiple windows side-by-side

### Spiral Layouts

Spiral layouts arrange windows in a spiral pattern, with window sizes decreasing as you move outward.

#### `awful.layout.suit.spiral`
**Spiral layout** - Arranges windows in a spiral pattern.

- Windows are arranged in a spiral starting from the center
- Each subsequent window is placed in the next position of the spiral
- Creates an interesting visual arrangement
- Window sizes may vary based on position in the spiral

#### `awful.layout.suit.spiral.dwindle`
**Dwindle spiral layout** - Spiral layout where window sizes decrease progressively.

- Similar to spiral, but with a more pronounced size reduction
- The focused window is typically larger
- Creates a "dwindling" effect as you move through the spiral
- Good for visual hierarchy where the focused window should stand out

### Max Layouts

Max layouts maximize windows, typically showing one window at a time in fullscreen or near-fullscreen mode.

#### `awful.layout.suit.max`
**Max layout** - Maximizes all windows, displaying one at a time.

- Each window takes up the full screen (or nearly full screen)
- Only one window is visible at a time
- Switching between windows shows them maximized
- Good for focused work on a single application

#### `awful.layout.suit.max.fullscreen`
**Fullscreen max layout** - Similar to max, but without borders or gaps.

- Windows are displayed in true fullscreen mode
- No borders or gaps between windows
- Maximum screen real estate usage
- Best for immersive applications or presentations

### Magnifier Layout

#### `awful.layout.suit.magnifier`
**Magnifier layout** - Enlarges the focused window while keeping others visible.

- The focused window is magnified/enlarged
- Other windows remain visible but smaller
- Useful for detailed work on one window while monitoring others
- The magnified window can be adjusted in size

### Corner Layouts

Corner layouts place the master client in a specified corner, with other clients arranged around it.

#### `awful.layout.suit.corner.nw`
**Northwest corner layout** - Master client in the top-left corner.

- Master window is positioned in the top-left corner
- Other windows are arranged around it
- Good for workflows where the primary window should be in the top-left

#### `awful.layout.suit.corner.ne`
**Northeast corner layout** - Master client in the top-right corner.

- Master window is positioned in the top-right corner
- Other windows fill the remaining space
- Useful for right-to-left reading workflows or specific monitor setups

#### `awful.layout.suit.corner.sw`
**Southwest corner layout** - Master client in the bottom-left corner.

- Master window is positioned in the bottom-left corner
- Other windows are arranged above and to the right
- Good for terminal-heavy workflows

#### `awful.layout.suit.corner.se`
**Southeast corner layout** - Master client in the bottom-right corner.

- Master window is positioned in the bottom-right corner
- Other windows fill the remaining space
- Useful for specific monitor configurations or workflows

---

## Lain Layouts (`lain.layout`)

The `lain` library provides additional custom layouts that extend AwesomeWM's layout capabilities. These layouts offer unique window management strategies.

### Termfair Layouts

Termfair layouts restrict window sizes and arrange them in columns with equal width but variable height. They're particularly useful for terminal windows.

#### `lain.layout.termfair`
**Termfair layout** - Windows arranged in columns, left-aligned, with equal width.

- Each window has the same width but variable height
- Windows are left-aligned in columns
- New windows are placed in the leftmost column, pushing existing windows to the right
- Once a row is full, a new row is created above it
- Configurable with `nmaster` (number of columns) and `ncol` (rows per column)

**Configuration example:**
```lua
lain.layout.termfair.nmaster = 3  -- 3 columns
lain.layout.termfair.ncol = 1     -- 1 row per column
```

**Visual progression:**
```
(1 window)        (2 windows)      (3 windows)
+---+---+---+     +---+---+---+     +---+---+---+
| 1 |   |   | ->  | 2 | 1 |   | ->  | 3 | 2 | 1 |
+---+---+---+     +---+---+---+     +---+---+---+
```

#### `lain.layout.termfair.stable`
**Stable termfair layout** - Similar to termfair, but new rows are created below existing rows.

- Same column-based arrangement as termfair
- New rows are added below existing rows instead of above
- More stable/predictable window placement
- Windows don't shift upward as new ones are added

**Visual progression:**
```
(1 window)        (2 windows)      (3 windows)
+---+---+---+     +---+---+---+     +---+---+---+
| 1 |   |   | ->  | 1 | 2 |   | ->  | 1 | 2 | 3 |
+---+---+---+     +---+---+---+     +---+---+---+
```

#### `lain.layout.termfair.center`
**Centered termfair layout** - Termfair with fixed number of vertical columns, centered until `nmaster` columns are reached.

- Similar to termfair but with centered columns
- Columns are centered until there are `nmaster` columns
- After that, windows are stacked as slaves
- Up to `ncol` clients per column

**Visual progression:**
```
(1 window)        (2 windows)      (3 windows)
+---+---+---+     +-+---+---+-+   +---+---+---+
|   | 1 |   | ->  | | 1 | 2 | | -> | 1 | 2 | 3 |
+---+---+---+     +-+---+---+-+   +---+---+---+
```

### Cascade Layouts

Cascade layouts arrange windows in a cascading/overlapping pattern, similar to traditional window managers but with more control.

#### `lain.layout.cascade`
**Cascade layout** - All windows of a tag are cascaded (overlapping with offset).

- Windows are arranged with a cascading/overlapping effect
- Each window is offset from the previous one
- Configurable offset in X and Y directions
- Useful for managing many windows while keeping them all accessible

**Configuration example:**
```lua
lain.layout.cascade.offset_x = 64  -- Horizontal offset
lain.layout.cascade.offset_y = 16  -- Vertical offset
lain.layout.cascade.nmaster = 5    -- Reserve space for 5 windows
```

#### `lain.layout.cascade.tile`
**Cascade tile layout** - Combines tile layout with cascading in the slave column.

- Similar to `awful.layout.suit.tile`, but slaves are cascaded instead of tiled
- Master window(s) on the left (or controlled by `mwfact`)
- Additional windows cascade in a column on the right
- New windows are placed above old windows
- Can overlap master window or be separate based on `ncol` setting

**Configuration example:**
```lua
lain.layout.cascade.tile.offset_x = 2      -- Small horizontal offset
lain.layout.cascade.tile.offset_y = 32      -- Vertical offset (titlebar height)
lain.layout.cascade.tile.extra_padding = 5 -- Padding when overlapping
lain.layout.cascade.tile.nmaster = 5       -- Number of master windows
lain.layout.cascade.tile.ncol = 2          -- 1 = overlapping, 2+ = separate
```

**Features:**
- `ncol = 1`: Slave column overlaps master window (with `extra_padding` to show it's there)
- `ncol > 1`: Slave column doesn't overlap, placed separately
- `extra_padding`: Reduces master window size when overlapping is enabled, so you can see slave windows

### Centerwork Layouts

Centerwork layouts focus on a main working window in the center, with additional windows arranged around it as "satellites."

#### `lain.layout.centerwork`
**Centerwork layout** - Main window centered, additional windows arranged around it.

- Starts with one window centered horizontally
- This is your main working window
- Additional windows are placed on the left and right alternately
- Creates a "satellite" arrangement around the main window
- **Note**: Navigation can be confusing with default keybindings. Use `awful.client.focus.bydirection()` for better navigation.

**Visual representation:**
```
Single window:          Multiple windows:
+------------------+    +------------------+
|    +--------+    |    | +--+ +------+ +--+|
|    |        |    |    | |  | |      | |  ||
|    |  MAIN  |    | -> | |  | | MAIN | |  ||
|    |        |    |    | |  | |      | |  ||
|    +--------+    |    | +--+ +------+ +--+|
+------------------+    +------------------+
```

**Recommended keybindings:**
```lua
-- Use direction-based focus for better navigation
awful.key({ modkey }, "j", function()
    awful.client.focus.bydirection("down")
    if client.focus then client.focus:raise() end
end),
awful.key({ modkey }, "k", function()
    awful.client.focus.bydirection("up")
    if client.focus then client.focus:raise() end
end),
awful.key({ modkey }, "h", function()
    awful.client.focus.bydirection("left")
    if client.focus then client.focus:raise() end
end),
awful.key({ modkey }, "l", function()
    awful.client.focus.bydirection("right")
    if client.focus then client.focus:raise() end
end),
```

#### `lain.layout.centerwork.horizontal`
**Horizontal centerwork layout** - Same as centerwork, but main window expands horizontally.

- Main window expands horizontally instead of vertically
- Additional windows are placed above and below the main window
- Useful for rotated screens (90° rotation)
- Better for wide, short screens or portrait-oriented monitors

---

## Layout Configuration

### Setting Layouts

Layouts are configured in `rc.lua`:

```lua
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    -- Add more layouts as needed
}
```

### Layout-Specific Configuration

Some layouts (especially lain layouts) have configurable parameters:

```lua
-- Termfair configuration
lain.layout.termfair.nmaster = 3
lain.layout.termfair.ncol = 1

-- Cascade configuration
lain.layout.cascade.offset_x = 64
lain.layout.cascade.offset_y = 16
lain.layout.cascade.nmaster = 5

-- Cascade.tile configuration
lain.layout.cascade.tile.offset_x = 2
lain.layout.cascade.tile.offset_y = 32
lain.layout.cascade.tile.extra_padding = 5
lain.layout.cascade.tile.nmaster = 5
lain.layout.cascade.tile.ncol = 2
```

### Layout Icons

Layout icons are available in `lain/icons/layout/`. To use them in your theme:

```lua
theme.lain_icons = os.getenv("HOME") .. "/.config/awesome/lain/icons/layout/default/"
theme.layout_termfair = theme.lain_icons .. "termfair.png"
theme.layout_centerfair = theme.lain_icons .. "centerfair.png"
theme.layout_cascade = theme.lain_icons .. "cascade.png"
theme.layout_cascadetile = theme.lain_icons .. "cascadetile.png"
theme.layout_centerwork = theme.lain_icons .. "centerwork.png"
theme.layout_centerworkh = theme.lain_icons .. "centerworkh.png"
```

---

## Choosing the Right Layout

### For General Use
- **`tile`** or **`tile.left`**: Classic tiling, good for most workflows
- **`fair`**: When you want all windows to have equal space

### For Terminal-Heavy Work
- **`termfair`** or **`termfair.stable`**: Designed specifically for terminals
- **`tile.bottom`**: Keep main window at bottom, terminals above

### For Focused Work
- **`centerwork`**: One main window with supporting windows around it
- **`max`**: Full focus on one window at a time

### For Many Windows
- **`cascade`** or **`cascade.tile`**: Manage many windows with cascading
- **`fair`**: Distribute many windows equally

### For Visual Hierarchy
- **`spiral.dwindle`**: Focused window is larger
- **`magnifier`**: Focused window is magnified

### For Specific Screen Orientations
- **`centerwork.horizontal`**: For rotated/portrait screens
- **`tile.top`** or **`tile.bottom`**: Based on your preferred master position

---

## Tips

1. **Remove unwanted layouts**: If you accidentally switch to a layout you don't like (like `floating`), remove it from `awful.layout.layouts` to prevent cycling to it.

2. **Per-tag layouts**: You can set different layouts for different tags using `awful.layout.set()`.

3. **Master width factor**: Adjust the size of the master area in tile layouts with `Mod4 + Alt + h/l`.

4. **Number of masters**: Control how many windows are in the master area with `Mod4 + Shift + h/l`.

5. **Columns**: Adjust the number of columns in layouts that support it with `Mod4 + Control + h/l`.

6. **Test layouts**: Try different layouts to find what works best for your workflow. You can always cycle back if you don't like one.
