-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local dbg = Utils.Debug
local Runtime = require("Runtime")
local ffi = require("ffi")
local string_find = string.find

Runtime.RegisterNativeMethod("java/lang/Object", "hashCode()I",
	function(self)
		return self:Hash()
	end
)

--- Class management --------------------------------------------------------

Runtime.RegisterNativeMethod("java/lang/Object", "getClass()Ljava/lang/Class;",
	function(self)
		return Runtime.GetClassForClimp(self:Climp())
	end
)

Runtime.RegisterNativeMethod("java/lang/Class", "getComponentType()Ljava/lang/Class;",
	function(self)
		local climp = self.forClimp
		local n = climp:ThisClass()
		local _, _, a, b = string_find(n, "^(.)(.*)$")
		if (a == "[") then
			local c = climp:ClimpLoader():LoadClimp(b)
			return Runtime.GetClassForClimp(c)
		else
			return nil
		end
	end
)

Runtime.RegisterNativeMethod("java/lang/Class", "isArray()Z",
	function(self)
		local climp = self.forClimp
		local n = climp:ThisClass()
		return not not string_find(n, "^%[")
	end
)

Runtime.RegisterNativeMethod("java/lang/Class", "isPrimitive()Z",
	function(self)
		local climp = self.forClimp
		local n = climp:ThisClass()
		return not not string_find(n, "^[VZBCSIJDF]$")
	end
)

--- Maths -------------------------------------------------------------------

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

Runtime.RegisterNativeMethod("org/apache/harmony/luni/util/NumberConverter", "convert(D)Ljava/lang/String;",
	function(d)
		return Runtime.NewString(tostring(tonumber(d)))
	end
)

--- Arrays ------------------------------------------------------------------

Runtime.RegisterNativeMethod("java/lang/System", "arraycopyImpl(Ljava/lang/Object;ILjava/lang/Object;II)V",
	function(src, srcpos, dest, destpos, length)
		local get = src.ArrayGet
		local put = dest.ArrayPut
		for i=0, length-1 do
			local j = get(src, srcpos+i)
			put(dest, destpos+i, j)
		end
	end
)

--- System bindings ---------------------------------------------------------

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

ffi.cdef([[
	extern int write(int fd, const void* buf, size_t count);
]])

Runtime.RegisterNativeMethod("org/apache/harmony/luni/platform/OSFileSystem", "writeImpl(J[BII)J",
	function(self, fd, data, offset, length)
		local store = ffi.cast('int8_t*', data.store)
		return ffi.C.write(fd, store+offset, length)
	end
)
