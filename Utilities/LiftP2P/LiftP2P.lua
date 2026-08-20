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

---@type table<string, function>
---@diagnostic disable-next-line: undefined-global
local api = silly or goofy or host
local allowed = { setPos = true, setRot = true, setVel = true, setVelocity = true }

---@class FOXLiftP2P.Payload
---@field protocol "Lift"
---@field action string The name of the function being called
---@field value number[] The vector as an array of numbers
---@field reason string The reason for lifting this person

---@param uuid string
---@param payload FOXLiftP2P.Payload
function p2p.events.on_receive(uuid, payload)
	if payload.protocol ~= "Lift" then return end
	local whitelist = cfg.blacklist ~= (cfg.whitelist[uuid] or cfg.whitelist[world.getEntity(uuid):getName()])
	if not whitelist then return end
	if not allowed[payload.action] then return end

	api[payload.action](api, payload.value[1], payload.value[2], payload.value[3])
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ API ♡˚
--==============================================================================================================================

---@class FOXLiftP2P.MovementFunctions
---@field setPos fun(uuid: string, x: number, y: number, z: number, ctx: string?)
---@field setPos fun(uuid: string, pos: Vector3, ctx: string?)
---@field setRot fun(uuid: string, x: number, y: number, ctx: string?)
---@field setRot fun(uuid: string, rot: Vector2, ctx: string?)
---@field setVel fun(uuid: string, x: number, y: number, z: number, ctx: string?)
---@field setVel fun(uuid: string, vel: Vector3, ctx: string?)
---@field setVelocity fun(uuid: string, x: number, y: number, z: number, ctx: string?)
---@field setVelocity fun(uuid: string, vel: Vector3, ctx: string?)

---@class FOXLiftP2P: FOXLiftP2P.MovementFunctions
local lift = {}

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
		return function(uuid, x, y, z, ctx)
			local value

			-- Parse from number params

			if type(z) == "string" then
				value = { x, y }
				ctx = z
			else
				value = { x, y, z }
			end

			-- Parse from vector param

			if type(x):find("Vector") then
				value = { x --[[@as Vector.any]]:unpack() }
				if type(y) == "string" then
					ctx = y
				end
			end

			return p2p.send(uuid, { protocol = "Lift", action = key, value = value, reason = ctx or "Grab" })
		end
	end,
})

--#ENDREGION
