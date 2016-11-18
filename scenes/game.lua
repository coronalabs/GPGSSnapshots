-- Game Scene

local json = require('json')
local composer = require('composer')
local widget = require('widget')

local scene = composer.newScene()

function scene:create(event)
	local group = self.view

	self.objects = {}
	self.playedTime = 0
	self.startTime = system.getTimer()

	local _W, _H = display.actualContentWidth, display.actualContentHeight
	local _CX, _CY = display.contentCenterX, display.contentCenterY

	-- Capture touch events and create a random figure on touch
	local touchRect = display.newRect(group, _CX, _CY, _W, _H)
	local super = self
	function touchRect:touch(event)
		if event.phase == 'began' then
			super:addFigure({x = event.x, y = event.y})
		end
		return true
	end
	touchRect:addEventListener('touch')

	-- Save game state in a temporary variable and go to the menu
	local backButton = widget.newButton({
		label = 'Back',
		width = 128, height = 64,
		x = _CX, y = 32,
		onRelease = function()
			local level = {figures = {}} -- Create a new table and insert into it all figures position, shape and color
			for i = 1, #self.objects do
				local o = self.objects[i]
				table.insert(level.figures, {x = o.x, y = o.y, shape = o.shape, color = table.copy(o.color)})
			end
			level.playedTime = self.playedTime + (system.getTimer() - self.startTime) / 1000
			composer.setVariable('level', level) -- Store the game state inside composer
			composer.gotoScene('scenes.menu', {time = 500, effect = 'slideRight'})
		end
	})
	group:insert(backButton)

	-- We have got a saved data, parse it
	if event.params then
		local level = json.decode(event.params) -- Turn JSON string into a Lua table with figures data
		self.playedTime = level.playedTime
		for i = 1, #level.figures do
			self:addFigure(level.figures[i]) -- Recreate each figure
		end
	end
end

-- The game is just a collection of some figures
function scene:addFigure(params)
	local group = self.view

	local shape = params.shape or math.random(1, 3) -- Random shape for the figure or restore from params
	local color = params.color or {math.random(), math.random(), math.random()} -- Random color for the figure or restore from params
	local size = 64

	local figure

	if shape == 1 then -- Circle
		figure = display.newCircle(group, params.x, params.y, size / 2)
	elseif shape == 2 then -- Square
		figure = display.newRect(group, params.x, params.y, size, size)
	else -- Diamond
		figure = display.newRect(group, params.x, params.y, size, size)
		figure.rotation = 45
	end

	figure:setFillColor(unpack(color)) -- Apply the color
	figure.shape = shape -- Save shape and color for later use
	figure.color = color

	-- Enable moving figures by touch
	function figure:touch(event)
		if event.phase == 'began' then
			self.xStart = event.xStart
			self.yStart = event.yStart
			display.getCurrentStage():setFocus(self)
			self.isFocused = true
		elseif self.isFocused then
			if event.phase == 'moved' then
				self.x = self.xStart + event.x - event.xStart
				self.y = self.yStart + event.y - event.yStart
			else
				display.getCurrentStage():setFocus(nil)
				self.isFocused = false
			end
		end
		return true
	end
	figure:addEventListener('touch')

	table.insert(self.objects, figure)

	return figure
end

scene:addEventListener('create')

return scene
