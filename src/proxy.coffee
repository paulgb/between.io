
fs = require 'fs'

{ProxyServer} = require('./proxyServer')
{Interceptor} = require('./models')

getFilename = (path, def) ->
  if result = /([^\/]+)$/.exec(path)
    result[1]
  else
    def

module.exports = (app, models) ->
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
    getTarget: (req, https) ->
      req.headers = caseHeaders(req.headers)
      interId = getInterceptorIdFromHost req.headers.Host
      @interceptor = models.interceptors.get interId
      if not @interceptor?
        return

      req.headers.host = @interceptor.host
      host = @interceptor.host
      if https
        port = 443
      else
        port = 80
      {host, port}

    onRequestWriteHead: (method, path, requestHeaders) ->
      host = @interceptor.host
      requestHeaders = caseHeaders requestHeaders
      @responseFilename = getFilename(path, 'download')
      @exchange = models.exchanges.create {
        method,
        path,
        host,
        requestHeaders}

      @interceptor.addExchange(@exchange)

      requestData = models.files.create
        contentEncoding: requestHeaders['Content-Encoding']
        contentType: requestHeaders['Content-Type']
        contentLength: requestHeaders['Content-Length']
        fileName: 'postdata.txt'

      @exchange.requestData = requestData.id
      @onRequestWrite = requestData.write
      @onRequestEnd = requestData.end
     
    onResponseWriteHead: (statusCode, responseHeaders) ->
      responseHeaders = caseHeaders responseHeaders
      @exchange.responseStatus = statusCode
      @exchange.responseHeaders = responseHeaders
      @interceptor.updateExchange(@exchange)

      responseData = models.files.create
        contentEncoding: responseHeaders['Content-Encoding']
        contentType: responseHeaders['Content-Type']
        contentLength: responseHeaders['Content-Length']
        fileName: @responseFilename

      @exchange.responseData = responseData.id
      @onResponseWrite = responseData.write
      @onResponseEnd = responseData.end

  privateKey = fs.readFileSync(app.get('private key'), 'ascii')
  cert = fs.readFileSync(app.get('certificate'), 'ascii')
  new ProxyServer(BetweenProxy, app.get('proxy port'),
    app.get('proxy https port'),
    privateKey,
    cert)

