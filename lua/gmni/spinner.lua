local helpers = require('gmni.helpers')

local loading_buffers = {}
local spinner = {'|', '/', '-', '\\'}

local function spin(bufnr)
	if loading_buffers[bufnr] == nil then
		return
	end

	if loading_buffers[bufnr] > #spinner then
		loading_buffers[bufnr] = 1
	end
	helpers.load_to_buf(bufnr, { "Loading... " .. spinner[loading_buffers[bufnr]] })
	loading_buffers[bufnr] = loading_buffers[bufnr] + 1

	vim.defer_fn(function ()
		spin(bufnr)
	end, 150)
end

local function start(bufnr)
	loading_buffers[bufnr] = 1
	spin(bufnr)
end

local function stop(bufnr)
	loading_buffers[bufnr] = nil
end

return {
	start = start,
	stop = stop,
}
