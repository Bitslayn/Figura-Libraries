<details>

<summary><code>FOXP2P.send()</code></summary>

Sends the given payload to the user

Throws if this user doesn't have FOX Peer-to-peer or the payload is invalid

Returns if the payload was sent successfully, and a response
#### Parameters:
```lua
function FOXP2P.send(uuid: string, payload: string|table)
  -> success: boolean
  2. response: any
```
|Name|Type(s)|Description|
|-|-|-|
|uuid|string|-|
|payload|string or table|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|success|boolean|-|
|response|any|-|
</details>