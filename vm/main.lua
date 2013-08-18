-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

-- Add the directory containing this script to the package path.

ServerDir = arg[0]:gsub("[^/]+$", "")
package.path = ServerDir .. "?.lua;" .. ServerDir .. "?/init.lua;" .. package.path

local Utils = require("Utils")
local ClassLoader = require("ClassLoader")
local pretty = require("pl.pretty")

local t = ClassLoader:LoadClass("com/cowlark/luje/Main")
local m = t:FindStaticMethod("main([Ljava/lang/String;)V")
m(t, nil)

pretty.dump(t)

