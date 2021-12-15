local log = require('gmni.log')
local Job = require('plenary.job')

local api = vim.api

local function edit(path)
	log.info("BufReadCmd: ", path)

	local bufnr = vim.api.nvim_get_current_buf()
	api.nvim_buf_set_name(bufnr, path)

	Job:new({
		command = 'gmni',
		args = { '-j', 'always', path },
		on_exit = vim.schedule_wrap(function(j, _)
			local contents = j:result()

			api.nvim_buf_set_option(bufnr, 'modifiable', true)
			api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
			api.nvim_buf_set_option(bufnr, 'modifiable', false)
		end),
	}):start()
end

return {
	edit = edit,
}

