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
  -> self: ModelPart
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
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|Returns `self` for chaining|
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
|textureType|[ModelPart.textureType](https://figura-wiki.pages.dev/enums/TextureTypes) (Optional)|Returns the texture type stored for this layer if a texture is defined|
|source|string or [Texture](https://figura-wiki.pages.dev/globals/Textures/Texture) (Optional)|Returns the source stored for this layer if the texture type is either `"RESOURCE"` or `"CUSTOM"`|
</details>
<details>

<summary><code>ModelPart:getTextureLayers()</code></summary>

Gets a list of all textures applied to this ModelPart indexed by its layer.

Also returns the number of texture layers currently applied.

```lua
local jacket = models.model.root.Body.Jacket

local textures, depth = jacket:getTextureLayers()

print(textures, depth)
```
#### Parameters:
```lua
(method) ModelPart:getTextureLayers()
  -> textures: ((string|Texture)?)[]
  2. depth: integer
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|textures|string or [Texture](https://figura-wiki.pages.dev/globals/Textures/Texture) array (Optional fields)|Returns the list of textures excluding inherited ones|
|depth|integer|Returns the number of textures currently applied to this part|
</details>
<details>

<summary><code>ModelPart:setRenderTypeLayer()</code></summary>

**Aliases:** `ModelPart:renderTypeLayer()`

Sets the render type of this part at the given layer.

```lua
local jacket = models.model.root.Body.Jacket

jacket:setRenderTypeLayer(3, "EYES")
```
#### Parameters:
```lua
(method) ModelPart:setRenderTypeLayer(layer: integer, renderType?: ModelPart.renderType)
  -> self: ModelPart
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
|renderType|[ModelPart.renderType](https://figura-wiki.pages.dev/enums/RenderTypes) (Optional)|Defaults to `"EMISSIVE"` for layer 2, but otherwise `"TRANSLUCENT"`|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|Returns `self` for chaining|
</details>
<details>

<summary><code>ModelPart:getRenderTypeLayer()</code></summary>

Gets the render type of this part at the given layer.

```lua
local jacket = models.model.root.Body.Jacket

local renderType = jacket:getRenderTypeLayer()

print(renderType)
```
#### Parameters:
```lua
(method) ModelPart:getRenderTypeLayer(layer: integer)
  -> renderType: (ModelPart.renderType)?
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|renderType|[ModelPart.renderType](https://figura-wiki.pages.dev/enums/RenderTypes) (Optional)|Returns the render type stored for this layer if a render type is defined|
</details>
<details>

<summary><code>ModelPart:setColor()</code></summary>

**Aliases:** `ModelPart:color()`

Sets the texture tint color of this part.

The last two parameters are ignored when a vector color is given.

```lua
local jacket = models.model.root.Body.Jacket
local red = vectors.hexToRGB("red")

jacket:setColor(red)
```
#### Parameters:
```lua
(method) ModelPart:setColor(r?: number|Vector3, g?: number, b?: number)
  -> self: ModelPart
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|r|number or [Vector3](https://figura-wiki.pages.dev/globals/Vectors/Vector3) (Optional)|Defaults to `1`|
|g|number (Optional)|Defaults to `1`|
|b|number (Optional)|Defaults to `1`|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|Returns `self` for chaining|
</details>
<details>

<summary><code>ModelPart:setColorLayer()</code></summary>

**Aliases:** `ModelPart:colorLayer()`

Sets the texture tint color of this part at the given layer.

The last two parameters are ignored when a vector color is given.

```lua
local jacket = models.model.root.Body.Jacket
local red = vectors.hexToRGB("red")

jacket:setColorLayer(3, red)
```
#### Parameters:
```lua
(method) ModelPart:setColorLayer(layer: integer, r?: number|Vector3, g?: number, b?: number)
  -> self: ModelPart
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
|r|number or [Vector3](https://figura-wiki.pages.dev/globals/Vectors/Vector3) (Optional)|Defaults to `1`|
|g|number (Optional)|Defaults to `1`|
|b|number (Optional)|Defaults to `1`|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|Returns `self` for chaining|
</details>
<details>

<summary><code>ModelPart:getColorLayer()</code></summary>

Gets the texture tint color of this part.

```lua
local jacket = models.model.root.Body.Jacket

local color = jacket:getColorLayer(3)

print(color)
```
#### Parameters:
```lua
(method) ModelPart:getColorLayer(layer: integer)
  -> color: Vector3
```
|Name|Type(s)|Description|
|-|-|-|
|self|[ModelPart](https://figura-wiki.pages.dev/globals/Models)|-|
|layer|integer|Target layer index|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|color|[Vector3](https://figura-wiki.pages.dev/globals/Vectors/Vector3)|Returns the color stored for this layer if a color is defined|
</details>