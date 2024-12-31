
local S, FS = smartshop.S, smartshop.FS

-- Cache for managers viewing as customer.
-- Used by node's inventory movement checks and showform().
-- { [<user_name>] = true }
smartshop.treat_as_customer = {}

-- Cache of shop position by user
-- { [<user_name>] = <pos> }
local user = {}

smartshop.showform = function(pos, player)
	local player_name = player:get_player_name()
	user[player_name] = pos
	local meta = core.get_meta(pos)
	local creative = meta:get_int("creative")
	local inv = meta:get_inventory()
	local inv_pos = string.format("list[nodemeta:%d,%d,%d;", pos.x, pos.y, pos.z)
	local is_manager = smartshop.is_manager(pos, player_name)
	if smartshop.treat_as_customer[player_name] then
		is_manager = false
	end
	local gui, stack
	if is_manager then
		-- Manager has been here to refill
		meta:set_int("alerted", 0)
		if creative == 1 then
			gui = "size[8,10.75]label[0.5,10.25;"
			if meta:get_int("type") == 1 then
				gui = gui .. FS("Your stock is limited.")
			else
				gui = gui .. FS("Your stock is unlimited.@nPaid items are trashed.")
			end
			gui = gui
				.. "]button[6,1;2.2,1;togglelimit;" .. FS("Toggle limit") .. "]"
				.. "tooltip[togglelimit;" .. FS("Toggle limit of stock.") .. "]"
		else
			gui = "size[8,10]"
		end
		gui = gui
			.. "button_exit[6,0;1.5,1;customer;" .. FS("Customer") .. "]"
			.. "tooltip[customer;" .. FS("View as customer.") .. "]"
			.. "label[0,0.2;" .. FS("Item:") .. "]"
			.. "label[0,1.2;" .. FS("Price:") .. "]"
			.. inv_pos .. "give1;2,0;1,1;]"
			.. inv_pos .. "pay1;2,1;1,1;]"
			.. inv_pos .. "give2;3,0;1,1;]"
			.. inv_pos .. "pay2;3,1;1,1;]"
			.. inv_pos .. "give3;4,0;1,1;]"
			.. inv_pos .. "pay3;4,1;1,1;]"
			.. inv_pos .. "give4;5,0;1,1;]"
			.. inv_pos .. "pay4;5,1;1,1;]"
		gui = gui
			.. inv_pos .. "main;0,2;8,4;]"
			.. "list[current_player;main;0,6.2;8,4;]"
			.. string.format(
				"listring[nodemeta:%d,%d,%d;main]", pos.x, pos.y, pos.z)
			.. "listring[current_player;main]"
	else
		-- Customer view
		gui = ""
			.. "size[8,6]"
			.. "list[current_player;main;0,2.2;8,4;]"
			.. "label[0,0.2;" .. FS("Item:") .. "]"
			.. "label[0,1.2;" .. FS("Price:") .. "]"
			.. inv_pos .. "give1;2,0;1,1;]"
		stack = inv:get_stack("pay1", 1)
		gui = gui
			.. "item_image_button[2,1;1,1;" .. stack:get_name()
			.. ";buy1;\n\n\b\b\b\b\b" .. stack:get_count() .. "]"
			.. inv_pos .. "give2;3,0;1,1;]"
		stack = inv:get_stack("pay2", 1)
		gui = gui
			.. "item_image_button[3,1;1,1;" .. stack:get_name()
			.. ";buy2;\n\n\b\b\b\b\b" .. stack:get_count() .. "]"
			.. inv_pos .. "give3;4,0;1,1;]"
		stack = inv:get_stack("pay3", 1)
		gui = gui
			.. "item_image_button[4,1;1,1;" .. stack:get_name()
			.. ";buy3;\n\n\b\b\b\b\b" .. stack:get_count() .. "]"
			.. inv_pos .. "give4;5,0;1,1;]"
		stack = inv:get_stack("pay4", 1)
		gui = gui
			.. "item_image_button[5,1;1,1;" .. stack:get_name()
			.. ";buy4;\n\n\b\b\b\b\b" .. stack:get_count() .. "]"
	end
	core.after(0.1, core.show_formspec, player_name, "smartshop.showform", gui)
end


smartshop.receive_fields = function(player, fields)
	local player_name = player:get_player_name()
	local pos = user[player_name]
	if not pos then
		return
	end

	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	local give_stack, pay_stack
	-- Transition shops to ghost inventory.
	if meta:get_int("ghost") ~= 1 then
		meta:set_int("ghost", 1)
		for i = 1, 4 do
			pay_stack = inv:get_stack("pay" .. i, 1)
			if inv:room_for_item("main", pay_stack) then
				pay_stack = inv:add_item("main", pay_stack)
			end
			if not pay_stack:is_empty() then
				core.add_item(pos, pay_stack)
			end
			give_stack = inv:get_stack("give" .. i, 1)
			if inv:room_for_item("main", give_stack) then
				give_stack = inv:add_item("main", give_stack)
			end
			if not give_stack:is_empty() then
				core.add_item(pos, give_stack)
			end
		end
	end

	if fields.customer then
		smartshop.treat_as_customer[player_name] = true
		smartshop.showform(pos, player)
		return
	end

	local owner = meta:get_string("owner")
	if fields.togglelimit then
		if meta:get_int("type") == 0 then
			-- Set to limited stock
			meta:set_int("type", 1)
		else
			-- Set to unlimited stock
			meta:set_int("type", 0)
		end
		smartshop.showform(pos, player)
		return

	elseif fields.quit then
print("got quit field")
		smartshop.update_info(pos)
		if owner == player_name
			or core.check_player_privs(player, { protection_bypass = true })
		then
			smartshop.update_entities(pos, "update")
		end
		user[player_name] = nil
		smartshop.treat_as_customer[player_name] = nil
		return
	end

	local n = 1
	-- Check up to 5 so it's easier to detect that no buy fields were clicked
	for i = 1, 5, 1 do
		n = i
		if fields["buy" .. i] then break end
	end
	if not fields["buy" .. n] then
print('escape pressed??')
		return
	end

	-- Get a copy of stack in give-inventory
	give_stack = inv:get_stack("give" .. n, 1)
	if give_stack:is_empty() then
		return
	end

	pay_stack = inv:get_stack("pay" .. n, 1)
	local limited_stock = meta:get_int("type") == 1
	if limited_stock and not inv:room_for_item("main", pay_stack) then
		core.chat_send_player(player_name,
			S("Error: The owner's stock is full, can't receive, "
			.. "exchange aborted."))
		return
	end

	local item_name = give_stack:get_name()
	if limited_stock and not inv:contains_item("main", give_stack) then
		core.chat_send_player(player_name,
			S("Error: @1 is sold out.", smartshop.get_human_name(item_name)))
		-- Do not alert twice
		if meta:get_int("alerted") == 0 then
			meta:set_int("alerted", 1)
			smartshop.send_mail(owner, pos, item_name)
		end
		return
	end

	local player_inv = player:get_inventory()
	if not player_inv:contains_item("main", pay_stack) then
		core.chat_send_player(player_name,
			S("Error: You don't have enough in your inventory to buy this, "
			.. "exchange aborted."))
		return
	end

	if not player_inv:room_for_item("main", give_stack) then
		core.chat_send_player(player_name,
			S("Error: Your inventory is full, exchange aborted."))
		return
	end

	-- Execute the actual transaction
	player_inv:remove_item("main", pay_stack)
	player_inv:add_item("main", give_stack)
	if limited_stock then
		inv:remove_item("main", give_stack)
		inv:add_item("main", pay_stack)
		if not inv:contains_item("main", give_stack) then
			-- Do not alert twice
			if meta:get_int("alerted") == 0 then
				meta:set_int("alerted", 1)
				smartshop.send_mail(owner, pos, item_name)
			end
		end
	end
end


core.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "smartshop.showform" then
		return false
	end

	smartshop.receive_fields(player, fields)
	return true
end)

