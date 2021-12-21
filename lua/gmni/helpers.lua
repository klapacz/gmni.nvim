local api = vim.api
local config = require('gmni.config')

local function load_to_buf(bufnr, content)
	api.nvim_buf_set_option(bufnr, 'modifiable', true)
	api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
	api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

local action_name_to_cmd = {
	enter_link = '<cmd>lua require("gmni").enter_link()<cr>',
	next_link = '<cmd>call GmniNextLink()<cr>',
	prev_link = '<cmd>call GmniPrevLink()<cr>',
}

local function set_buf_keymaps(bufnr)
	for action, mapping in pairs(config.config.keymaps) do
		local cmd = action_name_to_cmd[action]

		vim.api.nvim_buf_set_keymap(bufnr, 'n', mapping, cmd, {
			silent = true,
			noremap = true,
		})
	end
end

return {
	load_to_buf = load_to_buf,
	set_buf_keymaps = set_buf_keymaps,
}

