do
  
  local function run(msg, matches)
    if msg.reply_to_message_id_ ~= 0 then
      
      local msg2 = td.getMessage(msg.chat_id_, msg.reply_to_message_id_,
        function(a, data)
          local dump = serpent.block(data, {comment=false})          
          sendText(msg.chat_id_, msg.reply_to_message_id_, _msg('<pre>'.. dump .. '</pre>'))
          end)
    end
    
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('vardump for everyone'),
    usage = {
      user = {
        'vardump',
      },
    },
    patterns = {
      '^vardump$',
    },
    run = run
  }

end
