--- Simple INI parser in Lua
-- @file lua-ini-parser

--local io = require "io"
--local os = require "os"
--local string = require "string"

--local argv = arg
local COMMENT_CHARS = ";%#"

----- Prints usage string.
--function print_usage()
--	print("usage: "..argv[0].." <ini_file>")
--end

--[[
====================================
	SECTION HOLDING MANY KEYVALS
====================================
--]]
local Section = {}

--- Constructs a new section object.
-- 
-- @param name Section title
-- @return New Section object
function Section.new(name)
	local sect = { name = name, props = {} }
	setmetatable(sect, { __index = Section })
	return sect
end

--- Returns value of a key in section.
-- 
-- @param key Key
-- @return Value of the key, or nil
function Section:get(key)
	if not key then return nil end -- throw error ?
	for k,v in pairs(self.props) do
		if k == key then return v end
	end
	return nil
end

--- Sets value of a key in section.
-- 
-- @param key Key
-- @param val Value
-- @return Given value or nil
function Section:set(key, val)
	if not key then return nil end
	self.props[key] = val
	return self.props[key]
end

--- Removes a key from section.
-- 
-- @param key Key
function Section:remove(key)
	self:set(key, nil)
end

--- Counts key-value pairs in section.
-- 
-- @return Number of elements
function Section:count()
	--[[ Cannot use #-notation or table.getn unfortunately (works only on numeric keys) ]]
	local cnt = 0
	for k,v in pairs(self.props) do
		cnt = cnt + 1
	end
	return cnt
end

--- Displays section contents in a structured graphical format.
function Section:print()
	print("Section \""..self.name.."\":")
	local empty = true
	for k,v in pairs(self.props) do
		empty = false
		print("  - "..k..": "..v)
	end
	if empty then print("  - <empty>") end
end

--[[
===========================
	MAIN .INI STRUCTURE
===========================
--]]
local INI = {}

--- Constructs a new INI structure.
-- 
-- @return New INI object
function INI.new()
	local ini = { sections = {} } -- "sections" is a table of (key,val) = (name, Section)
	setmetatable(ini, { __index = INI })
	return ini
end

--- Returns value of a key in section.
-- 
-- @param sect Section name
-- @param key Key
-- @return Key value
function INI:get(sect, key)
	if not sect then return nil end
	return self:get_section(sect):get(key)
end

--- Sets value of a key in a section.
-- 
-- @param sect Section name
-- @param key Key
-- @param val New value
function INI:set(sect, key, val)
	if not sect then return nil end -- throw error ?
	self:get_section(sect):set(key, val)
	return val
end

--- Return a section reference (table).
-- 
-- A blank section is created if it doesn't exist.
-- 
-- @param sect Section name
-- @return Section
function INI:get_section(sect)
	if not sect then return nil end -- throw error ?
	local s = self.sections[sect]
	if not s then
		s = Section.new(sect)
		self.sections[sect] = s
	end
	return s
end

--- Removes key from a section.
-- 
-- @param sect Section name
-- @param key Key
function INI:remove(sect, key)
	self:set(sect, key, nil)
end

--- Removes a whole section from INI.
-- 
-- @param sect Section name
function INI:remove_section(sect)
	self.sections[sect] = nil
end

--- Removes all sections from INI
function INI:clear()
	for _,s in pairs(self.sections) do
		self:remove_section(s.name)
	end
end

--- Counts sections in INI.
-- 
-- @return Number of sections
function INI:count()
	--[[ Cannot use #-notation or table.getn unfortunately (works only on numeric keys) ]]
	local cnt = 0
	for k,v in pairs(self.sections) do
		cnt = cnt + 1
	end
	return cnt
end

--- Parses the given file stream into .INI structure 
-- 
-- @param fp File stream
-- @return Parsed INI() structure
function INI.parse(fp)
	local parsed = INI.new()
	local curr_sect = nil

	for line in fp:lines() do
		if #line < 1 then
			-- continue if empty
		elseif string.match(line, "^%s*["..COMMENT_CHARS.."].*") then
			-- This is a comment line
		else
			local sect = string.match(line, "^%s*%[%s*([^%]]+%s*)%]")
			if sect then
				-- Encountered new section
				parsed:get_section(sect) -- will generate new empty section
				curr_sect = sect
			else
				-- Encountered an attribute assignment
				local k, v = string.match(line, "%s*([^=]+)=%s?(.*)")
				if not k then k = "" end
				if not v then v = "" end
				if k then
					-- Trim one whitespace before "=" if it exists
					if k:sub(-1) == " " then k = k:sub(1, #k - 1) end

					-- Keyvals must be inside some section
					local cnt = parsed:count()
					if k == "" then
					elseif cnt == 0 then print(">   Keyval ("..k.."="..v..") encountered outside any section; skipping...")
					else
						parsed:set(curr_sect, k, v)
					end
				end
			end
		end
	end
	return parsed
end

--- Displays INI contents in a hierarchical graphical format.
function INI:print()
	print("<.INI structure>")
	if self:count() == 0 then print("  +-> <empty>")
	else
		for sect_name,sect in pairs(self.sections) do
			print("  |")
			print("  +-> [SECTION] \""..sect_name.."\"")
			if sect:count() == 0 then print("  |     +-> <EMPTY>")
			else
				for k,v in pairs(sect.props) do
					print("  |     |")
					print("  |     +-> [PROP] \""..k.."\": \""..tostring(v).."\"")
				end
			end
		end
		print("  V")
	end
end


-- Exports --
return {
	INI = INI,
	Section = Section,
	COMMENT_CHARS = COMMENT_CHARS
}
