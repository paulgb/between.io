
jade = require('jade')
highlight = require('highlight.js')

module.exports = (app, models) ->
  # for testing only!
  models.interceptors.create
    host: 'bitaesthetics.com'

  app.get '/', (req, res) ->
    res.render 'index', {}

  app.post '/new', (req, res) ->
    interceptor = models.interceptors.create
      host: req.body.host

    res.redirect "/transcript/#{interceptor.id}/"

  app.get '/transcript/:id', (req, res) ->
    interceptor = models.interceptors.get req.params.id
    res.render 'transcript', {interceptor, transcript: interceptor.transcript}

  app.get '/exchange/:id', (req, res) ->
    exchange = models.exchanges.get req.params.id
    if not exchange?
      res.redirect '/'
    renderer = new RenderManager()
    res.render 'exchange', {exchange, renderer: renderer.render}

