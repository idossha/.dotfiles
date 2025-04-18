-- Add LuaRocks paths
package.path = package.path .. ';' .. vim.fn.expand('$HOME') .. '/.luarocks/share/lua/5.1/?.lua;' .. vim.fn.expand('$HOME') .. '/.luarocks/share/lua/5.1/?/init.lua'
package.cpath = package.cpath .. ';' .. vim.fn.expand('$HOME') .. '/.luarocks/lib/lua/5.1/?.so'

-- to source this file after changes run :luafile %
-- % represent the current file.
-- 
-- if you have another user or wish to develop, change what you require below.

-- Example 'develop' subir:
-- require("develop.core")
-- require("develop.lazy")

require("idossha.core")
require("idossha.lazy")
