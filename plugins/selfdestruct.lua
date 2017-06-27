do
  local filename = './data/selfdestruct.lua'
  local chats = (loadfile './data/selfdestruct.lua')()

  local function insert(chat_id, secs)
  	chat_id = tonumber(chat_id)
  	secs = tonumber(secs)
    chats[chat_id] = secs
    saveConfig(chats, filename)
    print("saved " .. chat_id)
  end

  local function delete(chat_id)
  	chat_id = tonumber(chat_id)
    chats[chat_id] = nil
    saveConfig(chats, filename)
    print("deleted " .. chat_id)
  end

  local function sendDetails( msg, titles )
  	local txt = ""
  	for k,v in pairs(chats) do
  		txt = txt .. "• " .. titles[k] .. " : " .. v .. "s\n"
  	end
  	sendText(msg.chat_id_, msg.id_, txt, 1, '')
  end

  local function list( msg )
  	local titles = {}
  	local n = 0
  	local empty = true

    for k,v in pairs(chats) do
    	n = n + 1
    	empty = false
    	td.getChat(k, function(a, d)
	        titles[k] = d.title_ or k
	        n = n - 1
	        if n == 0 then
	        	sendDetails(msg, titles)
	        end
	    end)
    end
    if empty then
    	sendText(msg.chat_id_, msg.id_, '[empty]')
    end
  end

	local function deleteMsg(msg)
		td.deleteMessages(msg.chat_id_, {[0] = msg.id_})
	end

	local function pre_process( msg )
		chat_id = tonumber(msg.chat_id_)
		if msg ~= nil and chats[chat_id] ~= nil then
			print(chats[chat_id])
			td.setAlarm(chats[chat_id], deleteMsg, msg)
		end
		return msg
	end
	local function run(msg, matches)
		if tonumber(msg.chat_id_) > 0 then --ignore for PMs
			return
		end
			td.deleteMessages(msg.chat_id_, {[0] = msg.id_}) --sd any /sd msg
		if matches[1] == "list" then 
			list(msg)
		elseif matches[1] == "0" or type(matches[1]) ~= 'string' then
			delete(msg.chat_id_)
		else
			insert(msg.chat_id_, matches[1])
		end
	end

	return {
	  description = _msg("self deleting messages in groups"),
	  usage = {
		user = {
		  "!sd [secs] to a chat",
		  "!sd 0 or just !sd to disable in that chat",
		  "!sd list to list",
		},
	  },
	  patterns = {
	    _config.cmd .. "sd ([0-9]+)$",
	    _config.cmd .. "sd()$",
	    _config.cmd .. "sd (list)$"
	  }, 
	  run = run,
	  pre_process = pre_process,
	  pre_process_self = true,
	  privilege = 5
	}
end