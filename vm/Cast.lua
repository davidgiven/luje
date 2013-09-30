-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local dbg = Utils.Debug
local ffi = require("ffi")
local string_byte = string.byte

ffi.cdef([[
union reader
{
	uint8_t b[8];
	uint32_t i[2];
	uint64_t l[1];
	float f[2];
	double d[1];
};
]])

local reader = ffi.new("union reader")

return
{
	IntToFloat = function(i)
		reader.i[0] = i
		return reader.f[0]
	end,

	IntPairToDouble = function(lo, hi)
		reader.i[0] = lo
		reader.i[1] = hi
		return reader.d[0]
	end,

	LongToDouble = function(l)
		reader.l[0] = l
		return reader.d[0]
	end,
}
