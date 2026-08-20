--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Lift Protocol v2.0

A unique interactions protocol focusing on security
Allows for interacting with the viewer with a whitelist
Supports Extura, Goofy, Silly, or a custom addon

Github: https://github.com/Bitslayn/FOX-s-Figura-APIs/blob/main/Utilities/LiftP2P
]]

--==============================================================================================================================
--#REGION ˚♡ Config ♡˚
--==============================================================================================================================

local p2p = require("./p2p")

---@class FOXLiftP2P.Config
local cfg = {
	---Set whether other players can move you
	enabled = true,
	---If true, uses the whitelist as a blacklist
	blacklist = false,
	---List of names who are allowed to call your functions
	---@type table<string, boolean>
	whitelist = {
		Steve = true,
		Alex = true,
	},
}

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Movement functions ♡˚
--==============================================================================================================================

-- Send ping to host to lift player
-- Host pings back saying they're being lifted
-- Everyone sees the lifter and liftee call their events

---@type table<string, function>
---@diagnostic disable-next-line: undefined-global
local api = silly or goofy or host

---@alias FOXLiftP2P.Actions
---| "setPos"
---| "setRot"
---| "setVel"
---| "setVelocity"
local allowed = { setPos = true, setRot = true, setVel = true, setVelocity = true }

---@class FOXLiftP2P.Payload
---@field protocol "Lift"?
---@field action string? The name of the function being called
---@field args number[]? The vector as an array of numbers
---@field ctx string? The reason for lifting this person

---@alias FOXLiftP2P.Events.Generic fun(uuid: string, action: FOXLiftP2P.Actions, ctx: string)
---@alias FOXLiftP2P.Events.Expire fun(uuid: string)
---@class FOXLiftP2P.Events
---@field on_lift FOXLiftP2P.Events.Generic Event called when you start being lifted by someone. Gives you their UUID, the function key, and a custom context
---@field each_lift FOXLiftP2P.Events.Generic Event called each call to lift you by someone. Gives you their UUID, the function key, and a custom context
---@field on_unlift FOXLiftP2P.Events.Expire Event called after you stop being lifted by someone. Gives you their UUID

local event = {
	---@type FOXLiftP2P.Events.Generic[]
	on_lift = {},
	---@type FOXLiftP2P.Events.Generic[]
	each_lift = {},
	---@type FOXLiftP2P.Events.Expire[]
	on_unlift = {},
}

---@type table<string, integer>
local lifters = {}

function events.tick()
	for uuid, t in pairs(lifters) do
		if t > 1 then
			lifters[uuid] = t - 1
		else
			for i = 1, #event.on_unlift do event.on_unlift[i](uuid) end
			lifters[uuid] = nil
		end
	end
end

---@param uuid string
---@param payload FOXLiftP2P.Payload
function p2p.events.on_receive(uuid, payload)
	if payload.protocol ~= "Lift" then return end

	local whitelist = not cfg.blacklist ~= not (cfg.whitelist[uuid] or cfg.whitelist[world.getEntity(uuid) and world.getEntity(uuid):getName()])
	if not (whitelist and allowed[payload.action]) then return end

	if not payload.args then return end
	pcall(api[payload.action], api, payload.args[1], payload.args[2], payload.args[3])

	if not lifters[uuid] then
		for i = 1, #event.on_lift do event.on_lift[i](uuid, payload.action, payload.ctx) end
	end
	lifters[uuid] = 5

	for i = 1, #event.each_lift do event.each_lift[i](uuid, payload.action, payload.ctx) end
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ API ♡˚
--==============================================================================================================================

-- TODO "add" and "sendPacket" overload or something

---@alias FOXLiftP2P.Position
---| fun(uuid: string, x: number?, y: number?, z: number?, ctx: string?): boolean, any
---| fun(uuid: string, pos: Vector3, ctx: string?): boolean, any
---@alias FOXLiftP2P.Rotation
---| fun(uuid: string, x: number?, y: number?, ctx: string?): boolean, any
---| fun(uuid: string, rot: Vector2, ctx: string?): boolean, any
---@alias FOXLiftP2P.Velocity
---| fun(uuid: string, x: number?, y: number?, z: number?, ctx: string?): boolean, any
---| fun(uuid: string, vel: Vector3, ctx: string?): boolean, any
---@class FOXLiftP2P.MovementFunctions
---@field setPos FOXLiftP2P.Position
---@field setRot FOXLiftP2P.Rotation
---@field setVel FOXLiftP2P.Velocity
---@field setVelocity FOXLiftP2P.Velocity

---@class FOXLiftP2P: FOXLiftP2P.MovementFunctions
local lift = {
	---@type FOXLiftP2P.Events
	events = setmetatable({}, {
		__newindex = function(_, k, v)
			assert(type(v) == "function", "Cannot assign value to event", 2)
			event[k][#event[k] + 1] = v
		end,
	}),
}

---Checks if you can lift this avatar
---
---You cannot lift someone who doesn't have you on their whitelist, or doesn't have lift enabled
---@param uuid string
---@return boolean
function lift.can_lift(uuid)
	return p2p.send(uuid, { protocol = "Lift", check = true }).can_lift or false
end

return setmetatable(lift, {
	---Allow indexing `lift` and calling viewer functions
	---@param _ FOXLiftP2P
	---@param key string
	__index = function(_, key)
		---@param uuid string
		---@param x number|Vector2|Vector3
		---@param y number
		---@param z number|string?
		---@param ctx string?
		---@return boolean, any
		return function(uuid, x, y, z, ctx)
			local args

			-- Parse from number params

			if type(z) == "string" then
				args = { x, y }
				ctx = z
			else
				args = { x, y, z }
			end

			-- Parse from vector param

			if type(x):find("Vector") then
				args = { x --[[@as Vector.any]]:unpack() }
				if type(y) == "string" then
					ctx = y
				end
			end

			return pcall(p2p.send, uuid, { protocol = "Lift", action = key, args = args, ctx = ctx or "DEFAULT" })
		end
	end,
})

--#ENDREGION
