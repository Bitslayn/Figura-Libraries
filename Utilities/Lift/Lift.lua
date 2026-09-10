--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Lift v2.0

Allows for interacting with the viewer with a whitelist
Uses SillyPlugin for its movement functions

Github: https://github.com/Bitslayn/Figura-Libraries/tree/main/Utilities/Lift
]]

--==============================================================================================================================
--#REGION ˚♡ Config ♡˚
--==============================================================================================================================

---@class FOXLift.Config
---@field whitelist table<FOXLift.PlayerID, boolean>
local config = {
	---Set whether other players can move you
	enabled = true,
	---If true, uses the whitelist as a blacklist
	blacklist = false,
	---List of names or uuids who are allowed to call your functions
	whitelist = {
		Steve = true,
		Alex = true,
	},
}

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Movement ♡˚
--==============================================================================================================================

-- If you don't use SillyPlugin then you may want to change these functions.
-- Security isn't much of a concern here as it is impossible for someone to send a NaN, Infinity, or other non-serializable types.
-- Avoid changing any fields or adding functions that other players wouldn't otherwise know about.

---@class FOXLift.MovementFunctions
local internal = {}

---Tries to set the position of a player
---
---Can fail if there are blocks in the way
---@param id FOXLift.PlayerID
---@param x number
---@param y number
---@param z number
---@param ctx string?
---@overload fun(id: FOXLift.PlayerID, pos: Vector3, ctx: string?)
---@diagnostic disable-next-line: unused-local
function internal.setPos(id, x, y, z, ctx)
	silly:setPos(x, y, z)
end

---Tries to move a player relative to their current position
---
---Can fail if there are blocks in the way
---@param id FOXLift.PlayerID
---@param x number
---@param y number
---@param z number
---@param ctx string?
---@overload fun(id: FOXLift.PlayerID, pos: Vector3, ctx: string?)
---@diagnostic disable-next-line: unused-local
function internal.addPos(id, x, y, z, ctx)
	local _x, _y, _z = player:getPos():unpack()
	silly:setPos(x + _x, y + _y, z + _z)
end

---Forcefully sets the position of a player
---
---Ignores walls but can fail if the destination is inside a block
---@param id FOXLift.PlayerID
---@param x number
---@param y number
---@param z number
---@param ctx string?
---@overload fun(id: FOXLift.PlayerID, pos: Vector3, ctx: string?)
---@diagnostic disable-next-line: unused-local
function internal.forcePos(id, x, y, z, ctx)
	---@diagnostic disable-next-line: unused-local
	local _x, _y, _z = player:getPos():unpack()
	silly:setPos(_x, 321, _z, true)
	silly:setPos(x, 321, z, true)
	silly:setPos(x, y, z, true)
end

---Sets the velocity of a player
---@param id FOXLift.PlayerID
---@param x number
---@param y number
---@param z number
---@param ctx string?
---@overload fun(id: FOXLift.PlayerID, vel: Vector3, ctx: string?)
---@diagnostic disable-next-line: unused-local
function internal.setVel(id, x, y, z, ctx)
	silly:setVel(x, y, z)
end

---Adds to the velocity of a player
---@param id FOXLift.PlayerID
---@param x number
---@param y number
---@param z number
---@param ctx string?
---@overload fun(id: FOXLift.PlayerID, vel: Vector3, ctx: string?)
---@diagnostic disable-next-line: unused-local
function internal.addVel(id, x, y, z, ctx)
	local _x, _y, _z = table.unpack(player:getNbt().Motion)
	silly:setVel(x + _x, y + _y, z + _z)
end

---Sets the head rotation of a player
---@param id FOXLift.PlayerID
---@param x number
---@param y number
---@param ctx string?
---@overload fun(id: FOXLift.PlayerID, rot: Vector2, ctx: string?)
---@diagnostic disable-next-line: unused-local
function internal.setRot(id, x, y, ctx)
	silly:setRot(x, y)
end

---Adds to the head rotation of a player
---@param id FOXLift.PlayerID
---@param x number
---@param y number
---@param ctx string?
---@overload fun(id: FOXLift.PlayerID, rot: Vector2, ctx: string?)
---@diagnostic disable-next-line: unused-local
function internal.addRot(id, x, y, ctx)
	local _y, _x = table.unpack(player:getNbt().Rotation)
	silly:setRot(x + _x, y + _y)
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Events ♡˚
--==============================================================================================================================

---@class FOXLift.Events
local event = {
	---@type fun(uuid: string) This event runs the moment you start being lifted by a new person. A callback gives you that person's uuid.
	---@diagnostic disable-next-line: assign-type-mismatch
	on_lift = {},
	---@type fun(uuid: string, ctx: string) This event runs for every lift function called on you. A callback gives you the person's uuid and the lift context.
	---@diagnostic disable-next-line: assign-type-mismatch
	each_lift = {},
	---@type fun(uuid: string) This event runs the moment you stop being lifted by any particular person. A callback gives you that person's uuid.
	---@diagnostic disable-next-line: assign-type-mismatch
	on_unlift = {},

	---@type fun() This event runs the moment you start being lifted by anyone.
	---@diagnostic disable-next-line: assign-type-mismatch
	first_lift = {},
	---@type fun() This event runs the moment you stop being lifted by everyone who was lifting you.
	---@diagnostic disable-next-line: assign-type-mismatch
	last_lift = {},
}

---@type FOXLift.Events
local lift_events = setmetatable({}, {
	__newindex = function(_, k, v)
		assert(type(v) == "function", "Cannot assign value to event")
		event[k][#event[k] + 1] = v
	end,
})

---@type table<string, integer>
local lifters = {}
function events.tick()
	for uuid, t in pairs(lifters) do
		if t > 1 then
			lifters[uuid] = t - 1
		else
			for i = 1, #event.on_unlift do event.on_unlift[i](uuid) end
			lifters[uuid] = nil
			if not next(lifters) then
				for i = 1, #event.last_lift do event.last_lift[i]() end
			end
		end
	end
end

---@param uuid string
---@param ctx string
local function call_events(uuid, ctx)
	if not next(lifters) then
		for i = 1, #event.first_lift do event.first_lift[i]() end
	end
	if not lifters[uuid] then
		for i = 1, #event.on_lift do event.on_lift[i](uuid) end
	end
	lifters[uuid] = 5

	for i = 1, #event.each_lift do event.each_lift[i](uuid, ctx) end
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Gateway ♡˚
--==============================================================================================================================

local session = client.intUUIDToString(client.generateUUID())

---@param uuid string
local function create_gateway(uuid)
	---@param key string
	---@param args table
	return function(key, args)
		local vars = world.avatarVars()[avatar:getUUID()]
		if not vars or vars.FOXLift.session ~= session then return end

		-- Check enabled
		if not config.enabled then return end

		-- Check whitelist
		local entity = world.getEntity(uuid)
		if config.blacklist == (entity and config.whitelist[entity:getName()] or config.whitelist[uuid]) then return end

		-- Call function
		local ok = pcall(internal[key], uuid, table.unpack(args))
		if not ok then return end

		-- Call events
		call_events(uuid, rawget(args, rawlen(args)))
	end
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Protocol ♡˚
--==============================================================================================================================

-- This is the current protocol, made with the help of 4P5.
-- It's very simple, calling acceptors which store only the viewer's proxy function.

-- The proxy function, provided by the wrapper, gives avatars access to functions in the viewer scope.

-- All you'll need to make Lift's protocol compatible with your wrapper is to provide your own proxy and config.
-- You can make the prompter do anything as long as lib.prompted stores the proxy as a function. The prompter is host scope.
-- Modifying what the acceptor does requires a Lift protocol version bump. Avoid touching this as it is viewer scope.
-- When an avatar calls your lib.prompted, they do so as pcall(lib.prompted, key, x, y, z). You will need a __call metamethod in your proxy.

---@class FOXLift.Protocol
---@field config FOXLift.Config
local lib = { config = config, version = 1.4, session = session }
avatar:store("FOXLift", lib)

---Creates and shares proxy function to the requesting avatar.
function lib.prompter(uuid)
	local plr = world.getEntity(uuid)
	if not plr then return end

	local var = plr:getVariable("FOXLift")
	lib.prompted = create_gateway(plr:getUUID())
	pcall(var and var.acceptor)
	lib.prompted = nil
end

---Accepted function stored on other avatars when a function has been accepted from the viewer.
---@type function?
local gateway

---Receives and stores proxy function.
function lib.acceptor()
	local vars = client.getViewer():getVariable("FOXLift")
	gateway = vars.prompted or gateway
end

do
	local vars = client.getViewer():getVariable("FOXLift")
	pcall(vars and vars.prompter, avatar:getUUID())
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Lift ♡˚
--==============================================================================================================================

---Either the player's username or UUID
---@alias FOXLift.PlayerID string

---@param id FOXLift.PlayerID
---@return string? uuid
local function getUUID(id)
	local entity = world.avatarVars()[id] and world.getEntity(id) or world.getPlayers()[id]
	if not entity then return end
	return entity:getUUID()
end

---@class FOXLift: FOXLift.MovementFunctions
local lift = { config = config, internal = internal, events = lift_events }

---Returns if a player has Lift
---@param id FOXLift.PlayerID
---@return boolean
function lift.hasLift(id)
	local vars = world.avatarVars()[getUUID(id)]
	return not not (vars and vars.FOXLift)
end

---Returns if a player with Lift is able to be lifted at all
---@param id FOXLift.PlayerID
---@return boolean
function lift.isEnabled(id)
	local vars = world.avatarVars()[getUUID(id)]
	return vars and vars.FOXLift and vars.FOXLift.config and vars.FOXLift.config.enabled or false
end

---Returns the whitelist table of a player with Lift
---@param id FOXLift.PlayerID
---@return table<FOXLift.PlayerID, boolean>?
function lift.getWhitelist(id)
	local vars = world.avatarVars()[getUUID(id)]
	return vars and vars.FOXLift and vars.FOXLift.config and vars.FOXLift.config.whitelist
end

---Returns if a player with Lift has their whitelist table set to blacklist
---@param id FOXLift.PlayerID
---@return boolean
function lift.usesBlacklist(id)
	local vars = world.avatarVars()[getUUID(id)]
	return vars and vars.FOXLift and vars.FOXLift.config and vars.FOXLift.config.blacklist
end

---Returns if you can lift a player
---@param id FOXLift.PlayerID
---@return boolean
function lift.canLift(id)
	if not (lift.hasLift(id) and lift.isEnabled(id)) then return false end

	local whitelist = lift.getWhitelist(id)
	if not whitelist then return false end

	return lift.usesBlacklist(id) ~= (whitelist[avatar:getEntityName()] or whitelist[avatar:getUUID()])
end

setmetatable(lift, {
	__index = function(_, key)
		return function(id, ...)
			-- Only the viewer can receive Lift requests
			if client.getViewer():getUUID() ~= getUUID(id) then return end

			local args = { ... }

			-- Unpack vector
			if type(args[1]):find("Vector") then
				local vec = { table.remove(args, 1):unpack() }
				for i = 1, #vec do
					table.insert(args, i, vec[i])
				end
			end

			-- Set default context
			if type(args[#args]) ~= "string" then
				args[#args + 1] = "DEFAULT"
			end

			if not gateway then return end
			pcall(gateway, key, parseJson(toJson(args)))
		end
	end,
})

return lift

--#ENDREGION
