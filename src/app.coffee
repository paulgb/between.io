
RenderManager = require('./renderers')
contentTypes = require('./contentTypes')

module.exports = (app, socketio, models) ->
  fileGetter = (types, headerMods = []) ->
    (req, res) ->
      file = models.files.get req.params.id
      if not file?
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

  app.get '/', (req, res) ->
    res.render 'index', {}

  app.post '/new', (req, res) ->
    interceptor = models.interceptors.create
      host: req.body.host

    res.redirect "/transcript/#{interceptor.id}/"

  app.get '/transcript/:id', (req, res) ->
    interceptor = models.interceptors.get req.params.id
    res.render 'transcript', {interceptor}

  app.get '/exchange/:id', (req, res) ->
    exchange = models.exchanges.get req.params.id
    if not exchange?
      res.redirect '/'
    renderer = new RenderManager()
    res.render 'exchange', {exchange, renderer: renderer.render}

  app.get '/raw/:id/:filename', fileGetter contentTypes.plaintextTypes,
    'Content-Type': 'text/plain'

  app.get '/image/:id/:filename', fileGetter contentTypes.imageTypes

  app.get '/file/:id/:filename', fileGetter contentTypes.allTypes,
    'Content-Disposition': 'attachment'
    
  socketio.sockets.on 'connection', (socket) ->
    socket.on 'subscribe', (transcriptId) ->
      transcript = models.interceptors.get transcriptId
      if not transcript?
          return
      socket.emit 'transcript', transcript.transcript

      transcript.transcriptEmitter.on 'prepend', (exchange) ->
        socket.emit 'exchange', exchange

      transcript.transcriptEmitter.on 'update', (exchange) ->
        socket.emit 'update', exchange

