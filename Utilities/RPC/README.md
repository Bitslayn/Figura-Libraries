<details>

<summary><code>FOXRPC.send()</code></summary>

Send an RPC request to an avatar, then immediately returns the avatar's response.

Throws if any issues occur during transit.
#### Parameters:
```lua
function FOXRPC.send(uuid: string, request: table)
  -> response: table
```
|Name|Type(s)|Description|
|-|-|-|
|uuid|string|-|
|request|table|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|response|table|-|
</details>