-- Luje
-- © 2013 David Given
-- This file is redistributable under the terms of the
-- New BSD License. Please see the COPYING file in the
-- project root for the full text.

local Utils = require("Utils")
local dbg = Utils.Debug
local Runtime = require("Runtime")
local Options = require("Options")
local string_byte = string.byte
local string_find = string.find
local string_gsub = string.gsub
local table_concat = table.concat
local Cast = require("Cast")
local ffi = require("ffi")
local ffi_new = ffi.new
local BtoSB = Cast.BtoSB
local BBtoW = Cast.BBtoW
local WtoSW = Cast.WtoSW
local WWtoI = Cast.WWtoI
local ItoSI = Cast.ItoSI

-- Table describing boxed values.

local boxinfo = {
	["Z"] = "int32_t",
	["B"] = "int8_t",
	["C"] = "uint16_t",
	["S"] = "int16_t ",
	["I"] = "int32_t ",
	["J"] = "int64_t ",
	["F"] = "float",
	["D"] = "double"
}

-- Resolves a field reference in a climp.

local function search_for_field_in_climp_class_hierarchy(climp, name)
	if climp.Analysis.Fields[name] then
		return climp
	end
	local superclimp = climp:SuperClimp()
	if superclimp then
		return search_for_field_in_climp_class_hierarchy(superclimp, name)
	end
	return nil
end

local function resolve_field_reference(climp, field)
	if not field.ResolvedClass then
		field.ResolvedClass = search_for_field_in_climp_class_hierarchy(climp, field.Name)
	end
	return field.ResolvedClass
end

-- Massages a field into a C name.

local function field_name(climp, field)
	local s = (resolve_field_reference(climp, field).ThisClass()).."/"..field.Name..field.Descriptor
	s = string_gsub(s, "_", "_U_")
	s = string_gsub(s, "/", "_S_")
	s = string_gsub(s, "%$", "_D_")
	return s
end

-- Returns an lvalue representing an object (or class) field.

local function field_lvalue(c, f)
	local bi = boxinfo[f.Descriptor]
	if bi then
		-- This is a boxed value.
		return "Fields['"..field_name(c, f).."']"
	else
		-- Non-boxed value (object reference).
		return "OFields['"..field_name(c, f).."']"
	end
end

-- This function does the bytecode compilation. It takes the bytecode and
-- converts it into a Lua script, then compiles it and returns the method as
-- a callable function.

local function compile_method(climp, analysis, mimpl)
	if Options.TraceCompilations then
		dbg("compiling: ", analysis.ThisClass, "::", mimpl.Name, mimpl.Descriptor)
	end

	local bytecode = mimpl.Code.Bytecode
	local pos = 0
	local sp = 0
	local lineno = 2 -- include line of boilerplate before code
	local stacksize = {} -- size of stack at each bytecode
	local entrypoints = {} -- any additional entrypoints waiting compilation
	local seenopcodes = {} -- opcodes which we've already compiled
	local wide = false -- was the last opcode 'wide'?
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

	local sw, uw -- assigned to either u1 or u2 depending on setting of wide

	-- Ensures that the current stack pointer matches any recorded stack for
	-- this address.
	
	local function checkstack(pc)
		local csp = stacksize[pc]
		if (csp == nil) then
			stacksize[pc] = sp
		elseif (csp ~= sp) then
			dbg("stack mismatch (address "..pc.." is currently "..csp..", but should be "..sp..")")
		end
	end

	-- Add a new entrypoint, recording the stack that it should have.
	
	local function addentrypoint(pc, newsp)
		if not newsp then
			newsp = sp
		end

		local csp = stacksize[pc]
		if (csp ~= nil) then
			if (csp ~= newsp) then
				Utils.Throw("stack mismatch in target (address "..pc.." is currently "..csp..", but should be "..newsp..")")
			end
		else
			stacksize[pc] = newsp
		end

		if not seenopcodes[pc] then
			entrypoints[pc] = true
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
		lineno = lineno + 1
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
		if Options.CheckNullPointers then
			emitnonl("if (", v, " == nil) then goto nullpointer end ")
		end
	end

	-- Perform a method call.
	
	local function methodcall(f, self)
		local numinparams = #f.InParams
		local inparams = {}
		if self then
			inparams[#inparams+1] = self
		end
		local o = #inparams
		for i = numinparams, 1, -1 do
			local d = f.InParams[i]
			sp = sp - d
			inparams[o+i] = "stack"..sp
		end

		emitnonl("(")
		emitnonl(table_concat(inparams, ", "))
		emitnonl(") ")
	end

	-- Emits code to check whether an exception is thrown. Note that the pc
	-- is, at this point, *after* the instruction that threw the exception.
	
	local function checkexception()
		emit("if e then epc=", pos-1, " goto exceptionhandler end")
	end

	-- Emit the function prologue.
	
	emitnonl("function(")
	local minlocals = 1
	do
		local first = true
		
		-- If this isn't a static method, local0 is always an implicit
		-- parameter representing 'this'.

		if not string_find(mimpl.AccessFlags, " static ") then
			emitnonl("local0")
			minlocals = 2
			first = false
		end

		-- The rest of the parameters (might be empty).

		for n, d in ipairs(mimpl.InParams) do
			if not first then
				emitnonl(", ")
			end
			first = false
			emitnonl("local", minlocals-1)
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

	-- Internal variables used for exception handling.
	emit("local _, e, epc")

	-- Common opcodes.
	
	local function pushconst_op(size, value)
		return function()
			emit("stack", sp, " = ", value)
			sp = sp + size
		end
	end

	local function arraystore_op(size)
		return function()
			sp = sp - (2+size)
			nullcheck("stack"..sp)
			emit("_, e = stack", sp, ":ArrayPut(stack", sp+1, ", stack", sp+2, ")")
			checkexception()
		end
	end

	local function arrayload_op(size)
		return function()
			sp = sp - 2
			nullcheck("stack"..sp)
			emit("stack", sp, ", e = stack", sp, ":ArrayGet(stack", sp+1, ")")
			checkexception()
			sp = sp + size
		end
	end

	local function localstore_op(size, index)
		return function()
			sp = sp - size
			emit("local", index, " = stack", sp)
		end
	end

	local function localload_op(size, index)
		return function()
			emit("stack", sp, " = local", index)
			sp = sp + size
		end
	end
	
	local function ifcmp_op(cmp)
		return function()
			local delta = s2() - 3
			sp = sp - 2
			emit("if (stack", sp, " ", cmp, " stack", sp+1, ") then goto pc_", pos+delta, " end")
			addentrypoint(pos+delta, sp)
		end
	end

	-- This table expands all the opcodes.

	local opcodemap = {
		[0x00] = function() -- nop
			emit("-- nop")
		end,

		[0x01] = pushconst_op(1, nil), -- aconst_null
		[0x02] = pushconst_op(1, -1), -- iconst_m1
		[0x03] = pushconst_op(1, 0), -- iconst_0
		[0x04] = pushconst_op(1, 1), -- iconst_1
		[0x05] = pushconst_op(1, 2), -- iconst_2
		[0x06] = pushconst_op(1, 3), -- iconst_3
		[0x07] = pushconst_op(1, 4), -- iconst_4
		[0x08] = pushconst_op(1, 5), -- iconst_5
		[0x09] = pushconst_op(2, 0), -- lconst_0
		[0x0a] = pushconst_op(2, 1), -- lconst_1
		[0x0b] = pushconst_op(1, 0), -- fconst_0
		[0x0c] = pushconst_op(1, 1), -- fconst_1
		[0x0d] = pushconst_op(1, 2), -- fconst_2
		[0x0e] = pushconst_op(2, 0), -- dconst_0
		[0x0f] = pushconst_op(2, 1), -- dconst_1

		[0x10] = function() -- bipush
			local i = s1()
			emit("stack", sp, " = ", i)
			sp = sp + 1
		end,

		[0x11] = function() -- sipush
			local i = s2()
			emit("stack", sp, " = ", i)
			sp = sp + 1
		end,

		[0x12] = function() -- ldc
			local i = u1()
			local c = climp:GetConstantValue(i)
			if (type(c) == "table") then
				c = constant(c)
			end
			emit("stack", sp, " = ", c)
			sp = sp + 1
		end,

		[0x13] = function() -- ldc
			local i = u2()
			local c = climp:GetConstantValue(i)
			if (type(c) == "table") then
				c = constant(c)
			end
			emit("stack", sp, " = ", c)
			sp = sp + 1
		end,

		[0x14] = function() -- ldc2_w
			local i = u2()
			local c = climp:GetConstantValue(i)
			emit("stack", sp, " = ", c)
			sp = sp + 2
		end,

		[0x15] = function() -- iload
			local i = uw()
			emit("stack", sp, " = local", i)
			sp = sp + 1
		end,

		[0x16] = function() -- lload
			local i = uw()
			emit("stack", sp, " = local", i)
			sp = sp + 2
		end,

		[0x17] = function() -- fload
			local i = uw()
			emit("stack", sp, " = local", i)
			sp = sp + 1
		end,

		[0x18] = function() -- dload
			local i = uw()
			emit("stack", sp, " = local", i)
			sp = sp + 2
		end,

		[0x19] = function() -- aload
			local i = uw()
			emit("stack", sp, " = local", i)
			sp = sp + 1
		end,

		[0x1a] = localload_op(1, 0), -- iload_0
		[0x1b] = localload_op(1, 1), -- iload_1
		[0x1c] = localload_op(1, 2), -- iload_2
		[0x1d] = localload_op(1, 3), -- iload_3
		[0x1e] = localload_op(2, 0), -- lload_0
		[0x1f] = localload_op(2, 1), -- lload_1
		[0x20] = localload_op(2, 2), -- lload_2
		[0x21] = localload_op(2, 3), -- lload_3
		[0x22] = localload_op(1, 0), -- fload_0
		[0x23] = localload_op(1, 1), -- fload_1
		[0x24] = localload_op(1, 2), -- fload_2
		[0x25] = localload_op(1, 3), -- fload_3
		[0x26] = localload_op(2, 0), -- dload_0
		[0x27] = localload_op(2, 1), -- dload_1
		[0x28] = localload_op(2, 2), -- dload_2
		[0x29] = localload_op(2, 3), -- dload_3
		[0x2a] = localload_op(1, 0), -- aload_0
		[0x2b] = localload_op(1, 1), -- aload_1
		[0x2c] = localload_op(1, 2), -- aload_2
		[0x2d] = localload_op(1, 3), -- aload_3

		[0x2e] = arrayload_op(1), -- iaload
		[0x2f] = arrayload_op(2), -- laload
		[0x30] = arrayload_op(1), -- faload
		[0x31] = arrayload_op(2), -- daload
		[0x32] = arrayload_op(1), -- aaload
		[0x33] = arrayload_op(1), -- baload
		[0x34] = arrayload_op(1), -- caload
		[0x35] = arrayload_op(1), -- saload

		[0x36] = function() -- istore
			local var = uw()
			sp = sp - 1
			emit("local", var, " = stack", sp)
		end,

		[0x37] = function() -- lstore
			local var = uw()
			sp = sp - 2
			emit("local", var, " = stack", sp)
		end,

		[0x38] = function() -- fstore
			local var = uw()
			sp = sp - 1
			emit("local", var, " = stack", sp)
		end,

		[0x39] = function() -- dstore
			local var = uw()
			sp = sp - 2
			emit("local", var, " = stack", sp)
		end,

		[0x3a] = function() -- astore
			local var = uw()
			sp = sp - 1
			emit("local", var, " = stack", sp)
		end,

		[0x3b] = localstore_op(1, 0), -- istore_0
		[0x3c] = localstore_op(1, 1), -- istore_1
		[0x3d] = localstore_op(1, 2), -- istore_2
		[0x3e] = localstore_op(1, 3), -- istore_3
		[0x3f] = localstore_op(2, 0), -- lstore_0
		[0x40] = localstore_op(2, 1), -- lstore_1
		[0x41] = localstore_op(2, 2), -- lstore_2
		[0x42] = localstore_op(2, 3), -- lstore_3
		[0x43] = localstore_op(1, 0), -- fstore_0
		[0x44] = localstore_op(1, 1), -- fstore_1
		[0x45] = localstore_op(1, 2), -- fstore_2
		[0x46] = localstore_op(1, 3), -- fstore_3
		[0x47] = localstore_op(2, 0), -- dstore_0
		[0x48] = localstore_op(2, 1), -- dstore_1
		[0x49] = localstore_op(2, 2), -- dstore_2
		[0x4a] = localstore_op(2, 3), -- dstore_3
		[0x4b] = localstore_op(1, 0), -- astore_0
		[0x4c] = localstore_op(1, 1), -- astore_1
		[0x4d] = localstore_op(1, 2), -- astore_2
		[0x4e] = localstore_op(1, 3), -- astore_3

		[0x4f] = arraystore_op(1), -- iastore
		[0x50] = arraystore_op(2), -- lastore
		[0x51] = arraystore_op(1), -- fastore
		[0x52] = arraystore_op(2), -- dastore
		[0x53] = arraystore_op(1), -- aastore
		[0x54] = arraystore_op(1), -- bastore
		[0x55] = arraystore_op(1), -- castore
		[0x56] = arraystore_op(1), -- sastore

		[0x57] = function() -- pop
			sp = sp - 1
			emit("-- pop")
		end,

		[0x58] = function() -- pop2
			sp = sp - 2
			emit("-- pop2")
		end,

		[0x59] = function() -- dup
			sp = sp + 1
			emit("stack", sp-1, " = stack", sp-2)
		end,

		[0x5a] = function() -- dup_x1
			sp = sp - 2
			emit("do local v2, v1 = stack", sp, ", stack", sp+1, " stack", sp, "=v1 stack", sp+1, "=v2 stack", sp+2, "=v1 end")
			sp = sp + 3
		end,

		[0x5b] = function() -- dup_x2
			sp = sp - 3
			emitnonl("do local v3, v2, v1 = stack", sp, ", stack", sp+1, ", stack", sp+2)
			emitnonl(" stack", sp, "=v1")
			emitnonl(" stack", sp+1, "=v3")
			emitnonl(" stack", sp+2, "=v2")
			emitnonl(" stack", sp+3, "=v1")
			emit(" end")
			sp = sp + 4
		end,

		[0x5c] = function() -- dup2
			sp = sp + 2
			emitnonl("stack", sp-2, " = stack", sp-4, " ")
			emit("stack", sp-1, " = stack", sp-3)
		end,

		[0x5d] = function() -- dup2_x1
			sp = sp - 3
			emitnonl("do local v3, v2, v1 = stack", sp, ", stack", sp+1, ", stack", sp+2)
			emitnonl(" stack", sp, "=v2")
			emitnonl(" stack", sp+1, "=v1")
			emitnonl(" stack", sp+2, "=v3")
			emitnonl(" stack", sp+3, "=v2")
			emitnonl(" stack", sp+4, "=v1")
			emit(" end")
			sp = sp + 5
		end,

		[0x60] = function() -- iadd
			emit("stack", sp-2, " = tonumber(cast('int32_t', cast('int32_t', stack", sp-2, ") + cast('int32_t', stack", sp-1, ")))")
			sp = sp - 1
		end,

		[0x61] = function() -- ladd
			emit("stack", sp-4, " = stack", sp-4, " + stack", sp-2)
			sp = sp - 2
		end,

		[0x62] = function() -- fadd
			emit("stack", sp-2, " = stack", sp-2, " + stack", sp-1)
			sp = sp - 1
		end,

		[0x63] = function() -- dadd
			emit("stack", sp-4, " = stack", sp-4, " + stack", sp-2)
			sp = sp - 2
		end,

		[0x64] = function() -- isub
			emit("stack", sp-2, " = tonumber(cast('int32_t', stack", sp-2, " - stack", sp-1, "))")
			sp = sp - 1
		end,

		[0x65] = function() -- lsub
			emit("stack", sp-4, " = stack", sp-4, " - stack", sp-2)
			sp = sp - 2
		end,

		[0x66] = function() -- fsub
			emit("stack", sp-2, " = stack", sp-2, " - stack", sp-1)
			sp = sp - 1
		end,

		[0x68] = function() -- imul
			emit("stack", sp-2, " = tonumber(cast('int32_t', cast('int32_t', stack", sp-2, ") * cast('int32_t', stack", sp-1, ")))")
			sp = sp - 1
		end,

		[0x69] = function() -- lmul
			emit("stack", sp-4, " = stack", sp-4, " * stack", sp-2)
			sp = sp - 2
		end,

		[0x6a] = function() -- fmul
			emit("stack", sp-2, " = stack", sp-2, " * stack", sp-1)
			sp = sp - 1
		end,

		[0x6c] = function() -- idiv
			emit("stack", sp-2, " = tonumber(cast('int32_t', stack", sp-2, " / stack", sp-1, "))")
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

		[0x6e] = function() -- fdiv
			emit("stack", sp-2, " = stack", sp-2, " / stack", sp-1)
			sp = sp - 1
		end,

		[0x6f] = function() -- ddiv
			emit("stack", sp-4, " = stack", sp-4, " / stack", sp-2)
			sp = sp - 2
		end,

		[0x67] = function() -- dsub
			emit("stack", sp-4, " = stack", sp-4, " - stack", sp-2)
			sp = sp - 2
		end,

		[0x70] = function() -- irem
			emit("stack", sp-2, " = tonumber(cast('int32_t', stack", sp-2, " % stack", sp-1, "))")
			sp = sp - 1
		end,

		[0x71] = function() -- lrem
			sp = sp - 4
			emit("stack", sp, " = stack", sp, " % stack", sp+2)
			sp = sp + 2
		end,

		[0x74] = function() -- ineg
			emit("stack", sp-1, " = tonumber(cast('int32_t', -stack", sp-1, "))")
		end,

		[0x75] = function() -- lneg
			emit("stack", sp-2, " = cast('int64_t', -stack", sp-2, ")")
		end,

		[0x78] = function() -- ishl
			emit("stack", sp-2, " = bit_lshift(stack", sp-2, ", stack", sp-1, ")")
			sp = sp - 1
		end,

		[0x7a] = function() -- ishr
			emit("stack", sp-2, " = bit_arshift(stack", sp-2, ", stack", sp-1, ")")
			sp = sp - 1
		end,

		[0x7e] = function() -- iand
			emit("stack", sp-2, " = bit_band(stack", sp-2, ", stack", sp-1, ")")
			sp = sp - 1
		end,

		[0x80] = function() -- ior
			emit("stack", sp-2, " = bit_bor(stack", sp-2, ", stack", sp-1, ")")
			sp = sp - 1
		end,

		[0x84] = function() -- iinc
			local var = uw()
			local i = sw()
			emit("local", var, " = tonumber(cast('int32_t', local", var, " + ", i, "))")
		end,

		[0x85] = function() -- i2l
			emit("stack", sp-1, " = cast('int64_t', stack", sp-1, ")")
			sp = sp + 1
		end,

		[0x86] = function() -- i2f
			emit("stack", sp-1, " = tonumber(stack", sp-1, ")")
		end,

		[0x87] = function() -- i2d
			emit("stack", sp-1, " = tonumber(stack", sp-1, ")")
			sp = sp + 1
		end,

		[0x88] = function() -- l2i
			emit("stack", sp-2, " = tonumber(cast('int32_t', stack", sp-2, "))")
			sp = sp - 1
		end,

		[0x8a] = function() -- l2d
			emit("stack", sp-2, " = tonumber(stack", sp-2, ")")
		end,

		[0x8b] = function() -- f2i
			emit("stack", sp-1, " = tonumber(cast('int32_t', stack", sp-1, "))")
		end,

		[0x8d] = function() -- f2d
			emit("stack", sp-1, " = cast('double', stack", sp-1, ")")
			sp = sp + 1
		end,

		[0x91] = function() -- i2b
			emit("stack", sp-1, " = tonumber(cast('int8_t', stack", sp-1, "))")
		end,

		[0x92] = function() -- i2c
			emit("stack", sp-1, " = tonumber(cast('uint16_t', stack", sp-1, "))")
		end,

		[0x93] = function() -- i2s
			emit("stack", sp-1, " = tonumber(cast('int16_t', stack", sp-1, "))")
		end,

		[0x94] = function() -- lcmp
			emitnonl("if (stack", sp-4, " == stack", sp-2, ") then stack", sp-4, " = 0 elseif ")
			emitnonl("(stack", sp-4, " < stack", sp-2, ") then stack", sp-4, " = -1 else ")
			emit("stack", sp-4, " = 1 end")
			sp = sp - 3
		end,
			
		[0x95] = function() -- fcmpl
			sp = sp - 2
			emitnonl("if (stack", sp, " == stack", sp+1, ") then stack", sp, " = 0 elseif ")
			emitnonl("(stack", sp, " > stack", sp+1, ") then stack", sp, " = 1 else ")
			emit("stack", sp, " = -1 end")
			sp = sp + 1
		end,

		[0x96] = function() -- fcmpg
			sp = sp - 2
			emitnonl("if (stack", sp, " == stack", sp+1, ") then stack", sp, " = 0 elseif ")
			emitnonl("(stack", sp, " < stack", sp+1, ") then stack", sp, " = -1 else ")
			emit("stack", sp, " = 1 end")
			sp = sp + 1
		end,

		[0x97] = function() -- dcmpl
			sp = sp - 4
			emitnonl("if (stack", sp, " == stack", sp+2, ") then stack", sp, " = 0 elseif ")
			emitnonl("(stack", sp, " > stack", sp+2, ") then stack", sp, " = 1 else ")
			emit("stack", sp, " = -1 end")
			sp = sp + 1
		end,

		[0x98] = function() -- dcmpg
			emitnonl("if (stack", sp-4, " == stack", sp-2, ") then stack", sp-4, " = 0 elseif ")
			emitnonl("(stack", sp-4, " < stack", sp-2, ") then stack", sp-4, " = -1 else ")
			emit("stack", sp-4, " = 1 end")
			sp = sp - 3
		end,

		[0x99] = function() -- ifeq
			local delta = s2() - 3
			sp = sp - 1
			emit("if (stack", sp, " == 0) then goto pc_", pos+delta, " end")
			addentrypoint(pos+delta, sp)
		end,

		[0x9a] = function() -- ifeq
			local delta = s2() - 3
			sp = sp - 1
			emit("if (stack", sp, " ~= 0) then goto pc_", pos+delta, " end")
			addentrypoint(pos+delta, sp)
		end,

		[0x9b] = function() -- iflt
			local delta = s2() - 3
			sp = sp - 1
			emit("if (stack", sp, " < 0) then goto pc_", pos+delta, " end")
			addentrypoint(pos+delta, sp)
		end,

		[0x9c] = function() -- ifge
			local delta = s2() - 3
			sp = sp - 1
			emit("if (stack", sp, " >= 0) then goto pc_", pos+delta, " end")
			addentrypoint(pos+delta, sp)
		end,

		[0x9d] = function() -- ifgt
			local delta = s2() - 3
			sp = sp - 1
			emit("if (stack", sp, " > 0) then goto pc_", pos+delta, " end")
			addentrypoint(pos+delta, sp)
		end,

		[0x9e] = function() -- ifle
			local delta = s2() - 3
			sp = sp - 1
			emit("if (stack", sp, " <= 0) then goto pc_", pos+delta, " end")
			addentrypoint(pos+delta, sp)
		end,

		[0x9f] = ifcmp_op("=="), -- if_icmpeq
		[0xa0] = ifcmp_op("~="), -- if_icmpne
		[0xa1] = ifcmp_op("<"), -- if_icmplt
		[0xa2] = ifcmp_op(">="), -- if_icmpge
		[0xa3] = ifcmp_op(">"), -- if_icmpgt
		[0xa4] = ifcmp_op("<="), -- if_icmple
		[0xa5] = ifcmp_op("=="), -- if_acmpeq
		[0xa6] = ifcmp_op("~="), -- if_acmpne

		[0xa7] = function() -- goto
			local delta = s2() - 3
			emit("goto pc_", pos+delta)
			addentrypoint(pos+delta, sp)
			sp = nil
		end,

		[0xac] = function() -- ireturn
			sp = sp - 1
			emit("do return stack", sp, " end")
			sp = nil
		end,

		[0xad] = function() -- lreturn
			sp = sp - 2
			emit("do return stack", sp, " end")
			sp = nil
		end,

		[0xae] = function() -- freturn
			sp = sp - 1
			emit("do return stack", sp, " end")
			sp = nil
		end,

		[0xaf] = function() -- dreturn
			sp = sp - 2
			emit("do return stack", sp, " end")
			sp = nil
		end,

		[0xb0] = function() -- areturn
			sp = sp - 1
			emit("do return stack", sp, " end")
			sp = nil
		end,

		[0xb1] = function() -- return
			emit("do return end")
			sp = nil
		end,

		[0xb2] = function() -- getstatic
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = climp:ClimpLoader():LoadClimp(f.Class)

			emit("stack", sp, " = ", constant(c), ".", field_lvalue(c, f))
			sp = sp + f.Size
		end,

		[0xb3] = function() -- putstatic
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = climp:ClimpLoader():LoadClimp(f.Class)

			sp = sp - f.Size
			emit(constant(c), ".", field_lvalue(c, f), " = stack", sp)
		end,

		[0xb4] = function() -- getfield
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = climp:ClimpLoader():LoadClimp(f.Class)

			sp = sp - 1
			nullcheck("stack"..sp)
			emit("stack", sp, " = stack", sp, ".", field_lvalue(c, f))
			sp = sp + f.Size
		end,

		[0xb5] = function() -- putfield
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = climp:ClimpLoader():LoadClimp(f.Class)

			sp = sp - f.Size - 1
			nullcheck("stack"..sp)
			emit("stack", sp, ".", field_lvalue(c, f), " = stack", sp+1)
		end,

		[0xb6] = function() -- invokevirtual
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = constant(climp:ClimpLoader():LoadClimp(f.Class))

			local self = "stack"..(sp-1-f.Size)
			nullcheck(self)

			if (f.OutParams > 0) then
				emitnonl(self)
			else
				emitnonl("_")
			end

			emitnonl(", e = ", self, ".Methods['", f.Name, f.Descriptor, "']")
			methodcall(f, self)
			checkexception()
			sp = sp - 1 + f.OutParams
		end,

		[0xb7] = function() -- invokespecial
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = constant(climp:ClimpLoader():LoadClimp(f.Class))

			local self = "stack"..(sp-1-f.Size)
			if (f.OutParams > 0) then
				emitnonl(self)
			else
				emitnonl("_")
			end

			emitnonl(", e = ", c, ".Methods['", f.Name, f.Descriptor, "']")
			methodcall(f, self)
			checkexception()
			sp = sp - 1 + f.OutParams
		end,

		[0xb8] = function() -- invokestatic
			local i = u2()
			local f = analysis.RefConstants[i]
			local c = constant(climp:ClimpLoader():LoadClimp(f.Class))

			if (f.OutParams > 0) then
				emitnonl("stack", sp-f.Size)
			else
				emitnonl("_")
			end

			emitnonl(", e = ", c, ".Methods['", f.Name, f.Descriptor, "']")
			methodcall(f)
			checkexception()
			sp = sp + f.OutParams
		end,

		[0xb9] = function() -- invokeinterface
			local i = u2()
			u2() -- read and ingore two bytes
			local f = analysis.RefConstants[i]
			local c = constant(climp:ClimpLoader():LoadClimp(f.Class))

			local self = "stack"..(sp-1-f.Size)
			nullcheck(self)

			if (f.OutParams > 0) then
				emitnonl(self)
			else
				emitnonl("_")
			end

			emitnonl(", e = ", self, ".Methods['", f.Name, f.Descriptor, "']")
			methodcall(f, self)
			checkexception()
			sp = sp - 1 + f.OutParams
		end,

		[0xbb] = function() -- new
			local i = u2()
			local f = analysis.ClassConstants[i]
			local c = constant(climp:ClimpLoader():LoadClimp(f))

			emit("stack", sp, ", e = runtime.New(", c, ")")
			checkexception()
			sp = sp + 1
		end,

		[0xbc] = function() -- newarray
			local i = u1()
			emit("stack", sp-1, ", e = runtime.NewArray(", i, ", stack", sp-1, ")")
			checkexception()
		end,

		[0xbd] = function() -- anewarray
			local i = u2()
			local f = analysis.ClassConstants[i]
			local c = constant(climp:ClimpLoader():LoadClimp(f))
			emit("stack", sp-1, ", e = runtime.NewAArray(", c, ", stack", sp-1, ")")
			checkexception()
		end,

		[0xbe] = function() -- arraylength
			nullcheck("stack"..(sp-1))
			emit("stack", (sp-1), ", e = stack", (sp-1), ":Length()")
			checkexception()
		end,

		[0xbf] = function() -- athrow
			local o = "stack"..(sp-1)
			emit("e = ", o)
			checkexception()
			sp = nil
		end,

		[0xc0] = function() -- checkcast
			local i = u2()
			local f = analysis.ClassConstants[i]
			local c = constant(climp:ClimpLoader():LoadClimp(f))

			local o = "stack"..(sp-1)
			emit("if not runtime.InstanceOf(", o, ", ", c, ") then error('bad cast') end")
		end,

		[0xc1] = function() -- instanceof
			local i = u2()
			local f = analysis.ClassConstants[i]
			local c = constant(climp:ClimpLoader():LoadClimp(f))

			local o = "stack"..(sp-1)
			emit(o, " = runtime.InstanceOf(", o, ", ", c, ")")
		end,

		[0xc2] = function() -- monitorenter
			emit("-- monitorenter")
			sp = sp - 1
		end,

		[0xc3] = function() -- monitorexit
			emit("-- monitorexit")
			sp = sp - 1
		end,

		[0xc4] = function() -- wide
			emit("-- wide")
			wide = true
		end,

		[0xc6] = function() -- ifnull
			local delta = s2() - 3
			sp = sp - 1
			emit("if (stack", sp, " == nil) then goto pc_", pos+delta, " end")
			addentrypoint(pos+delta, sp)
		end,

		[0xc7] = function() -- ifnonnull
			local delta = s2() - 3
			sp = sp - 1
			emit("if (stack", sp, " ~= nil) then goto pc_", pos+delta, " end")
			addentrypoint(pos+delta, sp)
		end,
	}

	-- Add the main code entrypoint.

	addentrypoint(0, 0)
	emit("goto pc_0")

	-- Add the exception handler.
	
	emit("::exceptionhandler::")
	emit("stack0 = e")
	for _, t in ipairs(mimpl.Code.ExceptionTable) do
		emitnonl("if (epc>=", t.start_pc, ") and (epc<", t.end_pc, ") ")
		if (t.catch_type ~= 0) then
			local f = analysis.ClassConstants[t.catch_type]
			local c = constant(climp:ClimpLoader():LoadClimp(f))

			emitnonl("and runtime.InstanceOf(e, ", c, ") ")
		end
		emit("then goto pc_", t.handler_pc, " end")
		addentrypoint(t.handler_pc, 1)
	end
	emit("do return nil, e end")

	-- Add the null pointer handler.
	
	if Options.CheckNullPointers then
		emit("::nullpointer::")
		emit("e = runtime.NullPointerException()")
		emit("goto exceptionhandler")
	end

	while true do
		-- Fetch the next entrypoint.

		pos = Utils.FindSmallestKey(entrypoints)
		if (pos == nil) then
			break
		end
		entrypoints[pos] = nil

		if not seenopcodes[pos] then
			emit("-- new entrypoint")
			sp = stacksize[pos]

			while (sp ~= nil) do
				if seenopcodes[pos] then
					-- Whups! This opcode has already been compiled. Rather
					-- than compile it again, jump to the original version.
					emit("goto pc_", pos)
					addentrypoint(pos, sp)
					break
				end

				seenopcodes[pos] = true
				checkstack(pos)
				output[#output+1] = "::pc_"..pos..":: "

				-- Ensure that 'wide' is honoured
				if wide then
					uw = u2
					sw = s2
					wide = false
				else
					uw = u1
					sw = s1
				end

				local opcode = u1()
				local opcodec = opcodemap[opcode]
				if not opcodec then
					Utils.Throw("unimplemented opcode 0x"..string.format("%02x", opcode))
				end
				emitnonl("--[[ sp=", sp, " line=", lineno, " --]] ")
				opcodec()
			end
		end
	end

	-- Emit function epilogue.
	
	emit("end")

	-- Wrap the whole thing in the constructor function used to pass in the
	-- constant pool.
	
	local wrapper = {
		"local ffi = require('ffi') ",
		"local runtime = require('Runtime') ",
		"local tonumber = tonumber ",
		"local cast = ffi.cast ",
		"local bit_lshift, bit_arshift, bit_band, bit_bor = bit.lshift, bit.arshift, bit.band, bit.bor ",
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
	
	if Options.DumpCompilations then
		dbg("source for: ", analysis.ThisClass, "::", mimpl.Name, mimpl.Descriptor, "\n", table_concat(wrapper), "\n")
	end

	local chunk, e = load(table_concat(wrapper),
		analysis.ThisClass.."::"..mimpl.Name..mimpl.Descriptor)
	Utils.Check(e, "compilation failed")

	-- Now actually call the constructor, with the constants, to produce the
	-- runnable method.
	
	return chunk()(unpack(constants))
end

-- This function takes a reference to a native method, and returns the
-- Lua method which implements it after looking it up in the native
-- method registration table.

local function compile_native_method(climp, analysis, mimpl)
	local f = Runtime.FindNativeMethod(analysis.ThisClass, mimpl.Name .. mimpl.Descriptor)
	Utils.Assert(f, "no native method for ", analysis.ThisClass, "::", mimpl.Name, mimpl.Descriptor)
	return f
end

local function compile_nonstatic_method(climp, analysis, mimpl)
	if string_find(mimpl.AccessFlags, " native ") then
		return compile_native_method(climp, analysis, mimpl)
	else
		return compile_method(climp, analysis, mimpl)
	end
end

local function compile_static_method(climp, analysis, mimpl)
	if string_find(mimpl.AccessFlags, " native ") then
		return compile_native_method(climp, analysis, mimpl)
	else
		return compile_method(climp, analysis, mimpl)
	end
end

local function returnszero()
	return 0
end

local constantparser = {
	["CONSTANT_class"] = function(c, analysis, climploader)
		local classname = analysis.Utf8Constants[c.name_index]
		local climp = climploader:LoadClimp(classname)
		return Runtime.GetClassForClimp(climp)
	end,

	["CONSTANT_String"] = function(c, analysis, climploader)
		local utf8 = analysis.Utf8Constants[c.string_index]
		return Runtime.NewString(utf8)
	end,
}

return function(climploader)
	local analysis
	local instancevartype
	local instancemethodcache = {}
	local superclimp
	local constants = {}
	local staticmethods = {}

	local c
	c = {
		Init = function(self, a)
			analysis = a
			self.Analysis = a

			-- Initialise static fields.

			local s = {}
			s[#s+1] = "struct {"
			for _, f in pairs(analysis.Fields) do
				if string_find(f.AccessFlags, " static ") then
					local bi = boxinfo[f.Descriptor]
					if bi then
						s[#s+1] = bi..' '..field_name(self, f)..';'
					end
				end
			end
			s[#s+1] = "}"
			s = table_concat(s, "\n")
			self.Fields = ffi.new(s)
			self.OFields = {}

			-- Load the superclass.

			if analysis.SuperClass then
				superclimp = climploader:LoadClimp(analysis.SuperClass)
			end

			-- Remember the types of instance fields.

			s = {}
			s[#s+1] = "struct {"
			self:AddInstanceFieldsToStruct(s)
			s[#s+1] = "}"
			s = table_concat(s, "\n")
			instancevartype = ffi.typeof(s)
		end,

		AddInstanceFieldsToStruct = function(self, s)
			for _, f in pairs(analysis.Fields) do
				if not string_find(f.AccessFlags, " static ") then
					local bi = boxinfo[f.Descriptor]
					if bi then
						s[#s+1] = bi..' '..field_name(self, f)..';'
					end
				end
			end

			if superclimp then
				superclimp:AddInstanceFieldsToStruct(s)
			end
		end,

		ThisClass = function(self)
			return analysis.ThisClass
		end,

		SuperClimp = function(self)
			return superclimp
		end,

		InitInstance = function(self, o)
			o.Fields = ffi_new(instancevartype, {})
			o.OFields = {}
		end,

		ClimpLoader = function(self)
			return climploader
		end,

		FindStaticMethod = function(self, n)
			--dbg("looking up ", n, " on ", analysis.ThisClass)
			local mimpl = analysis.Methods[n]
			if not mimpl then
				return nil
			end
			return compile_static_method(self, analysis, mimpl)
		end,

		FindMethod = function(self, n)
			if not instancemethodcache[n] then
				local mimpl = analysis.Methods[n]
				if not mimpl then
					if superclimp then
						return superclimp:FindMethod(n)
					end
					return nil
				end
				instancemethodcache[n] = compile_nonstatic_method(self, analysis, mimpl)
			end
			return instancemethodcache[n]
		end,

		GetConstantValue = function(self, index)
			if not constants[index] then
				local c = analysis.Constants[index]
				if (type(c) == "table") then
					local parser = constantparser[c.tag]
					if parser then
						c = parser(c, analysis, climploader)
					else
						Utils.Throw("can't get constant index "..index.." for "..analysis.ThisClass.."; tag is "..c.tag)
					end
				end
				constants[index] = c
			end
			return constants[index]
		end,

		Methods = staticmethods,
	}

	setmetatable(staticmethods,
		{
			__index = function(self, k)
				local m = c:FindStaticMethod(k)
				rawset(staticmethods, k, m)
				return m
			end,
		}
	)

	return c
end

