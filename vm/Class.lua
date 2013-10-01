-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local dbg = Utils.Debug
local Runtime = require("Runtime")
local pretty = require("pl.pretty")
local string_byte = string.byte
local string_find = string.find
local table_concat = table.concat
local Cast = require("Cast")
local BtoSB = Cast.BtoSB
local BBtoW = Cast.BBtoW
local WtoSW = Cast.WtoSW
local WWtoI = Cast.WWtoI
local ItoSI = Cast.ItoSI

-- This function does the bytecode compilation. It takes the bytecode and
-- converts it into a Lua script, then compiles it and returns the method as
-- a callable function.

local function compile_method(class, analysis, mimpl)
	local bytecode = mimpl.Code.Bytecode
	local pos = 0
	local sp = 0
	local stacksize = {}
	local output = {}

	local function u1()
		pos = pos + 1 -- increment first to apply +1 offset
		return string_byte(bytecode, pos)
	end

	local function s1()
		local u = u1()
		return BtoSB(u)
	end

	local function u2()
		local hi = u1()
		local lo = u1()
		return BBtoW(hi, lo)
	end

	local function s2()
		local i = u2()
		return WtoSW(i)
	end

	local function u4()
		local hi = u2()
		local lo = u2()
		return WWtoI(hi, lo)
	end

	local function s4()
		local i = u4()
		return ItoSI(i)
	end

	local function checkstack(pc)
		local csp = stacksize[pc]
		if (csp == nil) then
			stacksize[pc] = sp
		else
			if (csp ~= sp) then
				Utils.Throw("stack mismatch (is currently "..sp..", but should be "..csp)
			end
		end
	end

	local function emitnonl(...)
		local args = {...}
		local argslen = select("#", ...)
		for i = 1, argslen do
			output[#output+1] = tostring(args[i])
		end
	end

	local function emit(...)
		emitnonl(...)
		output[#output+1] = "\n"
	end

	-- Add a constant to the (internal, per-method) constant pool.

	local constants = {}
	local function constant(c)
		assert(type(c) == "table")
		local n = constants[c]
		if n then
			return n
		end

		constants[#constants+1] = c
		n = "constant"..#constants
		constants[c] = n
		return n
	end

	-- Emit a check for null for the specified variable.
	
	local function nullcheck(v)
		emitnonl("nullcheck(", v, "); ")
	end

	-- Emit the function prologue.
	
	emitnonl("function(")
	local minlocals = 1
	do
		local first = true
		for n, d in ipairs(mimpl.InParams) do
			if not first then
				emitnonl(", ")
			end
			first = false
			emitnonl("local", (minlocals-1))
			minlocals = minlocals + d
		end
	end
	emit(")")

	-- Declare the variables we're going to put our stack and locals in.

	for i = 1, mimpl.Code.MaxStack do
		emit("local stack", i-1)
	end

	for i = minlocals, mimpl.Code.MaxLocals do
		emit("local local", i-1)
	end

	-- This table expands all the opcodes.

	local opcodemap = {
		[0x01] = function() -- aconst_null
			emit("stack", sp, " = nil")
			sp = sp + 1
		end,

		[0x02] = function() -- iconst_m1
			emit("stack", sp, " = -1")
			sp = sp + 1
		end,

		[0x03] = function() -- iconst_0
			emit("stack", sp, " = 0")
			sp = sp + 1
		end,

		[0x04] = function() -- iconst_1
			emit("stack", sp, " = 1")
			sp = sp + 1
		end,

		[0x05] = function() -- iconst_2
			emit("stack", sp, " = 2")
			sp = sp + 1
		end,

		[0x06] = function() -- iconst_3
			emit("stack", sp, " = 3")
			sp = sp + 1
		end,

		[0x07] = function() -- iconst_4
			emit("stack", sp, " = 4")
			sp = sp + 1
		end,

		[0x08] = function() -- iconst_5
			emit("stack", sp, " = 5")
			sp = sp + 1
		end,

		[0x09] = function() -- lconst_0
			emit("stack", sp, " = 0")
			sp = sp + 2
		end,

		[0x0a] = function() -- lconst_1
			emit("stack", sp, " = 1")
			sp = sp + 2
		end,

		[0x0e] = function() -- dconst_0
			emit("stack", sp, " = 0")
			sp = sp + 2
		end,

		[0x0f] = function() -- dconst_1
			emit("stack", sp, " = 1")
			sp = sp + 2
		end,

		[0x10] = function() -- bipush
			local i = s1()
			emit("stack", sp, " = ", i)
			sp = sp + 1
		end,

		[0x12] = function() -- ldc
			local i = u1()
			local c = analysis.SimpleConstants[i]
			if (type(c) == "table") then
				c = constant(c)
			end
			emit("stack", sp, " = ", c)
			sp = sp + 1
		end,

		[0x14] = function() -- ldc2_w
			local i = u2()
			local c = analysis.SimpleConstants[i]
			emit("stack", sp, " = ", c)
			sp = sp + 2
		end,

		[0x16] = function() -- lload
			local i = u1()
			emit("stack", sp, " = local", i)
			sp = sp + 2
		end,

		[0x18] = function() -- dload
			local i = u1()
			emit("stack", sp, " = local", i)
			sp = sp + 2
		end,

		[0x1a] = function() -- iload_0
			emit("stack", sp, " = local0")
			sp = sp + 1
		end,

		[0x1b] = function() -- iload_1
			emit("stack", sp, " = local1")
			sp = sp + 1
		end,

		[0x1c] = function() -- iload_2
			emit("stack", sp, " = local2")
			sp = sp + 1
		end,

		[0x1d] = function() -- iload_3
			emit("stack", sp, " = local3")
			sp = sp + 1
		end,

		[0x1e] = function() -- lload_0
			emit("stack", sp, " = local0")
			sp = sp + 2
		end,

		[0x1f] = function() -- lload_1
			emit("stack", sp, " = local1")
			sp = sp + 2
		end,

		[0x20] = function() -- lload_2
			emit("stack", sp, " = local2")
			sp = sp + 2
		end,

		[0x21] = function() -- lload_3
			emit("stack", sp, " = local3")
			sp = sp + 2
		end,

		[0x26] = function() -- dload_0
			emit("stack", sp, " = local0")
			sp = sp + 2
		end,

		[0x27] = function() -- dload_1
			emit("stack", sp, " = local1")
			sp = sp + 2
		end,

		[0x28] = function() -- dload_2
			emit("stack", sp, " = local2")
			sp = sp + 2
		end,

		[0x29] = function() -- dload_3
			emit("stack", sp, " = local3")
			sp = sp + 2
		end,

		[0x2a] = function() -- aload_0
			emit("stack", sp, " = local0")
			sp = sp + 1
		end,

		[0x2b] = function() -- aload_1
			emit("stack", sp, " = local1")
			sp = sp + 1
		end,

		[0x2c] = function() -- aload_2
			emit("stack", sp, " = local2")
			sp = sp + 1
		end,

		[0x2d] = function() -- aload_3
			emit("stack", sp, " = local3")
			sp = sp + 1
		end,

		[0x37] = function() -- lstore
			local var = u1()
			sp = sp - 2
			emit("local", var, " = stack", sp)
		end,

		[0x3b] = function() -- istore_0
			sp = sp - 1
			emit("local0 = stack", sp)
		end,

		[0x3c] = function() -- istore_1
			sp = sp - 1
			emit("local1 = stack", sp)
		end,

		[0x3d] = function() -- istore_2
			sp = sp - 1
			emit("local2 = stack", sp)
		end,

		[0x3e] = function() -- istore_3
			sp = sp - 1
			emit("local3 = stack", sp)
		end,

		[0x3f] = function() -- lstore_0
			sp = sp - 2
			emit("local0 = stack", sp)
		end,

		[0x40] = function() -- lstore_1
			sp = sp - 2
			emit("local1 = stack", sp)
		end,

		[0x41] = function() -- lstore_2
			sp = sp - 2
			emit("local2 = stack", sp)
		end,

		[0x42] = function() -- lstore_3
			sp = sp - 2
			emit("local3 = stack", sp)
		end,

		[0x48] = function() -- dstore_1
			sp = sp - 2
			emit("local1 = stack", sp)
		end,

		[0x4a] = function() -- dstore_3
			sp = sp - 2
			emit("local3 = stack", sp)
		end,

		[0x5c] = function() -- dup2
			sp = sp + 2
			emitnonl("stack", sp-2, " = stack", sp-4, " ")
			emit("stack", sp-1, " = stack", sp-3)
		end,

		[0x60] = function() -- iadd
			emit("stack", sp-2, " = stack", sp-2, " + stack", sp-1)
			sp = sp - 1
		end,

		[0x61] = function() -- ladd
			emit("stack", sp-4, " = stack", sp-4, " + stack", sp-2)
			sp = sp - 2
		end,

		[0x63] = function() -- dadd
			emit("stack", sp-4, " = stack", sp-4, " + stack", sp-2)
			sp = sp - 2
		end,

		[0x64] = function() -- isub
			emit("stack", sp-2, " = bit.tobit(stack", sp-2, " - stack", sp-1, ")")
			sp = sp - 1
		end,

		[0x65] = function() -- lsub
			emit("stack", sp-4, " = stack", sp-4, " - stack", sp-2)
			sp = sp - 2
		end,

		[0x68] = function() -- imul
			emit("stack", sp-2, " = stack", sp-2, " * stack", sp-1)
			sp = sp - 1
		end,

		[0x69] = function() -- lmul
			emit("stack", sp-4, " = stack", sp-4, " * stack", sp-2)
			sp = sp - 2
		end,

		[0x6c] = function() -- idiv
			emit("stack", sp-2, " = bit.tobit(stack", sp-2, " / stack", sp-1, ")")
			sp = sp - 1
		end,

		[0x6b] = function() -- dmul
			emit("stack", sp-4, " = stack", sp-4, " * stack", sp-2)
			sp = sp - 2
		end,

		[0x6d] = function() -- ldiv
			emit("stack", sp-4, " = stack", sp-4, " / stack", sp-2)
			sp = sp - 2
		end,

		[0x6f] = function() -- ddiv
			emit("stack", sp-4, " = stack", sp-4, " / stack", sp-2)
			sp = sp - 2
		end,

		[0x67] = function() -- dsub
			emit("stack", sp-4, " = stack", sp-4, " - stack", sp-2)
			sp = sp - 2
		end,

		[0x84] = function() -- iinc
			local var = u1()
			local i = s1()
			emit("local", var, " = bit.tobit(local", var, " + ", i, ")")
		end,

		[0x85] = function() -- i2l
			emit("stack", sp-1, " = ffi.cast('int64_t', stack", sp-1, ")")
			sp = sp + 1
		end,

		[0x87] = function() -- i2d
			emit("stack", sp-1, " = tonumber(stack", sp-1, ")")
			sp = sp + 1
		end,

		[0x88] = function() -- l2i
			emit("stack", sp-2, " = bit.tobit(tonumber(stack", sp-2, "))")
			sp = sp - 1
		end,

		[0x8a] = function() -- l2d
			emit("stack", sp-2, " = tonumber(stack", sp-2, ")")
		end,

		[0x94] = function() -- lcmp
			emitnonl("if (stack", sp-4, " == stack", sp-2, ") then stack", sp-4, " = 0 elseif ")
			emitnonl("(stack", sp-4, " < stack", sp-2, ") then stack", sp-4, " = -1 else ")
			emit("stack", sp-4, " = 1 end")
			sp = sp - 3
		end,
			
		[0x98] = function() -- dcmpg
			emitnonl("if (stack", sp-4, " == stack", sp-2, ") then stack", sp-4, " = 0 elseif ")
			emitnonl("(stack", sp-4, " < stack", sp-2, ") then stack", sp-4, " = -1 else ")
			emit("stack", sp-4, " = 1 end")
			sp = sp - 3
		end,

		[0x99] = function() -- ifeq
			local delta = s2() - 3
			emit("if (stack", sp-1, " == 0) then goto pc_", pos+delta, " end")
			sp = sp - 1
		end,

		[0x9a] = function() -- ifeq
			local delta = s2() - 3
			emit("if (stack", sp-1, " ~= 0) then goto pc_", pos+delta, " end")
			sp = sp - 1
		end,

		[0x9b] = function() -- iflt
			local delta = s2() - 3
			emit("if (stack", sp-1, " < 0) then goto pc_", pos+delta, " end")
			sp = sp - 1
		end,

		[0x9c] = function() -- ifge
			local delta = s2() - 3
			emit("if (stack", sp-1, " >= 0) then goto pc_", pos+delta, " end")
			sp = sp - 1
		end,

		[0x9d] = function() -- ifgt
			local delta = s2() - 3
			emit("if (stack", sp-1, " > 0) then goto pc_", pos+delta, " end")
			sp = sp - 1
		end,

		[0x9e] = function() -- ifle
			local delta = s2() - 3
			emit("if (stack", sp-1, " <= 0) then goto pc_", pos+delta, " end")
			sp = sp - 1
		end,

		[0xa2] = function() -- if_icmpge
			local delta = s2() - 3
			emit("if (stack", sp-2, " >= stack", sp-1, ") then goto pc_", pos+delta, " end")
			sp = sp - 2
		end,

		[0xa7] = function() -- goto
			local delta = s2() - 3
			emit("goto pc_", pos+delta)
			sp = 0
		end,

		[0xac] = function() -- ireturn
			emit("do return stack", sp-1, " end")
			sp = 0
		end,

		[0xaf] = function() -- dreturn
			emit("do return stack", sp-2, " end")
			sp = 0
		end,

		[0xb0] = function() -- areturn
			emit("do return stack", sp-1, " end")
			sp = 0
		end,

		[0xb1] = function() -- return
			emit("do return end")
			sp = 0
		end,

		[0xb3] = function() -- putstatic
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = constant(class:ClassLoader():LoadClass(f.Class))

			sp = sp - f.Size
			emit(c, ".fs_", f.Name, " = stack", sp)
		end,

		[0xb2] = function() -- getstatic
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = constant(class:ClassLoader():LoadClass(f.Class))

			emit("stack", sp, " = ", c, ".fs_", f.Name)
			sp = sp + f.Size
		end,

		[0xb6] = function() -- invokevirtual
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = constant(class:ClassLoader():LoadClass(f.Class))

			pretty.dump(f)
			emit("-- invokevirtual")
		end,

		[0xb8] = function() -- invokestatic
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = constant(class:ClassLoader():LoadClass(f.Class))

			emitnonl("do local r, e = ", c, "['m_", f.Name, f.Descriptor, "'](")

			local numinparams = #f.InParams
			local inparams = {}
			for n, d in ipairs(f.InParams) do
				sp = sp - d
				inparams[numinparams - n + 1] = "stack"..sp
			end

			emitnonl(table_concat(inparams, ", "))
			emitnonl(") ")

			if (f.OutParams > 0) then
				emitnonl("stack", sp, " = r")
				sp = sp + f.OutParams
			end

			emit(" end")
		end,

		[0xbe] = function() -- arraylength
			nullcheck("stack"..(sp-1))
			emit("stack", (sp-1), " = stack", (sp-1), ":length()")
		end,
	}

	while (pos < #bytecode) do
		checkstack(pos)
		output[#output+1] = "::pc_"..pos..":: "

		local opcode = u1()
		local opcodec = opcodemap[opcode]
		if not opcodec then
			Utils.Throw("unimplemented opcode 0x"..string.format("%02x", opcode))
		end
		opcodec()
	end

	-- Emit function epilogue.
	
	emit("return end")

	-- Wrap the whole thing in the constructor function used to pass in the
	-- constant pool.
	
	local wrapper = {
		"local ffi = require('ffi') ",
		"return function("
	}

	do
		local first = true
		for k, _ in ipairs(constants) do
			if not first then
				wrapper[#wrapper+1] = ", "
			end
			first = false
			wrapper[#wrapper+1] = "constant"..k
		end
	end

	wrapper[#wrapper+1] = ")\nreturn "
	wrapper[#wrapper+1] = table_concat(output)
	wrapper[#wrapper+1] = "end"

	-- Compile it.
	
	dbg(table_concat(wrapper))
	local chunk, e = load(table_concat(wrapper))
	Utils.Check(e, "compilation failed")

	-- Now actually call the constructor, with the constants, to produce the
	-- runnable method.
	
	return chunk()(unpack(constants))
end

-- This function takes a reference to a native method, and returns the
-- Lua method which implements it after looking it up in the native
-- method registration table.

local function compile_native_method(class, analysis, mimpl)
	local f = Runtime.FindNativeMethod(analysis.ThisClass, mimpl.Name .. mimpl.Descriptor)
	Utils.Assert(f, "no native method for ", analysis.ThisClass, "::", mimpl.Name, mimpl.Descriptor)
	return f
end

local function compile_static_method(class, analysis, mimpl)
	if string_find(mimpl.AccessFlags, " native ") then
		return compile_native_method(class, analysis, mimpl)
	else
		return compile_method(class, analysis, mimpl)
	end
end

return function(classloader)
	local analysis

	local c
	c = {
		Init = function(self, a)
			analysis = a

			-- Create any fields defined by this class.

			for name, field in pairs(a.Fields) do
				dbg("warning: field ", name, " initialised to 0")
				c["fs_"..name] = 0
			end
		end,

		ClassLoader = function(self)
			return classloader
		end,

		FindStaticMethod = function(self, n)
			dbg("looking for ", n)

			local mimpl = analysis.Methods[n]
			m = compile_static_method(self, analysis, mimpl)
			return m
		end
	}

	setmetatable(c,
		{
			__index = function(self, k)
				local _, _, n = string_find(k, "m_(.*)")
				Utils.Assert(n, "table slot for method ('", k, "') does not begin with m_")
				local m = c:FindStaticMethod(n)
				c[k] = m
				return m
			end
		}
	)

	return c
end

