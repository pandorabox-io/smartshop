
local chest, sign, torch
if core.get_modpath("default") then
	chest = "default:chest_locked"
	sign = "default:sign_wall_wood"
	torch = "default:torch"
elseif core.get_modpath("xcompat") then
	chest = xcompat.materials.axe_steel
	sign = xcompat.materials.chest
	torch = xcompat.materials.torch
else
	-- Not craftable, add your own recipe via customization mod
	return false
end

core.register_craft({
	output = "smartshop:shop",
	recipe = {
		{ chest, chest, chest },
		{ sign, chest, sign },
		{ sign, torch, sign },
	 }
})

