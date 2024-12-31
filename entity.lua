
-- Offset matrix for shop entities.
-- Adjustments depending on heading (param2 of 0 to 3).
local dir_delta = {
	{ x = 0, y = 0, z = -1 }, { x = -1, y = 0, z = 0 },
	{ x = 0, y = 0, z = 1 }, { x = 1, y = 0, z = 0 },
}
-- Slot 1 -> upper left; Slot 2 -> upper right
-- Slot 3 -> lower left; Slot 4 -> lower right
local slot_delta = {
	{
		{ x = -0.2, y = 0.2, z = 0 }, { x = 0.2, y = 0.2, z = 0 },
		{ x = -0.2, y = -0.2, z = 0 }, { x = 0.2, y = -0.2, z = 0 },
	}, {
		{ x = 0, y = 0.2, z = 0.2 }, { x = 0, y = 0.2, z = -0.2 },
		{ x = 0, y = -0.2, z = 0.2 }, { x = 0, y = -0.2, z = -0.2 },
	}, {
		{ x = 0.2, y = 0.2, z = 0 }, { x = -0.2, y = 0.2, z = 0 },
		{ x = 0.2, y = -0.2, z = 0 }, { x = -0.2, y = -0.2, z = 0 },
	}, {
		{ x = 0, y = 0.2, z = -0.2 }, { x = 0, y = 0.2, z = 0.2 },
		{ x = 0, y = -0.2, z = -0.2 }, { x = 0, y = -0.2, z = 0.2 },
	}
}

-- Constants to calculate entity yaw
local double_pi = 2 * math.pi
local half_pi = .5 * math.pi


function smartshop.update_entities(pos, command)
	-- Clear
	local lent
	-- In future versions we'll be able to use the safer core.objects_inside_radius
	local objects = core.get_objects_inside_radius(pos, .5)
	for _, entity in ipairs(objects) do
		lent = entity and entity:get_luaentity()
		if lent and (lent._smartshop or lent.smartshop) then
			entity:remove()
		end
	end
	if command == "clear" then
		return
	end

	-- Update / re-create
	local param2 = core.get_node(pos).param2
	local dp = dir_delta[param2 + 1]
	if not dp then
		-- Refuse to add entities for nodes rotated up/down
		return
	end

	local pos1 = vector.copy(pos)
	pos1.x = pos1.x + dp.x * 0.01
	pos1.y = pos1.y + dp.y * 6.5 / 16
	pos1.z = pos1.z + dp.z * 0.01
	local entity, item_name, pos2
	local inv = core.get_meta(pos):get_inventory()
	for i = 1, 4, 1 do
		item_name = inv:get_stack("give" .. i, 1):get_name()
		if item_name ~= "" then
			pos2 = vector.add(pos1, slot_delta[param2 + 1][i])
			entity = core.add_entity(pos2, "smartshop:item", item_name)
			entity:set_yaw(double_pi - param2 * half_pi)
		end
	end
end

-- Backward compat, depricated, will be removed at some point
local have_warned = false
function smartshop.update(...)
	if not have_warned then
		have_warned = true
		core.log("warning", "[smartshop] Depricated use of smartshop.update(). "
			.. "Use smartshop.update_entities() instead\n"
			.. debug.traceback())
	end
	return smartshop.update_entities(...)
end


core.register_entity("smartshop:item", {
	initial_properties = {
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		hp_max = 1,
		physical = false,
		textures = { "air" },
		type = "",
		visual = "wielditem",
		visual_size = { x = .20, y = .20 },
	},
	_smartshop = true,
	on_activate = function(self, staticdata)
		if staticdata and staticdata ~= "" then
			-- Deal with old entities that also kept pos saved
			local data = staticdata:split(';')
			self.item = data and data[1]
		end
		if self.item then
			self.object:set_properties({ textures = { self.item } })
		else
			self.object:remove()
		end
	end,
	get_staticdata = function(self)
		return self.item or ""
	end,
})

