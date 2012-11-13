
module.exports.run = (serverClass) ->
  express = require 'express'
  http = require 'http'
  https = require 'https'
  path = require 'path'
  fs = require 'fs'

  passport = require 'passport'
  DailyCredStrategy = require('passport-dailycred').Strategy
  {configFromEnv} = require './config'

  MongoStore = require('connect-mongo')(express)

  app = express()

  configFromEnv app, serverClass

  app.set 'dailycred callback', "http://#{app.get('client hostname')}/auth"
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'

  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser(app.get 'cookie secret')

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

  if app.get('tls') == 'true'
    if app.get 'tls intermediate'
      ic = [fs.readFileSync(app.get('tls intermediate'), 'ascii')]
    else
      ic = []
    privateKey = fs.readFileSync app.get('tls private key'), 'ascii'
    cert = fs.readFileSync app.get('tls certificate'), 'ascii'
    credentials =
      key: privateKey
      cert: cert
      ca: ic
    server = https.createServer credentials, app
  else
    server = http.createServer app

  server.listen app.get('port'), ->
    console.log "Express server listening on port " + app.get('port')
    
  socketio = require('socket.io').listen server
  socketio.set 'log level', 2

  passportSocket = require 'passport.socketio'
  socketio.set 'authorization', passportSocket.authorize
    sessionKey: 'connect.sid'
    sessionStore: sessionStore
    sessionSecret: app.get 'session secret'

  require('./client')(app, socketio)



