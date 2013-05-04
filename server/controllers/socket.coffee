irc = require "irc"

class SocketController
  constructor: (socket) ->
    session = socket.handshake.session
    @client = undefined
    login = (data) =>
      @client = new irc.Client data.host,data.nick
      @client.on "registered", -> 
        session.host = @opt.server
        session.nick = @nick
        session.save()
        socket.emit "loggedin",{host: session.host ,nick: session.nick}
      @client.on "message", (from,to,message) -> socket.emit "message", {from:from,to:to,message:message}
      @client.on "error", (error) -> console.log "Error:",error
    unless session and session.nick
      socket.emit "loggedout"
    else
      login session

    socket.on "login", login

    socket.on "message", (data) =>
      #console.log "message:",data
      @client.say data.to, data.message
      data.from = @client.nick
      socket.emit "sent", data

    socket.on "join", (channel) =>
      @client.join channel, -> socket.emit "joined",channel

    socket.on "disconnect", =>
      @client and @client.disconnect()

module.exports = SocketController
