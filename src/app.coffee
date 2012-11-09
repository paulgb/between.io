
Types = require 'mongoose'
url = require 'url'

RenderManager = require './renderers'
contentTypes = require './contentTypes'
{SubscriptionManager} = require './subscriptionManager'

ensureAuthenticated = (req, res, next) ->
  if (req.isAuthenticated())
    return next()
  res.redirect '/login'

module.exports = (app, socketio) ->
  {Interceptor, Exchange, ExchangePipe, File, idAllocator} = app.models
  fileGetter = (types, headerMods = []) ->
    (req, res) ->
      file = File.findById req.params.id, (err, file) ->
        if err?
          res.writeHead(404)
          res.write('File not found')
          res.end()
        else if contentTypes.matchType(file.contentType, types)
          headers =
            'Content-Type': file.contentType
            'Content-Length': file.data.length
            'Connection': 'close'
          for header, value of headerMods
            headers[header] = value
          res.writeHead(200, headers)
          res.write(file.data)
          res.end()
        else
          res.writeHead(403)
          res.write('Wrong file type for this operation')
          res.end()

  app.get '/raw/:id/:filename', fileGetter contentTypes.plaintextTypes,
    'Content-Type': 'text/plain'

  app.get '/image/:id/:filename', fileGetter contentTypes.imageTypes

  app.get '/file/:id/:filename', fileGetter contentTypes.allTypes,
    'Content-Disposition': 'attachment'
    
  app.get '/', (req, res) ->
    if req.user?
      Interceptor.find {user: req.user.id}, (err, interceptors) ->
        res.render 'index', {interceptors}
    else
      res.render 'landing'

  app.post '/new', ensureAuthenticated, (req, res) ->
    iUrl = req.body.url
    if iUrl.indexOf('://') == -1
      iUrl = 'http://' + iUrl
    {protocol, port, hostname} = url.parse(iUrl)
    if protocol == 'http:' and port?
      httpPort = parseInt(port)
    else
      httpPort = 80
    if protocol == 'https:' and port?
      httpsPort = parseInt(port)
    else
      httpsPort = 443
    interceptor = new Interceptor
      _id: idAllocator.take()
      host: hostname
      httpPort: httpPort
      httpsPort: httpsPort
      user: req.user.id

    interceptor.save ->
      res.redirect "/transcript/#{interceptor._id}/"

  app.get '/transcript/:id', (req, res) ->
    Interceptor.findById req.params.id, (err, interceptor) ->
      if not interceptor?
        return res.render 'notfound'
      if req.user.id isnt interceptor.user
        return res.render 'baduser'
      res.render 'transcript', {interceptor}

  app.get '/exchange/:id', (req, res) ->
    renderer = new RenderManager()
    query = Exchange.findById req.params.id
    query = query.populate 'requestData'
    query = query.populate 'responseData'
    query.exec (err, exchange) ->
      if not exchange?
        return res.render 'notfound'
      if req.user.id isnt exchange.user
        return res.render 'baduser'
      res.render 'exchange', {exchange, renderer: renderer.render}
    
  subscriptionManager = new SubscriptionManager (exchange, socket) ->
    socket.emit 'transcript', [exchange]

  exchangeStream = ExchangePipe.find().populate('exchange').tailable().stream()
  
  exchangeStream.on 'data', (data) ->
    subscriptionManager.notify(data.interceptor, data.exchange)

  socketio.sockets.on 'connection', (socket) ->
    socket.on 'subscribe', (transcriptId) ->
      console.log "got subscribe request for #{transcriptId}"
      subscriptionManager.sub(transcriptId, socket.id, socket)

      query = Exchange.find({interceptor: transcriptId})
      query = query.limit(30).sort('-_id').exec (err, exchanges) ->
        if err
          console.log "mongo error: #{err}"
          return
          
        if exchanges.length > 0
          socket.emit 'transcript', exchanges.reverse()

      socket.on 'disconnect', ->
        subscriptionManager.unsub(transcriptId, socket.id)

