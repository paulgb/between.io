
RenderManager = require './renderers'
contentTypes = require './contentTypes'
{Interceptor, Exchange, File} = require './models'
Types = require 'mongoose'

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
    
  socketio.sockets.on 'connection', (socket) ->
    socket.on 'subscribe', (transcriptId) ->
      console.log "got subscribe request for #{transcriptId}"

      maxId = null
      update = ->
        query = Exchange.find()
        if maxId?
          query = query.where('_id').gt(maxId)
        query = query.limit(30).sort('_id').exec (err, exchanges) ->
          if exchanges.length > 0
            maxId = exchanges[exchanges.length-1]._id
            socket.emit 'transcript', exchanges

      update()
      interval = setInterval(update, 2000)
      socket.on 'disconnect', ->
        clearInterval(interval)

