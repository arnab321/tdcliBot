do
  local function run(msg, matches)
    sendText(msg.chat_id_, msg.id_, _msg("I'm gonna die 😫... RIP."), 0, '',
      function (a,d)
        local output = util.shellCommand("pkill -f 'tg/telegram-cli -WRs ./bot/bot.lua -c '")
      end)
  end

  return {
    description = _msg("kills the td-cli instance. Useful for testing, when started via ./tdcliBot startLoop"),
    usage = {
      user = {
        "/die",
      },
    },
    patterns = {
  	  _config.cmd .. "die$"
    }, 
    run = run,
    privilege = 5
  }
end