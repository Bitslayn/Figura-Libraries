--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's P2P Protocol v1.0

Allows for securily sending JSON payloads to other avatars

Github: TODO
]]

--==============================================================================================================================
--#REGION ˚♡ Shared ♡˚
--==============================================================================================================================

-- https://discord.com/channels/1129805506354085959/1234218592187453452/1539761721403768893

---Calls a scrict [pcall](command:extension.lua.doc?["en-us/52/manual.html/pdf-pcall"]) on the function. Protects against stack overflow errors.
---@param f function
---@param ... any
---@return boolean success
---@return any result
---@return any ...
local function strict_pcall(f, ...)
	local var = { ... }
	local out

	local vec = vectors.vec2()
	local ok, res = pcall(vec.applyFunc, vec, function(_, i)
		---@diagnostic disable-next-line: missing-return-value, missing-return
		if i > 1 then return end; out = { f(table.unpack(var)) }
	end)

	if ok then
		return ok, table.unpack(out)
	else
		return ok, res
	end
end

-- https://discord.com/channels/1129805506354085959/1234218592187453452/1357793315302670398

---Returns the type of an argument, bypassing any `__type` or `__metatable` shenanigans.
---@param v any
---@return string type
local function get_type(v)
	return pcall(rawget, v, "") and "table" or type(v)
end

---Packs the given value if it's not already a string
---@param v any
---@return string
local function pack_json(v)
	if get_type(v) == "string" then return v end
	return toJson(v)
end

-- https://discord.com/channels/1129805506354085959/1234218592187453452/1432167163250217003

---Raises an error if the value of its argument v is false (i.e., `nil` or `false`); otherwise, returns all its arguments. In case of error, `message` is the error object; when absent, it defaults to `"assertion failed!"`
---@generic T
---@param v? T
---@param message? any
---@param level? integer
---@return T v
function assert(v, message, level)
	return v or error(message or "Assertion failed!", (level or 1) + 1)
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Pipes ♡˚
--==============================================================================================================================

local session = client.intUUIDToString(client.generateUUID())

---@alias FOXP2P.Events.OnReceive fun(uuid: string, payload: table)
---@class FOXP2P.Events
---@field on_receive FOXP2P.Events.OnReceive

local event = {
	---@type FOXP2P.Events.OnReceive[]
	on_receive = {},
}

---Creates a new pipe with the uuid being that of the intended sender
---@param uuid string
local function new_pipe(uuid)
	---@param payload string
	local pipe = function(payload)
		assert(world.avatarVars()[avatar:getUUID()].FOXP2P.session == session, "Avatar session expired")

		payload = parseJson(payload)

		for i = 1, #event.on_receive do
			event.on_receive[i](uuid, payload)
		end
	end

	return pipe
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Prompter/Acceptor ♡˚
--==============================================================================================================================

---@alias FOXP2P.Pipe fun(payload: string)

---@type table<string, FOXP2P.Pipe>
local pipes = {}

---@alias FOXP2P.Vars {FOXP2P: FOXP2P.Store?}
---@class FOXP2P.Store
---@field pipe FOXP2P.Pipe?
local store = { version = "1.0", session = session }
avatar:store("FOXP2P", store)

---Create new pipe for uuid
---@param uuid string
function store.prompter(uuid)
	---@type FOXP2P.Vars?
	local vars = world.avatarVars()[uuid]
	if not (vars and vars.FOXP2P) then return end

	store.pipe = new_pipe(uuid)
	strict_pcall(vars.FOXP2P.acceptor, avatar:getUUID())
	store.pipe = nil
end

---Fetch created pipe from uuid
---@param uuid string
function store.acceptor(uuid)
	---@type FOXP2P.Vars?
	local vars = world.avatarVars()[uuid]
	if not (vars and vars.FOXP2P) then return end

	if vars.FOXP2P.pipe then
		pipes[uuid] = vars.FOXP2P.pipe
	end
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ API ♡˚
--==============================================================================================================================

---@class FOXP2P
local p2p = {
	---@type FOXP2P.Events
	events = setmetatable({}, {
		__newindex = function(_, k, v)
			assert(get_type(v) == "function", "Cannot assign value to event", 2)
			event[k][#event[k] + 1] = v
		end,
	}),
}

---Sends the given payload to the user
---
---Throws if this user doesn't have FOX Peer-to-peer or the payload is invalid
---
---Returns if the payload was sent successfully, and a response
---@param uuid string
---@param payload string|table
---@return boolean success
---@return any response
function p2p.send(uuid, payload)
	-- Open pipe

	store.prompter(uuid)

	local pipe = pipes[uuid]
	assert(pipe, "Failed opening pipe", 2)

	-- Package payload

	local ok1, json = strict_pcall(pack_json, payload)
	assert(ok1, "Failed packaging payload", 2)

	-- Send payload

	return strict_pcall(pipe, json)
end

return p2p

--#ENDREGION
