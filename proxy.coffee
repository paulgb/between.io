
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

  caseHeaders = (headers) ->
    newHeaders = {}
    for header, value of headers
      header = header.replace /(^|-)\w/g, (a) -> a.toUpperCase()
      newHeaders[header] = value
    return newHeaders

  proxy = httpProxy.createServer (req, res, proxy) ->
    streamId = getStreamFromHost(req.headers.host)
    host = getHost(streamId)
    port = 80
    path = req.url
    method = req.method
    req.headers = caseHeaders(req.headers)
    
    request = {host, port, path, method, req_headers: req.headers, res_headers: {}, parts: [], len:0, data:'', postdata:''}
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
    res.writeHead = (statusCode, headers) =>
      res.oldWriteHead statusCode, headers

      request.status = statusCode
      request.res_headers = headers

    req.on 'data', (data) ->
      request.postdata += data

    req.headers.Host = host
    console.log "Sending request to proxy #{host}, #{req.url}"
    proxy.proxyRequest req, res, {host, port}

  proxy.listen 80, ->
    console.log 'proxy server listening'

