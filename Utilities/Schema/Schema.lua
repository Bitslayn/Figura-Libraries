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

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Nodes ♡˚
--==============================================================================================================================

---@alias Schema.Node.Any
---| Schema.Node.Table
---| Schema.Node.Integer
---| Schema.Node.Enum

---Uses the provided nodes to build a table of values. Returns this table.
---@param key Schema.Node<any>
---@param value Schema.Node<any>
---@return Schema.Node<table>
function api_schema.list(key, value)
	---@class Schema.Node.Table
	---@field type "list"
	local self = { type = "list", key = key, value = value }
	return setmetatable(self, { __type = "Schema.Node.Table", __index = api_node })
end

---Extracts and returns an integer. A width in bits must be provided.
---@param width integer
---@return Schema.Node<integer>
function api_schema.uint(width)
	---@class Schema.Node.Integer
	---@field type "uint"
	local self = { type = "uint", width = width }
	return setmetatable(self, { __type = "Schema.Node.Integer", __index = api_node })
end

---Uses the node's return to index a table. Returns the value from the table.
---@generic K, V
---@param key Schema.Node<K>
---@param enum table<K, V>
---@return Schema.Node<V>
function api_schema.enum(key, enum)
	---@class Schema.Node.Enum
	---@field type "enum"
	local self = { type = "enum", key = key, enum = enum }
	return setmetatable(self, { __type = "Schema.Node.Enum", __index = api_node })
end

---Extracts and returns a boolean.
---@return Schema.Node<boolean>
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
function api_node:encode(table)
	
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Decoder ♡˚
--==============================================================================================================================

---@param self Schema.Node.Any
---@param ... integer
---@return table
function api_node:decode(...)

end

--#ENDREGION

return api_schema
