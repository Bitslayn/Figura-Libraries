--[[
____  ___ __   __
| __|/ _ \\ \ / /
| _|| (_) |> w <
|_|  \___//_/ \_\
FOX's Data Packages Lib v1.3

Github: https://github.com/Bitslayn/FOX-s-Figura-APIs/blob/main/Utilities/PackageD.lua
]]

--==============================================================================================================================
--#REGION ˚♡ Environment ♡˚
--==============================================================================================================================

---@class FOXPackageD
local lib = {}

local prefix = "#"
local _FOX = setmetatable({}, { __index = _G })

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ Utils ♡˚
--==============================================================================================================================

-- These are taken from FiguraMC/Figura

---@class FOXPackageD.Path
---@field chunks string[]
---@field is_absolute boolean

---@param path string
---@return FOXPackageD.Path
local function get_path(path)
	local chunks = {}

	path:gsub("\\", "/")
		:gsub("%.([^./])", "/%1")
		:gsub("//", "/")
		:gsub("[^/]+", function(c)
			chunks[#chunks + 1] = c
		end)

	local is_absolute = path:sub(1, 1) ~= "."
	if chunks[1] == "." then
		table.remove(chunks, 1)
	end

	return { chunks = chunks, is_absolute = is_absolute }
end

---@param base string?
---@param other string?
---@return string
local function resolve_path(base, other)
	if not other then return "" end

	local _other = get_path(other)
	if _other.is_absolute then
		return table.concat(_other.chunks, "/")
	end

	local _base = get_path(base or "")
	_base.chunks[#_base.chunks] = nil

	for i = 1, #_other.chunks do
		if _other.chunks[i] == ".." then
			_base.chunks[#_base.chunks] = nil
		else
			_base.chunks[#_base.chunks + 1] = _other.chunks[i]
		end
	end

	return table.concat(_base.chunks, "/")
end

---@return string?
local function get_working_dir()
	return select(2, pcall(function() error("", 5) end)):match(prefix:gsub("%A", "%%%1") .. "([^:]+)")
end

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ require ♡˚
--==============================================================================================================================

---Stores the scripts that have loaded and their returns
---@type table<string, any[]>
local loaded = {}

lib.loaded = loaded

---Stores what scripts are being required in the current stack
---
---Allows for detection of circular dependencies
---@type table<string, boolean>
local loading = {}

---Loads a script from the data folder, returning any script returns
---
---Sets the environment of loaded scripts so that host-only scripts can require other host-only scripts
---
---@see require
---@param modname string
---@return ...
function lib.require(modname)
	local path = resolve_path(get_working_dir(), modname)

	-- Return script already loaded
	if loaded[path] then return table.unpack(loaded[path]) end

	-- Attempts to load the script onto the current stack
	if loading[path] then
		error("Detected circular dependency in script " .. path, 2)
	end

	loading[path] = true
	local ok, res = pcall(file.readString, file, path .. ".lua")
	if not ok then
		if res:find("java.io.FileNotFoundException") then
			error('Tried to require nonexistent script "' .. path .. '"!', 2)
		else
			error(res, 2)
		end
	end

	local script, err = load(res, prefix .. path, _FOX)
	if not script then
		error(err, 2)
	end

	local result = { script(path:match("(.-)/?([^/]+)$")) }
	loading[path] = nil

	-- Store all scripts loaded off the current stack
	loaded[path] = result
	return table.unpack(result)
end

_FOX.require = lib.require

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ listFiles ♡˚
--==============================================================================================================================

---Recursive helper for listFiles
---@param dir string
---@param recursive boolean?
---@param list string[]
local function list_recursive(dir, recursive, list)
	-- Replicate a very niche feature of listFiles
	if file:isFile(dir .. ".lua") then
		list[#list + 1] = dir:gsub("/", ".")
		return
	end

	-- Loop through files if possible, adding lua scripts to the list
	local files = file:list(dir)
	if not files then return end

	local pre = dir ~= "" and dir .. "/" or dir
	for i = 1, #files do
		local curr = pre .. files[i]

		local name, ext = files[i]:match("([^.]*)%.?(.-)$")
		if recursive and file:isPathAllowed(curr) and file:isDirectory(curr) then
			list_recursive(curr, recursive, list)
		elseif ext == "lua" then
			list[#list + 1] = pre:gsub("/", ".") .. name
		end
	end
end

---Gets the list of all lua scripts in the data folder at the given directory.
---
---If `recursive` is set, all scripts in all subdirectories will be listed.
---
---@see listFiles
---@param dir string?
---@param recursive boolean?
---@return string[]
---@nodiscard
function lib.listFiles(dir, recursive)
	local path = resolve_path(get_working_dir(), dir)

	-- Assert host environment
	local ok, res = pcall(file.exists, file, "")
	if not ok then
		error(res, 2)
	end

	local list = {}
	list_recursive(path, recursive, list)
	return list
end

_FOX.listFiles = lib.listFiles

--#ENDREGION --=================================================================================================================
--#REGION ˚♡ TextureAPI ♡˚
--==============================================================================================================================

---@param path string
---@return string
local function read_base64(path)
	local stream = file:openReadStream(path)
	local length = stream:available()

	local buffer = data:createBuffer(length)
	buffer:readFromStream(stream)
	buffer:setPosition(0)
	local base64 = buffer:readBase64(length)
	buffer:close()

	stream:close()
	return base64
end

---Shadow's Figura's TextureAPI, allowing for indexing textures from the data folder.
---
---@see TextureAPI
---@class FOXPackageD.TextureAPI: TextureAPI
lib.textures = setmetatable({}, {
	__index = function(_, name)
		if not textures[name] then
			textures:read(name, read_base64(name:gsub("%.", "/") .. ".png"))
		end
		return textures[name]
	end
})

_FOX.textures = lib.textures

return lib

--#ENDREGION
