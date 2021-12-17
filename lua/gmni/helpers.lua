local api = vim.api

local function load_to_buf(bufnr, content)
	api.nvim_buf_set_option(bufnr, 'modifiable', true)
	api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
	api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

return {
	load_to_buf = load_to_buf,
}

