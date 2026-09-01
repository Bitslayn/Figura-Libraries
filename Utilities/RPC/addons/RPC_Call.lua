--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's RPC Call v1.0 - An RPC Addon

Adds method registering through RPC

Github: https://github.com/Bitslayn/Figura-Libraries/tree/main/Utilities/RPC
]]

--==============================================================================================================================
--#REGION ˚♡ RPC ♡˚
--==============================================================================================================================

local RPC = require("./RPC")

---@alias FOXRPC.CallAddon.Request {lib: "FOXRPC.Call", key: string|integer, val: unknown[]?}
---@alias FOXRPC.CallAddon.Response unknown[]

---@type table<string|integer, function>
local funcs = {}

---@param uuid string
---@param request FOXRPC.CallAddon.Request
function RPC.events.on_receive(uuid, request)
	if request.lib ~= "FOXRPC.Call" then return end
	return { funcs[request.key](uuid, table.unpack(request.val or {})) }
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Library ♡˚
--==============================================================================================================================

---@class FOXRPC.CallAddon
local lib = {}

---@class FOXRPC.CallAddon.Avatar<T>
---@field uuid T
---@field [string|integer] fun(self: self, ...): self

local meta = {
	---Create a new soft link to a remote function.
	---@param key string|integer
	__index = function(_, key)
		---Function that calls remote function. Returns self if the response is empty, otherwise the unpacks and returns the response.
		---@param self FOXRPC.CallAddon.Avatar
		---@return ...
		return function(self, ...)
			---@type FOXRPC.CallAddon.Response
			local response = RPC.send(self.uuid, { lib = "FOXRPC.Call", key = key, val = { ... } })

			if next(response) then
				return table.unpack(response)
			else
				return self
			end
		end
	end,
}

---Gets the functions of an avatar by UUID.
---@generic T
---@param uuid `T`
---@return FOXRPC.CallAddon.Avatar<T>
function lib.get(uuid)
	return setmetatable({ uuid = uuid }, meta)
end

---Registers a new function that can be called by other avatars.
---@param key string|integer
---@param func fun(uuid: string, ...): any
function lib.register(key, func)
	assert(type(func) == "function", "Only functions can be registered")
	funcs[key] = func
end

return lib

--#ENDREGION
