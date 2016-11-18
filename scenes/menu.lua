-- Menu Scene

local json = require('json')
local composer = require('composer')
local widget = require('widget')
local gpgs = require('plugin.gpgs')

local snapshotFilename = 'snapshot1' -- A random name for a save slot

local scene = composer.newScene()

function scene:create()
	local group = self.view

	local w, h = 200, 64
	local _CX, _CY = display.contentCenterX, display.contentCenterY

	local playButton = widget.newButton({
		label = 'New Game',
		width = w, height = h,
		x = _CX, y = _CY - 200,
		onRelease = function()
			composer.gotoScene('scenes.game', {time = 500, effect = 'slideLeft'})
		end
	})
	group:insert(playButton)

	local loadButton = widget.newButton({
		label = 'Load Game',
		width = w, height = h,
		x = _CX, y = _CY - 100,
		onRelease = function()
			self:checkLogin(function() -- Check if the user is currently logged in and proceed
				gpgs.snapshots.open({ -- Open the save slot
					filename = snapshotFilename,
					listener = function(event)
						if not event.isError then
							local data = event.snapshot.contents.read() -- Read snapshot content and pass it to the game
							composer.gotoScene('scenes.game', {time = 500, effect = 'slideLeft', params = data})
						else
							native.showAlert('Snapshots', 'Can\'t open the snapshot ' .. snapshotFilename .. '.', {'OK'})
						end
					end
				})
			end)
		end
	})
	group:insert(loadButton)

	local saveButton = widget.newButton({
		label = 'Save Game',
		width = w, height = h,
		x = _CX, y = _CY,
		onRelease = function()
			local level = composer.getVariable('level') -- Get current game state
			if not level then -- If no data - don't proceed
				native.showAlert('Snapshots', 'Start a game first!', {'OK'})
				return
			end
			self:checkLogin(function() -- Check if the user is currently logged in and proceed
				gpgs.snapshots.open({ -- Open the save slot
					filename = snapshotFilename,
					create = true, -- Create the snapshot if it's not found
					listener = function(event)
						if not event.isError then
							event.snapshot.contents.write(json.encode(level)) -- Write new data as a JSON string into the snapshot
							gpgs.snapshots.save({
								snapshot = event.snapshot,
								description = 'Save slot ' .. snapshotFilename,
								progress = #level, -- Define the progress value as a number of objects on the screen
								playedTime = level.playedTime,
								listener = function(event)
									native.showAlert('Snapshots', 'Saving was ' .. (event.isError and 'unsuccessful' or 'successful') .. '.', {'OK'})
								end
							})
						else
							native.showAlert('Snapshots', 'Can\'t open the snapshot ' .. snapshotFilename .. '.', {'OK'})
						end
					end
				})
			end)
		end
	})
	group:insert(saveButton)

	local showButton = widget.newButton({
		label = 'Show Snapshots',
		width = w, height = h,
		x = _CX, y = _CY + 100,
		onRelease = function()
			self:checkLogin(function() -- Check if the user is currently logged in and proceed
				gpgs.snapshots.show({ -- Open the save slot
					title = 'Saved Games',
					disableAdd = true,
					disableDelete = true
				})
			end)
		end
	})
	group:insert(showButton)
end

-- Check if we are logged in and once logged in - call the listener
function scene:checkLogin(listener)
	if gpgs.isConnected() then
		listener()
	else
		gpgs.login({
			userInitiated = true,
			listener = function(event)
				if not event.isError then
					listener()
				else
					native.showAlert('Snapshots', 'There was a problem signing in: ' .. event.errorMessage, {'OK'})
				end
			end
		})
	end
end

scene:addEventListener('create')

return scene
