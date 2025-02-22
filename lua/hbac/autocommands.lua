local state = require("hbac.state")
local utils = require("hbac.utils")
local config = require("hbac.config")

-- 第一次不处理
local first_run = true

local M = {
	autoclose = {
		name = "hbac_autoclose",
	},
	autopin = {
		name = "hbac_autopin",
	},
}

M.autoclose.setup = function()
	state.autoclose_enabled = true
	vim.api.nvim_create_autocmd({ "BufReadPost" }, {
		group = vim.api.nvim_create_augroup(M.autoclose.name, { clear = true }),
		pattern = { "*" },
		callback = function()
			if first_run then
				first_run = false
				return
			end
			local current_buf = vim.api.nvim_get_current_buf()
			local buftype = vim.api.nvim_buf_get_option(current_buf, "buftype")
			-- if the buffer is not a file - do nothing
			if buftype ~= "" then
				return
			end

			local buffers = vim.tbl_filter(function(buf)
				-- Filter out buffers that are not listed
				return vim.api.nvim_buf_get_option(buf, "buflisted")
			end, vim.api.nvim_list_bufs())
			local num_buffers = #buffers
			if num_buffers <= config.values.threshold then
				return
			end

			local buffers_to_close = num_buffers - config.values.threshold

			-- Buffer sorted by current > pinned > is_in_window > named > unnamed
			table.sort(buffers, utils.sort_by)

			local reserved_num = config.values.reserved_unedited_num or 1
			for i = 1, buffers_to_close, 1 do
				local buffer = buffers[i]
				if not utils.buf_autoclosable(buffer) then
					goto continue
				elseif reserved_num > 0 then
					reserved_num = reserved_num - 1
				else
					config.values.close_command(buffer)
				end
				::continue::
			end
		end,
	})
end

M.autoclose.disable = function()
	-- pcall failure likely indicates that augroup doesn't exist - which is fine, since its
	-- autocmds is effectively disabled in that case
	pcall(function()
		vim.api.nvim_del_augroup_by_name(M.autoclose.name)
	end)
end

M.autopin.setup = function()
	local id = vim.api.nvim_create_augroup(M.autopin.name, {
		clear = false,
	})
	vim.api.nvim_create_autocmd({ "BufRead" }, {
		group = id,
		pattern = { "*" },
		callback = function()
			vim.api.nvim_create_autocmd({ "InsertEnter", "BufModifiedSet", "BufWrite" }, {
				buffer = 0,
				once = true,
				callback = function()
					local bufnr = vim.api.nvim_get_current_buf()
					if state.is_pinned(bufnr) then
						return
					end
					state.toggle_pin(bufnr)
				end,
			})
		end,
	})
	vim.api.nvim_create_autocmd({ "BufDelete" }, {
		group = id,
		pattern = { "*" },
		callback = function(event)
			if not state.is_pinned(event.buf) then
				return
			end
			state.toggle_pin(event.buf)
		end,
	})
end

return M
