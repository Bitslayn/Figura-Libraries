# FOX's Color Wheel

<img width="800" height="500" alt="thumb-colorwheel" src="https://github.com/user-attachments/assets/3281176c-8b9d-4f9d-a5ea-3e66e3e42c4f" />

## Documentation

```lua
local wheel = require("FOXColorWheel")

wheel:pos(100, 100)
	:scale(2)
	:visible(true)
	:color(vec(1, 1, 0))

print(wheel:getColor())
```

<details>

<summary><code>FOXColorWheel:pos()</code></summary>

Moves the color wheel on the screen

The position is positive `+, +` rather than Figura's negative `-, -`
#### Parameters:
```lua
(method) FOXColorWheel:pos(x: number, y: number)
  -> FOXColorWheel
```
|Name|Type(s)|Description|
|-|-|-|
|self|FOXColorWheel|-|
|x|number|-|
|y|number|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|FOXColorWheel|-|
</details>
<details>

<summary><code>FOXColorWheel:scale()</code></summary>

Scales the color wheel from the center of the wheel
#### Parameters:
```lua
(method) FOXColorWheel:scale(s: number)
  -> FOXColorWheel
```
|Name|Type(s)|Description|
|-|-|-|
|self|FOXColorWheel|-|
|s|number|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|FOXColorWheel|-|
</details>
<details>

<summary><code>FOXColorWheel:visible()</code></summary>

Sets the visibility state of the color wheel
#### Parameters:
```lua
(method) FOXColorWheel:visible(state: boolean)
  -> FOXColorWheel
```
|Name|Type(s)|Description|
|-|-|-|
|self|FOXColorWheel|-|
|state|boolean|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|FOXColorWheel|-|
</details>
<details>

<summary><code>FOXColorWheel:color()</code></summary>

Sets the previous and current colors being picked
#### Parameters:
```lua
(method) FOXColorWheel:color(rgb: Vector3)
  -> FOXColorWheel
```
|Name|Type(s)|Description|
|-|-|-|
|self|FOXColorWheel|-|
|rgb|[Vector3](https://figura-wiki.pages.dev/globals/Vectors/Vector3)|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|-|FOXColorWheel|-|
</details>
<details>

<summary><code>FOXColorWheel:getColor()</code></summary>

Gets the currently picked color
#### Parameters:
```lua
(method) FOXColorWheel:getColor()
  -> rgb: Vector3
```
|Name|Type(s)|Description|
|-|-|-|
|self|FOXColorWheel|-|
#### Returns:
|Name|Type(s)|Description|
|-|-|-|
|rgb|[Vector3](https://figura-wiki.pages.dev/globals/Vectors/Vector3)|-|
</details>

## Example Snippet
This example script integrates with Figura's action wheel.

Each action centers the wheel to the screen. You can additionaly call `wheel:color()` with the previous picked color, then set `on_close` to a function that runs post processing such as applying the color to an outfit. 

```lua
local wheel = require("FOXColorWheel")
local is_coloring = false
local on_close = function() end

-- Keybind
keybinds:fromVanilla("figura.config.action_wheel_button")
	:onRelease(function()
		if not is_coloring then return end

		-- Show wheel
		wheel:visible(true)
		renderer:setRenderCrosshair(false)
		host:setUnlockCursor(true)
	end)
	:onPress(function()
		if not is_coloring then return end

		-- Hide wheel
		wheel:visible(false)
		renderer:setRenderCrosshair(true)
		host:setUnlockCursor(false)

		on_close()
		is_coloring = false
	end)

-- Get the default action page
local page = action_wheel:getCurrentPage()
if not page then
	page = action_wheel:newPage()
end

-- Create actions
page:newAction()
	:title("Color Wheel (Main)")
	:item("red_dye")
	:onLeftClick(function()
		-- Center to screen
		local x, y = (client:getWindowSize() / client.getGuiScale() / 2):unpack()
		wheel:pos(x, y)

		-- Load default color
		wheel:color(vec(1, 0, 0))

		-- Queue wheel
		is_coloring = true
		function on_close()
			print("Main", wheel:getColor())
		end
	end)

page:newAction()
	:title("Color Wheel (Alt)")
	:item("blue_dye")
	:onLeftClick(function()
		-- Center to screen
		local x, y = (client:getWindowSize() / client.getGuiScale() / 2):unpack()
		wheel:pos(x, y)

		-- Load default color
		wheel:color(vec(math.random(), math.random(), math.random()))

		-- Queue wheel
		is_coloring = true
		function on_close()
			print("Alt", wheel:getColor())
		end
	end)
```
