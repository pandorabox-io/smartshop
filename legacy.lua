
-- Unused code snippets

smartshop.get_offer = function(pos)
	if not pos or not core.get_node(pos) then return end

	if core.get_node(pos).name ~= "smartshop:shop" then return end

	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	local offer = {}
	for i = 1, 4, 1 do
		offer[i] = {
			give = inv:get_stack("give" .. i, 1):get_name(),
			give_count = inv:get_stack("give" .. i, 1):get_count(),
			pay = inv:get_stack("pay" .. i, 1):get_name(),
			pay_count = inv:get_stack("pay" .. i, 1):get_count(),
		 }
	end
	return offer
end


smartshop.use_offer = function(pos, player, n)
	local pressed = {}
	pressed["buy" .. n] = true
	smartshop.user[player:get_player_name()] = pos
	smartshop.receive_fields(player, pressed)
	smartshop.user[player:get_player_name()] = nil
	smartshop.update_entities(pos)
end


---- This lbm is used to add pre-update smartshops to the price database.
---- Activate with care! Warning: very slow.
--core.register_lbm({
--	name = "smartshop:update",
--	nodenames = { "smartshop:shop" },
--	action = function(pos, node)
--		smartshop.update_info(pos)
--	end,
--})

