do

  local function getIds(chat_id, msg_id, resolvedId)
    local text =  '<code>' .. (resolvedId or chat_id) .. '</code>'
    sendText(chat_id, msg_id, text, 1, nil, function (arg,data)
      td.setAlarm(5, function( a,d )
        td.deleteMessages(chat_id, {[0] = msg_id, data.id_})
      end)
    end)
  end

  local function getUser_cb(arg, data)
    getIds(arg.chat_id, arg.msg_id)
  end

--------------------------------------------------------------------------------

  local function run(msg, matches)
    local chat_id, user_id, _, _ = util.extractIds(msg)
    local input = msg.content_.text_
    local extra = {chat_id = chat_id, msg_id = msg.id_}

    if util.isMod(user_id, chat_id) then
      if util.isReply(msg) and matches[1] == 'id' then
        td.getMessage(chat_id, msg.reply_to_message_id_, function(a, d)
          td.getUser(d.sender_user_id_, getUser_cb, {
              chat_id = a.chat_id,
              msg_id = d.id_
          })
        end, {chat_id = chat_id})
      elseif matches[1] == '@' then
        td.searchPublicChat(matches[2], function(a, d)
          -- local exist, err = util.checkUsername(d)
          -- local username = a.username
          local chat_id = a.chat_id
          local msg_id = a.msg_id

          -- if not exist then
          --   return sendText(chat_id, msg_id, _msg(err):format(username))
          -- end
          getIds(chat_id, msg_id, d.id_)
        end, extra)
      elseif matches[1]:match('%d+$') then
        td.getUser(matches[1], getUser_cb, extra)
      end
    end

    if msg.reply_to_message_id_ == 0 and matches[1] == 'id' then
      td.getUser(user_id, getUser_cb, extra)
    end
  end

--------------------------------------------------------------------------------

  return {
    description = _msg('Short, chat id, easier to copy'),
    usage = {
      --moderator = {
        --'<code>!id</code>',
        --_msg('Returns the IDs of the replied users.'),
        --'',
        --'<code>!id [user_id]</code>',
        --_msg('Return the IDs for the given user_id.'),
        --'',
        --'<code>!id @[username]</code>',
        --_msg('Return the IDs for the given username.'),
        --'',
      --},
      user = {
        'https://telegra.ph/Id-02-08',
        --'<code>!id</code>',
        --_msg('Returns your IDs.'),
        --'',
      },
    },
    patterns = {
      _config.cmd .. '(id)$',
      _config.cmd .. 'id (@)(.+)$',
      _config.cmd .. 'id (%d+)$',
    },
    run = run
  }

end
