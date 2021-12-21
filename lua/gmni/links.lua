local urltools = require('socket.url')
local log = require('gmni.log')

local api = vim.api

local function open(new_url, base_url)
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

local function enter_link()
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

	open(segments[1])
end

return {
	open = open,
	enter_link = enter_link,
}
