
httpProxy = require 'http-proxy'
http = require 'http'

module.exports = (app, sharedState) ->
  getHost = (streamId) ->
    sharedState.hostMap[streamId]

  getStreamFromHost = (host) ->
    hostbase = app.get 'proxy host'
    hregex = new RegExp("([\\d\\w]+)\\.#{hostbase}")
    result = hregex.exec(host)
    result[1]

  proxy = httpProxy.createServer (req, res, proxy) ->
    streamId = getStreamFromHost(req.headers.host)
    host = getHost(streamId)
    port = 80
    path = req.url
    method = req.method
    req_headers = req.headers
    
    request = {host, port, path, method, req_headers, res_headers: {}}
    request.id = sharedState.requests.add(request)

    sharedState.streams[streamId].unshift(request)

    res.oldWriteHead = res.writeHead
    res.writeHead = (statusCode, reasonPhrase, headers) =>
      res.oldWriteHead statusCode, reasonPhrase, headers

      if typeof(reasonPhrase == 'object')
        headers = reasonPhrase
        reasonPhrase = undefined

      request.status = statusCode
      request.res_headers = headers

    req.headers.host = host
    proxy.proxyRequest req, res, {host, port}

  proxy.listen 80, ->
    console.log 'proxy server listening'

