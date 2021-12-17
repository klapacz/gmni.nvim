local api = vim.api

local function load_to_buf(bufnr, content)
	api.nvim_buf_set_option(bufnr, 'modifiable', true)
	api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
	api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

local function popup_options(text)
	return {
		relative = "cursor",
		position = {
			row = 0,
			col = 0,
		},
		border = {
			style = "rounded",
			highlight = "FloatBorder",
			text = {
				top = text,
				top_align = "center",
			},
		},
		highlight = "Normal:Normal",
	}
end

local function menu_options(callback, lines)
	return {
		lines = lines,
		keymap = {
			focus_next = { "j", "<tab>" },
			focus_prev = { "k", "<s-tab>" },
			close = { "<Esc>" },
			submit = { "<CR>" },
		},
		min_width = 20,
		on_close = callback,
		on_submit = callback,
	}
end

return {
	load_to_buf = load_to_buf,
	popup_options = popup_options,
	menu_options = menu_options,
}

