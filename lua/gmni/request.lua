local Job = require('plenary.job')
local helpers = require('gmni.helpers')
local spinner = require('gmni.spinner')
local log = require('gmni.log')
local links = require('gmni.links')

local api = vim.api

local function request(url, kwargs)
	kwargs = kwargs or {}

	local args = { '-iN' }
	local bufnr = api.nvim_get_current_buf()
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
				local message = job:stderr_result()
				vim.notify(message[1] .. "\n" ..  message[2], "warn")

				vim.ui.select({ "always", "once" }, { prompt =  "Trust?" }, function (item)
					if item == nil then
						api.nvim_buf_delete(bufnr, {})
						return
					end

					request(url, { trust = item })
				end)
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

				links.open(meta, url)
				api.nvim_buf_delete(bufnr, {})
				return
			end

			-- handle input
			if vim.startswith(header, "1") then
				local prompt = header:gsub("^1%d ", "")
				vim.ui.input(prompt .. ": ", function (query)
					if query == nil or query == "" then
						log.warn("Empty input, canceling.")
					else
						links.open("?" .. query, url)
					end
					api.nvim_buf_delete(bufnr, {})
				end)
				return
			end

			-- other not success statuses
			if not vim.startswith(header, "2") then
				log.warn("gemini unsuccessful response:", header)
			end

			log.info("Status:", header)

			if string.find(header, "text/gemini") then
				api.nvim_buf_set_option(bufnr, 'filetype', 'gemtext')
				helpers.set_buf_keymaps(bufnr)
			end

			helpers.load_to_buf(bufnr, result)
		end),
	}):start()
end

return request
