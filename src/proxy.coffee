
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
    getTarget: (req) ->
      req.headers = caseHeaders(req.headers)
      interId = getInterceptorIdFromHost req.headers.Host
      @interceptor = models.interceptors.get interId
      req.headers.host = @interceptor.host
      host: @interceptor.host
      port: @interceptor.port ? 80

    onRequestWriteHead: (method, path, requestHeaders) ->
      host = @interceptor.host
      requestHeaders = caseHeaders requestHeaders
      @responseFilename = getFilename(path, 'download')
      @exchange = models.exchanges.create {
        method,
        path,
        host,
        requestHeaders}

      @interceptor.transcript.unshift(@exchange)
      @interceptor.transcriptEmitter.emit 'prepend', @exchange

      @exchange.requestData = models.files.create
        contentEncoding: requestHeaders['Content-Encoding']
        contentType: requestHeaders['Content-Type']
        contentLength: requestHeaders['Content-Length']
        fileName: 'postdata.txt'

      @onRequestWrite = @exchange.requestData.write
      @onRequestEnd = @exchange.requestData.end
     
    onResponseWriteHead: (statusCode, responseHeaders) ->
      responseHeaders = caseHeaders responseHeaders
      @exchange.responseStatus = statusCode
      @exchange.responseHeaders = responseHeaders
      @exchange.responseData = models.files.create
        contentEncoding: responseHeaders['Content-Encoding']
        contentType: responseHeaders['Content-Type']
        contentLength: responseHeaders['Content-Length']
        fileName: @responseFilename

      @onResponseWrite = @exchange.responseData.write
      @onResponseEnd = @exchange.responseData.end

  new ProxyServer(BetweenProxy)

