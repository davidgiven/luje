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
local string_byte = string.byte

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
		return self.componentType
	end
)

Runtime.RegisterNativeMethod("java/lang/Class", "isArray()Z",
	function(self)
		return self.isArray
	end
)

Runtime.RegisterNativeMethod("java/lang/Class", "isPrimitive()Z",
	function(self)
		return self.isPrimitive
	end
)

Runtime.RegisterNativeMethod("java/lang/Class", "getName()Ljava/lang/String;",
	function(self)
		local n = self.forClimp:ThisClass()
		return Runtime.NewString(n)
	end
)

--- Maths -------------------------------------------------------------------

Runtime.RegisterNativeMethod("java/lang/Math", "sqrt(D)D", math.sqrt)
Runtime.RegisterNativeMethod("java/lang/Math", "sin(D)D", math.sin)
Runtime.RegisterNativeMethod("java/lang/Math", "cos(D)D", math.cos)
Runtime.RegisterNativeMethod("java/lang/Math", "tan(D)D", math.tan)
Runtime.RegisterNativeMethod("java/lang/Math", "log(D)D", math.log)

Runtime.RegisterNativeMethod("java/lang/Math", "max(II)I", math.max)
Runtime.RegisterNativeMethod("java/lang/Math", "max(JJ)J", math.max)
Runtime.RegisterNativeMethod("java/lang/Math", "max(FF)F", math.max)
Runtime.RegisterNativeMethod("java/lang/Math", "max(DD)D", math.max)
Runtime.RegisterNativeMethod("java/lang/Math", "min(II)I", math.min)
Runtime.RegisterNativeMethod("java/lang/Math", "min(JJ)J", math.min)
Runtime.RegisterNativeMethod("java/lang/Math", "min(FF)F", math.min)
Runtime.RegisterNativeMethod("java/lang/Math", "min(DD)D", math.min)

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

Runtime.RegisterNativeMethod("java/lang/System", "gc()V", collectgarbage)

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

--- Exceptions --------------------------------------------------------------

Runtime.RegisterNativeMethod("java/lang/Throwable", "fillInStackTrace()Ljava/lang/Throwable;",
	function(self)
		return self
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
	extern int close(int fd);
]])

Runtime.RegisterNativeMethod("org/apache/harmony/luni/platform/OSFileSystem", "writeImpl(J[BII)J",
	function(self, fd, data, offset, length)
		local store = ffi.cast('int8_t*', data.store)
		return ffi.C.write(fd, store+offset, length)
	end
)

Runtime.RegisterNativeMethod("org/apache/harmony/luni/platform/OSFileSystem", "closeImpl(J)I",
	function(self, fd)
		return ffi.C.close(fd)
	end
)
