do
  local filename = './data/schedule.lua'
  local cronned = (loadfile './data/schedule.lua')()

  local function save_cron(origin, text, date)
    if not cronned[date] then
      cronned[date] = {}
    end
    local arr = { origin,  text } ;
    table.insert(cronned[date], arr)
    saveConfig(cronned, filename)
    return 'Saved!'
  end

  local function delete_cron(date)
    for k,v in pairs(cronned) do
      if k == date then
  	  cronned[k]=nil
      end
    end
    saveConfig(cronned, filename)
  end

  local function split(str, sep)
     local sep, fields = sep or "|", {}
     local pattern = string.format("([^%s]+)", sep)
     str:gsub(pattern, function(c) fields[#fields+1] = c end)
     return fields
  end

  local function cron()
    for date, values in pairs(cronned) do
    	if date < os.time() then --time's up
        local msgs = split(values[1][2], "|")
        local idx = math.random(1, #msgs)
  	  	sendText(values[1][1], 0, msgs[idx])
    		delete_cron(date) --TODO: Maybe check for something else? Like user
  	end

    end
  end

  local function callbackres(arg, data)
  	-- 1=msg 2=delay 3=text
    if data.id_ ~= nil then
      td.getChat(data.id_, function(a, d)
        local t= ""
        if d.title_ then
          t = d.title_ .. " will receive: '" ..  arg[3]  .. "' on \n" 
          for i=1,#arg[2] do
        		save_cron(data.id_, arg[3], arg[2][i])
        		t= t .. os.date("%x at %H:%M:%S", arg[2][i]) .."\n"
          end
        else
          t = d.message_
        end
        sendText(arg[1].chat_id_, arg[1].id_, t)
      end)
  	else
  		sendText(arg[1].chat_id_, arg[1].id_, "username lookup failed")
  	end
  end

  local function run(msg, matches)
    local delay = 0
    local delays = {}
    local intMin, intMax, times

    for i = 2, #matches-1 do
      local b,_ = string.gsub(matches[i],"[a-zA-Z]","")
      if string.find(matches[i], "-") then
        local parts = split(matches[i], "-")
        intMin = parts[1]
        intMax = parts[2]
      end
      if string.find(matches[i], "x") then
        times=b
      end

      if string.find(matches[i], ":") then
        local parts = split(matches[i], ":")
        delay=delay+parts[1]*3600+parts[2]*60
        if #parts == 3 then
    	    delay=delay+parts[3]
    	  end
      end
    end

    local datetime = os.date ("*t")
    local nowsecs = datetime.hour *3600 + datetime.min *60 + datetime.sec --+9*3600+ 30*60
    local text = matches[#matches]

    if (not intMax and not intMin) then 
      if (delay<=nowsecs) then
      	delay = delay -nowsecs + 24*3600 + os.time() 
      else
      	delay = delay - nowsecs +os.time()
      end
      delays[1] = delay
    else
      math.randomseed( datetime.sec )
      for i=1,times do
        delays[#delays+1] = os.time() + math.random(intMin, intMax)*60
      end
    end
    if string.sub(matches[1],1,1)=='@' then
      td.searchPublicChat(matches[1], callbackres, {msg, delays, text})
    elseif matches[1] == ' ' then
      callbackres({msg, delays, text}, {id_ = msg.chat_id_})
    else
      callbackres({msg, delays, text}, {id_ = matches[1]})
    end
  end

  return {
    description = _msg("schedule messages to anyone, with support for random intervals and text"),
    usage = {
        user = {
      	_config.cmd .. "sch @user/id 2:00 text",
      	_config.cmd .. "sch @user/id 2:10:55 text1|text2",
      	_config.cmd .. "sch @user/id 2-5 x20 msg1|msg2|msg3"
      },
    },
    patterns = {
      _config.cmd .. "sch (@?-?.+) ([0-9]+:[0-9]+) (.+)$",
      _config.cmd .. "sch (@?-?.+) ([0-9]+:[0-9]+[:][0-9]+) (.+)$",
      _config.cmd .. "sch (@?-?.+) ([0-9]+-[0-9]+) ([x][0-9]+) (.+)$",

      _config.cmd .. "sch( )([0-9]+:[0-9]+) (.+)$",
      _config.cmd .. "sch( )([0-9]+:[0-9]+[:][0-9]+) (.+)$",
      _config.cmd .. "sch( )([0-9]+-[0-9]+) ([x][0-9]+) (.+)$"
    }, 
    run = run,
    cron = cron,
    privilege = 5,
  }
end