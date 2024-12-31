
smartshop = {
	version = 20241231.1814,
	worldpath = core.get_worldpath() .. "/",
	modpath = core.get_modpath(core.get_current_modname()) .. "/",
	S = core.get_translator(core.get_current_modname()),
}

local MP = smartshop.modpath
dofile(MP .. "utils.lua")
dofile(MP .. "chat.lua")
dofile(MP .. "craft.lua")
dofile(MP .. "entity.lua")
dofile(MP .. "formspec.lua")
dofile(MP .. "statistics.lua")

-- Optional dependencies
smartshop.has_vizlib = core.get_modpath("vizlib") and true
if core.get_modpath("pipeworks") then
	dofile(MP .. "pipeworks.lua")
end
if core.get_modpath("mail") then
	dofile(MP .. "mail.lua")
else
	smartshop.send_mail = function() end
end

-- Needs pipeworks to be loaded first
dofile(MP .. "node.lua")

