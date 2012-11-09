
express = require 'express'
http = require 'http'
path = require 'path'

app = express()

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.set 'proxy port', process.env.PROXY_PORT || 80
  app.set 'proxy https port', process.env.PROXY_HTTPS_PORT || 443
  app.set 'private key', process.env.PRIVATE_KEY || 'testkeys/key.pem'
  app.set 'certificate', process.env.CERTIFICATE || 'testkeys/wildcard.crt'
  app.set 'mongodb host', process.env.MONGODB_HOST || 'mongodb://localhost/between'
  app.set 'id bunch size', process.env.ID_BUNCH_SIZE || 10
  app.set 'id min allocated', process.env.ID_MIN_ALLOCATED || 5
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
  app.use require('browserify')(__dirname + '/public/js/client.coffee')
  app.use express.static(path.join(__dirname, 'public'))

  app.set 'proxy host', process.env.PROXY_HOST || 'between.io'

app.models = require('./models.coffee')(app)

if process.env.AUTH_USER?
  app.get '/healthcheck', (req, res) ->
      res.writeHead(200)
      res.end()

  app.get '/googleed106e19283bb2cc.html', (req, res) ->
      res.writeHead(200)
      res.end('google-site-verification: googled0582ab45aea5431.html\n')

  auth = express.basicAuth process.env.AUTH_USER, process.env.AUTH_PASS
  app.get '/', auth, (req, res, next) -> next()

app.configure 'development', ->
  app.use express.errorHandler()

server = http.createServer(app)

server.listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
  
socketio = require('socket.io').listen server
socketio.set 'log level', 2

require('./app')(app, socketio)

require('./proxy')(app)

