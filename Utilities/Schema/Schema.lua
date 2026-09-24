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

---@class FOXSchema
local api_schema = {}

---@class FOXSchema.Node
local api_node = {}

---@alias FOXSchema.Node.Any
---| FOXSchema.Node.Table
---| FOXSchema.Node.Integer
---| FOXSchema.Node.Enum

---@class FOXSchema.Node.Table
---@field type "list"
---@field key FOXSchema.Node.Any
---@field val FOXSchema.Node.Any

---@class FOXSchema.Node.Integer
---@field type "uint"
---@field wid integer

---@class FOXSchema.Node.Enum
---@field type "enum"
---@field key FOXSchema.Node.Any
---@field enum table
---@field flip table
---@field wid integer

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Nodes ♡˚
--==============================================================================================================================

---Uses the provided nodes to build a table of values. Returns this table.
---@param key FOXSchema.Node<any>
---@param val FOXSchema.Node<any>
---@return FOXSchema.Node<table>
---@nodiscard
function api_schema.list(key, val)
	local self = { type = "list", key = key, val = val }
	return setmetatable(self, { __type = "Schema.Node.Table", __index = api_node })
end

---Extracts and returns an integer. A width in bits must be provided.
---@param wid integer
---@return FOXSchema.Node<integer>
---@nodiscard
function api_schema.uint(wid)
	local self = { type = "uint", wid = wid }
	return setmetatable(self, { __type = "Schema.Node.Integer", __index = api_node })
end

---Uses the node's return to index a table. Returns the value from the table.
---@generic K, V
---@param key FOXSchema.Node<K>
---@param enum table<K, V>
---@return FOXSchema.Node<V>
---@nodiscard
function api_schema.enum(key, enum)
	local flip = {}
	for k, v in next, enum do
		flip[v] = k
	end

	---@diagnostic disable-next-line: undefined-field
	local self = { type = "enum", key = key, enum = enum, flip = flip, wid = key.wid }
	return setmetatable(self, { __type = "Schema.Node.Enum", __index = api_node })
end

---Extracts and returns a boolean.
---@return FOXSchema.Node<boolean>
---@nodiscard
function api_schema.bool()
	return api_schema.enum(api_schema.uint(1), { [0] = false, [1] = true })
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Binary ♡˚
--==============================================================================================================================

---Reads up to 32 bits from the integer array
---@param ints integer[]
---@param pos integer
---@param wid integer
---@return integer
---@nodiscard
local function read(ints, pos, wid)
	local byte = math.floor(pos / 32) + 1
	local stream = bit32.bor(
		bit32.rshift(ints[byte] or 0, pos % 32),
		bit32.lshift(ints[byte + 1] or 0, 32 - pos % 32)
	)
	return bit32.extract(stream, 0, wid)
end

---Writes up to 32 bits to the integer array
---@param ints integer[]
---@param pos integer
---@param wid integer
---@param val integer
local function write(ints, pos, wid, val)
	local offset = pos % 32
	local byte = math.floor(pos / 32) + 1

	if offset + wid > 32 then
		local lwid = 32 - offset
		local rwid = wid - lwid
		local lval = bit32.extract(val, 0, lwid)
		local rval = bit32.extract(val, lwid, rwid)

		ints[byte] = bit32.replace(ints[byte] or 0, lval, offset, lwid)
		ints[byte + 1] = bit32.replace(ints[byte + 1] or 0, rval, 0, rwid)
	else
		ints[byte] = bit32.replace(ints[byte] or 0, val, offset, wid)
	end
end

---Signs all integers in the array
---
---Pinging unsigned integers could cost an additional 4 bytes!
---@param ints integer[]
local function sign(ints)
	local buffer = data:createBuffer()

	for i = 1, #ints do
		buffer:writeInt(ints[i])
	end

	buffer:setPosition(0)

	for i = 1, #ints do
		ints[i] = buffer:readInt()
	end

	buffer:close()
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Encoder ♡˚
--==============================================================================================================================

-- TODO Pending rewrite

---@class FOXSchema.Encode
local lib_encode = {}

---@param node FOXSchema.Node.Table
---@param state FOXSchema.Encode.State
---@param tbl table
function lib_encode.list(node, state, tbl)
	local keys = {}
	local vals = {}
	for key, val in pairs(tbl) do
		key = lib_encode[node.key.type](node.key, state, key)

		keys[#keys + 1] = key
		vals[key] = val
	end
	table.sort(keys)

	-- Distinguishes between table<integer, any> and any[], where a table of any[] does not contain any holes.

	local max = math.max(0, table.unpack(keys))
	local min = math.min(max, table.unpack(keys))
	local limit = math.min(#keys, 2 ^ node.key.wid - 1)

	local holes
	if node.key.enum then
		holes = node.key.enum[0] or #node.key.enum > limit
	else
		holes = min < 1 or 1 - min + max ~= limit
	end

	write(state.ints, state.pos, 1, holes and 1 or 0)
	write(state.ints, state.pos + 1, node.key.wid, limit)
	state.pos = state.pos + node.key.wid + 1

	for i = 1, limit do
		if holes then
			write(state.ints, state.pos, node.key.wid, keys[i])
			state.pos = state.pos + node.key.wid
		end
		local val = lib_encode[node.val.type](node.val, state, vals[keys[i]])
		if val then
			write(state.ints, state.pos, node.val.wid, val)
			state.pos = state.pos + node.val.wid
		end
	end
end

---@param node FOXSchema.Node.Integer
---@param state FOXSchema.Encode.State
---@param val integer
---@return integer
function lib_encode.uint(node, state, val)
	return val
end

---@param node FOXSchema.Node.Enum
---@param state FOXSchema.Encode.State
---@param val unknown
---@return unknown
function lib_encode.enum(node, state, val)
	return lib_encode[node.key.type](node.key, state, node.flip[val])
end

---Returns the binary representation of the given table following this schema
---@param self FOXSchema.Node.Any
---@param tbl table
---@return integer ...
---@nodiscard
function api_node:encode(tbl)
	---@class FOXSchema.Encode.State
	local state = { pos = 0, ints = {} }
	lib_encode[self.type](self, state, tbl)

	sign(state.ints)
	return table.unpack(state.ints)
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Decoder ♡˚
--==============================================================================================================================

---@class FOXSchema.Decode
local lib_decode = {}

---@param node FOXSchema.Node.Table
---@param state FOXSchema.Decode.State
function lib_decode.list(node, state)
	local holes = read(state.ints, state.pos, 1) == 1
	state.pos = state.pos + 1
	local depth = read(state.ints, state.pos, node.key.wid)
	state.pos = state.pos + node.key.wid

	local output = {}
	for i = 1, depth do
		local key = lib_decode[node.key.type](node.key, state, not holes and i or nil)
		local val = lib_decode[node.val.type](node.val, state)

		output[key] = val
	end

	return output
end

---@param node FOXSchema.Node.Integer
---@param state FOXSchema.Decode.State
---@param val integer?
---@return integer
function lib_decode.uint(node, state, val)
	if val then return val end
	val = read(state.ints, state.pos, node.wid)
	state.pos = state.pos + node.wid
	return val
end

---@param node FOXSchema.Node.Enum
---@param state FOXSchema.Decode.State
---@param val unknown
---@return unknown
function lib_decode.enum(node, state, val)
	return node.enum[lib_decode[node.key.type](node.key, state, val)]
end

---Returns a table representing the given binary data following this schema
---@param self FOXSchema.Node.Any
---@param ... integer
---@return table
---@nodiscard
function api_node:decode(...)
	---@class FOXSchema.Decode.State
	local state = { pos = 0, ints = { ... } }
	local output = lib_decode[self.type](self, state)

	return output
end

--#ENDREGION

return api_schema
