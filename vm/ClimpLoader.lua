-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local Options = require("Options")
local dbg = Utils.Debug
local classanalyser = require("classanalyser")
local string_find = string.find

local cache = {}
local path = "../bin/"

-- module reference resolved lazily to avoid startup issues
local Climp

local function LoadClimp(self, name)
	local c = cache[name]
	if c then
		return c
	end

	if not Climp then
		Climp = require("Climp")
	end

	if Options.TraceCompilations then
		dbg("loading: ", name)
	end

	local t
	if string_find(name, "^[[VZBCSIJDF]") then
		t = {
			ThisClass = name,
			SuperClass = "java/lang/Object",
			Fields = {},
			Methods = {},
		}
	else
		local s = Utils.LoadFile(path..name..".class")
		t = classanalyser(s)
	end

	c = Climp(self)
	cache[name] = c
	c:Init(t)

	-- Call the static constructor for the class.
	
	local m = c.Methods["<clinit>()V"]
	--dbg("class init: ", name, " = ", m)
	if m then 
		m()
	end
	return c
end

local function New()
	return {
		LoadClimp = LoadClimp,
	}
end

local default = New()
return {
	Default = default,
	New = New
}

