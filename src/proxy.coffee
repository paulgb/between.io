
fs = require 'fs'

{ProxyServer} = require('./proxyServer')
{FileBuffer} = require './fileBuffer'

getFilename = (path, def) ->
  if result = /([^\/]+)$/.exec(path)
    result[1]
  else
    def

module.exports = (app) ->
  {Interceptor, Exchange, File, idAllocator} = app.models
  getInterceptorIdFromHost = (host) ->
    hostbase = app.get 'proxy host'
    hregex = new RegExp("([\\d\\w]+)\\.#{hostbase}")
    result = hregex.exec(host)
    if result
      result[1]
    else
      console.log "no match for #{host}"

  caseHeaders = (headers) ->
    newHeaders = {}
    for header, value of headers
      header = header.replace /(^|-)\w/g, (a) -> a.toUpperCase()
      newHeaders[header] = value
    return newHeaders

  class BetweenProxy
    getTarget: (req, server, callback) =>
      req.headers = caseHeaders(req.headers)

      console.log req.headers.Host
      console.log req.url
      if /^proxy\./.exec(req.headers.Host)
        console.log 'proxy request'
        interId = 'proxy'
      else
        interId = getInterceptorIdFromHost req.headers.Host

      Interceptor.findById interId, (err, interceptor) =>
        if err?
          console.log err
          callback(err)
          return
        if not interceptor?
          callback "No interceptor for id #{interId}"
          return
        
        console.log interceptor
        @interceptor = interceptor

        if interceptor.type == 'proxy'
          console.log 'url:', req.url
          host = req.headers.host
        else
          req.headers.host = @interceptor.host
          host = @interceptor.host
          if server.https
            port = @interceptor.httpsPort
          else
            port = @interceptor.httpPort
        callback undefined, {host, port}

    onRequestWriteHead: (method, path, requestHeaders) =>
      host = @interceptor.host
      requestHeaders = caseHeaders requestHeaders
      @responseFilename = getFilename path, 'download'
      @exchange = new Exchange
        _id: idAllocator.take()
        host: host
        method: method
        path: path
        requestHeaders: requestHeaders
        interceptor: @interceptor.id
        user: @interceptor.user

      requestData = new File
        _id: idAllocator.take()
        contentEncoding: requestHeaders['Content-Encoding']
        contentType: requestHeaders['Content-Type']
        contentLength: requestHeaders['Content-Length']
        fileName: 'postdata.txt'
        user: @interceptor.user

      @exchange.requestData = requestData.id
      @exchange.save()

      file = new FileBuffer(requestHeaders['Content-Length'],
        requestHeaders['Content-Encoding'])

      file.on 'data', (data) =>
        requestData.data = data
        requestData.save()

      @onRequestWrite = file.write
      @onRequestEnd = file.end
     
    onResponseWriteHead: (statusCode, responseHeaders) =>
      responseHeaders = caseHeaders responseHeaders
      @exchange.responseStatus = statusCode
      @exchange.responseHeaders = responseHeaders

      responseData = new File
        _id: idAllocator.take()
        contentEncoding: responseHeaders['Content-Encoding']
        contentType: responseHeaders['Content-Type']
        contentLength: responseHeaders['Content-Length']
        fileName: @responseFilename
        user: @interceptor.user

      @exchange.responseData = responseData.id
      @exchange.save()

      file = new FileBuffer(responseHeaders['Content-Length'],
        responseHeaders['Content-Encoding'])

      file.on 'data', (data) =>
        responseData.data = data
        responseData.save()

      @onResponseWrite = file.write
      @onResponseEnd = file.end

  privateKey = fs.readFileSync(app.get('private key'), 'ascii')
  cert = fs.readFileSync(app.get('certificate'), 'ascii')
  if app.get('intermediate cert')
    ic = [fs.readFileSync(app.get('intermediate cert'), 'ascii')]
  else
    ic = []
  servers =
    http:
      port: app.get 'proxy port'
    https:
      port: app.get 'proxy https port'
      target:
        https: true
      https:
        key: privateKey
        cert: cert
        ca: ic
  new ProxyServer(BetweenProxy, servers)

