-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local dbg = Utils.Debug
local pretty = require("pl.pretty")
local string_byte = string.byte
local string_find = string.find
local table_concat = table.concat

local native_methods = {}

return {
	RegisterNativeMethod = function(class, name, func)
		native_methods[class.." "..name] = func
	end,

	FindNativeMethod = function(class, name)
		return native_methods[class.." "..name]
	end,

	New = function(classo)
		local o = {
			Class = classo
		}
		classo:InitInstance()

		setmetatable(o,
			{
				__index = function(self, k)
					local _, _, n = string_find(k, "m_(.*)")
					Utils.Assert(n, "table slot for method ('", k, "') does not begin with m_")
					local m = classo:FindMethod(n)
					rawset(o, k, m)
					return m
				end,
			}
		)

		return o
	end,
}

