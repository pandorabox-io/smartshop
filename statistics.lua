-- Rudementary statistics of available items and prices.
-- Keeps track of item counts but prices are only kept track
-- of if the requested payment is in minegeld.
-- Databases from older versions may have stray entries of shops
-- that have been removed or moved. There are probably still ways
-- to make the database dirty depending on what mods are installed.

local S = smartshop.S

-- Interval for globalstep to write report file.
smartshop.report_interval = tonumber(core.settings:get(
	"smartshop.report_interval")) or 0

-- Should offers without minegeld as payment be ignored in statistics.
smartshop.include_mg_only = core.settings:get(
	"smartshop.include_mg_only") or "true"
smartshop.include_mg_only = smartshop.include_mg_only == "true"

-- Entirely ignore statistics.
smartshop.disable_statistics = core.settings:get("smartshop.disable_statistics") or "false"
smartshop.disable_statistics = smartshop.disable_statistics == "true"

-- Table by 'item_name' of number of items being offered at 'pos'
-- { <item_name> = { <pos string> = <count> }}
smartshop.item_stats = {}

-- Table by 'item_name' of price offered at position 'pos'
-- { <item_name> = { <pos string> = <price> } }
smartshop.item_prices = {}

local worldpath = smartshop.worldpath

-- Load item stats
do
	if smartshop.disable_statistics then
		return
	end

	local data
	local file = io.open(worldpath .. "smartshop_itemcounts.txt", "r")
	if file then
		data = core.deserialize(file:read("*all"))
		if type(data) == "table" then
			smartshop.item_stats = data
		end
		file:close()
	end

	file = io.open(worldpath .. "smartshop_itemprices.txt", "r")
	if file then
		data = core.deserialize(file:read("*all"))
		if type(data) == "table" then
			smartshop.item_prices = data
		end
		file:close()
	end
end

-- Sum up all available item_name at every pos
function smartshop.get_item_count(item_name)
	if smartshop.disable_statistics then
		return 0
	end

	if not smartshop.item_stats[item_name] then
		return 0
	end

	local sum = 0
	for _, count in pairs(smartshop.item_stats[item_name]) do
		sum = sum + count
	end
	return sum
end


-- Calculate an average price for item_name
function smartshop.get_item_price(item_name)
	if smartshop.disable_statistics then
		return 0
	end

	if not smartshop.item_prices[item_name] then
		return 0
	end

	local count = smartshop.get_item_count(item_name)
	if count == 0 then
		return 0
	end

	local sum = 0
	for spos, price in pairs(smartshop.item_prices[item_name]) do
		sum = sum + price * smartshop.item_stats[item_name][spos]
	end
	return sum / count
end


-- Count how many shops offer item_name (regardless of inventory)
function smartshop.get_shop_count(item_name)
	if smartshop.disable_statistics then
		return 0
	end

	if not smartshop.item_stats[item_name] then
		return 0
	end

	local sum = 0
	for _ in pairs(smartshop.item_stats[item_name]) do
		sum = sum + 1
	end
	return sum
end


-- Remove all references to 'spos'
-- If 'spos' is '(<x>,<y>,<z>)<i>' then only that exact 'spos'
-- is removed. However if 'spos' is '(<x>,<y>,<z>)' then
-- also '(<x>,<y>,<z>)1', '(<x>,<y>,<z>)2', '(<x>,<y>,<z>)3', '(<x>,<y>,<z>)4'
-- are removed too. Those are the newer position strings that also indicate
-- the slot of the shop at the given position. This syntax helps that 'remove_pos'
-- does not need to be called four times whenever a shop is dug up or moved.
function smartshop.remove_pos(spos)
	if smartshop.disable_statistics then
		return
	end

	local purge_positions = { spos }
	local do_five = ")" == spos:sub(-1)
print(dump(do_five))
	if do_five then
		for i = 1, 4 do
			table.insert(purge_positions, spos .. i)
		end
	end
	local new_stats = {}
	-- Gather affected item names while looping counts
	-- to speed up the loop through prices
	local affected_items = {}
	local preserved_positions, has_preserved, delete_position
	for item_name, dict in pairs(smartshop.item_stats) do
		preserved_positions = {}
		has_preserved = false
		for apos, count in pairs(dict) do
			delete_position = false
			for _, purge_pos in ipairs(purge_positions) do
				if apos == purge_pos then
					delete_position = true
					if not affected_items[item_name] then
						affected_items[item_name] = true
					end
				end
			end
			if not delete_position then
				-- Preserve
				has_preserved = true
				preserved_positions[apos] = count
			end
		end
		if has_preserved then
			new_stats[item_name] = preserved_positions
		end
	end

	-- Prices
	local new_prices = {}
	for item_name in pairs(affected_items) do
		preserved_positions = {}
		has_preserved = false
		for apos, price in pairs(smartshop.item_prices[item_name]) do
			delete_position = false
			for _, purge_pos in ipairs(purge_positions) do
				if apos == purge_pos then
					delete_position = true
				end
			end
			if not delete_position then
				-- Preserve
				has_preserved = true
				preserved_positions[apos] = price
			end
		end
		if has_preserved then
			new_prices[item_name] = preserved_positions
		end
	end
print(dump(smartshop.item_stats))
print(dump(smartshop.new_stats))
	smartshop.item_stats = new_stats
	smartshop.item_prices = new_prices
	--smartshop.save_counts()
	--smartshop.save_prices()
end


function smartshop.save_counts()
	if smartshop.disable_statistics then
		return
	end

	local file = io.open(worldpath .. "smartshop_itemcounts.txt", "w")
	if file then
		file:write(core.serialize(smartshop.item_stats))
		file:close()
	end
end


function smartshop.save_prices()
	if smartshop.disable_statistics then
		return
	end

	local file = io.open(worldpath .. "smartshop_itemprices.txt", "w")
	if file then
		file:write(core.serialize(smartshop.item_prices))
		file:close()
	end
end


-- Set number of items of type 'item' sold at position 'spos'
function smartshop.set_count_pos(spos, item_name, count)
print('set_count_pos ' .. spos)
	if smartshop.disable_statistics then
		return
	end

	if not smartshop.item_stats[item_name] then
		smartshop.item_stats[item_name] = {}
	end
	smartshop.item_stats[item_name][spos] = count
	smartshop.save_counts()
end

-- Depricated: will be removed at some point
local have_warned_count = false
smartshop.itemsatpos = function(...)
	if not have_warned_count then
		have_warned_count = true
		core.log("warning", "Depricated use of smartshop.itemsatpos(). "
			.. "Use smartshop.set_count_pos() instead\n"
			.. debug.traceback())
	end
	return smartshop.set_count_pos(...)
end


-- Set price of 'item_name' sold at position 'spos'
function smartshop.set_price_pos(spos, item_name, price)
	if smartshop.disable_statistics then
		return
	end

	if not smartshop.item_prices[item_name] then
		smartshop.item_prices[item_name] = {}
	end
	smartshop.item_prices[item_name][spos] = price
	smartshop.save_prices()
end

-- Depricated: will be removed at some point
local have_warned_price = false
smartshop.itempriceatpos = function(...)
	if not have_warned_price then
		have_warned_price = true
		core.log("warning", "Depricated use of smartshop.itempriceatpos(). "
			.. "Use smartshop.set_price_pos() instead\n"
			.. debug.traceback())
	end
	return smartshop.set_price_pos(...)
end


-- Used by chat command and globalstep to export a report.
function smartshop.report()
	if smartshop.disable_statistics then
		return false, S("Statistics are disabled.")
	end

	local file = io.open(worldpath .. "smartshop_report.txt", "w")
	if not file then
		return false, S("Could not write to file.")
	end

	for item_name in pairs(smartshop.item_stats) do
		file:write(string.format("%s %d %.3f %d\n",
			item_name,
			smartshop.get_item_count(item_name),
			smartshop.get_item_price(item_name),
			smartshop.get_shop_count(item_name)))
	end
	file:close()
	return true, S("Report file written.")
end


-- Write report file at intervals.
if smartshop.report_interval > 0 then
	local timer = 0
	core.register_globalstep(function(dtime)
		timer = timer + dtime;
		if timer >= smartshop.report_interval then
			smartshop.report()
			timer = 0
		end
	end)
end

