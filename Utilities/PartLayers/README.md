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

```lua
local jacket = models.model.root.Body.Jacket
local pride_pin = textures["pride_pin"]

jacket:setTextureLayer(3, "CUSTOM", pride_pin)
```
#### Parameters:
```lua
(method) ModelPart:setTextureLayer(layer: integer, textureType?: ModelPart.textureType, source?: string|Texture)
  -> ModelPart
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
|textureType|[ModelPart.textureType](https://figura-wiki.pages.dev/enums/TextureTypes) (Optional)|Defaults to `"PRIMARY"` or `"SECONDARY"`|
|source|string or [Texture](https://figura-wiki.pages.dev/globals/Textures/Texture) (Optional)|Required for `"RESOURCE"` and `"CUSTOM"` texture types|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|Returns `self` for chaining|
</details>
<details>

<summary><code>ModelPart:getTextureLayer()</code></summary>

Gets the texture layer of this part.

```lua
local jacket = models.model.root.Body.Jacket

local textureType, source = jacket:getTextureLayer(3)

print(textureType, source)
```
#### Parameters:
```lua
(method) ModelPart:getTextureLayer(layer: integer)
  -> textureType: (ModelPart.textureType)?
  2. source: (string|Texture)?
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|textureType|[ModelPart.textureType](https://figura-wiki.pages.dev/enums/TextureTypes) (Optional)|Returns the texture type stored for this layer if this layer is defined|
|source|string or [Texture](https://figura-wiki.pages.dev/globals/Textures/Texture) (Optional)|Returns the source stored for this layer if the texture type is either `"RESOURCE"` or `"CUSTOM"`|
</details>
<details>

<summary><code>ModelPart:getTextureLayers()</code></summary>

Gets a list of all textures applied to this ModelPart indexed by its layer.

Also returns the number of texture layers currently applied.
#### Parameters:
```lua
(method) ModelPart:getTextureLayers()
  -> ((string|Texture)?)[]
  2. integer
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|string or [Texture](https://figura-wiki.pages.dev/globals/Textures/Texture) array (Optional fields)|-|
|-|integer|-|
</details>
<details>

<summary><code>ModelPart:setRenderTypeLayer()</code></summary>

**Aliases:** `ModelPart:renderTypeLayer()`

Sets the render type of this part at the given layer.

This part inherits from its parent if `renderType` is `nil`.
#### Parameters:
```lua
(method) ModelPart:setRenderTypeLayer(layer: integer, renderType?: ModelPart.renderType)
  -> ModelPart
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
|renderType|[ModelPart.renderType](https://figura-wiki.pages.dev/enums/RenderTypes) (Optional)|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
</details>
<details>

<summary><code>ModelPart:getRenderTypeLayer()</code></summary>

Gets the render type of this part at the given layer.

Returns `nil` if it is inheriting from its parent.
#### Parameters:
```lua
(method) ModelPart:getRenderTypeLayer(layer: integer)
  -> (ModelPart.renderType)?
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|[ModelPart.renderType](https://figura-wiki.pages.dev/enums/RenderTypes) (Optional)|-|
</details>
<details>

<summary><code>ModelPart:setColor()</code></summary>

**Aliases:** `ModelPart:color()`

Sets the color multiplier of this part.

This is a multiplier, that means that `1, 1, 1` will result in no change and `0, 0, 0` will result in black.

If a color channel is nil, it will default to `1`.
#### Parameters:
```lua
(method) ModelPart:setColor(r?: number|Vector3, g?: number, b?: number)
  -> ModelPart
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|r|number or [Vector3](https://figura-wiki.pages.dev/globals/Vectors/Vector3) (Optional)|-|
|g|number (Optional)|-|
|b|number (Optional)|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
</details>
<details>

<summary><code>ModelPart:setColorLayer()</code></summary>

**Aliases:** `ModelPart:colorLayer()`

Sets the color multiplier of this part at the given layer.

This is a multiplier, that means that `1, 1, 1` will result in no change and `0, 0, 0` will result in black.

If a color channel is nil, it will default to `1`.
#### Parameters:
```lua
(method) ModelPart:setColorLayer(layer: integer, r?: number|Vector3, g?: number, b?: number)
  -> ModelPart
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
|r|number or [Vector3](https://figura-wiki.pages.dev/globals/Vectors/Vector3) (Optional)|-|
|g|number (Optional)|-|
|b|number (Optional)|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
</details>
<details>

<summary><code>ModelPart:getColorLayer()</code></summary>

Gets the color multiplier of this part.

This is a multiplier, that means that `1, 1, 1` will result in no change and `0, 0, 0` will result in black.
#### Parameters:
```lua
(method) ModelPart:getColorLayer(layer: integer)
  -> Vector3
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|[Vector3](https://figura-wiki.pages.dev/globals/Vectors/Vector3)|-|
</details>