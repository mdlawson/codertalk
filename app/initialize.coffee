window.App = App = require 'app'
App.socket = io.connect()
App.user = Ember.Object.create()

# Templates

require 'templates/application'
require 'templates/index'
require 'templates/login'
require 'templates/chat'

# Models




# Controllers


App.LoginController = Ember.Object.extend
  nick: undefined
  password: undefined
  host: undefined
  login: ->
    App.socket.emit "login",
      nick: @get "nick"
      password: @get "password"
      host: @get("host") or "irc.freenode.net"

App.ChatController = Ember.ArrayController.extend
  init: ->
    @_super()
    receive = (data) => @receiveMessage data
    App.socket.on "sent", receive
    App.socket.on "message", receive
  sendMessage: ->
    App.socket.emit "message",
      to: @get "context"
      message: @get "message"
    @set "message", ""
  receiveMessage: (data) ->
    data.me = data.from is App.user.get("nick")
    context = if data.me or data.to[0] is "#" then data.to else data.from 
    @store[context] or @store[context] = []
    @store[context].pushObject data
    @notifyPropertyChange "store"
    # @pushObject data
    console.log data
  contexts: (->
    Ember.keys @get "store"
  ).property("store")
  show: (context) ->
    console.log "Switching to:", context
    @set "content",@get("store").get(context)
    @set "context",context
  add: ->
    input = @get "entry"
    channels = (item for item in input.split(" ") when item[0] is "#")
    if channels.length
      App.socket.emit "join", channels.join(" ")
    for context in input.split(" ")
      @store[context] or @store[context] = []
    @notifyPropertyChange "store"
    @set "entry",""




# Views


# Routes

App.ApplicationRoute = Em.Route.extend
  init: ->
    App.socket.on "loggedin", (data) =>
      App.user.setProperties data
      @transitionTo "chat"
    App.socket.on "loggedout", =>
      @transitionTo "login"

App.ChatRoute = Em.Route.extend
  setupController: (controller) -> 
    controller.set "store", Ember.Object.create()
    controller.set "content", []

# Store


# App.Store = DS.Store.extend
#   revision: 11


# Router


App.Router.reopen(
  location: 'history'
)

App.Router.map ->
  @route "index", path: "/"
  @route "login", path: "/login"
  @route "chat" , path: "/chat"