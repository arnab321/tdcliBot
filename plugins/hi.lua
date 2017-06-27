do
  local function run(msg, matches)
  	wassup={"hi","wassup?","hey","wassup?","hows u?","what r u doing?","how was ur day?","hello","yo","hieeeeeee"}
  	i=math.random(0,9)
    if (tonumber(msg.chat_id_) > 0 and _config.bot.id ~= msg.sender_user_id_ ) then
      td.setAlarm(i, function(a,d)
        sendText(msg.chat_id_, 0, _msg(wassup[i]))
        end)
    end
  end

  return {
    description = _msg("says hi"),
    usage = {
      user = {
        "says hi",
      },
    },
    patterns = {
  	   nocase("^hi"),nocase("^hey"),nocase("^hello") --,nocase("^how"),nocase("^yo")
    }, 
    run = run 
  }
end