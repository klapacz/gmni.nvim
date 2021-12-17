local helpers = require('gmni.helpers')

local loading_buffers = {}
local spinner = {'|', '/', '-', '\\'}

local function spin(bufnr)
	local loading = loading_buffers[bufnr]
	if loading == nil then
		return
	end

	if loading > #spinner then
		loading_buffers[bufnr] = 1
	end
	helpers.load_to_buf(bufnr, { "Loading... " .. spinner[loading] })
	loading_buffers[bufnr] = loading + 1

	vim.fn.timer_start(200, function ()
		spin(bufnr)
	end)
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
