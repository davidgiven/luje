-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local dbg = Utils.Debug
local Runtime = require("Runtime")
local ffi = require("ffi")

Runtime.RegisterNativeMethod("java/lang/Math", "sqrt(D)D", math.sqrt)
Runtime.RegisterNativeMethod("java/lang/Math", "sin(D)D", math.sin)
Runtime.RegisterNativeMethod("java/lang/Math", "cos(D)D", math.cos)
Runtime.RegisterNativeMethod("java/lang/Math", "tan(D)D", math.tan)
Runtime.RegisterNativeMethod("java/lang/Math", "log(D)D", math.log)

ffi.cdef([[
	struct timeval
	{
		long tv_sec;
		long tv_usec;
	};

	extern int gettimeofday(struct timeval* tv, void* tz);
]])

local timeval = ffi.new("struct timeval")
Runtime.RegisterNativeMethod("java/lang/System", "currentTimeMillis()J",
	function()
		ffi.C.gettimeofday(timeval, nil)
		return ffi.cast("int64_t", timeval.tv_sec) * 1000LL +
			ffi.cast("int64_t", timeval.tv_usec) / 1000LL
	end
)

Runtime.RegisterNativeMethod("java/io/FileDescriptor", "getStdInDescriptor()J",
	function() return 0 end)
Runtime.RegisterNativeMethod("java/io/FileDescriptor", "getStdOutDescriptor()J",
	function() return 1 end)
Runtime.RegisterNativeMethod("java/io/FileDescriptor", "getStdErrDescriptor()J",
	function() return 2 end)
Runtime.RegisterNativeMethod("java/io/FileDescriptor", "oneTimeInitialization()V",
	function() end)

Runtime.RegisterNativeMethod("org/apache/harmony/luni/platform/OSFileSystem", "oneTimeInitializationImpl()V",
	function() end)

Runtime.RegisterNativeMethod("org/apache/harmony/luni/platform/OSMemory", "getPointerSizeImpl()I",
	function() return 8 end)
Runtime.RegisterNativeMethod("org/apache/harmony/luni/platform/OSMemory", "isLittleEndianImpl()Z",
	function() return 1 end)

