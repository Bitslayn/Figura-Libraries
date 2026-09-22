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
local schema = {}

---@class Schema.Node<T>
local node = {}

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Nodes ♡˚
--==============================================================================================================================

---Uses the provided nodes to build a table of values. Returns this table.
---@param key Schema.Node<any>
---@param value Schema.Node<any>
---@return Schema.Node<table>
function schema.list(key, value)
	return setmetatable({ type = "list", key = key, value = value }, { __type = "Schema.Node.Table", __index = node })
end

---Extracts and returns an integer. A width in bits must be provided.
---@param width integer
---@return Schema.Node<integer>
function schema.uint(width)
	return setmetatable({ type = "uint", width = width }, { __type = "Schema.Node.Integer", __index = node })
end

---Uses the node's return to index a table. Returns the value from the table.
---@generic K, V
---@param key Schema.Node<K>
---@param enum table<K, V>
---@return Schema.Node<V>
function schema.enum(key, enum)
	return setmetatable({ type = "enum", key = key, enum = enum }, { __type = "Schema.Node.Enum", __index = node })
end

---Extracts and returns a boolean.
---@return Schema.Node<boolean>
function schema.bool()
	return schema.enum(schema.uint(1), { [0] = false, [1] = true })
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Encoder ♡˚
--==============================================================================================================================

-- Lists need to store the length of the table, and each item needs to store its index

---@param table table
---@return integer ...
function node:encode(table)

end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Decoder ♡˚
--==============================================================================================================================

---@param ... integer
---@return table
function node:decode(...)

end

--#ENDREGION

return schema
