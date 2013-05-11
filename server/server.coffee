# if not require("piping")(hook:true)

#   return
exports.startServer = (port,root,callback) ->
  path = require "path"
  express = require "express"
  app = express()
  RedisStore = require('connect-redis')(express)
  server = require("http").createServer app
  io = require("socket.io").listen server
  redis = require("redis").createClient()

  secret = "SuperSecret"
  key = "connect.sid"
  cookieParser = express.cookieParser secret
  #store = new express.session.MemoryStore()
  store = new RedisStore client: redis

  io.configure "development", ->
    io.set "transports",["websocket"]
    io.set "log level", 2
  io.set "authorization", (data, done) ->
    if not (data or data.headers or data.headers.cookie) then done "No cookie in header", false 
    cookieParser data,{}, (err) ->
      if err then done err,false
      sessionId = (data.secureCookies and data.secureCookies[key]) or (data.signedCookies and data.signedCookies[key]) or (data.cookies and data.cookies[key])
      if not sessionId then done "Could not find cookie with key: #{key}",false 
      data.sessionId = sessionId
      store.load sessionId, (err, session) ->
        if err then done err, false
        data.session = session
        done null, true
  app.use express.bodyParser()
  app.set "port", port
  app.use cookieParser
  app.use express.session secret: secret, store: store, key: key
  app.use express.static root
  app.use app.router

#  app.get "/", (req,res) ->
#    res.render "index"
  app.get "/logout", (req,res) ->
    req.session.destroy ->
      res.redirect "/"

  index = path.join root,"index.html"
  app.get "*", (req,res) ->
    res.sendfile index
  console.log "Express server listening"
  server.listen app.get "port"

  SocketController = require "./controllers/socket"

  io.sockets.on "connection", (socket) -> new SocketController socket

  callback()
  return app