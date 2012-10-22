
class StorageCollection
  constructor: ->
    @radix = 36
    @data = []

  add: (obj) ->
    id = @data.length
    @data.push obj
    id.toString @radix

  get: (id) ->
    id = parseInt id, @radix
    @data[id]

module.exports = (app, sharedState) ->
  sharedState.streamAutoIncr = 3214
  sharedState.hostMap = {'2ha': 'bitaesthetics.com'}
  sharedState.streams = {'2ha': []}
  sharedState.requests = new StorageCollection()

  app.get '/', (req, res) ->
    res.render 'index', {}

  app.post '/new', (req, res) ->
    sharedState.streamAutoIncr += 1
    streamId = sharedState.streamAutoIncr.toString(36)
    sharedState.hostMap[streamId] = req.body.host
    sharedState.streams[streamId] = []
    res.redirect "/watch/#{streamId}/"

  app.get '/watch/:stream', (req, res) ->
    streamId = req.params.stream
    shortURL = "http://#{streamId}.#{app.get('proxy host')}"
    host = sharedState.hostMap[streamId]
    stream = sharedState.streams[streamId]
    res.render 'watch', {streamId, shortURL, host, stream}

  app.get '/request/:id', (req, res) ->
    request = sharedState.requests.get req.params.id
    res.render 'request', {request}

