# Guide
You can send requests to other avatars by passing in their UUID and giving a request

Avatar A - Sender
```lua
local RPC = require("./RPC")

local ok, res = pcall(RPC.send, "18af3143-5056-4122-9c8c-9d3eb956c407", { wave = true }) -- Pcall as RPC.send is errorable
if ok and res.success then
    animations.model.Wave:play() -- Wave back
end
```
Their avatar would listen for the request and send a response. Requests can be filtered out by sender uuid.

Avatar B - Receiver
```lua
local RPC = require("./RPC")

function RPC.events.on_receive(uuid, request)
  if uuid ~= "6284a02d-272a-4d4e-9788-fbcf0a835337" then return end -- Only receive from Avatar A

  if request.wave then
    animations.model.Wave:play()
    return { success = true } -- Responses have to also be tables
  end
end
```
Anything that is not a string, number, or boolean will be stripped from the request and response.
# Call Addon
There is an addon which makes the process more streamlined by introducing chainable methods.
Avatar A - Caller
```lua
local RPC_Call = require("./RPC_Call")

local avatar_b = RPC_Call.get("18af3143-5056-4122-9c8c-9d3eb956c407")

if avatar_b:wave() == true then
    animations.model.Wave:play() -- Wave back
end
```
Their avatar would listen for the request and send a response. Requests can be filtered out by sender uuid.

Avatar B - Library Holder
```lua
local RPC_Call = require("./RPC_Call")

RPC_Call.register("wave", function(uuid, ...)
    if uuid ~= "6284a02d-272a-4d4e-9788-fbcf0a835337" then return end -- Only wave to Avatar A
    animations.model.Wave:play()
    return true
end)
```
