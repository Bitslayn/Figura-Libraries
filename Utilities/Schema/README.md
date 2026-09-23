# Introduction

Schema allows you to encode and decode tables into binary. This is useful for when you want to ping a table but don't want to waste bytes doing so.

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
x - length
b - contents

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
x - length
b - value

hxxxxxbb bbbbbbbb bbbbbbbb bbbbbbbb
01101011 11111111 11111111 11111111
]]

-- 16.2x smaller

local states = {}
for i = 1, 26 do
	state[i] = true
end

ping(states) -- 81 bytes
ping(Schema.list(Schema.uint(5), Schema.bool()):encode(states)) -- 5 bytes
```

```lua
--[[ Pinging array of 4 booleans (with holes)

h : w/ holes
x : length
b : value
i : index
- : byte padding

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
x : length
b : value
i : index
- : byte padding

hxxxxx + (iiiiib x 26) + ----
111010 + (000001 x 26) + 0000
]]

-- We know from the previous test that Figura pings tables with keys
-- regardless given the unchanged byte count, so we'll just enable the
-- flag to read keys with Schema.

-- 3.375x smaller

local states = {}
for i = 1, 26 do
	state[i] = true
end

ping(states) -- 81 bytes
ping(Schema.list(Schema.uint(5), Schema.bool()):encode(states)) -- 24 bytes
```

</details>
