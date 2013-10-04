-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
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

	dbg("loading: ", name)
	local t
	if string_find(name, "^%[") then
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
	
	local m = c["m_<clinit>()V"]
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

