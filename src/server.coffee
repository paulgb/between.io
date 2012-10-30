
express = require 'express'
http = require 'http'
path = require 'path'

app = express()

models = require('./models')

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser('your secret here')
  app.use express.session()
  app.use app.router
  app.use require('less-middleware')({ src: __dirname + '/public' })
  app.use express.static(path.join(__dirname, 'public'))

  app.set 'proxy host', 'between.io'

app.configure 'development', ->
  app.use express.errorHandler()

server = http.createServer(app)

server.listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
  
socketio = require('socket.io').listen server

require('./app')(app, socketio, models)

require('./proxy')(app, models)

