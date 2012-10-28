
{ProxyServer} = require('./proxyServer')

class BasicProxy extends ProxyServer
  getTarget: (req) ->
    req.headers.host = 'graph.facebook.com'
    host: req.headers.host
    port: 80

  onRequestWriteHead: (method, path, headers) ->
    console.log 'onResponseWriteHead', method, path, headers

  onRequestWrite: (data) ->
    console.log 'onRequestData', data

  onRequestEnd: ->
    console.log 'onRequestEnd'

  onResponseWriteHead: (statusCode, headers) ->
    console.log 'onResponseWriteHead', statusCode, headers

  onResponseWrite: (data) ->
    console.log 'onResponseData', data

  onResponseEnd: ->
    console.log 'onResponseEnd'

new BasicProxy(8000)

