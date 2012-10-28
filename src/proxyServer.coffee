
httpProxy = require 'http-proxy'

exports.ProxyServer = class ProxyServer
  # Class representing an HTTP proxy, instrumented with 
  # hooks to capture and modify the request and response
  # before they are forwarded. It is left to subclasses
  # to implement these functions.
  #
  # The subclass can override the following methods:
  #   getTarget(req)
  #     given the request object, return an Object
  #     with attributes {host, port, https} of the server
  #     to target
  #   onRequestWriteHead(method, path, headers)
  #     called when the request headers are available
  #   onRquestData(data)
  #     called when a chunk of request data is sent
  #   onRequestEnd()
  #     called when the client is finished sending
  #     the request
  #   onResponseWriteHead(statusCode, headers)
  #     called when the server has responded with
  #     headers
  #   onResponseWrite(data)
  #     called when the server sends a chunk of data
  #   onResponseEnd()
  #     called when the server ends the connection
  constructor: (@port = 80) ->
    @proxy = httpProxy.createServer (req, res, proxy) =>
      @onRequestWriteHead? req.method, req.url, req.headers
      target = @getTarget req if @getTarget?

      res._oldEnd = res.end
      res.end = =>
        @onResponseEnd?()
        res._oldEnd()

      res._oldWrite = res.write
      res.write = (chunk) =>
        @onResponseWrite? chunk
        res._oldWrite chunk

      res._oldWriteHead = res.writeHead
      res.writeHead = (statusCode, headers) =>
        @onResponseWriteHead? statusCode, headers
        res._oldWriteHead statusCode, headers
      
      req.on 'data', @onRequestWrite if @onRequestWrite
      req.on 'end', @onRequestEnd if @onRequestEnd

      proxy.proxyRequest req, res, target

    @start()

  start: ->
    @proxy.listen @port, =>
      console.log "Proxy listening on port #{@port}"


