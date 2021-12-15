local Job = require('plenary.job')
local api = vim.api

local function get(url)
	Job:new({
		command = 'gmni',
		args = { '-j', 'always', url },
		on_exit = vim.schedule_wrap(function(j, result)
			local lines = j:result()

			api.nvim_command('tabnew')

			api.nvim_buf_set_lines(0, 0, #lines, false, lines)
			api.nvim_buf_set_name(0, url)

			api.nvim_buf_set_option(0, 'modifiable', false)
		end),
	}):start()
end

return {
	get = get,
}

