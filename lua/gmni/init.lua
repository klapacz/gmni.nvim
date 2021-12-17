local trust_policy, request

local log = require('gmni.log')
local Job = require('plenary.job')
local urltools = require('socket.url')
local helpers = require('gmni.helpers')
local spinner = require('gmni.spinner')

local api = vim.api

local function goto_link(new_url, base_url)
	local parsed = urltools.parse(new_url)

	if parsed.scheme == "gemini" then
		api.nvim_command(":e " .. urltools.build(parsed))
		return
	end

	-- relative urls
	if parsed.scheme == nil then
		base_url = urltools.parse(base_url or api.nvim_buf_get_name(0))
		if base_url.path == nil then base_url.path = "/" end

		local absolute = urltools.absolute(
			urltools.build(base_url),
			urltools.build(parsed)
		)

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

local Menu = require("nui.menu")

local popup_options = {
	relative = "cursor",
	position = {
		row = 0,
		col = 0,
	},
	border = {
		style = "rounded",
		highlight = "FloatBorder",
		text = {
			top = "Trust?",
			top_align = "center",
		},
	},
	highlight = "Normal:Normal",
}

function trust_policy(bufnr, url, message)
	helpers.load_to_buf(bufnr, { message[1], message[2], "" })
	api.nvim_win_set_cursor(0, {3, 0})

	local function callback (item)
		if item == nil or item.text == "exit" then
			api.nvim_buf_delete(bufnr, {})
			return
		end

		request(url, { trust = item.text })
	end

	-- HACK: timer is needed to open menu in proper location
	vim.fn.timer_start(5, function ()
		Menu(popup_options, {
			relative = "cursor",
			lines = {
				Menu.item("always"),
				Menu.item("once"),
				Menu.item("exit"),
			},
			keymap = {
				focus_next = { "j", "<tab>" },
				focus_prev = { "k", "<s-tab>" },
				close = { "<Esc>" },
				submit = { "<CR>" },
			},
			min_width = 20,
			on_close = callback,
			on_submit = callback,
		}):mount()
	end)
end

function request(url, kwargs)
	kwargs = kwargs or {}

	local args = { '-iN' }
	local bufnr = vim.api.nvim_get_current_buf()
	api.nvim_buf_set_option(bufnr, 'swapfile', false)
	api.nvim_buf_set_option(bufnr, 'buftype', 'nowrite')
	spinner.start(bufnr)

	if kwargs.trust then
		table.insert(args, '-j')
		table.insert(args, kwargs.trust)
	end

	table.insert(args, url)
	Job:new({
		command = 'gmni',
		args = args,

		on_exit = vim.schedule_wrap(function(job, exit_code)
			spinner.stop(bufnr)
			if exit_code == 6 then
				trust_policy(bufnr, url, job:stderr_result())
				return
			end

			if exit_code ~= 0 then
				log.debug("`gmni` error:", unpack(job:stderr_result()))
				return
			end

			local result = job:result()
			local header = table.remove(result, 1)

			-- handle redirection
			if vim.startswith(header, "3") then
				local status_code, meta = unpack(vim.split(header, " "))
				log.warn("Redirection with code:", status_code, "to", meta)

				goto_link(meta, url)
				api.nvim_buf_delete(bufnr, {})
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

			-- other not success statuses
			if not vim.startswith(header, "2") then
				log.warn("gemini unsuccessful response:", header)
			end

			log.info("Status:", header)

			if string.find(header, "text/gemini") then
				api.nvim_buf_set_option(bufnr, 'filetype', 'gemtext')
			end

			helpers.load_to_buf(bufnr, result)

			api.nvim_buf_set_keymap(bufnr, 'n', '<cr>', '<cmd>lua require("gmni").follow_link()<cr>', { silent = true })
			api.nvim_buf_set_keymap(bufnr, 'n', '<tab>', '<cmd>call GmniNextLink()<cr>', { silent = true })
			api.nvim_buf_set_keymap(bufnr, 'n', '<s-tab>', '<cmd>call GmniPrevLink()<cr>', { silent = true })
		end),
	}):start()
end

return {
	follow_link = follow_link,
	request = request,
}

