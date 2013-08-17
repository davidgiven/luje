-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local dbg = Utils.Debug
local string_byte = string.byte
local string_sub = string.sub

local function loadclass(classdata)
	local classobj = {}
	local pos = 1

	local function b()
		local r = string_byte(classdata, pos)
		pos = pos + 1
		return r
	end

	local function u2()
		return b()*0x100 + b()
	end

	local function u4(n)
		return u2()*0x10000 + u2()
	end

	local function utf8(count)
		local s = string_sub(classdata, pos, pos+count-1)
		pos = pos + count
		return s
	end

	if (u4() ~= 0xcafebabe) then
		return nil, "not a class file"
	end

	classobj.minorversion = u2()
	classobj.majorversion = u2()

	-- Load constant pool

	local ref_reader = function()
		return {
			class_index = u2(),
			name_and_type_index = u2()
		}
	end

	local constant_reader =
	{
		[1] = function() -- CONSTANT_Utf8
			local len = u2()
			return utf8(len)
		end,

		[3] = function() -- CONSTANT_Integer
		end,

		[4] = function() -- CONSTANT_Float
		end,

		[5] = function() -- CONSTANT_Long
		end,

		[6] = function() -- CONSTANT_Double
		end,

		[7] = function() -- CONSTANT_Class
			return {
				name_index = u2()
			}
		end,

		[8] = function() -- CONSTANT_String
			return {
				string_index = u2()
			}
		end,

		[9] = ref_reader, -- CONSTANT_Fieldref
		[10] = ref_reader, -- CONSTANT_Methodref
		[11] = ref_reader, -- CONSTANT_InterfaceMethodref

		[12] = function() -- CONSTANT_NameAndType
			return {
				name_index = u2(),
				descriptor_index = u2()
			}
		end
	}

	local constant_pool_count = u2()
	classobj.constants = {}
	for i=1, constant_pool_count-1 do
		local tag = b()
		local reader = constant_reader[tag]
		if not reader then
			return nil, "invalid constant pool tag "..tag
		end

		local c = reader()
		if not c then
			return nil, "unimplemented constant pool tag "..tag
		end

		classobj.constants[i] = c
	end

	-- More miscellaneous fields

	classobj.access_flags = u2()
	classobj.this_class = u2()
	classobj.super_class = u2()

	-- Load interfaces list

	local interfaces_count = u2()
	classobj.interfaces = {}
	for i = 0, interfaces_count-1 do
		classobj.interfaces[i] = u2()
	end

	-- Function to load an attribute --- we'l use this later.

	local function attribute()
		local a = {}
		a.attribute_name_index = u2()
		local len = u4()
		a.info = utf8(len)
		return a
	end

	local function attributes()
		local attributes_count = u2()
		local a = {}
		for i = 1, attributes_count do
			a[i] = attribute()
		end
		return a
	end

	-- Fields.

	local fields_count = u2()
	classobj.fields = {}
	for i = 1, fields_count do
		classobj.fields[i] = {
			access_flags = u2(),
			name_index = u2(),
			descriptor_index = u2(),
			attributes = attributes()
		}
	end

	-- Methods.

	local methods_count = u2()
	classobj.methods = {}
	for i = 1, methods_count do
		classobj.methods[i] = {
			access_flags = u2(),
			name_index = u2(),
			descriptor_index = u2(),
			attributes = attributes()
		}
	end

	classobj.attributes = attributes()
	return classobj
end

return loadclass

