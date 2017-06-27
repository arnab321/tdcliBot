do
  local filename = './data/bridge.lua'
  local bridges = (loadfile './data/bridge.lua')()

  local function insert(id1, id2, probability, media)
    id1 = tonumber(id1)
    id2 = tonumber(id2)
    probability = tonumber(probability)
    if media ~= nil then
      media = string.lower(media)
    end
    if id1 == id2 then
      return "err: IDs are same"
    end
    local arr = {p=probability, media=media};
    local c = 0
    
    td.getChat(id2, function(a, d)
      -- util.vardump(d)
      local txt = ""
      if d.ID == "Error" then
        txt = d.message_
      else
        if d.type_.channel_ ~= nil and d.type_.channel_.is_supergroup_ == false then -- do not post to channels
          txt = "Linked one-way"
        else
          bridges[id1] = bridges[id1] or {}
          bridges[id1][id2] = arr
          txt = "Linked 2-ways"
        end
          bridges[id2] = bridges[id2] or {}
          bridges[id2][id1] = arr -- we have write access to id1 (current chat)
        saveConfig(bridges, filename)
        txt = txt .. ' with a probability of ' .. probability
      end
      sendText(id1, 0, txt)
    end)
  end

  local function delete(id) --unlinks this id from all pairs (for now)
    local c = 0
    local i = 1
    id = tonumber(id)
    for k,v in pairs(bridges) do
      if k == id then
        bridges[k] = nil
        c = c + 1
      else
        for kk,vv in pairs(v) do
          if kk == id then
            bridges[k][kk] = nil
            c = c + 1
          end
        end
        if next(bridges[k]) == nil then -- if parent is now empty, del that too
          bridges[k] = nil
        end
      end
    end
    saveConfig(bridges, filename)
    if c == 0 then
      return "There are no linked bridges"
    else
      return "Burnt " .. c .. " bridges"
    end
  end

  local function sendDetails( msg, titles )
  	local txt = ""
    local i = 1
    local pairsDone = {}

  	for k,v in pairs(bridges) do
      local first = true

      for kk,vv in pairs(v) do
        if not (pairsDone[k] == kk or pairsDone[kk] == k) then
          if first == true then
            txt = txt .. "\n" .. i .." • " .. titles[k]
            i = i + 1
            first = false
          else
            txt = txt .. ".       "
          end
          if bridges[kk] == nil or bridges[kk][k] == nil then
        		txt = txt .. "  -->  "
          else
            txt = txt .. "  <==>  "
          end
    			txt = txt .. titles[kk] .. "\n (probability: " .. vv.p 
            .. ", media: " .. (vv.media or "all") .. ")\n"
          pairsDone[k] = kk
        end
      end
  	end
  	sendText(msg.chat_id_, msg.id_, txt, 1, '')
  end

  function getChatTitles(titles, d)
    titles.n = titles.n - 1
    if d.title_ ~= nil then
      titles[tonumber(d.id_)] = d.title_
      if titles.n == 0 then
        sendDetails(titles.msg, titles)
      end
    end
  end

  local function list( msg )
  	local n = 0
    local titles = {n=0, msg=msg}
    
  	for k,v in pairs(bridges) do -- serialize, remove duplicates
      if titles[k] == nil then 
          titles[k] = k
          titles.n = titles.n + 1
          td.getChat(k, getChatTitles, titles)
      end
      for kk,vv in pairs(v) do
        if titles[kk] == nil then
          titles[kk] = kk
          titles.n = titles.n + 1
          td.getChat(kk, getChatTitles, titles)
        end
      end
	  end
    if titles.n == 0 then
      sendText(msg.chat_id_, msg.id_, '[empty]')
    end
  end

  local function callbackres(arg, data)
    -- 1=msg 2=probability
    local txt
    --vardump(arg[1])
    if (not arg[2]) then
        txt = "err in args"
    elseif data.id_ ~= nil then
      txt = insert(arg[1].chat_id_, data.id_, arg[2], arg[3])
    else
      txt = "username lookup failed"
    end
    sendText(arg[1].chat_id_, arg[1].id_, txt)
  end

  function check(msg, mediaTypes, media, probability)
    local t = "Message" .. string.upper(string.sub(media,1,1)) .. string.sub(media,2)
    -- mediaTypes=nil : allow all types
    if msg.content_.ID == t and (mediaTypes == nil or string.find(mediaTypes, media) ~= nil) 
        and math.random(0,100) <= probability*100 then
      return true
    else
      return false
    end
  end
  -- [[[[(((({{"''''stop laughing''''"}}))))]]]]
  -- ignore text entities and media captions, so that it doesnt look like a bot forwarding messages
  local function pre_process(msg)
    local chat_id = tonumber(msg.chat_id_)
    local receivers = bridges[chat_id]
    if receivers ~= nil and (chat_id < 0 or 
      (chat_id > 0 and chat_id == tonumber(msg.sender_user_id_))) then
      
      local persistId = nil
      
      for k,v in pairs(receivers) do
        if check(msg, v.media, "text", v.p) then
          sendText(k, 0, msg.content_.text_)
        elseif check(msg, v.media, "photo", v.p) then
          persistId =  msg.content_.photo_.sizes_
          persistId = persistId[#persistId].photo_.persistent_id_
          td.sendPhoto(k, 0, 0, 1, nil, persistId)
        elseif check(msg, v.media, "animation", v.p) then
          persistId =  msg.content_.animation_.animation_.persistent_id_
          td.sendAnimation(k, 0, 0, 1, nil, persistId)
        elseif check(msg, v.media, "sticker", v.p) then
          persistId =  msg.content_.sticker_.sticker_.persistent_id_
          td.sendSticker(k, 0, 0, 1, nil, persistId)
        elseif check(msg, v.media, "video", v.p) then
          persistId =  msg.content_.video_.video_.persistent_id_
          td.sendVideo(k, 0, 0, 1, nil, persistId)
        elseif check(msg, v.media, "audio", v.p) then
          persistId =  msg.content_.audio_.audio_.persistent_id_
          td.sendAudio(k, 0, 0, 1, nil, persistId)
        elseif check(msg, v.media, "voice", v.p) then
          persistId =  msg.content_.voice_.voice_.persistent_id_
          td.sendVoice(k, 0, 0, 1, nil, persistId)
        elseif check(msg, v.media, "document", v.p) then
          persistId =  msg.content_.document_.document_.persistent_id_
          td.sendDocument(k, 0, 0, 1, nil, persistId)
        elseif check(msg, v.media, "location", v.p) then
          local loc =  msg.content_.location_
          td.sendLocation(k, 0, 0, 1, nil, loc.latitude_, loc.longitude_)
        elseif check(msg, v.media, "contact", v.p) then
          local con =  msg.content_.contact_
          td.sendContact(k, 0, 0, 1, nil, con.phone_number_, con.first_name_, con.last_name_, con.user_id_)
        end
      end
    end
    return msg
  end

  local function run(msg, matches)
    if matches[1] == "list" then
      list(msg)
    elseif matches[1] == "del" then
      sendText(msg.chat_id_, msg.id_, _msg(delete(msg.chat_id_)))
    else
      if string.sub(matches[1],1,1) == '@' then
        td.searchPublicChat(matches[1], callbackres, {msg, matches[2], matches[3]})
      else
        callbackres({msg, matches[2], matches[3]}, {id_ = matches[1]})
      end
    end
  end

  return {
    description = "sends and receives from another user/chat/channel",
    usage = {
      user = {
        "!bridge del, !bridge list, !bridge @username/chat_id, !bridge @username/chat_id text,photo,contact"
      },
    },
    patterns = {
       _config.cmd .. "bridge (@?-?.+) ([0-1].[0-9]+)$",
       _config.cmd .. "bridge (@?-?.+) (1)$",
       _config.cmd .. "bridge (@?-?.+) ([0-1].[0-9]+) (.+)$",
       _config.cmd .. "bridge (@?-?.+) (1) (.+)$",
       _config.cmd .. "bridge (list)$",
       _config.cmd .. "bridge (del)$"
       
    }, 
    run = run,
    pre_process = pre_process,
    privilege = 5
  }
end