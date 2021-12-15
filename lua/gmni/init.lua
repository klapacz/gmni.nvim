local log = require('gmni.log')
local Job = require('plenary.job')

local api = vim.api

local function follow_link()
	log.info("follow link")
end

local function edit(url)
	local bufnr = vim.api.nvim_get_current_buf()
	api.nvim_buf_set_name(bufnr, url)

	Job:new({
		command = 'gmni',
		args = { '-j', 'always', url },
		on_exit = vim.schedule_wrap(function(j, status)
			log.info("Status: ", status)
			log.info("Path: ", url)
			local contents = j:result()

			api.nvim_buf_set_option(bufnr, 'modifiable', true)
			api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
			api.nvim_buf_set_option(bufnr, 'modifiable', false)
			api.nvim_buf_set_option(bufnr, 'filetype', 'gemtext')

			api.nvim_buf_set_keymap(bufnr, 'n', '<cr>', '<cmd>lua require("gmni").follow_link()<cr>', { silent = true })
			api.nvim_buf_set_keymap(bufnr, 'n', '<tab>', '/^=><cr>w<cmd>noh<cr>', { silent = true })
			api.nvim_buf_set_keymap(bufnr, 'n', '<s-tab>', '?^=><cr>nw<cmd>noh<cr>', { silent = true })
		end),
	}):start()
end

return {
	edit = edit,
	follow_link = follow_link,
}

