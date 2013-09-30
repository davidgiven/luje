-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local classreader = require("classreader")
local String = require("String")
local dbg = Utils.Debug
local pretty = require("pl.pretty")
local string_byte = string.byte
local string_find = string.find
local table_concat = table.concat

local resolveattributes

local attribute_resolvers =
{
	["Code"] = function(class, attribute)
		local a = {
			MaxStack = attribute.max_stack,
			MaxLocals = attribute.max_locals,
			Bytecode = attribute.code,
			ExceptionTable = attribute.exception_table,
		}
		resolveattributes(class, attribute.attributes, a)
		return a
	end,

	["Synthetic"] = function(class, attribute)
		return true
	end,

	["SourceFile"] = function(class, attribute)
		return class.Utf8Constants[attribute.sourcefile_index]
	end,

	["LineNumberTable"] = function(class, attribute)
		return attribute
	end,

	["LocalVariableTable"] = function(class, attribute)
		return attribute
	end,

	["Deprecated"] = function(class, attribute)
		return true
	end,

	["StackMapTable"] = function(class, attribute)
		return attribute
	end,

	["ConstantValue"] = function(class, attribute)
		return attribute.value
	end,
}

resolveattributes = function(class, attributes, a)
	if not a then
		a = {}
	end

	for _, attribute in ipairs(attributes) do
		local name = attribute.attribute_name
		local resolver = attribute_resolvers[name]
		if not resolver then
			Utils.Throw("cannot analyse attribute "..name)
		end

		a[name] = resolver(class, attribute)
	end

	return a
end

local parse_descriptor_token

local descriptor_token_parser = {
	[68] = function(d, pos) -- D
		return 2, pos+1
	end,

	[70] = function(d, pos) -- F
		return 1, pos+1
	end,

	[73] = function(d, pos) -- I
		return 1, pos+1
	end,

	[74] = function(d, pos) -- J
		return 2, pos+1
	end,

	[86] = function(d, pos) -- V
		return 0, pos
	end,

	[91] = function(d, pos) -- [
		local _, p = parse_descriptor_token(d, pos+1)
		return 1, p
	end,

	[76] = function(d, pos) -- L
		local s, e = string_find(d, ";", pos+1)
		return 1, e+1
	end
}

parse_descriptor_token = function(d, pos)
	local b = string_byte(d, pos)
	local parser = descriptor_token_parser[b]
	if not parser then
		Utils.Throw("unknown descriptor token at pos "..pos.." of "..d)
	end

	return parser(d, pos)
end

local function parse_descriptor_input_params(d)
	local params = {}
	local pos = 2

	local p
	while (string_byte(d, pos) ~= 41) do
		p, pos = parse_descriptor_token(d, pos)
		params[#params+1] = p
	end

	return params
end

local function parse_descriptor_output_params(d)
	local pos = string_find(d, ")", 1, true)
	return (parse_descriptor_token(d, pos+1))
end

local function parse_access_flags(flags)
	local f = {""}
	if (bit.band(flags, 0x0001) ~= 0) then f[#f+1] = "public" end
	if (bit.band(flags, 0x0002) ~= 0) then f[#f+1] = "private" end
	if (bit.band(flags, 0x0004) ~= 0) then f[#f+1] = "protected" end
	if (bit.band(flags, 0x0008) ~= 0) then f[#f+1] = "static" end
	if (bit.band(flags, 0x0010) ~= 0) then f[#f+1] = "final" end
	if (bit.band(flags, 0x0020) ~= 0) then f[#f+1] = "synchronized" end
	if (bit.band(flags, 0x0040) ~= 0) then f[#f+1] = "volatile" end
	if (bit.band(flags, 0x0080) ~= 0) then f[#f+1] = "transient" end
	if (bit.band(flags, 0x0100) ~= 0) then f[#f+1] = "native" end
	if (bit.band(flags, 0x0200) ~= 0) then f[#f+1] = "interface" end
	if (bit.band(flags, 0x0400) ~= 0) then f[#f+1] = "abstract" end
	if (bit.band(flags, 0x0800) ~= 0) then f[#f+1] = "strict" end
	f[#f+1] = ""
	return table_concat(f, " ")
end

local function analyseclass(classdata)
	local impl, e = classreader(classdata)
	if e then
		Utils.Throw(e)
	end

	local Utf8Constants = {}
	setmetatable(Utf8Constants,
		{
			__index = function(self, k)
				local s = impl.constants[k]
				assert(type(s) == "string")
				self[k] = s
				return s
			end
		}
	)

	local ClassConstants = {}
	setmetatable(ClassConstants,
		{
			__index = function(self, k)
				local ci = impl.constants[k].name_index
				if (ci == 0) then
					return nil
				end
				local s = Utf8Constants[ci]
				self[k] = s
				return s
			end
		}
	)

	local RefConstants = {}
	setmetatable(RefConstants,
		{
			__index = function(self, k)
				local c = impl.constants[k]
				local n = impl.constants[c.name_and_type_index]

				local f = {}
				f.Name = Utf8Constants[n.name_index]
				f.Descriptor = Utf8Constants[n.descriptor_index]
				f.Class = ClassConstants[c.class_index]

				if (string_byte(f.Descriptor, 1) == 40) then
					f.InParams = parse_descriptor_input_params(f.Descriptor)
					f.OutParams = parse_descriptor_output_params(f.Descriptor)
				else
					f.Size = (parse_descriptor_token(f.Descriptor, 1))
				end

				self[k] = f
				return f
			end
		}
	)

	local SimpleConstants = {}
	setmetatable(SimpleConstants,
		{
			__index = function(self, k)
				local c = impl.constants[k]
				local cc
				if (type(c) == "table") then
					if c.string_index then
						cc = String(Utf8Constants[c.string_index])
					end
				else
					cc = c
				end

				if not cc then
					Utils.Throw("can't handle ldc with constant index "..k)
				end

				self[k] = cc
				return cc
			end
		}
	)

	local Methods = {}
	for _, m in ipairs(impl.methods) do
		local name = Utf8Constants[m.name_index]
		local descriptor = Utf8Constants[m.descriptor_index]
		local method = {
			AccessFlags = parse_access_flags(m.access_flags),
			Name = name,
			Descriptor = descriptor,
			InParams = parse_descriptor_input_params(descriptor),
			OutParams = parse_descriptor_output_params(descriptor),
		}
		resolveattributes(class, m.attributes, method)
		Methods[name..descriptor] = method
	end

	local Fields = {}
	for _, f in ipairs(impl.fields) do
		local name = Utf8Constants[f.name_index]
		local descriptor = Utf8Constants[f.descriptor_index]
		local field = {
			AccessFlags = parse_access_flags(f.access_flags),
			Name = name,
			Descriptor = descriptor,
		}
		resolveattributes(class, f.attributes, method)
		Fields[name] = field
	end

	class = {
		MinorVersion = impl.minor_version,
		MajorVersion = impl.major_version,
		AccessFlags = parse_access_flags(impl.access_flags),
		ThisClass = ClassConstants[impl.this_class],
		SuperClass = ClassConstants[impl.super_class],
		Utf8Constants = Utf8Constants,
		ClassConstants = ClassConstants,
		RefConstants = RefConstants,
		SimpleConstants = SimpleConstants,
		Methods = Methods,
		Fields = Fields,
	}

	resolveattributes(class, impl.attributes, class)
	return class
end

return analyseclass
