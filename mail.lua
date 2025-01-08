
local S = smartshop.S

local wants_table = mail.version and mail.version >= 3


function smartshop.send_mail(owner, pos, item_name)
	local spos = smartshop.pos_to_string(pos)
	local human_name = smartshop.get_human_name(item_name)
	local msg = {
		src = "DO NOT REPLY",
		dst = owner,
		subject = S("Out of @1 at @2", human_name, spos),
		body = S("Your smartshop at @1 is out of @2. Please restock.",
			spos, human_name),
	}
	if wants_table then
		mail.send(msg)
	else
		mail.send(msg.src, owner, msg.subject, msg.body)
	end
end
