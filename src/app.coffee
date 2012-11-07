
Types = require 'mongoose'

RenderManager = require './renderers'
contentTypes = require './contentTypes'
{Interceptor, Exchange, ExchangePipe, File} = require './models'
{SubscriptionManager} = require './subscriptionManager'

module.exports = (app, socketio) ->
  app.get '/', (req, res) ->
    res.render 'index', {}

  app.post '/new', (req, res) ->
    interceptor = new Interceptor
      host: req.body.host

    interceptor.save ->
      res.redirect "/transcript/#{interceptor.id}/"

  app.get '/transcript/:id', (req, res) ->
    Interceptor.findById req.params.id, (err, interceptor) ->
      res.render 'transcript', {interceptor}

  app.get '/exchange/:id', (req, res) ->
    renderer = new RenderManager()
    query = Exchange.findById req.params.id
    query = query.populate 'requestData'
    query = query.populate 'responseData'
    query.exec (err, exchange) ->
      console.log exchange
      res.render 'exchange', {exchange, renderer: renderer.render}
    
  subscriptionManager = new SubscriptionManager (exchange, socket) ->
    socket.emit 'transcript', [exchange]

  exchangeStream = ExchangePipe.find().populate('exchange').tailable().stream()
  
  exchangeStream.on 'data', (data) ->
    console.log data
    subscriptionManager.notify(data.interceptor, data.exchange)

  socketio.sockets.on 'connection', (socket) ->
    console.log socket
    socket.on 'subscribe', (transcriptId) ->
      console.log "got subscribe request for #{transcriptId}"
      subscriptionManager.sub(transcriptId, socket.id, socket)

      ###
      query = Exchange.find({interceptor: transcriptId})
      query = query.limit(30).sort('-_id').exec (err, exchanges) ->
        if exchanges.length > 0
          socket.emit 'transcript', exchanges
      ###

      socket.on 'disconnect', ->
        subscriptionManager.unsub(transcriptId, socket.id)

