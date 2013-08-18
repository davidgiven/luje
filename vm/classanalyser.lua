-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local classreader = require("classreader")
local dbg = Utils.Debug

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
	end
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
	})

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
		})

	local Methods = {}
	for _, m in ipairs(impl.methods) do
		local name = Utf8Constants[m.name_index]
		local descriptor = Utf8Constants[m.descriptor_index]
		local method = {
			AccessFlags = m.access_flags,
			Name = name,
			Descriptor = descriptor,
		}
		resolveattributes(class, m.attributes, method)
		Methods[name..descriptor] = method
	end

	local Fields = {}
	for _, f in ipairs(impl.fields) do
		local name = Utf8Constants[f.name_index]
		local descriptor = Utf8Constants[f.descriptor_index]
		local field = {
			AccessFlags = f.access_flags,
			Name = name,
			Descriptor = descriptor,
		}
		resolveattributes(class, f.attributes, method)
		Fields[name] = field
	end

	class = {
		MinorVersion = impl.minor_version,
		MajorVersion = impl.major_version,
		AccessFlags = impl.access_flags,
		ThisClass = ClassConstants[impl.this_class],
		SuperClass = ClassConstants[impl.super_class],
		Utf8Constants = Utf8Constants,
		ClassConstants = ClassConstants,
		Methods = Methods,
		Fields = Fields
	}

	resolveattributes(class, impl.attributes, class)
	return class
end

return analyseclass