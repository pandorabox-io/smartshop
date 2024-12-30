
-- TODO: what about updating info when items are removed via injectors?

smartshop.tube = {
	input_inventory = "main",
	connect_sides = {
		left = 1, front = 1, top = 1,
		right = 1, back = 1, bottom = 1,
	},

	-- (pos, node, stack, direction)
	insert_object = function(pos, _, stack)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		local added = inv:add_item("main", stack)
		smartshop.update_info(pos)

		return added
	end,

	-- (pos, node, stack, direction)
	can_insert = function(pos, _, stack)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		local sell_name
		for i = 1, 4 do
			sell_name = inv:get_stack("give" .. i, 1):get_name()
			if sell_name == stack:get_name() then
				return inv:room_for_item("main", stack)
			end
		end

		return false
	end,
}

