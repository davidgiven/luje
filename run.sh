#!/bin/sh
export LUA_CPATH='/usr/lib/'$(gcc -dumpmachine)'/lua/5.1/?.so;;'
export LUA_PATH='/usr/share/lua/5.1/?.lua;;'
exec luajit "$@" vm/main.lua

