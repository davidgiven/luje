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
	int8_t sb[8];
	uint16_t w[4];
	int16_t sw[4];
	uint32_t i[2];
	int32_t si[2];
	uint64_t l[1];
	int64_t sl[1];
	float f[2];
	double d[1];
};
]])

local r = ffi.new("union reader")

local writers =
{
	B = function(i)       r.b[0] = i end,
	SB = function(i)      r.sb[0] = i end,
	BB = function(hi, lo) r.b[0] = lo r.b[1] = hi end,
	W = function(i)       r.w[0] = i end,
	SW = function(i)      r.sw[0] = i end,
	WW = function(hi, lo) r.w[0] = lo r.w[1] = hi end,
	I = function(i)       r.i[0] = i end,
	SI = function(i)      r.si[0] = i end,
	II = function(hi, lo) r.i[0] = lo r.i[1] = hi end,
	L = function(i)       r.l[0] = i end,
	SL = function(i)      r.sl[0] = i end,
	F = function(i)       r.f[0] = i end,
	D = function(i)       r.d[0] = i end,
}

local readers =
{
	B = function()        return r.b[0] end,
	SB = function()       return r.sb[0] end,
	W = function()        return r.w[0] end,
	SW = function()       return r.sw[0] end,
	I = function()        return r.i[0] end,
	SI = function()       return r.si[0] end,
	L = function()        return r.l[0] end,
	SL = function()       return r.si[0] end,
	F = function()        return r.f[0] end,
	D = function()        return r.d[0] end,
}

local methods = {}
for rn, r in pairs(readers) do
	for wn, w in pairs(writers) do
		local rf = r
		local wf = w
		methods[wn.."to"..rn] = function(hi, lo)
			wf(hi, lo)
			return rf()
		end
	end
end

return methods

