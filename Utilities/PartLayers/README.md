# FOX's Part Layers

## Description

## Guide

## Documentation
<details>

<summary><code>ModelPart:setTextureLayer()</code></summary>

**Aliases:** `ModelPart:textureLayer()`

Sets the texture layer of this part.

Layers can be removed if a texture type isn't provided when calling this method.

A custom texture type requires a Texture in the source field. Similarly, a resource string is required for the resource texture type.

#### Parameters:

```lua
ModelPart:setTextureLayer(layer, textureType, source)
```

| Name | Type(s) | Description |
| - | - | - |
| layer | integer | Target layer index |
| textureType | [ModelPart.textureType](https://figura-wiki.pages.dev/enums/TextureTypes) (Optional) | Defaults to `"PRIMARY"` or `"SECONDARY"` |
| source | string or [Texture](https://figura-wiki.pages.dev/globals/Textures/Texture) (Optional) | Required for `"RESOURCE"` and `"CUSTOM"` texture types |

<details>

<summary>Overloads</summary>

The `"RESOURCE"` texture type requires a resource string in the source field

| Name | Type(s) |
| - | - |
| layer | integer |
| textureType | "RESOURCE" |
| source | string |

The `"CUSTOM"` texture type requires a Texture in the source field

| Name | Type(s) |
| - | - |
| layer | integer |
| textureType | "CUSTOM" |
| source | [Texture](https://figura-wiki.pages.dev/globals/Textures/Texture) |

</details>

#### Returns:

| Name | Type(s) | Description |
| - | - | - |
| - | [ModelPart](https://figura-wiki.pages.dev/globals/Models) | Returns `self` for chaining |

#### Example:

```lua
local jacket = models.model.root.Body.Jacket
local pride_pin = textures["pride_pin"]

jacket:setTextureLayer(3, "CUSTOM", pride_pin)
```

</details>
<details>

<summary><code>ModelPart:getTextureLayer()</code></summary>

Gets the texture layer of this part.

#### Parameters:

```lua
ModelPart:setTextureLayer(layer)
```

| Name | Type(s) | Description |
| - | - | - |
| layer | integer | Target layer index |

#### Returns:

| Name | Type(s) | Description |
| - | - | - |
| textureType | [ModelPart](https://figura-wiki.pages.dev/globals/Models) | Returns the texture type stored for this layer if this layer is defined |
| source | string or [Texture](https://figura-wiki.pages.dev/globals/Textures/Texture) (Optional) | Returns the source stored for this layer if the texture type is either `"RESOURCE"` or `"CUSTOM"` |

#### Example:

```lua
local jacket = models.model.root.Body.Jacket

local textureType, source = jacket:getTextureLayer(3)

print(textureType, source)
```

</details>