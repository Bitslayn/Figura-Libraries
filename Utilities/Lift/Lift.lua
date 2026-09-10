--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Lift v2.1

Allows for interacting with the viewer with a whitelist
Uses SillyPlugin for its movement functions

Github: https://github.com/Bitslayn/Figura-Libraries/tree/main/Utilities/Lift
]]

--==============================================================================================================================
--#REGION ˚♡ Config ♡˚
--==============================================================================================================================

-- FOXRPC is required to use Lift v2.x
-- https://github.com/Bitslayn/Figura-Libraries/tree/main/Utilities/RPC

local RPC = require("./RPC")

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
--#REGION ˚♡ Lift ♡˚
--==============================================================================================================================

---@class FOXLift: FOXLift.MovementFunctions
local lift = { config = config, internal = internal }
avatar:store("LiftRPC", config)

---Either the player's username or UUID
---@alias FOXLift.PlayerID string

---@param id FOXLift.PlayerID
---@return string? uuid
local function getUUID(id)
	local entity = world.avatarVars()[id] and world.getEntity(id) or world.getPlayers()[id]
	if not entity then return end
	return entity:getUUID()
end

---Returns if a player has LiftRPC
---@param id FOXLift.PlayerID
---@return boolean
function lift.hasLift(id)
	local vars = world.avatarVars()[getUUID(id)]
	return not not (vars and vars.LiftRPC)
end

---Returns if a player with LiftRPC is able to be lifted at all
---@param id FOXLift.PlayerID
---@return boolean
function lift.isEnabled(id)
	local vars = world.avatarVars()[getUUID(id)]
	return vars and vars.LiftRPC and vars.LiftRPC.enabled or false
end

---Returns the whitelist table of a player with LiftRPC
---@param id FOXLift.PlayerID
---@return table<FOXLift.PlayerID, boolean>?
function lift.getWhitelist(id)
	local vars = world.avatarVars()[getUUID(id)]
	return vars and vars.LiftRPC and vars.LiftRPC.whitelist
end

---Returns if a player with LiftRPC has their whitelist table set to blacklist
---@param id FOXLift.PlayerID
---@return boolean
function lift.usesBlacklist(id)
	local vars = world.avatarVars()[getUUID(id)]
	return vars and vars.LiftRPC and vars.LiftRPC.blacklist
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
lift.events = setmetatable({}, {
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
---@param request FOXLift.Request
local function call_events(uuid, request)
	local ctx = request.val[#request.val]

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
--#REGION ˚♡ RPC ♡˚
--==============================================================================================================================

---@class FOXLift.Request
---@field lib "Lift"
---@field id integer
---@field key string
---@field val unknown[]

---@param uuid string
---@param request FOXLift.Request
function RPC.events.on_receive(uuid, request)
	if request.lib ~= "Lift" then return end

	-- Check enabled
	if not lift.config.enabled then return end

	-- Check whitelist
	local entity = world.getEntity(uuid)
	if lift.config.blacklist == (entity and lift.config.whitelist[entity:getName()] or lift.config.whitelist[uuid]) then return end

	-- Call function
	local ok = pcall(lift.internal[request.key], uuid, table.unpack(request.val))
	if not ok then return end

	-- Call events
	call_events(uuid, request)
end

setmetatable(lift, {
	__index = function(_, key)
		return function(id, ...)
			local val = { ... }

			-- Unpack vector
			if type(val[1]):find("Vector") then
				local vec = { table.remove(val, 1):unpack() }
				for i = 1, #vec do
					table.insert(val, i, vec[i])
				end
			end

			-- Set default context
			if type(val[#val]) ~= "string" then
				val[#val + 1] = "DEFAULT"
			end

			pcall(RPC.send, getUUID(id), { lib = "Lift", key = key, val = val })
		end
	end,
})

return lift

--#ENDREGION
