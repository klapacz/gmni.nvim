local log = require('gmni.log')
local url_parser = require('gmni.url')
local Job = require('plenary.job')

local api = vim.api

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

	local url = url_parser.parse(segments[1])

	if url.scheme == "gemini" then
		api.nvim_command(":e " .. url:normalize())
		return
	end

	-- relative urls
	if url.scheme == nil then
		local curr_url = url_parser.parse(api.nvim_buf_get_name(0))
		local resolved = curr_url:resolve(url:normalize())
		api.nvim_command(":e " .. resolved)
		return
	end

	log.warn("Not a gemini link.")
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

		on_exit = vim.schedule_wrap(function(job, status)
			if status == 6 then
				local stderr_result = job:stderr_result()
				local option = vim.fn.input("Trust " .. stderr_result[2] .. "? (always/once): ")
				load(url, { trust = option })
				return
			end

			if status ~= 0 then
				return
			end

			local result = job:result()
			local gemini_status = table.remove(result, 1)
			log.info("Status: ", status, gemini_status)

			if string.find(gemini_status, "text/gemini") then
				api.nvim_buf_set_option(bufnr, 'filetype', 'gemtext')
			end

			api.nvim_buf_set_option(bufnr, 'modifiable', true)
			api.nvim_buf_set_lines(bufnr, 0, -1, false, result)

			api.nvim_buf_set_option(bufnr, 'modifiable', false)
			api.nvim_buf_set_option(bufnr, 'readonly', true)
			api.nvim_buf_set_option(bufnr, 'swapfile', false)
			api.nvim_buf_set_option(bufnr, 'buftype', 'nowrite')

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

