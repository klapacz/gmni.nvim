local Job = require'plenary.job'
local api = vim.api
local M = {}

function M.get(url)
	Job:new({
		command = 'gmni',
		args = { '-j', 'always', url },
		on_exit = vim.schedule_wrap(function(j, result)
			local lines = j:result()

			-- create new tab and get buffer id
			api.nvim_command("tabnew")
			local bufnr = api.nvim_win_get_buf(0)

			api.nvim_buf_set_lines(bufnr, 0, #lines, false, lines)
		end),
	}):start()
end

return M
