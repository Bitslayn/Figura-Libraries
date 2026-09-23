--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Schema v1.0-dev

Allows for encoding and decoding tables into binary

Github: https://github.com/Bitslayn/Figura-Libraries/tree/main/Utilities/Schema
]]

--==============================================================================================================================
--#REGION ˚♡ Classes ♡˚
--==============================================================================================================================

---@class Schema
local api_schema = {}

---@class Schema.Node
local api_node = {}

---@alias Schema.Node.Any
---| Schema.Node.Table
---| Schema.Node.Integer
---| Schema.Node.Enum

---@class Schema.Node.Table
---@field type "list"
---@field key Schema.Node.Any
---@field val Schema.Node.Any

---@class Schema.Node.Integer
---@field type "uint"
---@field width integer

---@class Schema.Node.Enum
---@field type "enum"
---@field key Schema.Node.Any
---@field enum table
---@field width integer

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Nodes ♡˚
--==============================================================================================================================

---Uses the provided nodes to build a table of values. Returns this table.
---@param key Schema.Node<any>
---@param val Schema.Node<any>
---@return Schema.Node<table>
---@nodiscard
function api_schema.list(key, val)
	local self = { type = "list", key = key, val = val }
	return setmetatable(self, { __type = "Schema.Node.Table", __index = api_node })
end

---Extracts and returns an integer. A width in bits must be provided.
---@param width integer
---@return Schema.Node<integer>
---@nodiscard
function api_schema.uint(width)
	local self = { type = "uint", width = width }
	return setmetatable(self, { __type = "Schema.Node.Integer", __index = api_node })
end

---Uses the node's return to index a table. Returns the value from the table.
---@generic K, V
---@param key Schema.Node<K>
---@param enum table<K, V>
---@return Schema.Node<V>
---@nodiscard
function api_schema.enum(key, enum)
	local self = { type = "enum", key = key, enum = enum, width = key.width --[[@as integer?]] or #enum }
	return setmetatable(self, { __type = "Schema.Node.Enum", __index = api_node })
end

---Extracts and returns a boolean.
---@return Schema.Node<boolean>
---@nodiscard
function api_schema.bool()
	return api_schema.enum(api_schema.uint(1), { [0] = false, [1] = true })
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Encoder ♡˚
--==============================================================================================================================

-- Lists need to store the length of the table, and each item needs to store its index

---@param self Schema.Node.Any
---@param table table
---@return integer ...
---@nodiscard
function api_node:encode(table)
	
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Decoder ♡˚
--==============================================================================================================================

---Writes the given integers to the buffer in little-endian order
---@param buffer Buffer
---@param ... integer
local function write_to_buffer(buffer, ...)
	local ints = { ... }
	for i = 1, #ints do
		buffer:writeIntLE(ints[i])
	end
end

---Extracts an integer from the buffer starting at the binary position and ending at pos + width
---@param buffer Buffer
---@param state Schema.Decode.State
---@return integer
local function extract_int(buffer, state, width)
	buffer:setPosition(math.floor(state.pos / 8))
	local stream = bit32.bor(
		bit32.rshift(buffer:readIntLE(), state.pos % 8),
		bit32.lshift(buffer:readIntLE(), 32 - state.pos % 8)
	)
	state.pos = state.pos + width
	return bit32.extract(stream, 0, width)
end

---@class Schema.Decode
local lib_decode = {}

---@param node Schema.Node.Table
---@param state Schema.Decode.State
function lib_decode.list(node, state)
	local holes = extract_int(state.buffer, state, 1) == 1
	local depth = extract_int(state.buffer, state, node.key.width)

	local output = {}
	for i = 1, depth do
		local key = lib_decode[node.key.type](node.key, state, holes and nil or i)
		local val = lib_decode[node.val.type](node.val, state)

		output[key] = val
	end

	return output
end

---@param node Schema.Node.Integer
---@param state Schema.Decode.State
---@param int integer?
---@return integer
function lib_decode.uint(node, state, int)
	if int then return int end
	return extract_int(state.buffer, state, node.width)
end

---@param node Schema.Node.Enum
---@param state Schema.Decode.State
---@param int integer?
---@return unknown
function lib_decode.enum(node, state, int)
	return node.enum[lib_decode[node.key.type](node.key, state, int)]
end

---Returns a table representing the given binary data following this schema
---@param self Schema.Node.Any
---@param ... integer
---@return table
---@nodiscard
function api_node:decode(...)
	local buffer = data:createBuffer()
	write_to_buffer(buffer, ...)

	---@class Schema.Decode.State
	local state = { pos = 0, buffer = buffer }
	local output = lib_decode[self.type](self, state)

	buffer:close()
	return output
end

--#ENDREGION

return api_schema
