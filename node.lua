
local S = smartshop.S
local floor = math.floor

-- Helper function to structure infotext.
local function tabled_infotext(owner, stuff)
	return
		S("(Smartshop of @1) Purchases left:", owner) .. "\n"
		.. "(" .. stuff.give1 .. ") " .. stuff.name1 .. "\n"
		.. "(" .. stuff.give2 .. ") " .. stuff.name2 .. "\n"
		.. "(" .. stuff.give3 .. ") " .. stuff.name3 .. "\n"
		.. "(" .. stuff.give4 .. ") " .. stuff.name4
end


-- Helper to update infotext without statistics.
-- It does introduce code duplication, so maybe we'll remove it in future.
local function fast_info(inv)
	local stuff = {}
	local item_name, available_sets
	local give_stack
	local give_count, stock_count
	local main_list = inv:get_list("main")
	local give_key, name_key
	local stock_counts = {}
	for i = 1, 4, 1 do
		give_key = "give" .. i
		name_key = "name" .. i
		give_stack = inv:get_stack(give_key, 1)
		give_count = give_stack:get_count()
		item_name = give_stack:get_name()
		available_sets = 0
		stock_count = stock_counts[item_name]
		if not stock_count then
			stock_count = 0
			for _, main_stack in ipairs(main_list) do
				if item_name == main_stack:get_name() then
					stock_count = stock_count + main_stack:get_count()
				end
			end
			stock_counts[item_name] = stock_count
		end
		if give_count > 0 then
			available_sets = floor(stock_count / give_count)
		end
		if item_name == "" then
			stuff[give_key] = ""
			stuff[name_key] = ""
		else
			stuff[give_key] = available_sets
			stuff[name_key] = smartshop.get_human_name(item_name)
		end
	end -- loop
	return stuff
end


-- Update infotext and statistics.
function smartshop.update_info(pos)
	if not pos then
		return nil
	end

	local meta = core.get_meta(pos)
	local owner = meta:get_string("owner")
	if meta:get_int("type") == 0 then
		meta:set_string("infotext", S("(Smartshop of @1) Stock is unlimited.", owner))
		return false
	end

	local inv = meta:get_inventory()
	if smartshop.disable_statistics then
		meta:set_string("infotext", tabled_infotext(owner, fast_info(inv)))
		return true
	end

	local spos = core.pos_to_string(pos)
	local stuff = {}
	local item_name, mg_price, available_sets
	local give_stack, pay_stack
	local give_count, pay_count, stock_count
	local main_list = inv:get_list("main")
	local give_key, name_key, pos_key
	local stock_counts = {}
	for i = 1, 4, 1 do
		give_key = "give" .. i
		name_key = "name" .. i
		pos_key = spos .. i
		give_stack = inv:get_stack(give_key, 1)
		give_count = give_stack:get_count()
		item_name = give_stack:get_name()
		pay_stack = inv:get_stack("pay" .. i, 1)
		pay_count = nil
		mg_price = smartshop.minegeld_to_number(pay_stack)
		if mg_price ~= nil and give_count > 0 then
			pay_count = mg_price / give_count
		end
		available_sets = 0
		stock_count = stock_counts[item_name]
		if not stock_count then
			stock_count = 0
			for _, main_stack in ipairs(main_list) do
				if item_name == main_stack:get_name() then
					stock_count = stock_count + main_stack:get_count()
				end
			end
			stock_counts[item_name] = stock_count
		end
		if give_count > 0 then
			available_sets = floor(stock_count / give_count)
		end
		if item_name == "" then
			stuff[give_key] = ""
			stuff[name_key] = ""
			smartshop.remove_pos(pos_key)
		else
			stuff[give_key] = available_sets
			stuff[name_key] = smartshop.get_human_name(item_name)
			if not pay_count and smartshop.include_mg_only then
				smartshop.remove_pos(pos_key)
			else
				smartshop.set_count_pos(pos_key, item_name,
					available_sets * give_count)
				smartshop.set_price_pos(pos_key, item_name, pay_count)
			end
		end
	end -- loop
	meta:set_string("infotext", tabled_infotext(owner, stuff))

	return true
end


core.register_node("smartshop:shop", {
	description = "Smartshop",
	tiles = { "default_chest_top.png^[colorize:#ffffff77^default_obsidian_glass.png" },
	groups = {
		choppy = 2,
		oddly_breakable_by_hand = 1,
		tubedevice = 1, tubedevice_receiver = 1,
	},
	is_ground_content = false,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.5, -0.5, -0.0, 0.5, 0.5, 0.5 }
	},
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 10,
	tube = smartshop.tube,

	on_rightclick = function(pos, _, player)
		smartshop.showform(pos, player)
	end,

	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_int("type", 1) -- 1 == limited resources; 0 == unlimited
		meta:set_int("ghost", 1) -- version indicator
		meta:get_inventory():set_size("main", 32)
		meta:get_inventory():set_size("give1", 1)
		meta:get_inventory():set_size("give2", 1)
		meta:get_inventory():set_size("give3", 1)
		meta:get_inventory():set_size("give4", 1)
		meta:get_inventory():set_size("pay1", 1)
		meta:get_inventory():set_size("pay2", 1)
		meta:get_inventory():set_size("pay3", 1)
		meta:get_inventory():set_size("pay4", 1)
	end,

	after_place_node = function(pos, placer)
		local meta = core.get_meta(pos)
		local player_name = placer and placer:is_player()
			and placer:get_player_name() or ""
		meta:set_string("owner", player_name)
		meta:set_string("infotext", S("Shop of @1", player_name))
		if not placer or not placer:is_player() then
			return
		end

		if core.check_player_privs(placer, { creative = true })
			or core.check_player_privs(placer, { give = true })
		then
			meta:set_int("creative", 1)
			meta:set_int("type", 0)
		end
	end,

	can_dig = function(pos, player)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		if not inv:is_empty("main") then
			return false
		end

		if meta:get_string("owner") == ""
			or meta:get_string("owner") == player:get_player_name()
			or core.check_player_privs(player, { protection_bypass = true })
		then
			return true
		end

-- TODO: check what happens with old non-ghost vendors that haven't been upgraded
		return false
	end,

	on_destruct = function(pos)
		smartshop.update_entities(pos, "clear")
		smartshop.remove_pos(core.pos_to_string(pos))
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local player_name = player:get_player_name()
		local is_manager = smartshop.is_manager(pos, player_name)
		if is_manager and smartshop.treat_as_customer[player_name] then
			is_manager = false
		end
		-- If player isn't a manager, nothing to do.
		if not is_manager then
			return 0
		end

		local meta = core.get_meta(pos)
		-- Main inventory or old shop: everything goes
		if listname == "main" or meta:get_int("ghost") == 0 then
			return stack:get_count()
		end

		-- Give or pay list
		local inv = meta:get_inventory()
		if inv:get_stack(listname, index):get_name() == stack:get_name() then
			inv:add_item(listname, stack)
		else
			inv:set_stack(listname, index, stack)
		end
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local player_name = player:get_player_name()
		local is_manager = smartshop.is_manager(pos, player_name)
		if is_manager and smartshop.treat_as_customer[player_name] then
			is_manager = false
		end
		-- If player isn't a manager, nothing to do.
		if not is_manager then
			return 0
		end

		local meta = core.get_meta(pos)
		-- Main inventory or old shop: everything goes
		if listname == "main" or meta:get_int("ghost") == 0 then
			return stack:get_count()
		end

		-- Give or pay list
		local inv = meta:get_inventory()
		inv:set_stack(listname, index, ItemStack())
		return 0
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index,
											to_list, to_index, count, player)
print('allow_metadata_inventory_move')
		local player_name = player:get_player_name()
		local is_manager = smartshop.is_manager(pos, player_name)
		if is_manager and smartshop.treat_as_customer[player_name] then
			is_manager = false
		end
		-- If player isn't a manager, nothing to do.
		if not is_manager then
			return 0
		end

		local meta = core.get_meta(pos)
		-- Old shops: everything goes
		if meta:get_int("ghost") == 0 then
			return count
		end

		if from_list == "main" and to_list == "main" then
			return count
		end

		local inv = meta:get_inventory()
		if to_list == "main" then
			inv:set_stack(from_list, from_index, ItemStack())
			return 0
		end

		local to_stack = inv:get_stack(to_list, to_index)
		local from_stack = inv:get_stack(from_list, from_index)
		from_stack:set_count(count)
		if from_list == "main" then
			if to_stack:get_name() == from_stack:get_name()
			then
				inv:add_item(to_list, from_stack)
			else
				inv:set_stack(to_list, to_index, from_stack)
			end
			return 0
		end

		-- Movements between pay and give inventories
		return count
	end,

	-- Make blast resistant.
	on_blast = function() end,

	-- [jumpdrive] compat
	on_movenode = function(from_pos, to_pos)
		smartshop.update_entities(from_pos, "clear")
		smartshop.remove_pos(core.pos_to_string(from_pos))
		smartshop.update_entities(to_pos, "update")
		smartshop.update_info(to_pos)
	end,
})


if core.get_modpath("mesecons_mvps") then
	mesecon.register_mvps_stopper("smartshop:shop")
end

