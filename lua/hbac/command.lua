local state = require("hbac.state")
local autocommands = require("hbac.autocommands")

local M = {
	subcommands = {},
}

M.subcommands.close_unpinned = function()
	local curbufnr = vim.api.nvim_get_current_buf()
	local buflist = vim.api.nvim_list_bufs()
	for _, bufnr in ipairs(buflist) do
		if vim.bo[bufnr].buflisted and bufnr ~= curbufnr and not state.is_pinned(bufnr) then
			require("hbac.setup").opts.close_command(bufnr)
		end
	end
	print("Hbac: Closed unpinned buffers")
end

M.subcommands.toggle_pin = function()
	local bufnr = vim.api.nvim_get_current_buf()
	print("Hbac: Buffer " .. bufnr .. " " .. state.toggle_pin(bufnr))
end

M.subcommands.toggle_autoclose = function()
	if state.autoclose_enabled then
		state.autoclose_enabled = false
		autocommands.autoclose.disable()
		print("Hbac: Autoclose disabled")
	else
		state.autoclose_enabled = true
		autocommands.autoclose.setup()
		print("Hbac: Autoclose enabled")
	end
end

M.vim_cmd_name = "Hbac"

M.vim_cmd_func = function(arg)
	if M.subcommands[arg] then
		M.subcommands[arg]()
	else
		print("Unknown Hbac command:", arg)
	end
end

M.vim_cmd_opts = {
	nargs = 1,
	complete = function()
		return { unpack(vim.tbl_keys(M.subcommands)) }
	end,
}

return M