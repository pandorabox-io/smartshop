
local S = smartshop.S

-- A wrapper to escape translations for formspec
function smartshop.FS(...)
	return core.formspec_escape(S(...))
end


-- A wrapper to non-pattern matching string.find()
function smartshop.string_contains_string(haystack, needle)
	return nil ~= string.find(haystack, needle, 1, true)
end


-- Fetches a human readable name of item_name.
function smartshop.get_human_name(item_name)
	if core.registered_items[item_name] then
		local item = ItemStack(item_name)
		return item:get_short_description() or item:get_description()
	else
		return S("Unknown Item")
	end
end


-- Check privs and ownership
function smartshop.is_manager(pos, player_name)
	return core.get_meta(pos):get_string("owner") == player_name
		or core.check_player_privs(player_name, { protection_bypass = true })
end


-- Return amount of minegeld in stack, returns nil if
-- stack is not composed of minegeld.
function smartshop.minegeld_to_number(stack)
	local count = stack:get_count()
	local stack_name = stack:get_name()
	if stack_name == "currency:minegeld_cent_5" then
		return count * .05
	elseif stack_name == "currency:minegeld_cent_10" then
		return count * .1
	elseif stack_name == "currency:minegeld_cent_25" then
		return count * .25
	elseif stack_name == "currency:minegeld" then
		return count
	elseif stack_name == "currency:minegeld_5" then
		return count * 5
	elseif stack_name == "currency:minegeld_10" then
		return count * 10
	elseif stack_name == "currency:minegeld_50" then
		return count * 50
	elseif stack_name == "currency:minegeld_100" then
		return count * 100
	else
		return nil
	end
end


-- Returns a slightly more human readable version of
-- core.pos_to_string()
function smartshop.pos_to_string(pos)
	return string.format("(%d, %d, %d)", pos.x, pos.y, pos.z)
end

