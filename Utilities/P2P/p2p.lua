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

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Pipes ♡˚
--==============================================================================================================================

local session = client.intUUIDToString(client.generateUUID())

---@alias FOXP2P.Events.OnReceive fun(uuid: string, pl: table): cb: table
---@class FOXP2P.Events
---@field on_receive FOXP2P.Events.OnReceive Executed when someone sends over a payload. Return a table to use as the callback

local event = {
	---@type FOXP2P.Events.OnReceive[]
	on_receive = {},
}

---Creates a new pipe with the uuid being that of the intended sender
---@param uuid string
local function new_pipe(uuid)
	---@param pl table
	---@return table cb
	local pipe = function(pl)
		local vars = world.avatarVars()[avatar:getUUID()]
		assert(vars and vars.FOXP2P and vars.FOXP2P.session == session, "Avatar session expired")

		pl = parseJson(branch_stack(toJson, pl))
		local cb = {}

		for i = 1, #event.on_receive do
			event.on_receive[i](uuid, pl)
		end

		return cb -- Todo, cries in recursion
	end

	return pipe
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Prompter/Acceptor ♡˚
--==============================================================================================================================

---@alias FOXP2P.Pipe fun(pl: string)

---@type FOXP2P.Pipe
local pipe

local avatar_uuid = avatar:getUUID()

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
	pcall(branch_stack, vars.FOXP2P.acceptor, avatar_uuid)
	store.pipe = nil
end

---Fetch created pipe from uuid
---@param uuid string
function store.acceptor(uuid)
	---@type FOXP2P.Vars?
	local vars = world.avatarVars()[uuid]
	if not (vars and vars.FOXP2P) then return end

	if vars.FOXP2P.pipe then
		pipe = vars.FOXP2P.pipe
	end
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ API ♡˚
--==============================================================================================================================

---@class FOXP2P
local p2p = {
	---@type FOXP2P.Events
	events = setmetatable({}, { __newindex = function(_, k, v) event[k][#event[k] + 1] = v end }),
}

---Sends the given payload to the user
---
---Returns a callback
---
---Errorable
---@param uuid string
---@param pl table
---@return table cb
function p2p.send(uuid, pl)
	---@type FOXP2P.Vars?
	local vars = world.avatarVars()[uuid]
	assert(vars and vars.FOXP2P, "Avatar doesn't have FOXP2P")

	branch_stack(vars.FOXP2P.prompter, avatar_uuid)
	local cb = branch_stack(pipe, pl)

	return parseJson(branch_stack(toJson, cb))
end

return p2p

--#ENDREGION
