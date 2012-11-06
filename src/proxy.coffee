
fs = require 'fs'

{ProxyServer} = require('./proxyServer')
{Interceptor, Exchange, File} = require './models'
{FileBuffer} = require './fileBuffer'

getFilename = (path, def) ->
  if result = /([^\/]+)$/.exec(path)
    result[1]
  else
    def

module.exports = (app) ->
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
      interId = getInterceptorIdFromHost req.headers.Host
      Interceptor.findById interId, (err, interceptor) =>
        @interceptor = interceptor
        if err
          console.log err
          callback(err)

        req.headers.host = @interceptor.host
        host = @interceptor.host
        if server.https
          port = 443
        else
          port = 80
        callback undefined, {host, port}

    onRequestWriteHead: (method, path, requestHeaders) =>
      host = @interceptor.host
      requestHeaders = caseHeaders requestHeaders
      @responseFilename = getFilename path, 'download'
      @exchange = new Exchange
        host: host
        method: method
        path: path
        requestHeaders: requestHeaders
        interceptor: @interceptor.id

      requestData = new File
        contentEncoding: requestHeaders['Content-Encoding']
        contentType: requestHeaders['Content-Type']
        contentLength: requestHeaders['Content-Length']
        fileName: 'postdata.txt'

      @exchange.save()

      file = new FileBuffer(requestHeaders['Content-Length'])

      file.on 'data', (data) =>
        requestData.data = data
        @exchange.requestData = requestData.id
        requestData.save()
        @exchange.save()

      @onRequestWrite = file.write
      @onRequestEnd = file.end
     
    onResponseWriteHead: (statusCode, responseHeaders) =>
      responseHeaders = caseHeaders responseHeaders
      @exchange.responseStatus = statusCode
      @exchange.responseHeaders = responseHeaders

      responseData = new File
        contentEncoding: responseHeaders['Content-Encoding']
        contentType: responseHeaders['Content-Type']
        contentLength: responseHeaders['Content-Length']
        fileName: @responseFilename

      @exchange.save()

      file = new FileBuffer(responseHeaders['Content-Length'])

      file.on 'data', (data) =>
        responseData.data = data
        @exchange.responseData = responseData.id
        responseData.save()
        @exchange.save()

      @onResponseWrite = file.write
      @onResponseEnd = file.end

  privateKey = fs.readFileSync(app.get('private key'), 'ascii')
  cert = fs.readFileSync(app.get('certificate'), 'ascii')
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
  new ProxyServer(BetweenProxy, servers)

