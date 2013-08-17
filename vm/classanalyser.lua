-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local classreader = require("classreader")
local dbg = Utils.Debug

local attribute_resolvers =
{
	["Synthetic"] = function(class, attribute)
		return true
	end,

	["SourceFile"] = function(class, attribute)
		return class.Utf8Constant[attribute.sourcefile_index]
	end,

	["Deprecated"] = function(class, attribute)
		return true
	end
}

local function resolveattributes(class, attributes)
	local a = {}

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

	local Utf8Constant = {}
	setmetatable(Utf8Constant,
	{
		__index = function(self, k)
			local s = impl.constants[k]
			self[k] = s
			return s
		end
	})

	local ClassConstant = {}
	setmetatable(ClassConstant,
		{
			__index = function(self, k)
				local ci = impl.constants[k].name_index
				if (ci == 0) then
					return nil
				end
				local s = Utf8Constant[ci]
				self[k] = s
				return s
			end
		})

	class = {
		MinorVersion = impl.minor_version,
		MajorVersion = impl.major_version,
		AccessFlags = impl.access_flags,
		ThisClass = ClassConstant[impl.this_class],
		SuperClass = ClassConstant[impl.super_class],
		Utf8Constant = Utf8Constant,
		ClassConstant = ClassConstant,
	}

	class.Attributes = resolveattributes(class, impl.attributes)
	return class
end

return analyseclass