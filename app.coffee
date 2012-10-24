
jade = require('jade')
filesize = require('filesize')

class RawRenderer
  canRender: (contentType) ->
    return true

  renderTemplate: jade.compile('pre= data')
  
  render: (file) ->
    @renderTemplate({data: file.data})

class DownloadRenderer
  canRender: (contentType) ->
    return true

  renderTemplate: jade.compile(
    '''
    div(class='row')
      table(class='table span2 table-bordered')
        tr
          th Type
          td= file.contentType
        tr
          th Size
          td= filesize(file.data.length)
        tr
          th Raw Size
          td= filesize(file.rawData.length)
        tr
          th Download
          td
            a(href='#') Download
    ''')

  render: (file) ->
    @renderTemplate({file: file, filesize})

class RenderManager
  constructor: ->
    @renderers = [
      new RawRenderer()
      new DownloadRenderer()
    ]

  render: (file) =>
    if file.data.length == 0
      return []
    renders = []
    for renderer in @renderers
      if renderer.canRender(file.contentType)
        renders.push renderer.render(file)
    return renders

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
  sharedState.exchanges = new StorageCollection()

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

  app.get '/exchange/:id', (req, res) ->
    exchange = sharedState.exchanges.get req.params.id
    renderer = new RenderManager()
    res.render 'exchange', {exchange, renderer: renderer.render}

