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
local Runtime = require("Runtime")
local string_gsub = string.gsub
require("natives")

-- Parse command line arguments.

local classtoload = nil
do
	local function do_help(arg)
		io.stderr:write("luje © 2013 David Given\n"..
		                "Usage: luje [<options>] <classname>\n"..
		                "The classpath is currently hard coded to be ./bin.\n"..
						"\n"..
						"Options:\n"..
						"  -h  --help   produce this message\n"..
						"\n"..
						"Here be dragons!\n")
		os.exit(0)
	end

	Utils.ParseCommandLine({...},
		{
			["h"] = do_help,
			["help"] = do_help,

			[" unrecognised"] = function(arg)
				Utils.UserError("option not recognised (try --help)")
			end,

			[" filename"] = function(arg)
				if classtoload then
					Utils.UserError("you may only specify one class to run (try --help)")
				end
				classtoload = arg
				return 1
			end
		}
	)
end

if not classtoload then
	Utils.UserError("you must specify a class to run (try --help)")
end
classtoload = string_gsub(classtoload, "%.", "/")

-- Load the destination class and run the main method on it.

local t, e = ClimpLoader.Default:LoadClimp(classtoload)
local m = t.Methods["main([Ljava/lang/String;)V"]
if not m then
	Utils.UserError("this isn't a main class (try --help)")
end

local r, e = m(t, nil)
if e then
	local es = e.Methods["toString()Ljava/lang/String;"](e)
	Utils.Debug("uncaught exception: ", Runtime.FromString(es))
end

