
-- NOTE: Removing for sale items using a filter injector will not
--       update infotext and statistcs. Since there is no way to
--       reliably detect if a player is removing items or a
--       filter injector and updating info on every inventory take
--       action seems overkill. At least when statistics are activated.

-- (pos, node, stack, direction)
local function can_insert(pos, _, stack)
	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	local stack_name = stack:get_name()
	local give_name
	for i = 1, 4 do
		give_name = inv:get_stack("give" .. i, 1):get_name()
		if give_name == stack_name then
			return inv:room_for_item("main", stack)
		end
	end

	return false
end


-- (pos, node, stack, direction)
local function insert_object(pos, _, stack)
	if not can_insert(pos, nil, stack) then
		return stack
	end

	local inv = core.get_meta(pos):get_inventory()
	local leftover = inv:add_item("main", stack)
	smartshop.update_info(pos)

	return leftover
end


smartshop.tube = {
	input_inventory = "main",
	connect_sides = {
		left = 1, front = 1, top = 1,
		right = 1, back = 1, bottom = 1,
	},
	-- Only tubes call this. Filter injectors call insert_object directly.
	can_insert = can_insert,
	insert_object = insert_object,
}

