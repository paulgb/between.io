
httpProxy = require 'http-proxy'
http = require 'http'
zlib = require 'zlib'

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
    
    request = {host, port, path, method, req_headers, res_headers: {}, parts: [], len:0, data:''}
    request.id = sharedState.requests.add(request)

    sharedState.streams[streamId].unshift(request)

    res.oldEnd = res.end
    res.end = ->
      res.oldEnd()
      data = new Buffer(request.len)
      i = 0
      for chunk in request.parts
        chunk.copy data, i, 0, chunk.length
        i += chunk.length
      if request.res_headers['content-encoding'] == 'gzip'
        request.res_headers['compressed-size'] = data.length
        request.res_headers['chunks'] = request.parts.length
        zlib.gunzip data, (err, data) ->
          if err
            request.data = err
          else
            request.data = data
      else
        request.data = data


    res.oldWrite = res.write
    res.write = (chunk) ->
      res.oldWrite(chunk)
      request.parts.push(chunk)
      request.len += chunk.length

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

