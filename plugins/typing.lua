do
	local function sendTyping(chat_id) 
		print ("typing to " .. chat_id)
		td.sendChatAction(chat_id, 'Typing', ok_cb)
	end

	local function scheduleTyping(chat_id, secs)
		elapsed = 0
		while (elapsed < tonumber(secs)) do
			td.setAlarm(elapsed, sendTyping, chat_id)
			elapsed = elapsed + math.random(5,9)			
		end	
	end

	local function run(msg, matches)
		if tonumber(msg.chat_id_) > 0 then --edit it for PM, delete it for group
			local txt = 'umm..'
			if matches[2] ~= nil then
				txt = matches[2]
			end
			td.editMessageText(msg.chat_id_, msg.id_, nil, txt, 1, nil, ok_cb)
		else
			td.deleteMessages(msg.chat_id_, {[0] = msg.id_})
		end
		scheduleTyping(msg.chat_id_, matches[1])
	end

	return {
	  description = _msg("Type forever"),
	  usage = {
		user = {
		  "!typing [secs] to a chat",
		},
	  },
	  patterns = {
	    _config.cmd .. "typing ([0-9]+)$",
	    _config.cmd .. "typing ([0-9]+) (.+)$"
	  }, 
	  run = run 
	}
end