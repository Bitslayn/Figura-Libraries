--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Part Layers v1.0-final-rc2

Adds the ability to set unlimited Texture, RenderType, and Color layers to a ModelPart
Injects into Figura's ModelPartAPI, adding layer methods, and replaces primary and secondary setters to use layers 1 and 2

Github: https://github.com/Bitslayn/FOX-s-Figura-APIs/blob/main/Utilities/PartLayers.lua
]]

--==============================================================================================================================
--#REGION ˚♡ Shared ♡˚
--==============================================================================================================================

local primaryTexture = models.primaryTexture
local secondaryTexture = models.secondaryTexture
local primaryRenderType = models.primaryRenderType
local secondaryRenderType = models.secondaryRenderType
local primaryColor = models.primaryColor
local secondaryColor = models.secondaryColor

local blank = textures:newTexture("PartLayers_blank", 1, 1):setPixel(0, 0, vec(0, 0, 0, 0))

local vec3 = vectors.vec3

---Converts raw args into a Vector3 with advanced error catching
---@param r number|Vector3?
---@param g number?
---@param b number?
local function color_args(r, g, b)
	local ok, res = xpcall(function()
		if type(r) == "number" or r == nil then
			return vec3():set(r or 1, g or 1, b or 1)
		end
		return vec3():set(r) -- Try set
	end, function(res)
		return res
			:match("%s+(.*)")                          -- Capture only the error message
			:gsub("set", "setColorLayer")              -- Replace blamed function name
			:gsub("%d", function(d) return tonumber(d) + 2 end) -- Elevate traceback
	end)
	if not ok then error(res, 3) end
	return res
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Object ♡˚
--==============================================================================================================================

---@type table<ModelPart, FOXPartLayers.Object>
local managed = {}

---Creates a new layer object for this ModelPart
---@param root ModelPart
---@return FOXPartLayers.Object
---@nodiscard
local function new(root)
	---@class FOXPartLayers.Object
	managed[root] = {
		---The root ModelPart
		---@type ModelPart
		root = root,
		---The root ModelPart's name
		---@type string
		name = root:getName(),
		---List of all ModelParts in this object
		---@type ModelPart[]
		parts = {},
		---ModelPart texture varargs by layer
		---@type table<integer, [ModelPart.textureType, string|Texture?]?>
		textures = { { "PRIMARY" }, { "SECONDARY" } },
		---ModelPart render types by layer
		---@type (ModelPart.renderType?)[]
		renderTypes = {},
		---ModelPart colors by layer
		---@type Vector3[]
		colors = {},
		---Render event holder
		---@type ModelPart
		task = root:newPart("task"),
	}

	primaryTexture(root, "CUSTOM", blank)
	secondaryTexture(root, "CUSTOM", blank)

	return managed[root]
end

------------------------------------------------------------------------------------------------
--#REGION ˚♡ Object > Library ♡˚
------------------------------------------------------------------------------------------------

---Re-allocates the copies
---@param obj FOXPartLayers.Object
local function realloc(obj)
	-- Find depth for textures table with holes

	local depth = 0
	for layer in pairs(obj.textures) do
		depth = math.max(depth, layer)
	end

	local desired_depth = math.ceil(depth / 2)

	-- Early return for unchanged size

	if desired_depth == #obj.parts then return end

	-- Grow or shrink modelpart copies

	if desired_depth > #obj.parts then
		for i = #obj.parts + 1, desired_depth do
			obj.parts[i] = (obj.parts[1] or obj.root)
				:copy(("%s (PartLayers %d & %d)"):format(obj.name, i * 2 - 1, i * 2)) -- Fix for AST; obj.name .. " (PartLayers " .. i * 2 - 1 .. " & " .. i * 2 .. ")"
				:moveTo(obj.root)
				:parentType("NONE")
				-- DEV NOTE: Niche Figura detail but the ModelPart matrix must be set after calling `parentType`. TL;DR this should always be called last.
				:matrix(matrices.mat4())

			primaryRenderType(obj.parts[i], "NONE")
			secondaryRenderType(obj.parts[i], "NONE")
		end
	else
		for i = desired_depth + 1, #obj.parts do
			obj.parts[i]:remove()
			obj.parts[i] = nil
		end
	end
end

---Updates the current texture layer in this part
---@param layer integer
---@param part ModelPart?
---@param is_prim boolean?
local function update(obj, layer, part, is_prim)
	-- Gets the part for this layer, and appropriate setter functions

	if part == nil then part = obj.parts[math.ceil(layer / 2)] end
	if not part then return end

	if is_prim == nil then is_prim = layer % 2 == 1 end
	local texture = is_prim and primaryTexture or secondaryTexture
	local render_type = is_prim and primaryRenderType or secondaryRenderType
	local color = is_prim and primaryColor or secondaryColor

	-- Updates the layer's texture and render type

	if obj.textures[layer] then
		texture(part, obj.textures[layer][1], obj.textures[layer][2])
		render_type(part, obj.renderTypes[layer])
		color(part, obj.colors[layer])
	else
		render_type(part, "NONE")
	end
end

---Updates all texture layers of this part
---@param obj FOXPartLayers.Object
local function interlace(obj)
	for i = 1, #obj.parts * 2 do
		update(obj, i, obj.parts[(i - 1) % #obj.parts + 1], i <= #obj.parts)
	end
end

---Queues realloc and interlace functions on this object
---@param obj FOXPartLayers.Object
local function dirty(obj)
	function obj.task.preRender()
		realloc(obj)
		interlace(obj)

		obj.task.preRender = nil
	end
end

--#ENDREGION

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ ModelPart ♡˚
--==============================================================================================================================

---@class ModelPart
local ModelPart = {}

local __index = figuraMetatables.ModelPart.__index
function figuraMetatables.ModelPart.__index(part, key)
	return ModelPart[key] or __index(part, key)
end

------------------------------------------------------------------------------------------------
--#REGION ˚♡ ModelPart > Layered Methods ♡˚
------------------------------------------------------------------------------------------------

---Sets the texture layer of this part.
---
---Setting the texture type to `"RESOURCE"` allows selecting any namespaced texture to use as the texture source.
---Setting the texture type to `"CUSTOM"` allows selecting a Figura `Texture` to use as the texture source.
---
---If `texture` is `nil`, and layer is `1`, it will default to `"PRIMARY"`.
---
---If `texture` is `nil`, and layer is `2`, it will default to `"SECONDARY"`.
---
---If `texture` is `nil`, and layer is `3` or above, that layer will be removed.
---@param self ModelPart
---@param layer integer
---@param texture ModelPart.textureType?
---@param source string|Texture?
---@return self
function ModelPart:setTextureLayer(layer, texture, source)
	if not layer or layer < 1 then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	if texture == "CUSTOM" and not source then error('"CUSTOM" texture type requires argument type: Texture', 2) end

	obj.textures[layer] = texture and { texture, source } or layer <= 2 and {} or nil
	obj.renderTypes[layer] = obj.renderTypes[layer] or layer > 2 and "TRANSLUCENT" or nil

	dirty(obj)

	return self
end

---Gets the texture data of this part at the given layer.
---
---If the texture of this layer is `"RESOURCE"` or `"CUSTOM"`, then a second value will be returned.
---@param layer integer
---@return ModelPart.textureType?
---@return string|Texture?
---@nodiscard
function ModelPart:getTextureLayer(layer)
	if not layer or layer < 1 then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	if layer == 1 then
		return obj.parts[1]:getPrimaryTexture()
	elseif layer == 2 then
		return obj.parts[1]:getSecondaryTexture()
	elseif not obj.textures[layer] then
		return nil, nil
	end

	---@diagnostic disable-next-line: redundant-return-value
	return table.unpack(obj.textures[layer])
end

---Gets a list of all textures applied to this ModelPart indexed by its layer.
---
---Also returns the number of texture layers currently applied.
---@return (string|Texture?)[]
---@return integer
---@nodiscard
function ModelPart:getTextureLayers()
	local obj = managed[self] or new(self)

	local depth = 0

	local flat = {}
	for layer, t in pairs(obj.textures) do
		flat[layer] = t[2]
		depth = math.max(depth, layer)
	end

	return flat, depth
end

---Sets the render type of this part at the given layer.
---
---This part inherits from its parent if `renderType` is `nil`.
---@param layer integer
---@param renderType ModelPart.renderType?
---@return self
function ModelPart:setRenderTypeLayer(layer, renderType)
	if not layer or layer < 1 then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	obj.renderTypes[layer] = renderType or layer > 2 and "TRANSLUCENT" or nil

	dirty(obj)

	return self
end

---Gets the render type of this part's primary layer.
---
---Returns `nil` if it is inheriting from its parent.
---@param layer integer
---@return ModelPart.renderType?
---@nodiscard
function ModelPart:getRenderTypeLayer(layer)
	if not layer or layer < 1 then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	return obj.renderTypes[layer]
end

---Sets the color multiplier of this part.
---
---This is a multiplier, that means that `1, 1, 1` will result in no change and `0, 0, 0` will result in black.
---
---If a color channel is nil, it will default to `1`.
---@param r number|Vector3?
---@param g number?
---@param b number?
---@overload fun(self: ModelPart, layer: integer, r: number?, g: number?, b: number?): ModelPart
---@overload fun(self: ModelPart, layer: integer, col: Vector3?): ModelPart
---@return self
function ModelPart:setColor(r, g, b)
	local obj = managed[self] or new(self)
	local col = color_args(r, g, b)

	for layer in pairs(obj.textures) do
		obj.colors[layer] = col
	end

	dirty(obj)

	return self
end

---Sets the color multiplier of this part at the given layer.
---
---This is a multiplier, that means that `1, 1, 1` will result in no change and `0, 0, 0` will result in black.
---
---If a color channel is nil, it will default to `1`.
---@param layer integer
---@param r number|Vector3?
---@param g number?
---@param b number?
---@overload fun(self: ModelPart, layer: integer, r: number?, g: number?, b: number?): ModelPart
---@overload fun(self: ModelPart, layer: integer, col: Vector3?): ModelPart
---@return self
function ModelPart:setColorLayer(layer, r, g, b)
	if not layer or layer < 1 then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	obj.colors[layer] = color_args(r, g, b)

	dirty(obj)

	return self
end

---Gets the color multiplier of this part.
---
---This is a multiplier, that means that `1, 1, 1` will result in no change and `0, 0, 0` will result in black.
---@param layer integer
---@return Vector3
---@nodiscard
function ModelPart:getColorLayer(layer)
	if not layer or layer < 1 then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	return obj.colors[layer]
end

---Gets the ModelPart at the given layer.
---
---May return `nil` if no texture exists for this layer.
---@param layer integer
---@return ModelPart?
---@nodiscard
function ModelPart:getPartToLayer(layer)
	if not layer or layer < 1 then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	return obj.parts[math.ceil(layer / 2)]
end

---Forces ModelPart layers to update
---@return ModelPart
function ModelPart:updateLayers()
	local obj = managed[self] or new(self)
	dirty(obj)
	return self
end

--#ENDREGION -----------------------------------------------------------------------------------
--#REGION ˚♡ ModelPart > Alias Methods ♡˚
------------------------------------------------------------------------------------------------

---@diagnostic disable: param-type-mismatch

ModelPart.textureLayer = ModelPart.setTextureLayer
ModelPart.renderTypeLayer = ModelPart.setRenderTypeLayer
ModelPart.colorLayer = ModelPart.setColorLayer
ModelPart.color = ModelPart.setColor

ModelPart.setPrimaryTexture = function(self, texture, source) return self:setTextureLayer(1, texture, source) end
ModelPart.primaryTexture = function(self, texture, source) return self:setTextureLayer(1, texture, source) end
ModelPart.setPrimaryRenderType = function(self, renderType) return self:setRenderTypeLayer(1, renderType) end
ModelPart.primaryRenderType = function(self, renderType) return self:setRenderTypeLayer(1, renderType) end
ModelPart.setPrimaryColor = function(self, ...) return self:setColorLayer(1, ...) end
ModelPart.primaryColor = function(self, ...) return self:setColorLayer(1, ...) end

ModelPart.setSecondaryTexture = function(self, texture, source) return self:setTextureLayer(2, texture, source) end
ModelPart.secondaryTexture = function(self, texture, source) return self:setTextureLayer(2, texture, source) end
ModelPart.setSecondaryRenderType = function(self, renderType) return self:setRenderTypeLayer(2, renderType) end
ModelPart.secondaryRenderType = function(self, renderType) return self:setRenderTypeLayer(2, renderType) end
ModelPart.setSecondaryColor = function(self, ...) return self:setColorLayer(2, ...) end
ModelPart.secondaryColor = function(self, ...) return self:setColorLayer(2, ...) end

--#ENDREGION

--#ENDREGION
