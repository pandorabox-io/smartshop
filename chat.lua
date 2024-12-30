
local S = smartshop.S

smartshop.report_priv = core.settings:get("smartshop.report_priv")
if not smartshop.report_priv or smartshop.report_priv == "" then
	smartshop.report_priv = "server"
end

-- Privilege registration (if needed)
core.register_on_mods_loaded(function()
	if not core.registered_privileges[smartshop.report_priv] then
		core.register_privilege(smartshop.report_priv, {
			description = S("Allow the use of smreport command."),
			give_to_singleplayer = false
		})
	end
end)


core.register_chatcommand("smreport", {
	description = S("Write number of items being sold to report file."),
	privs = { smartshop.report_priv },
	func = function()
		return smartshop.report()
	end,
})


core.register_chatcommand("smstats", {
	description = S("Get number of items being sold."),
	params = S("<item name>"),
	func = function(_, params)
		local item_name = params:match("(%S+)")
		if not item_name then
			return false, S("Usage: /smstats <item name>")
		end

		if not smartshop.item_stats[item_name] then
		   return false, S("No stats on @1.", item_name)
		end

		local sum = smartshop.get_item_count(item_name)
		local out = S("Number of items: @1@nNumber of shops offering item: @2",
			sum, smartshop.get_shop_count(item_name))

		if sum == 0 then
		   return true, out
		end

		return true, out .. S("@nAverage price: @1", string.format("%.3f",
			smartshop.get_item_price(item_name)))
	end,
})


-- Due to some engine troubles there are sometimes stray
-- shop entities and sometimes banner nodes without entities.
-- Calling this command fixes both situations.
core.register_chatcommand("smartshop_fix_entities", {
	description = S("Recreates the smartshop-visuals in your surroundings."),
	func = function(player_name)
		local player = core.get_player_by_name(player_name)
		if not player then
			return
		end

		local t1 = core.get_us_time()

		-- Do a more thurough cleanup than smartshop.update_entities() does
		local lent
		local radius = 10
		local entity_count = 0
		local pos = player:get_pos()
		local objects = core.get_objects_inside_radius(pos, radius)
		for _, entity in ipairs(objects) do
			lent = entity:get_luaentity()
			if lent and ((lent._smartshop or lent.smartshop)
				or lent.name == "smartshop:item")
			then
				entity_count = entity_count + 1
				entity:remove()
			end
		end

		local pos1 = vector.subtract(pos, radius)
		local pos2 = vector.add(pos, radius)
		local pos_list = core.find_nodes_in_area(pos1, pos2, "smartshop:shop")

		for _, node_pos in ipairs(pos_list) do
			smartshop.update_entities(node_pos)
		end

		if smartshop.has_vizlib then
			vizlib.draw_cube(pos, radius)
		end

		local t2 = core.get_us_time()
		local diff = t2 - t1
		local millis = diff / 1000

		return true, S("Removed @1 smartshop entities and refreshed @2 shops in @3 ms.",
			entity_count, #pos_list, millis)
	end
})

