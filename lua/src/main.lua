local io = require "io"
local os = require "os"
local string = require "string"
local argv = arg

--- Loads symbols from a module, skipping errors
-- 
-- If file wasn't found or some other os error occured
-- first value will be nil (error message is in second value).
-- If first value is not nil, file was loaded partially and error
-- message will be in second value
-- 
-- @param filename to load
-- @return table containing loaded symbols, or nil if file not found
-- @return error message 
function load_symbols(filename)
	local file_f, err = loadfile(filename)

	if not file_f then
		return nil, err
	end

	local func_env = {}
	setmetatable(func_env, { __index = _G })
	if setfenv then
		setfenv(file_f, func_env)
	end
	
	local _,err = pcall(file_f)
	return func_env, err
end

function inject_symbols(filename)
	func_env, syms_or_err = load_symbols(filename)
	if type(syms_or_err) == "table" then
		for k,v in pairs(syms_or_err) do
			_G[k] = v
		end
	end
	return func_env, syms_or_err
end

-- dirty & dirtier harry --
if not inject_symbols("lua-ini-parser.lua") then
	inject_symbols("src/lua-ini-parser.lua")
end


-- Random "tests"
--[[
print("\nRandom tests:\n")
do
	local ini = INI.new()

	print("Ini items: "..tostring(ini:count()))
	ini:set("second", "john", "wick")
	print(" Added [second] -> \"john\": \"wick\"")
	ini:set("second", "janko", "jankic")
	print(" Added [second] -> \"janko\": \"jankic\"")
	ini:set("third", "janez", "jansa")
	print(" Added [third] -> \"janez\": \"jansa\"")
	print()
	print("Sections in INI struct: "..tostring(ini:count()))
	
	print()
	ini:print()
	print()

	print("get_section( )")
	print(ini:get_section("second"))
	print(ini:get_section("third"))

	print("Reading  [second] \"janko\" : " ..(ini:get("second", "janko") or "NIL") )
	print("Reading nonexistent value  [second] \"nekamacka\" : "..(ini:get("second", "nekamacka") or "NIL"))
	print("Reading nonexistent section  [fourth] : "..(ini:get("fourth", "nepostojecamacka") or "NIL"))

	ini:remove("second", "janko")
	ini:remove("second", "john")
	ini:remove("third", "janez")
	ini:remove_section("second")
	ini:remove_section("third")
	ini:remove_section("fourth")

	ini:set("lalalala", "kekeke", "lelelele")

	print()
	ini:print()
	print()
	ini:clear()
	print()
end
--]]


--- Prints usage string.
function print_usage()
	print("usage: "..argv[0].." <ini_file>")
end

if not argv[1] then
	print_usage()
	os.exit(1)
end

local fp, err = io.open(argv[1])
if not fp then
	print("File opening error: " .. err)
	os.exit(2)
end

print()
local parsed = INI.parse(fp)
parsed:print()
print("\nDone.")