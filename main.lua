display.setStatusBar(display.HiddenStatusBar)
display.setDefault('background', 1)

local json = require('json')
local composer = require('composer')
local gpgs = require('plugin.gpgs')

composer.recycleOnSceneChange = true -- Automatically remove scenes from memory

gpgs.init(function(event)
	print('Init event:', json.prettify(event))
	if not event.isError then
		-- Try to automatically log in the user without displaying the login screen if the user doesn't want to login
		gpgs.login({
			listener = function(event)
				print('Login event:', json.prettify(event))
			end
		})
	end
end)

-- Initialize randomizer
math.randomseed(os.time())

-- Show menu scene
composer.gotoScene('scenes.menu')
