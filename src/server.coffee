
express = require 'express'
http = require 'http'
path = require 'path'

app = express()

models = require('./models')

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.set 'proxy port', process.env.PROXY_PORT || 80
  app.set 'proxy https port', process.env.PROXY_HTTPS_PORT || 443
  app.set 'private key', process.env.PRIVATE_KEY || 'testkeys/key.pem'
  app.set 'certificate', process.env.CERTIFICATE || 'testkeys/cert.crt'
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser('c374b67c4cd99a6ef1ccfcca2aeb93ff')
  app.use express.session()
  app.use app.router
  app.use require('less-middleware')({ src: __dirname + '/public' })
  app.use express.static(path.join(__dirname, 'public'))

  app.set 'proxy host', process.env.PROXY_HOST || 'between.io'

if process.env.AUTH_USER?
  app.get '/healthcheck', (req, res) ->
      res.writeHead(200)
      res.end()

  auth = express.basicAuth process.env.AUTH_USER, process.env.AUTH_PASS
  app.get '/', auth, (req, res, next) -> next()

app.configure 'development', ->
  app.use express.errorHandler()

server = http.createServer(app)

server.listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
  
socketio = require('socket.io').listen server

require('./app')(app, socketio, models)

require('./proxy')(app, models)

