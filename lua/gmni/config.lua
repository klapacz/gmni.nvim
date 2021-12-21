local config = {
	keymaps = {
		next_link = "<tab>",
		prev_link = "<s-tab>",
		enter_link = "<cr>",
	},
}


local function setup(user_config)
	user_config = user_config or {}
	config.keymaps = vim.tbl_deep_extend(
		"force",
		config.keymaps,
		user_config.keymaps or {}
	)
end

return {
	config = config,
	setup = setup,
}

