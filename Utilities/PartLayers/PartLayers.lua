--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Part Layers v1.0-final-rc4

Adds the ability to set unlimited Texture, RenderType, and Color layers to a ModelPart
Injects into Figura's ModelPartAPI, adding layer methods, and replaces primary and secondary setters to use layers 1 and 2

Github: https://github.com/Bitslayn/Figura-Libraries/tree/main/Utilities/PartLayers
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

---Use Manuel's Task if this is present
local ok, Task = pcall(require, "./task")
Task = ok and Task or setmetatable({}, {
	__call = function(_, a, b, c, d)
		for i = a, b do c(i) end
		if d then d() end
	end,
})

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ FOXPartLayers ♡˚
--==============================================================================================================================

---@class FOXPartLayers.Part
---@field name string Custom name given to copied parts
---@field parts ModelPart[] List of all ModelParts used for layer rendering
---@field layers FOXPartLayers.Layers ModelPart customizations by layer
---@field bitmask integer
---@field depth integer Number of layers applied to this part
---@field queue ModelPart? Render event holder

---@class FOXPartLayers.Layers
---@field textures (string|Texture?)[]
---@field textureTypes (ModelPart.textureType?)[]
---@field renderTypes (ModelPart.renderType?)[]
---@field colors table<integer, Vector3> [0] used for changing the default color on all layers

---@type table<ModelPart, FOXPartLayers.Part>
local managed = {}

---@type FOXPartLayers.Layers
local defaults = {
	textures = {},
	textureTypes = { "PRIMARY", "SECONDARY" },
	renderTypes = setmetatable({ "TRANSLUCENT", "EMISSIVE" }, { __index = function() return "TRANSLUCENT" end }),
	colors = setmetatable({ [0] = vec3(1, 1, 1) }, { __index = function() return vec3(1, 1, 1) end }),
}

---Creates a new layer object for this ModelPart
---@param root ModelPart
---@return FOXPartLayers.Part
local function new(root)
	---@type FOXPartLayers.Part
	managed[root] = {
		name = root:getName() .. " (PartLayers)",
		parts = { root },
		layers = {
			textures = setmetatable({}, { __index = defaults.textures }),
			textureTypes = setmetatable({}, { __index = defaults.textureTypes }),
			renderTypes = setmetatable({}, { __index = defaults.renderTypes }),
			colors = setmetatable({}, { __index = defaults.colors }),
		},
		bitmask = 3,
		depth = 2,
	}

	return managed[root]
end

------------------------------------------------------------------------------------------------
--#REGION ˚♡ FOXPartLayers > Render Algorithm ♡˚
------------------------------------------------------------------------------------------------

---Grow or shrink ModelPart copy depth to desired depth
---@param obj FOXPartLayers.Part
---@param depth integer
---@param callback function
local function resize(obj, depth, callback)
	if depth == #obj.parts then return end

	if depth > #obj.parts then
		-- Grow

		Task(#obj.parts + 1, depth, function(i)
			obj.parts[i] = obj.parts[i - 1]
				:copy(obj.name)
				:moveTo(obj.parts[i - 1])
				:parentType("NONE")
				:matrix(matrices.mat4())

			primaryRenderType(obj.parts[i], "NONE")
			secondaryRenderType(obj.parts[i], "NONE")
		end, callback)
	else
		-- Shrink

		Task(depth + 1, #obj.parts, function(i)
			obj.parts[i]:remove()
			obj.parts[i] = nil
		end, callback)
	end
end

---Sets the texture, renderType, and color for a single layer
---@param obj FOXPartLayers.Part
---@param curr_layer integer
---@param prev_layer integer
---@param part ModelPart
---@param primary boolean
local function set(obj, curr_layer, prev_layer, part, primary)
	local texture = primary and primaryTexture or secondaryTexture
	local render_type = primary and primaryRenderType or secondaryRenderType
	local color = primary and primaryColor or secondaryColor

	if curr_layer then
		texture(part, obj.layers.textureTypes[curr_layer], obj.layers.textures[curr_layer])
		render_type(part, obj.layers.renderTypes[curr_layer])

		local old = obj.layers.colors[prev_layer]
		local col = obj.layers.colors[curr_layer]

		if part == obj.parts[1] then
			color(part, col + E)
		else
			color(part, (col + E) / (old + E))
		end
	else
		render_type(part, "NONE")
	end
end

---Applies changes to ModelParts, interlacing and flattening layers to use the least complexity
---@param obj FOXPartLayers.Part
local function apply(obj)
	---@type integer[]
	local layers = {}

	Task(1, obj.depth, function(i)
		layers[#layers + 1] = obj.layers.textureTypes[i] and i or nil
	end, function()
		local count = math.ceil(#layers / 2)

		resize(obj, count, function()
			Task(1, count * 2, function(i)
				local curr_layer = layers[i]
				local prev_layer = layers[i - 1]
				local part = obj.parts[(i - 1) % count + 1]
				local primary = i <= count
				set(obj, curr_layer, prev_layer, part, primary)
			end)
		end)
	end)
end

---Links parts so they can inherit layers
---@param child FOXPartLayers.Part
---@param parent FOXPartLayers.Part
local function link(child, parent)
	child.bitmask = bit32.bor(parent.bitmask, child.bitmask)
	child.depth = math.floor(math.log(child.bitmask, 2)) + 1

	setmetatable(child.layers.textures, { __index = parent.layers.textures })
	setmetatable(child.layers.textureTypes, { __index = parent.layers.textureTypes })
	setmetatable(child.layers.renderTypes, { __index = parent.layers.renderTypes })
	setmetatable(child.layers.colors, { __index = parent.layers.colors })
end

---Queues layer application and applies layer inheritance
---@param obj FOXPartLayers.Part
local function queue(obj)
	if obj.queue then return end
	obj.queue = obj.parts[1]:newPart("")

	---@param parent ModelPart
	local function recurse(parent)
		local children = parent:getChildren()
		Task(1, #children, function(i)
			local child = children[i]
			if child == obj.queue then return end
			if not managed[child] then new(child) end

			link(managed[child], managed[parent])

			if child:getType() == "GROUP" then
				recurse(child)
			else
				apply(managed[child])
			end
		end)
	end

	function obj.queue.preRender()
		recurse(obj.parts[1])

		obj.queue:remove()
		obj.queue = nil
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
---Layers can be removed if a texture type isn't provided when calling this method.
---
---A custom texture type requires a Texture in the source field. Similarly, a resource string is required for the resource texture type.
---
---```lua
---   local jacket = models.model.root.Body.Jacket
---   local pride_pin = textures["pride_pin"]
---
---   jacket:setTextureLayer(3, "CUSTOM", pride_pin)
---```
---@param layer integer Target layer index
---@param textureType ModelPart.textureType? Defaults to `"PRIMARY"` or `"SECONDARY"`
---@param source string|Texture? Required for `"RESOURCE"` and `"CUSTOM"` texture types
---@overload fun(self: ModelPart, layer: integer, textureType: "RESOURCE", source: string) The `"RESOURCE"` texture type requires a resource string in the source field
---@overload fun(self: ModelPart, layer: integer, textureType: "CUSTOM", source: Texture) The `"CUSTOM"` texture type requires a Texture in the source field
---@return self self Returns `self` for chaining
function ModelPart:setTextureLayer(layer, textureType, source)
	if not layer or layer ~= math.clamp(layer, 1, 32) then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	if textureType == "CUSTOM" and not source then error('"CUSTOM" texture type requires argument type: Texture', 2) end

	-- Update bitmask and depth
	-- Prevent removing layers 1 and 2

	if textureType then
		obj.bitmask = bit32.bor(obj.bitmask, 2 ^ (layer - 1))
	elseif layer > 2 then
		obj.bitmask = bit32.band(obj.bitmask, bit32.bnot(2 ^ (layer - 1)))
	end
	obj.depth = math.floor(math.log(obj.bitmask, 2)) + 1

	obj.layers.textures[layer] = source
	obj.layers.textureTypes[layer] = textureType

	queue(obj)

	return self
end

---Gets the texture layer of this part.
---
---```lua
---   local jacket = models.model.root.Body.Jacket
---
---   local textureType, source = jacket:getTextureLayer(3)
---
---   print(textureType, source)
---```
---@param layer integer Target layer index
---@return ModelPart.textureType? textureType Returns the texture type stored for this layer if a texture is defined
---@return string|Texture? source Returns the source stored for this layer if the texture type is either `"RESOURCE"` or `"CUSTOM"`
---@nodiscard
function ModelPart:getTextureLayer(layer)
	if not layer or layer ~= math.clamp(layer, 1, 32) then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	return rawget(obj.layers.textureTypes, layer), rawget(obj.layers.textures, layer)
end

---Gets a list of all textures applied to this ModelPart indexed by its layer.
---
---Also returns the number of texture layers currently applied.
---
---```lua
---   local jacket = models.model.root.Body.Jacket
---
---   local textures, depth = jacket:getTextureLayers()
---
---   print(textures, depth)
---```
---@return (string|Texture?)[] textures Returns the list of textures excluding inherited ones
---@return integer depth Returns the number of textures currently applied to this part
---@nodiscard
function ModelPart:getTextureLayers()
	local obj = managed[self] or new(self)

	return { table.unpack(obj.layers.textures, 1, obj.depth) }, obj.depth
end

---Sets the render type of this part at the given layer.
---
---```lua
---   local jacket = models.model.root.Body.Jacket
---
---   jacket:setRenderTypeLayer(3, "EYES")
---```
---@param layer integer Target layer index
---@param renderType ModelPart.renderType? Defaults to `"EMISSIVE"` for layer 2, but otherwise `"TRANSLUCENT"`
---@return self self Returns `self` for chaining
function ModelPart:setRenderTypeLayer(layer, renderType)
	if not layer or layer ~= math.clamp(layer, 1, 32) then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	obj.layers.renderTypes[layer] = renderType or layer > 2 and "TRANSLUCENT" or nil

	queue(obj)

	return self
end

---Gets the render type of this part at the given layer.
---
---```lua
---   local jacket = models.model.root.Body.Jacket
---
---   local renderType = jacket:getRenderTypeLayer()
---
---   print(renderType)
---```
---@param layer integer Target layer index
---@return ModelPart.renderType? renderType Returns the render type stored for this layer if a render type is defined
---@nodiscard
function ModelPart:getRenderTypeLayer(layer)
	if not layer or layer ~= math.clamp(layer, 1, 32) then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	return rawget(obj.layers.renderTypes, layer)
end

---Sets the texture tint color of this part.
---
---The last two parameters are ignored when a vector color is given.
---
---```lua
---   local jacket = models.model.root.Body.Jacket
---   local red = vectors.hexToRGB("red")
---
---   jacket:setColor(red)
---```
---@param r number|Vector3? Defaults to `1`
---@param g number? Defaults to `1`
---@param b number? Defaults to `1`
---@overload fun(self: ModelPart, layer: integer, r: number?, g: number?, b: number?): ModelPart
---@overload fun(self: ModelPart, layer: integer, col: Vector3?): ModelPart
---@return self self Returns `self` for chaining
function ModelPart:setColor(r, g, b)
	local obj = managed[self] or new(self)

	obj.layers.colors = setmetatable({ [0] = color_args(r, g, b) }, getmetatable(obj.layers.colors))

	queue(obj)

	return self
end

---Sets the texture tint color of this part at the given layer.
---
---The last two parameters are ignored when a vector color is given.
---
---```lua
---   local jacket = models.model.root.Body.Jacket
---   local red = vectors.hexToRGB("red")
---
---   jacket:setColorLayer(3, red)
---```
---@param layer integer Target layer index
---@param r number|Vector3? Defaults to `1`
---@param g number? Defaults to `1`
---@param b number? Defaults to `1`
---@overload fun(self: ModelPart, layer: integer, r: number?, g: number?, b: number?): ModelPart
---@overload fun(self: ModelPart, layer: integer, col: Vector3?): ModelPart
---@return self self Returns `self` for chaining
function ModelPart:setColorLayer(layer, r, g, b)
	if not layer or layer ~= math.clamp(layer, 1, 32) then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	obj.layers.colors[layer] = color_args(r, g, b)

	queue(obj)

	return self
end

---Gets the texture tint color of this part.
---
---```lua
---   local jacket = models.model.root.Body.Jacket
---
---   local color = jacket:getColorLayer(3)
---
---   print(color)
---```
---@param layer integer Target layer index
---@return Vector3 color Returns the color stored for this layer if a color is defined
---@nodiscard
function ModelPart:getColorLayer(layer)
	if not layer or layer ~= math.clamp(layer, 1, 32) then error("Invalid layer index: " .. tostring(layer), 2) end
	local obj = managed[self] or new(self)

	local col = rawget(obj.layers.colors, layer) or rawget(obj.layers.colors, 0)

	return col:copy()
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

---**This function is deprecated due to ModelPart handling changes.**
---
---~~Gets the ModelPart at the given layer.~~
---
---~~May return `nil` if no texture exists for this layer.~~
---@deprecated
ModelPart.getPartToLayer = nil

---**This function is deprecated as it no longer serves its intended purpose.**
---
---~~Forces ModelPart layers to update~~
---@deprecated
ModelPart.updateLayers = nil

--#ENDREGION

--#ENDREGION
