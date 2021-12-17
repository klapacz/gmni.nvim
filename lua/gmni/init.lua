local log = require('gmni.log')
local Job = require('plenary.job')
local urltools = require('socket.url')

local api = vim.api

local function goto_link(raw_url, base_url)
	local parsed = urltools.parse(raw_url)

	if parsed.scheme == "gemini" then
		api.nvim_command(":e " .. urltools.build(parsed))
		return
	end

	-- relative urls
	if parsed.scheme == nil then
		base_url = base_url or api.nvim_buf_get_name(0)
		local absolute = urltools.absolute(base_url, raw_url)

		api.nvim_command(":e " .. absolute)
		return
	end

	log.warn("Not a gemini link.")
end

local function follow_link()
	local line = api.nvim_get_current_line()

	if not vim.startswith(line, "=>") then
		log.warn("Not link line.")
		return
	end

	line = line:gsub("^=>", "")
	local segments = vim.split(line, "%s", {trimempty = true})

	if #segments < 1 then
		log.warn("Link not provided.")
		return
	end

	goto_link(segments[1])
end

local function load_to_buf(bufnr, content)
	api.nvim_buf_set_option(bufnr, 'modifiable', true)
	api.nvim_buf_set_option(bufnr, 'readonly', false)

	api.nvim_buf_set_lines(bufnr, 0, -1, false, content)

	api.nvim_buf_set_option(bufnr, 'modifiable', false)
	api.nvim_buf_set_option(bufnr, 'readonly', true)
	api.nvim_buf_set_option(bufnr, 'swapfile', false)
	api.nvim_buf_set_option(bufnr, 'buftype', 'nowrite')
end

local function load(url, kwargs)
	kwargs = kwargs or {}

	local args = { '-iN' }
	local bufnr = vim.api.nvim_get_current_buf()
	-- Does next line do anything?
	api.nvim_buf_set_name(bufnr, url)

	if kwargs.trust then
		table.insert(args, '-j')
		table.insert(args, kwargs.trust)
	end

	table.insert(args, url)
	Job:new({
		command = 'gmni',
		args = args,

		on_exit = vim.schedule_wrap(function(job, exit_code)
			if exit_code == 6 then
				local stderr_result = job:stderr_result()
				local option = vim.fn.input("Trust " .. stderr_result[2] .. "? (always/once): ")
				load(url, { trust = option })
				return
			end

			if exit_code ~= 0 then
				log.debug("Error: ", unpack(job:stderr_result()))
				return
			end

			local result = job:result()
			local header = table.remove(result, 1)

			-- handle redirection
			if vim.startswith(header, "3") then
				local status_code, meta = unpack(vim.split(header, " "))
				log.warn("Redirection with code:", status_code, "to", meta)

				goto_link(meta, url)
				api.nvim_buf_delete(bufnr)
				return
			end

			-- handle input
			if vim.startswith(header, "1") then
				local prompt = header:gsub("^1%d ", "") .. ": "
				local query = vim.fn.input(prompt)

				if query ~= "" then
					goto_link("?" .. query, url)
				else
					log.warn("Empty search query, canceling.")
				end
				api.nvim_buf_delete(bufnr, {})
				return
			end

			log.info("Status: ", exit_code, header)

			if string.find(header, "text/gemini") then
				api.nvim_buf_set_option(bufnr, 'filetype', 'gemtext')
			end

			load_to_buf(bufnr, result)

			api.nvim_buf_set_keymap(bufnr, 'n', '<cr>', '<cmd>lua require("gmni").follow_link()<cr>', { silent = true })
			api.nvim_buf_set_keymap(bufnr, 'n', '<tab>', '<cmd>call GmniNextLink()<cr>', { silent = true })
			api.nvim_buf_set_keymap(bufnr, 'n', '<s-tab>', '<cmd>call GmniPrevLink()<cr>', { silent = true })
		end),
	}):start()
end

return {
	follow_link = follow_link,
	load = load,
}

