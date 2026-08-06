--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Part Layers v1.0-final-rc4-dev

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

local vec3 = vectors.vec3

local E = 1e-6

---Converts raw args into a Vector3 with advanced error catching
---@param r number|Vector3?
---@param g number?
---@param b number?
local function color_args(r, g, b)
	if type(r) == "number" or r == nil then
		return vec3():set(r or 1, g or 1, b or 1)
	end
	return vec3():set(r)
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Object ♡˚
--==============================================================================================================================

--[[Renderer rewrite

Limitations:
Ground limitations will need to be set in place. ModelParts which have children should never render extra layers.

New plan: Queue and linked tables
Instead of doing everything in render and overrunning resource limits, exhaust a queue and use linked tables rather than a customization stack.

Old plan: Layer Customization Stack
Groups should propagate customizations to all children, allowing for proper mixing and avoiding interlacing groups.

When a layer needs to be updated, it will mark children as dirty if they exist.
If a parent is found to have had additional layers, marks them as dirty.
Use preRender to push to the stack and postRender to pop from the stack.

Render events should only be applied to ModelPart relatives that are managed.
]]

---@type table<ModelPart, FOXPartLayers.ModelPart>
local managed = {}

---Creates a new layer object for this ModelPart
---@param root ModelPart
---@return FOXPartLayers.ModelPart
---@nodiscard
local function new(root)
	---@class FOXPartLayers.Layers
	---@field textures table<integer, [ModelPart.textureType, string|Texture?]?> ModelPart texture varargs by layer
	---@field renderTypes (ModelPart.renderType?)[] ModelPart render types by layer
	---@field colors table<integer, Vector3> ModelPart colors by layer

	---@class FOXPartLayers.ModelPart
	---@field name string The root ModelPart's name
	---@field parts ModelPart[] List of all ModelParts in this object
	---@field layers FOXPartLayers.Layers
	---@field task ModelPart Render event holder
	managed[root] = {
		name = root:getName(),
		parts = { root },
		layers = {
			textures = { {}, {} },
			renderTypes = {},
			colors = { [0] = root:getColor() },
		},
		task = root:newPart("task"),
	}

	return managed[root]
end

------------------------------------------------------------------------------------------------
--#REGION ˚♡ Object > Library ♡˚
------------------------------------------------------------------------------------------------

---Re-allocates the copies
---@param obj FOXPartLayers.ModelPart
local function realloc(obj)
	-- Find depth for textures table with holes

	local depth = 0
	for layer in pairs(obj.layers.textures) do
		depth = math.max(depth, layer)
	end

	local desired_depth = math.ceil(depth / 2)

	-- Early return for unchanged size

	if desired_depth == #obj.parts then return end

	-- Grow or shrink modelpart copies

	if desired_depth > #obj.parts then
		for i = #obj.parts + 1, desired_depth do
			obj.parts[i] = obj.parts[i - 1]
				:copy(("%s (PartLayers %d & %d)"):format(obj.name, i * 2 - 1, i * 2)) -- Fix for AST; obj.name .. " (PartLayers " .. i * 2 - 1 .. " & " .. i * 2 .. ")"
				:moveTo(obj.parts[i - 1])
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
---@param obj FOXPartLayers.ModelPart
---@param part ModelPart
---@param layer integer
---@param primary boolean
local function update(obj, part, layer, primary)
	-- Gets the appropriate setter functions

	local texture = primary and primaryTexture or secondaryTexture
	local render_type = primary and primaryRenderType or secondaryRenderType
	local color = primary and primaryColor or secondaryColor

	-- Updates the layer's texture, render type, and color

	if obj.layers.textures[layer] then
		texture(part, obj.layers.textures[layer][1], obj.layers.textures[layer][2])
		render_type(part, obj.layers.renderTypes[layer])

		local old = obj.layers.colors[layer - 1] or vec3(1, 1, 1) -- `1, 1, 1` fix for setColor, you cannot tint something that doesn't exist
		local col = obj.layers.colors[layer] or obj.layers.colors[0]

		if part == obj.parts[1] then
			color(part, col + E)
		else
			color(part, (col + E) / (old + E))
		end
	else
		render_type(part, "NONE")
	end
end

---Updates all texture layers of this part
---@param obj FOXPartLayers.ModelPart
local function interlace(obj)
	for i = 1, #obj.parts * 2 do
		update(obj, obj.parts[(i - 1) % #obj.parts + 1], i, i <= #obj.parts)
	end
end

---Queues realloc and interlace functions on this object
---@param obj FOXPartLayers.ModelPart
local function queue(obj)
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

	obj.layers.textures[layer] = texture and { texture, source } or layer <= 2 and {} or nil
	obj.layers.renderTypes[layer] = obj.layers.renderTypes[layer] or layer > 2 and "TRANSLUCENT" or nil

	queue(obj)

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
	elseif not obj.layers.textures[layer] then
		return nil, nil
	end

	---@diagnostic disable-next-line: redundant-return-value
	return table.unpack(obj.layers.textures[layer])
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
	for layer, t in pairs(obj.layers.textures) do
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

	obj.layers.renderTypes[layer] = renderType or layer > 2 and "TRANSLUCENT" or nil

	queue(obj)

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

	return obj.layers.renderTypes[layer]
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

	obj.color = color_args(r, g, b)
	obj.colors = {}

	queue(obj)

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

	obj.layers.colors[layer] = color_args(r, g, b)

	queue(obj)

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

	return obj.layers.colors[layer]
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
	queue(obj)
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
