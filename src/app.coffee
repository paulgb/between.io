
RenderManager = require './renderers'
contentTypes = require './contentTypes'
{Interceptor, Exchange, File} = require './models'

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
    Exchange.findById req.params.id, (err, interceptor) ->
      res.render 'exchange', {exchange}
    
  socketio.sockets.on 'connection', (socket) ->
    socket.on 'subscribe', (transcriptId) ->
      console.log "got subscribe request for #{transcriptId}"

