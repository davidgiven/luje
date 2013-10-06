-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local ffi = require("ffi")
local Utils = require("Utils")
local dbg = Utils.Debug
local string_byte = string.byte
local string_find = string.find
local string_sub = string.sub
local string_char = string.char
local table_concat = table.concat
local ClimpLoader = require("ClimpLoader")

local native_methods = {}
local globalhash = 0
local classobjects = {}
local stringobjects = {}

local primitivetypes =
{
	[4] = {"Z", "bool"},
	[5] = {"C", "uint16_t"},
	[6] = {"F", "float"},
	[7] = {"D", "double"},
	[8] = {"B", "uint8_t"},
	[9] = {"S", "int16_t"},
	[10] = {"I", "int32_t"},
	[11] = {"J", "int64_t"}
}

local function New(climp)
	local hash = globalhash
	globalhash = globalhash + 1

	local methods = {}
	setmetatable(methods,
		{
			__index = function(self, k)
				local m = climp:FindMethod(k)
				rawset(methods, k, m)
				return m
			end
		}
	)

	local fields = {}

	local o = {
		Climp = function() return climp end,
		Hash = function() return hash end,
		Methods = methods,
		Fields = fields
	}
	climp:InitInstance(o)

	return o
end

local function simpleconstructor(n)
	local c = ClimpLoader.Default:LoadClimp(n)
	local o = New(c)
	o.Methods["<init>()V"](o)
	return o
end

local function NewArray(kind, length)
	local k = primitivetypes[kind]
	Utils.Assert(k, "unsupported primitive kind ", kind)
	local typechar, impl = k[1], k[2]

	local classname = "["..typechar
	local climp = ClimpLoader.Default:LoadClimp(classname)
	local object = New(climp)

	local init
	if (length == 0) then
		init = {}
	else
		init = {0}
	end
	local store = ffi.new(impl.."["..tonumber(length).."]", init)

	object.ArrayPut = function(self, index, value)
		if (index < 0) or (index >= length) then
			return nil, simpleconstructor("java/lang/ArrayIndexOutOfBoundsException")
		end
		store[index] = value
	end

	object.ArrayGet = function(self, index)
		if (index < 0) or (index >= length) then
			return nil, simpleconstructor("java/lang/ArrayIndexOutOfBoundsException")
		end
		return store[index]
	end
			
	object.Length = function(self)
		return length
	end

	object.store = store

	return object
end

-- Creates a read-only byte[] array with data stored in the supplied string.

local function NewStringArray(data)
	local climp = ClimpLoader.Default:LoadClimp("[B")
	local object = New(climp)

	object.ArrayPut = function(self, index, value)
		Utils.Throw("attempted write to StringArray")
	end

	object.ArrayGet = function(self, index)
		if (index < 0) or (index >= #data) then
			return nil, simpleconstructor("java/lang/ArrayIndexOutOfBoundsException")
		end
		return string_byte(data, index+1)
	end
			
	object.Length = function(self)
		return #data
	end

	object.store = data

	return object
end

return {
	RegisterNativeMethod = function(class, name, func)
		native_methods[class.." "..name] = func
	end,

	FindNativeMethod = function(class, name)
		return native_methods[class.." "..name]
	end,

	New = New,
	NewArray = NewArray,

	NewAArray = function(climp, length)
		local classname = "[L"..climp:ThisClass()..";"
		local arrayclimp = ClimpLoader.Default:LoadClimp(classname)
		local object = New(arrayclimp)

		local store = {}

		object.ArrayPut = function(self, index, value)
			if (index < 0) or (index >= length) then
				return nil, simpleconstructor("java/lang/ArrayIndexOutOfBoundsException")
			end
			store[index] = value
		end

		object.ArrayGet = function(self, index)
			if (index < 0) or (index >= length) then
				return nil, simpleconstructor("java/lang/ArrayIndexOutOfBoundsException")
			end
			return store[index]
		end
			
		object.Length = function(self)
			return length
		end

		return object
	end,

	InstanceOf = function(o, climp)
		if not o then
			return true
		end
		local c = o:Climp()
		while c do
			if (c == climp) then
				return true
			end
			c = c:SuperClimp()
		end
		return false
	end,

	GetClassForClimp = function(climp)
		if not classobjects[climp] then
			local c = ClimpLoader.Default:LoadClimp("java/lang/Class")
			local o = New(c)
			local n = climp:ThisClass()
			o.forClimp = climp
			o.isArray = not not string_find(n, "^%[")
			o.isPrimitive = not not string_find(n, "^[VZBCSIJDF]$")
			classobjects[climp] = o
		end
		return classobjects[climp]
	end,

	NewString = function(utf8)
		if not stringobjects[utf8] then
			local c = ClimpLoader.Default:LoadClimp("java/lang/String")
			local o = New(c)
			local a = NewStringArray(utf8)
			o.Methods["<init>([BI)V"](o, a, 0)

			stringobjects[utf8] = o
		end
		return stringobjects[utf8]
	end,

	FromString = function(s)
		local ss = {}
		local len = s.Methods["length()I"](s)
		for i=0, len-1 do
			local c = s.Methods["charAt(I)C"](s, i)
			ss[#ss+1] = string_char(c)
		end
		return table_concat(ss)
	end,
	
	NullPointerException = function()
		return simpleconstructor("java/lang/NullPointerException")
	end,
}

