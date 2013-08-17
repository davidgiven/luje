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
		return Utils.Throw("not a class file")
	end

	classobj.minor_version = u2()
	classobj.major_version = u2()

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
			Utils.Throw("invalid constant pool tag "..tag)
		end

		local c = reader()
		if not c then
			Utils.Throw("unimplemented constant pool tag "..tag)
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

	local attributes

	local attribute_reader = {
		["ConstantValue"] = function()
		end,

		["Code"] = function()
			local a = {}
			a.max_stack = u2()
			a.max_locals = u2()

			local code_length = u4()
			a.code = utf8(code_length)

			local exception_table_length = u2()
			a.exception_table = {}
			for i = 1, exception_table_length do
				a.exception_table[i] = {
					start_pc = u2(),
					end_pc = u2(),
					handler_pc = u2(),
					catch_type = u2()
				}
			end

			a.attributes = attributes()
			return a
		end,

		["Exceptions"] = function()
			local number_of_exceptions = u2()
			local a = {}
			for i = 1, number_of_exceptions do
				a[i] = u2()
			end
			return a
		end,

		["InnerClasses"] = function()
			local number_of_classes = u2()
			local a = {}
			for i = 1, number_of_classes do
				a[i] = {
					inner_class_info_index = u2(),
					outer_class_info_index = u2(),
					inner_name_index = u2(),
					inner_class_access_flags = u2()
				}
			end
			return a
		end,

		["Synthetic"] = function()
			return {};
		end,

		["SourceFile"] = function()
			return {
				sourcefile_index = u2()
			}
		end,

		["LineNumberTable"] = function()
			local line_number_table_length = u2()
			local a = {}
			for i = 1, line_number_table_length do
				a[i] = {
					start_pc = u2(),
					line_number = u2()
				}
			end
			return a
		end,

		["LocalVariableTable"] = function()
			local local_variable_table_length = u2()
			local a = {}
			for i = 1, local_variable_table_length do
				a[i] = {
					start_pc = u2(),
					length = u2(),
					name_index = u2(),
					descriptor_index = u2(),
					index = u2()
				}
			end
			return a
		end,

		["Deprecated"] = function()
			return {};
		end,
	}

	local function attribute()
		local attribute_name_index = u2()
		local attribute_name = classobj.constants[attribute_name_index]
		local reader = attribute_reader[attribute_name]

		if not reader then
			Utils.Throw("unknown attribute with name index "..attribute_name_index)
		end

		local len = u4()
		local oldpos = pos
		local a = reader()
		if not a then
			Utils.Throw("unimplemented attribute "..attribute_name)
		end
		a.attribute_name = attribute_name

		pos = oldpos + len
		return a
	end

	attributes = function()
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

