local request = require('gmni.request')
local links = require('gmni.links')
local config = require('gmni.config')

return {
	request = request,
	enter_link = links.enter_link,
	setup = config.setup,
}
