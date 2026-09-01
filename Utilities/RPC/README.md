You can send requests to other avatars by passing in their UUID and giving a request

```lua
local RPC = require("./RPC")

local request = { foo = "bar" }
local ok, res = pcall(RPC.send, "18af3143-5056-4122-9c8c-9d3eb956c407", request)

if res.wave then
  animations.model.Wave:play()
end
```

Their avatar would listen for the request and send a response. Requests can be filtered out by sender uuid.

```lua
local RPC = require("./RPC")

function RPC.events.on_receive(uuid, request)
  if uuid ~= "6284a02d-272a-4d4e-9788-fbcf0a835337" then return end

  if request.foo == "bar" then
    animations.model.Wave:play()

    return { wave = true }
  end
end
```

The sender can then read the response and run their code.

```lua
if res.wave then
  animations.model.Wave:play()
end
```

Anything that is not a string, number, or boolean will be stripped from the request and response.
