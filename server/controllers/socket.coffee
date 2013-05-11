irc = require "irc"
redis = require("redis").createClient()
messagesKey = "messages/"
class SocketController
  constructor: (socket) ->
    @socket = socket
    @session = session = socket.handshake.session
    @client = undefined
  
    unless session and session.nick
      socket.emit "loggedout"
    else
      @login session

    socket.on "login", @login

    socket.on "message", (data) =>
      data.from = @client.nick
      @client.say data.to, data.message
      data = @save data, false
      @socket.emit "message", data      

    socket.on "join", @join

    socket.on "disconnect", =>
      @client and @client.disconnect()

  login: (data) =>
    session = @session
    socket = @socket
    @client = client = new irc.Client data.host,data.nick
    client.on "registered", -> 
      session.host = @opt.server
      session.nick = @nick
      session.save()
      socket.emit "loggedin",{host: session.host ,nick: session.nick}
    client.on "message", (from,to,message) => 
      data = @save {from: from, to: to, message: message}, true
      @socket.emit "message", data
    client.on "error", (error) -> console.log "Error:",error

  save: (data,received) =>
    data.time = Date.now()
    key = messagesKey + if data.to[0] is "#" then data.to else @client.nick + "-" + if received then data.from else data.to  
    redis.rpush key, JSON.stringify data
    return data

  join: (contexts) =>
    contexts = contexts.split " "
    people = []
    channels = []
    for context in contexts
      if context[0] is "#" then channels.push context else people.push context
      key = messagesKey + if context[0] is "#" then context else @client.nick + "-" + context
      redis.lrange key, -500, -1, (err, results) ->
        if err then console.log err
        socket.emit "log",context,"["+results.join(",")+"]"
    socket.emit "joined", people 
    if channels.length then @client.join channels, -> socket.emit "joined",channels
module.exports = SocketController
