-- This file  needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
	theme = "onedark",

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

M.base46 = {
	-- Base46 is the theme engine; newer versions expect this table
	theme = "onedark",
	theme_toggle = { "bearded-arc" },
	transparency = false,
}

return M
