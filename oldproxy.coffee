
httpProxy = require 'http-proxy'
http = require 'http'
zlib = require 'zlib'

class StreamingFile
  @fromHeaders: (headers) ->
    new StreamingFile(headers['content-type'],
                      headers['content-encoding'],
                      headers['content-length'])

  constructor: (@contentType, @contentEncoding, @contentLength) ->
    @chunks = []
    @lenProcessed = 0
    @status = 'open'

  pushData: (data) =>
    @chunks.push(data)
    @lenProcessed += data.length

  err: (@error) ->
    console.log("Error: #{@error}")

  end: =>
    if @contentLength? and @lenProcessed.toString() != @contentLength
      @status = 'error'
      @err("Bad content length (expected #{@contentLength} bytes, got #{@lenProcessed})")
    else if @lenProcessed == 0
      @status = 'no data'
      @data = ''
    else
      @rawData = new Buffer(@lenProcessed)
      i = 0
      for chunk in @chunks
        chunk.copy @rawData, i, 0, chunk.length
        i += chunk.length

      if @contentEncoding == 'gzip'
        zlib.gunzip @rawData, (err, data) =>
          if err
            @status = 'error'
            @err(err)
          else
            @status = 'done'
            @data = data
      else
        @status = 'done'
        @data = @rawData

module.exports = (app, sharedState) ->
  getHost = (streamId) ->
    sharedState.hostMap[streamId]

  getStreamFromHost = (host) ->
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

  proxy = httpProxy.createServer (req, res, proxy) ->
    streamId = getStreamFromHost(req.headers.host)

    exchange =
      stream: streamId
      host: getHost(streamId)
      port: 80
      path: req.url
      method: req.method
      requestHeaders: caseHeaders(req.headers)
      requestData: streamingFileFromHeaders(req.headers)

    exchange.id = sharedState.exchanges.add(exchange)

    if streamId not in sharedState.streams
      res.write('bad')
      return

    sharedState.streams[streamId].unshift(exchange)

    res.oldEnd = res.end
    res.end = ->
      res.oldEnd()
      exchange.responseData.end()

    res.oldWrite = res.write
    res.write = (chunk) ->
      res.oldWrite(chunk)
      exchange.responseData.pushData(chunk)

    res.oldWriteHead = res.writeHead
    res.writeHead = (statusCode, headers) ->
      res.oldWriteHead statusCode, headers

      exchange.responseStatus = statusCode
      exchange.responsePhrase = http.STATUS_CODES[statusCode]
      exchange.responseHeaders = caseHeaders(headers)
      exchange.responseData = streamingFileFromHeaders(headers)

    req.on 'data', exchange.requestData.pushData
    req.on 'end', exchange.requestData.end

    req.headers = caseHeaders(req.headers)
    req.headers.Host = exchange.host
    console.log "Sending request to proxy #{exchange.host}, #{exchange.path}"
    proxy.proxyRequest req, res, {host: exchange.host, port: exchange.port}

  proxy.listen 80, ->
    console.log 'proxy server listening'

