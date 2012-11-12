
express = require 'express'
http = require 'http'
path = require 'path'

passport = require 'passport'
DailyCredStrategy = require('passport-dailycred').Strategy

MongoStore = require('connect-mongo')(express)

app = express()

app.set 'port', process.env.PORT || 3000
app.set 'proxy host', process.env.PROXY_HOST || 'between.io'
app.set 'proxy port', process.env.PROXY_PORT || 80
app.set 'proxy https port', process.env.PROXY_HTTPS_PORT || 443
app.set 'private key', process.env.PRIVATE_KEY || 'testkeys/key.pem'
app.set 'certificate', process.env.CERTIFICATE || 'testkeys/wildcard.crt'
app.set 'intermediate cert', process.env.INTERMEDIATE_CERT
app.set 'mongodb host', process.env.MONGODB_HOST || 'mongodb://localhost/between'
app.set 'id bunch size', process.env.ID_BUNCH_SIZE || 10
app.set 'id min allocated', process.env.ID_MIN_ALLOCATED || 5
app.set 'dailycred client id', process.env.DAILYCRED_CLIENT_ID
app.set 'dailycred secret', process.env.DAILYCRED_SECRET
app.set 'client host', process.env.CLIENT_HOST
app.set 'dailycred callback', "http://#{app.get('client host')}/auth"
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
app.use express.logger('dev')
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser('c374b67c4cd99a6ef1ccfcca2aeb93ff')

app.set 'session secret','0afe64dbf1ab51bf133843767797e523'
sessionStore = new MongoStore
  url: app.get 'mongodb host'

app.use express.session
  secret: app.get 'session secret'
  store: sessionStore

app.use require('less-middleware')({ src: __dirname + '/public' })
app.use require('browserify')(__dirname + '/public/js/client.coffee')

passport.serializeUser (user, done) ->
  done null, "#{user.email};#{user.id}"

passport.deserializeUser (userStr, done) ->
  [email, id] = userStr.split ';'
  done null, {email, id}

passport.use(new DailyCredStrategy {
  clientID: app.get 'dailycred client id'
  clientSecret: app.get 'dailycred secret'
  callbackURL: app.get 'dailycred callback'
  }, (accessToken, refreshToken, profile, done) ->
    done(null, profile))

app.use passport.initialize()
app.use passport.session()

app.use (req, res, next) ->
  res.locals.user = req.user
  next()

app.configure 'development', ->
  app.use express.errorHandler()

app.use app.router
app.use express.static(path.join(__dirname, 'public'))

app.get '/login', passport.authenticate('dailycred'), ->

app.get '/auth', passport.authenticate('dailycred',
  {failureRedirect: '/login'}),
  (req, res) ->
    res.redirect('/')

app.get '/logout', (req, res) ->
  req.logout()
  res.redirect('/')

app.models = require('./models.coffee')(app)

server = http.createServer(app)

server.listen app.get('port'), ->
  console.log "Express server listening on port " + app.get('port')
  
socketio = require('socket.io').listen server
socketio.set 'log level', 2

passportSocket = require 'passport.socketio'
socketio.set 'authorization', passportSocket.authorize
  sessionKey: 'connect.sid'
  sessionStore: sessionStore
  sessionSecret: app.get 'session secret'


require('./app')(app, socketio)

require('./proxy')(app)


