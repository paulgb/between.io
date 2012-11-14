
###
client.coffee contains all of the business logic for the
web-client. It's primarily an Express app. The app object
is created by clientServer.coffee and passed to this
module, which binds functions to the app.
###

Types = require 'mongoose'
url = require 'url'

RenderManager = require './renderers'
contentTypes = require './contentTypes'
{SubscriptionManager} = require './subscriptionManager'

ensureAuthenticated = (req, res, next) ->
  ###
  Simple Express middleware to ensure a user is logged-in.
  This is normally not used since we usually need
  to know whether a user has access to a given object,
  which implies authentication.
  ###
  if (req.isAuthenticated())
    return next()
  res.redirect '/login'

module.exports = (app, socketio) ->
  ###
  This module exports a single function, which allows us
  to pass the app and socketio object in.
  ###
  {Interceptor, Exchange, ExchangePipe, File, idAllocator} = app.models
  fileGetter = (types, headerMods = []) ->
    ###
    fileGetter returns a view function which can be
    used to retrieve a particular file with arbitrary
    header overrides.
    ###
    (req, res) ->
      file = File.findById req.params.id, (err, file) ->
        if err?
          res.writeHead(404)
          res.write('File not found')
          res.end()
        else if contentTypes.matchType(file.contentType, types)
          # matching the content type here is important to
          # avoid XSS vulnerabilities
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
    ###
    Show landing page if user is not logged in, otherwise
    list interceptors and show form to create a new one
    ###
    if req.user?
      Interceptor.find {user: req.user.id}, (err, interceptors) ->
        res.render 'index', {interceptors}
    else
      res.render 'landing'

  app.post '/new', ensureAuthenticated, (req, res) ->
    ###
    User is creating a new interceptor.
    ###

    iUrl = req.body.url
    if iUrl.indexOf('://') == -1
      # links without a protocol specification will
      # not parse right if a port is given, so make
      # sure a protocol is present
      iUrl = 'http://' + iUrl
    {protocol, port, hostname} = url.parse(iUrl)
    
    # The user can specify a port in the URL, but
    # only for the protocol given. Defaults for
    # each port apply otherwise.
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
    ###
    Show the details of a transcript.
    Most of this page is rendered on the browser,
    since it gets updates in real-time.
    ###
    Interceptor.findById req.params.id, (err, interceptor) ->
      if not interceptor?
        return res.render 'notfound'
      if req.user.id isnt interceptor.user
        return res.render 'baduser'
      res.render 'transcript', {interceptor}

  app.get '/exchange/:id', (req, res) ->
    ###
    Get the details of a particular exchange.
    ###
    
    # a RenderManager controls the way data
    # from the body of the request and response
    # is handled
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
    
  ###
  This section is dedicated to allowing the browser-side code
  to subscribe to changes to data. We do this by keeping a single
  connection to the database server alive which receives all new
  ExchangePipe objects. These objects are created by the Exchange
  object's middleware whenever an Exchange object is saved (see
  models.coffee).

  When browsers open a websocket to listen for changes to a
  transcript, they are added to a SubscriptionManager (see
  subscriptionManager.coffee) which maps the Interceptor that
  they are listening for to the socket they're connected on.
  When the database sends notification that an Exchange object
  has changed, the SubscriptionManager notifies the correct
  socket.
  ###
  
  subscriptionManager = new SubscriptionManager (exchange, socket) ->
    # the SubscriptionManager uses an internal mapping to send
    # back the socket associated with the ID given in the notify call
    socket.emit 'transcript', [exchange]

  # Note that this is a tailable stream of a query -- it will
  # continue to stream data as long as the connection is open!
  exchangeStream = ExchangePipe.find().populate('exchange').tailable().stream()
  
  exchangeStream.on 'data', (data) ->
    # A new ExchangePipe object has come in from the database;
    # let subscriptionManager decide who to notify
    subscriptionManager.notify(data.interceptor, data.exchange)

  socketio.sockets.on 'connection', (socket) ->
    socket.on 'subscribe', (transcriptId) ->
      console.log "got subscribe request for #{transcriptId}"
      interceptor = Interceptor.findById transcriptId, (err, interceptor) ->
        if err
          socket.emit 'error', 'Interceptor not found'
          return
        if interceptor.user isnt socket.handshake.user.id
          # The node module passport.socketio adds passport.js
          # middleware to socket.io so that we can verify that
          # users only ask to subscribe to interceptors that they
          # own
          socket.emit 'error', 'Invalid user for this interceptor'
          return

        # Subscribe to future updates
        subscriptionManager.sub(transcriptId, socket.id, socket)

        # At connection time we query for the most recent
        # exchanges for a one-time package
        query = Exchange.find({interceptor: transcriptId})
        query = query.limit(30).sort('-_id').exec (err, exchanges) ->
          if err
            console.log "mongo error: #{err}"
            return
            
          if exchanges.length > 0
            socket.emit 'transcript', exchanges.reverse()

        socket.on 'disconnect', ->
          subscriptionManager.unsub(transcriptId, socket.id)

