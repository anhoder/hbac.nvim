local state = require("hbac.state")
local config = require("hbac.config")

local M = {}

M.get_listed_buffers = function()
	return vim.tbl_filter(function(bufnr)
		return vim.api.nvim_buf_get_option(bufnr, "buflisted")
	end, vim.api.nvim_list_bufs())
end

M.buf_autoclosable = function(bufnr)
	local current_buf = vim.api.nvim_get_current_buf()
	if state.is_pinned(bufnr) or bufnr == current_buf then
		return false
	end
	local buffer_windows = vim.fn.win_findbuf(bufnr)
	if #buffer_windows > 0 and not config.values.close_buffers_with_windows then
		return false
	end
	return true
end

-- Buffer sorted by current > pinned > is_in_window > named > unnamed
M.sort_by = function(a, b)
	local current_buf = vim.api.nvim_get_current_buf()
	if a == current_buf or b == current_buf then
		return b == current_buf
	end
	if state.is_pinned(a) ~= state.is_pinned(b) then
		return state.is_pinned(b)
	end

	local a_windowed = #(vim.fn.win_findbuf(a)) > 0
	local b_windowed = #(vim.fn.win_findbuf(b)) > 0
	if a_windowed ~= b_windowed then
		return b_windowed
	end

	local a_unnamed = vim.api.nvim_buf_get_name(a) == ""
	local b_unnamed = vim.api.nvim_buf_get_name(b) == ""
	if a_unnamed ~= b_unnamed then
		return a_unnamed
	end

	return a < b
end

return M
