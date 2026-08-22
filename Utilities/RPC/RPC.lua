--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's RPC Protocol v1.1

Allows for securely sending and receiving messages between avatars

Github: https://github.com/Bitslayn/Figura-Libraries/tree/main/Utilities/RPC
]]

--==============================================================================================================================
--#REGION ˚♡ Shared ♡˚
--==============================================================================================================================

---Calls the function off-stack
---
---Makes stack overflow errors pcallable
---@param f function
---@param ... any
---@return any ...
local function branch_stack(f, ...)
	local var, out = { ... }, {}

	vectors.vec2():applyFunc(function(_, i)
		---@diagnostic disable-next-line: missing-return-value, missing-return
		if i > 1 then return end; out = { f(table.unpack(var)) }
	end)

	return table.unpack(out)
end

---Runs the table through the json serializer
---
---Functionally copies the table while removing Userdata, functions, and other non-serializable types
---@param t table
---@return table t
local function sanitize(t)
	return parseJson(branch_stack(toJson, t))
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Endpoints ♡˚
--==============================================================================================================================

local session = client.intUUIDToString(client.generateUUID())

---This event runs whenever an avatar sends a request. Returning a table from this event will send a response.
---
---If multiple `on_receive` events return a response, the responses get merged together into a single table.
---@alias FOXRPC.Events.OnReceive fun(uuid: string, request: table): response: table?
---@class FOXRPC.Events
---@field on_receive FOXRPC.Events.OnReceive

local event = {
	---@type FOXRPC.Events.OnReceive[]
	on_receive = {},
}

---Creates a new endpoint with the uuid being that of the intended sender
---@param uuid string
---@return FOXRPC.Endpoint
local function new_endpoint(uuid)
	return function(request)
		local vars = world.avatarVars()[avatar:getUUID()]
		assert(vars and vars.FOXRPC and vars.FOXRPC.session == session, "Avatar session expired")

		request = sanitize(request)

		local response = {}
		for i = 1, #event.on_receive do
			local t = event.on_receive[i](uuid, request)
			if t then
				for k, v in next, t do response[k] = v end
			end
		end

		return sanitize(response)
	end
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Prompter/Acceptor ♡˚
--==============================================================================================================================

---@alias FOXRPC.Vars {FOXRPC: FOXRPC.Store?}
---@class FOXRPC.Store
---@field endpoint FOXRPC.Endpoint?
local store = { version = "1.1", session = session }
avatar:store("FOXRPC", store)
local avatar_uuid = avatar:getUUID()

---@alias FOXRPC.Endpoint fun(pl: table): table
---@type FOXRPC.Endpoint
local endpoint

---Create new endpoint for uuid
---@param uuid string
function store.prompter(uuid)
	---@type FOXRPC.Vars?
	local vars = world.avatarVars()[uuid]
	if not (vars and vars.FOXRPC) then return end

	-- Refuse connection if this script is outdated
	if client.compareVersions(store.version, vars.FOXRPC.version) == -1 then return end

	store.endpoint = new_endpoint(uuid)
	pcall(branch_stack, vars.FOXRPC.acceptor, avatar_uuid)
	store.endpoint = nil
end

---Fetch created endpoint from uuid
---@param uuid string
function store.acceptor(uuid)
	---@type FOXRPC.Vars?
	local vars = world.avatarVars()[uuid]
	if not (vars and vars.FOXRPC) then return end

	if vars.FOXRPC.endpoint then
		endpoint = vars.FOXRPC.endpoint
	end
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ API ♡˚
--==============================================================================================================================

---@class FOXRPC
local FOXRPC = {
	---@type FOXRPC.Events
	events = setmetatable({}, { __newindex = function(_, k, v) event[k][#event[k] + 1] = v end }),
}

---Send an RPC request to an avatar, then immediately returns the avatar's response.
---
---Throws if any issues occur during transit.
---@param uuid string
---@param request table
---@return table response
function FOXRPC.send(uuid, request)
	---@type FOXRPC.Vars?
	local vars = world.avatarVars()[uuid]
	assert(vars and vars.FOXRPC, "Avatar doesn't have FOXRPC")

	branch_stack(vars.FOXRPC.prompter, avatar_uuid)
	local response = branch_stack(endpoint, sanitize(request))

	return sanitize(response)
end

return FOXRPC

--#ENDREGION
