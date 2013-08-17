-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

-- Add the directory containing this script to the package path.

ServerDir = arg[0]:gsub("[^/]+$", "")
package.path = ServerDir .. "?.lua;" .. ServerDir .. "?/init.lua;" .. package.path

local Utils = require("Utils")
local classreader = require("classreader")
local serpent = require("serpent")

local s = Utils.LoadFile("../bin/com/cowlark/luje/Main.class")
local t, e = classreader(s)
if e then
	Utils.FatalError(e)
end
print(serpent.block(t))

