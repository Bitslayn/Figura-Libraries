--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Color Wheel v1.1

Github: https://github.com/Bitslayn/FOX-s-Figura-APIs/blob/main/Utilities/ColorWheel
]]

--==============================================================================================================================
--#REGION ˚♡ Setup ♡˚
--==============================================================================================================================

-- Create GUI root
local root = models:newPart("root", "Gui"):visible(false)

-- Create texture
local TAU = math.pi * 2
local txtr = textures:newTexture("FOXCW", 7, 7)

	-- Draw hue ring
	:applyFunc(0, 0, 7, 7, function(_, x, y)
		x = x / 7 - 0.5
		y = y / 7 - 0.5
		local angle = math.atan2(x, -y)
		return vectors.hsvToRGB(angle / TAU, 1, 1):augmented(1)
	end)
	:fill(2, 2, 3, 3, vec(0, 0, 0, 0))

	-- Draw sat/val graph
	:pixel(2, 2, vec(1, 1, 1))
	:applyFunc(3, 2, 2, 2, function() return vec(1, 0, 0, 1) end)
	:fill(2, 3, 2, 1, vec(0, 0, 0))
	:update()

-- models:newPart("test", "Gui"):newSprite(""):texture(txtr, 7, 7):size(100, 100)

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Widgets ♡˚
--==============================================================================================================================

---Creates the hue ring
---@param sides integer
---@param radius number
---@param weight number
local function hue(sides, radius, weight)
	-- Create points
	---@type Vector2[]
	local points = {}
	for i = 1, sides do
		local rad = math.rad(360 / sides * i)
		points[i] = vec(math.sin(rad), math.cos(rad))
	end

	-- Create polygon
	local dim = txtr:getDimensions()
	local pad = (dim - 1) / dim
	for s = 1, sides do
		---@type Vector2[]
		local uvs = { points[s] * weight, points[s], points[s % sides + 1], points[s % sides + 1] * weight }
		local sprite = root:newSprite("" .. s)
			:texture(txtr)
			:renderType("BLURRY")

		for i, vert in ipairs(sprite:getVertices()) do
			local uv = -uvs[i]
			vert:pos(uv.xy_ * radius)
				:uv(uv * pad / 2 + 0.5)
		end
	end
end

-- Create hue ring
hue(12, 50, 0.8)

-- Create sat/val graph
root:newSprite("g")
	:texture(txtr, 7, 7)
	:pos(24, 24)
	:size(48, 48)
	:uvPixels(2.5, 2.5)
	:region(1, 1)
	:renderType("BLURRY")

-- Create selected color preview
root:newSprite("s")
	:texture(txtr, 7, 7)
	:pos(-60, 50)
	:size(30, 30)
	:uvPixels(5, 3)
	:region(0, 0)

-- Create previous color preview
root:newSprite("p")
	:texture(txtr, 7, 7)
	:pos(-60, 20)
	:size(30, 30)
	:uvPixels(5, 4)
	:region(0, 0)

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Handles ♡˚
--==============================================================================================================================

---Creates and returns a new point
---@return ModelPart
local function point()
	local part = root:newPart("point")

	-- Inner circle
	part:newText("" .. 1)
		:text("⚬")
		:scale(2)
		:pos(2.5, 11.5)

	-- Outer circle
	part:newText("" .. 2)
		:text("{text = ⚪, color = black}")
		:scale(2)
		:pos(3.5, 11.5)

	return part
end

-- Create handles
local hue_point = point():pos(0, 45)
local sv_point = point():pos(-24, 24)

-- Create color code text
local hue_text = root:newText("t")
	:text("#FF0000\nH: 0.00°\nS: 100.00%\nV: 100.00%")
	:pos(-60, -13)
local function hue_format(hsv)
	local hex = vectors.rgbToHex(vectors.hsvToRGB(hsv)):upper()
	local h, s, v = (hsv * vec(360, 100, 100)):unpack()
	hue_text:text(("#%s\nH: %.02f°\nS: %.02f%%\nV: %.02f%%"):format(hex, h, s, v))
end

-- Hue handle math
local a = math.cos(math.pi / 12)
local function g(x) return a / math.cos(x * math.pi / 12) end
local function hue_update(h)
	local rad = math.rad(360 * h)
	local dist = 45 * g(math.fmod(h * 12, 1) * 2 - 1)
	hue_point:pos(-math.sin(rad) * dist, math.cos(rad) * dist)
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Mouse Click ♡˚
--==============================================================================================================================

local pos = vec(0, 0)
local scale = 1
local color = vec(1, 1, 1)

local click = keybinds:of("FOXColorPicker - Click", "key.mouse.left", true):enabled(false)

-- Handle clicking and dragging hue ring
local function hue_drag()
	if not click:isPressed() then events.render:remove(hue_drag) end

	local mouse_pos = (client.getMousePos() / client.getGuiScale() - pos) / scale
	local x, y = mouse_pos:unpack()

	local angle = math.atan2(x, -y)
	local h = (angle / TAU + 1) % 1
	color.x = h
	hue_update(h)
	hue_format(color)

	txtr:pixel(3, 2, vectors.hsvToRGB(h, 1, 1))
		:pixel(4, 2, vectors.hsvToRGB(color))
		:update()
end

-- Handle clicking and dragging sat/val graph
local function sv_drag()
	if not click:isPressed() then events.render:remove(sv_drag) end

	local mouse_pos = (client.getMousePos() / client.getGuiScale() - pos) / scale
	local x, y = mouse_pos:unpack()
	x = math.clamp(-x / 24, -1, 1)
	y = math.clamp(-y / 24, -1, 1)

	sv_point:pos(x * 24, y * 24)
	color.yz = vec((1 - x) / 2, (1 + y) / 2)
	hue_format(color)

	txtr:pixel(4, 2, vectors.hsvToRGB(color))
		:update()
end

-- Handle mouse presses
function click.press()
	if not (host:isCursorUnlocked() or host:isChatOpen()) then return end

	local mouse_pos = (client.getMousePos() / client.getGuiScale() - pos) / scale
	local mouse_dist = mouse_pos:length()
	if 40 < mouse_dist and mouse_dist < 50 then
		events.render:register(hue_drag)
	elseif -vec(24, 24) < mouse_pos and mouse_pos < vec(24, 24) then
		events.render:register(sv_drag)
	end
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Library ♡˚
--==============================================================================================================================

---@class FOXColorWheel
local lib = {}

---Moves the color wheel on the screen
---
---The position is positive `+, +` rather than Figura's negative `-, -`
---@param x number
---@param y number
---@return self
function lib:pos(x, y)
	pos = vec(x, y)
	root:pos(-pos.xy_)
	return self
end

---Scales the color wheel from the center of the wheel
---@param s number
---@return self
function lib:scale(s)
	scale = s
	root:scale(s)
	return self
end

---Sets the visibility state of the color wheel
---@param state boolean
---@return self
function lib:visible(state)
	root:visible(state)
	click:enabled(state)
	return self
end

---Sets the previous and current colors being picked
---@param rgb Vector3
---@return self
function lib:color(rgb)
	color = vectors.rgbToHSV(rgb)

	hue_update(color.x)
	hue_format(color)

	local _, x, y = color:unpack()
	x = -(x - 0.5) * 48
	y = (y - 0.5) * 48
	sv_point:pos(x, y)

	txtr:pixel(3, 2, vectors.hsvToRGB(color.x, 1, 1))
		:pixel(4, 2, vectors.hsvToRGB(color))
		:pixel(4, 3, vectors.hsvToRGB(color))
		:update()

	return self
end

---Gets the currently picked color
---@return Vector3 rgb
function lib:getColor()
	return vectors.hsvToRGB(color)
end

return lib

--#ENDREGION
