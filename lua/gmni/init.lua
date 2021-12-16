local log = require('gmni.log')
local url_parser = require('gmni.url')
local Job = require('plenary.job')

local api = vim.api

local function follow_link()
	local line = api.nvim_get_current_line()
	local raw_url = vim.split(line, "%s")[2]
	local url = url_parser.parse(raw_url)

	if url.scheme == "gemini" then
		api.nvim_command(":e " .. raw_url)
		return
	end

	-- relative urls
	if url.scheme == nil then
		local curr_url = url_parser.parse(api.nvim_buf_get_name(0))
		local resolved = curr_url:resolve(raw_url)
		api.nvim_command(":e " .. resolved)
	end
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
	follow_link = follow_link,
	edit = edit,
}

