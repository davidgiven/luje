-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local ffi = require("ffi")
local Utils = require("Utils")
local dbg = Utils.Debug
local pretty = require("pl.pretty")
local string_byte = string.byte
local string_find = string.find
local table_concat = table.concat

local native_methods = {}
local globalhash = 0

local primitivetypes =
{
	[4] = "bool",
	[5] = "uint16_t",
	[6] = "float",
	[7] = "double",
	[8] = "uint8_t",
	[9] = "int16_t",
	[10] = "int32_t",
	[11] = "int64_t"
}

return {
	RegisterNativeMethod = function(class, name, func)
		native_methods[class.." "..name] = func
	end,

	FindNativeMethod = function(class, name)
		return native_methods[class.." "..name]
	end,

	New = function(classo)
		local hash = globalhash
		globalhash = globalhash + 1

		local o = {
			Class = classo,
			Hash = function() return hash end,
		}
		classo:InitInstance()

		setmetatable(o,
			{
				__index = function(self, k)
					local _, _, n = string_find(k, "m_(.*)")
					if n then
						Utils.Assert(n, "table slot for method ('", k, "') does not begin with m_")
						local m = classo:FindMethod(n)
						rawset(o, k, m)
						return m
					else
						return nil
					end
				end,
			}
		)

		return o
	end,

	NewArray = function(kind, length)
		local t = primitivetypes[kind]
		Utils.Assert(t, "unsupported primitive kind ", kind)

		local store = ffi.new(t.."["..tonumber(length).."]")

		local hash = globalhash
		globalhash = globalhash + 1

		return {
			ArrayPut = function(self, index, value)
				Utils.Assert((index >= 0) and (index < length), "array out of bounds access")
				store[index] = value
			end,

			ArrayGet = function(self, index)
				Utils.Assert((index >= 0) and (index < length), "array out of bounds access")
				return store[index]
			end,
				
			Length = function(self)
				return length
			end,

			Hash = function()
				return hash
			end
		}
	end,

	NewAArray = function(classo, length)
		local store = {}

		local hash = globalhash
		globalhash = globalhash + 1

		return {
			ArrayPut = function(self, index, value)
				Utils.Assert((index >= 0) and (index < length), "array out of bounds access")
				store[index] = value
			end,

			ArrayGet = function(self, index)
				Utils.Assert((index >= 0) and (index < length), "array out of bounds access")
				return store[index]
			end,
				
			Length = function(self)
				return length
			end,

			Hash = function()
				return hash
			end
		}
	end
}

