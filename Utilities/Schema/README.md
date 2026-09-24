# Introduction

Schema allows you to encode and decode tables into binary. You create a schema based on the table you want to convert, and then call the encoder/decoder to run the conversion.

So who is this for? This script is for anyone who's wanting to ping structured tables of data without overrunning resource limits. This can also be used for general data compression.

# Benchmarks

Schema takes advantage of integers for pinging data. A single integer could cost 2 - 5 bytes. In contrast, pinging Figura tables cost 3 bytes per table entry, plus an additional 3 bytes.

For these benchmarks, I will be pinging a table of booleans. Schema is capable of compressing more complex types, but a table of booleans acts as a good baseline.

| Type                  | Bools | Bytes    |
| --------------------- | ----- | -------- |
| `...integer` (Schema) | 4     | 2 bytes  |
| `...integer` (Schema) | 26    | 5 bytes  |
| `boolean[]`           | 4     | 15 bytes |
| `boolean[]`           | 26    | 81 bytes |

<details>

<summary><code>Code</code></summary>

```lua
--[[ Pinging array of 4 booleans

h - w/ holes
x - depth
b - value

hxxxbbbb
01001111
]]

-- 7.5x smaller

local states = { true, true, true, true }

ping(states) -- 15 bytes
ping(Schema.list(Schema.uint(3), Schema.bool()):encode(states)) -- 2 bytes
```

```lua
--[[ Pinging array of 26 booleans

h - w/ holes
x - depth
b - value

hxxxxxbb bbbbbbbb bbbbbbbb bbbbbbbb
01101011 11111111 11111111 11111111
]]

-- 16.2x smaller

local states = {}
for i = 1, 26 do
	states[i] = true
end

ping(states) -- 81 bytes
ping(Schema.list(Schema.uint(5), Schema.bool()):encode(states)) -- 5 bytes
```

```lua
--[[ Pinging array of 4 booleans (with holes)

h : w/ holes
x : depth
b : value
i : index
- : empty

hxxxiiib iiibiiib iiib----
11000011 01010111 10010000
]]

-- 3.75x smaller

local states = { [1] = true, [2] = true, [4] = true, [5] = true }

ping(states) -- 15 bytes (Unchanged)
ping(Schema.list(Schema.uint(3), Schema.bool()):encode(states)) -- 4 bytes
```

```lua
--[[ Pinging array of 26 booleans (with holes)

h : w/ holes
x : depth
b : value
i : index
- : empty

hxxxxx + (iiiiib x 26) + ----
111010 + (000001 x 26) + 0000
]]

-- We know from the previous test that Figura pings tables with keys
-- regardless given the unchanged byte count, so we'll just enable the
-- flag to read keys with Schema.

-- 3.375x smaller

local states = {}
for i = 1, 26 do
	states[i] = true
end

ping(states) -- 81 bytes
ping(Schema.list(Schema.uint(5), Schema.bool()):encode(states)) -- 24 bytes
```

</details>

# Documentation

This library is complex and requires that you read everything so you know what you're doing. **Do not just copy and paste code blindly!**

Each example expects that you've read and fully understood the last. If you don't understand something, or you have any questions or comments, please feel free to reach out in the thread.

## Integers : `Schema.uint(width)`

### Description

Integers represent variable width numbers. The "u" in `uint` stands for unsigned.

### Parameters

- **Width** - Defines how many bits to consume. The range for that integer becomes width ^ 2 - 1.

### Example

```lua
local Schema = require("Schema")

--- An integer ranging 0 - 15 (2^4-1)
local integer_schema = Schema.uint(4)
```

---

## Booleans : `Schema.bool()`

### Description

Booleans consume a single bit and represent either `true` or `false`. The boolean schema takes no parameters.

### Example

```lua
local Schema = require("Schema")

--- A simple boolean
local boolean_schema = Schema.bool()
```

---

## Lists : `Schema.list(key, value)`

### Description

Lists represent tables. During compression, lists have the ability to omit the key if the table doesn't contain holes. Lists can also be nested to build more complex types.

### Parameters

When calling `Schema.list()`, you must provide two parameters of either a `uint` or an `enum`. Additionally, you can provide a `list` as the second parameter which allows for nesting tables.

- **Key** - The first parameter is the key. It determines how many indices can fit in this table. For example, when you provide a `Schema.uint()` and give the width, you're saying the table can have width ^ 2 - 1 indices.
- **Value** - The second parameter is the value. This is pretty self-explanatory.

### Example

```lua
local Schema = require("Schema")

-- Symolic of the boolean[] type, has a max depth of 7 indices.
local state_schema =
	-- boolean[]
	Schema.list(Schema.uint(3),
		-- boolean
		Schema.bool()
	)

-- Extra example with nested tables
local nested_schema =
	-- integer[][]
	Schema.list(Schema.uint(3),
		-- integer[]
		Schema.list(Schema.uint(2),
			-- integer
			Schema.uint(4)
		)
	)
```

---

## Enums : `Schema.enum(key, enum)`

### Description

Enums allow you to substitute values with other values. It's important to remember that you're not reading a string or another type from the binary directly. You're still reading an integer, but it's being translated to something else.

### Parameters

When calling `Schema.enum()`, you provide a table that is used to map one value to another.

- **Key** - The first parameter is the key. It takes a schema such as `uint` or `bool`, but can also take other enums.
- **Enum** - The second parameter is the enum. This takes a table which returns the value corresponding to the key.

### Example

```lua
local Schema = require("Schema")

-- This is the same as `Schema.bool()`
local boolean_schema = Schema.enum(Schema.uint(1), {
	[0] = false,
	[1] = true,
})

-- Converts 0 -> "helmet" and so on
local armor_schema = Schema.enum(Schema.uint(4), {
	[0] = "helmet",
	[1] = "chestplate",
	[2] = "leggings",
	[3] = "boots",
})

-- Symbolic of table<string, boolean>, where the string is our armor type
local visible_schema = Schema.list(armor_schema, boolean_schema)
```

---

# Guide

TODO Explain how to use this with pings. Explain the process of creating a schema from a table's type, limitations or what to note when thinking about what types can be represented, and how to encode/decode a table.

```lua
local Schema = require("Schema")

---@alias Outfit table<Outfit.ClothesTypes, Outfit.ClothesProps[]>
---@alias Outfit.ClothesTypes "hats"|"shirts"|"gloves"|"pants"|"socks"|"shoes"
---@class Outfit.ClothesProps
---@field id integer
---@field color integer

local clothes_types = Schema.enum(Schema.uint(3), { "hats", "shirts", "gloves", "pants", "socks", "shoes" })
local clothes_props = Schema.enum(Schema.uint(2), { "id", "color" })

local clothes_schema = Schema.list(clothes_types, Schema.list(Schema.uint(2), Schema.list(clothes_props, Schema.uint(8))))

---@type Outfit
local outfit = { shirts = { { id = 0, color = 0 } } }

function pings.apply_outfit(...)
	outfit = clothes_schema:decode(...)
end

pings.apply_outfit(clothes_schema:encode(outfit))
```