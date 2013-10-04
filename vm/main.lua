-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

-- Add the directory containing this script to the package path.

ServerDir = arg[0]:gsub("[^/]+$", "")
package.path = ServerDir .. "?.lua;" .. ServerDir .. "?/init.lua;" .. package.path

local Utils = require("Utils")
local ClimpLoader = require("ClimpLoader")
local pretty = require("pl.pretty")

require("natives")

local t = ClimpLoader.Default:LoadClimp("com/cowlark/luje/OTest")
local m = t["m_main([Ljava/lang/String;)V"]
Utils.Assert(m, "this isn't a main class")
local r = m(t, nil)

pretty.dump(r)
pretty.dump(t)

