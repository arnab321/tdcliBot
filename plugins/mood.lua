do
  local key = _config.key.mood

  local function request(text)
     local url = "https://shl-mp.p.mashape.com/webresources/jammin/emotionV2"
     local payload = "lang=en&text=" .. text
     --[[ {"lang":"en","text":text} ]]
     local respbody = {}
     local headers = {
        ["X-Mashape-Key"] = key,
        ["Accept"] = "application/json",
        ['Content-Type'] = 'application/x-www-form-urlencoded', 
        ["Content-Length"] = payload:len(),
     }

     
     local body, code = https.request{
        url = url,
        method = "POST",
        headers = headers,
        source = ltn12.source.string(payload),
        sink = ltn12.sink.table(respbody),
        protocol = "tlsv1"
     }
     if code ~= 200 then return "", code end
     local body = json.decode(table.concat(respbody))
     return body, code
  end

  local function parseData(data,msg)
  	local str
  	local ambiguous= data.ambiguous == 'yes'
    --getUser(msg.sender_user_id_)
  	str="<code>"..msg.sender_user_id_.."</code> is "

  	if (data.bullying == "yes") then
  		str=str .."a <code>bully</code>. \n\nSigns of "
  	else
  		str=str .."in "
     	end
     	
     	if (ambiguous==true) then
     		str = str .. "either "
     	end
     	
     	for i=1, #data.groups  do
     		
     		str= str.. "<code>"..data.groups[i].name.."</code> ("
     		for j=1, #data.groups[i].emotions do
     			str = str .. data.groups[i].emotions[j]
     			if (j ~= #data.groups[i].emotions) then
     				str = str .. ", "
     			end
     		end

     		str=str .. ") "
     		if (ambiguous==true and i ~= #data.groups) then
     			str = str .. " \t or \t"
     		elseif (ambiguous==false and i ~= #data.groups) then
     			str = str .. " as well as "
     		end
     	end
  	return str
  end

  local function mood(msg)
     --vardump(text[1])
     local txt = msg.content_.text_
     txt = txt:gsub("/mood", "")
     print(txt)
     if (string.len(txt)<5) then
     		return "That text was so short :/"
     end
     local data, code = request(txt)
     if code ~= 200 then return "There was an error. "..code end

     return parseData(data,msg)
  end

  local function run(msg, matches)
  	local txt = ""
    
  	if msg.reply_to_message_id_ ~= 0 then

      txt = "poop"
      td.getMessage(msg.chat_id_, msg.reply_to_message_id_, 
          function (a, data)
            --print(json.encode(msg))
            if type(data.content_.text_) ~= "nil" then
              txt = mood(data)
              sendText(data.chat_id_, data.id_, txt)
            end
        end)
  		      
  	elseif type(msg.content_.text_) ~= "nil" and string.len(matches[1]) > 1 then
  		txt = mood(msg)
  		sendText(msg.chat_id_, msg.id_, txt)
    end
     --return request('http://www.uni-regensburg.de/Fakultaeten/phil_Fak_II/Psychologie/Psy_II/beautycheck/english/durchschnittsgesichter/m(01-32)_gr.jpg')
   	
     --return data
  end

  return {
     description = _msg("detect emotions. reply to a msg by /mood"),
     usage = {
      user = {
        _config.cmd .. "mood [text]"
        },
     },
     patterns = {
        _config.cmd .. "mood (.*)$",
        _config.cmd .. "mood()$"
     },
     run = run,
     -- pre_process=pre_process
  }
end